//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Jul 06  Brian Frank  Creation
//

**************************************************************************
** Parameterized
**************************************************************************

**
** common parameterized type for user define generic type ref
**
class ParameterizedType : ProxyType {
  override Bool hasGenericParameter
  CType[] genericParams

  static new create(CType baseType, CType[] params) {
    if (baseType.qname == "sys::List") {
      return ListType(params.first)
    }
    else if (baseType.qname == "std::Map") {
      return MapType(params.first, params.last)
    }
    else if (baseType.qname == "sys::Func") {
      ret := params.first
      types := CType[,]
      names := Str[,]
      for (i:=1; i<params.size; ++i) {
        types.add(params[i])
        names.add(('a'+i-1).toCode)
      }
      return FuncType(types, names, params.first)
    }
    else {
      return ParameterizedType.make(baseType, params)
    }
  }

  protected new make(CType baseType, CType[] params)
    : super(baseType)
  {
    this.genericParams = params
    hasGenericParameter = params.any { it.hasGenericParameter }
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override Bool isVal() { false }

  override Bool isNullable() { false }
  override once CType toNullable() { NullableType(this) }
  override CType toNonNullable() { return this }

  override Bool isGeneric() { false }
  override Bool isParameterized() { true }

  override once CType toListOf() { ListType(this) }

  override once COperators operators() { COperators(this) }

  override once Str:CSlot slots() { parameterizeSlots }

  override Bool isValid() { root.isValid && genericParams.all { it.isValid }}

  override Int flags()
  {
    baseFlags := root.flags
    if (root.isPublic && genericParams.all { it.isPublic })
      baseFlags = baseFlags.or(FConst.Public)
    else
      baseFlags = baseFlags.and(FConst.Public.not)
      baseFlags = baseFlags.or(FConst.Internal)
    return baseFlags
  }

  override Bool fits(CType t)
  {
    t = t.toNonNullable
    if (this == t) return true
    if (t == root) return true
    if (t.isObj) return true
    if (t.qname == root.qname) return true
    return false
  }

  private Str:CSlot parameterizeSlots()
  {
    root.slots.map |CSlot slot->CSlot| { parameterizeSlot(slot) }
  }

  private CSlot parameterizeSlot(CSlot slot)
  {
    if (slot is CMethod)
    {
      CMethod m := slot
      if (!m.isGeneric) return slot
      p := ParameterizedMethod(this, m)
      return p
    }
    else
    {
      f := (CField)slot
      if (!f.fieldType.hasGenericParameter) return slot
      p := ParameterizedField(this, f)
      return p
    }
  }

  internal CType parameterize(CType t)
  {
    if (!t.hasGenericParameter) return t
    nullable := t.isNullable
    nn := t.toNonNullable

    if (nn is ParameterizedType) {
      pt := (ParameterizedType)nn
      params := pt.genericParams.map |p|{ parameterize(p) }
      t = ParameterizedType.create(pt.root, params)
    }
    else {
      t = doParameterize(((GenericParamType)nn).paramName)
    }
    t = nullable ? t.toNullable : t
    return t
  }

  virtual CType doParameterize(Str name)
  {
    gp := root.getGenericParamType(name)
    if (gp == null) {
      throw Err(name)
    }

    return genericParams.getSafe(gp.index, gp.bound)
  }

  //override once Str signature() { "$qname$extName" }
  override once Str extName() { "<"+genericParams.join(",",|s|{ s.signature })+">" }
}

**************************************************************************
** ListType
**************************************************************************

**
** ListType models a parameterized List type.
**
class ListType : ParameterizedType
{
  new make(CType v)
    : super(v.ns.listType, [v])
  {
    this.v = v
  }

  CType v { private set }
}

**************************************************************************
** MapType
**************************************************************************

**
** MapType models a parameterized Map type.
**
class MapType : ParameterizedType
{
  new make(CType k, CType v)
    : super(k.ns.mapType, [k,v])
  {
    this.k = k
    this.v = v
  }

  CType k { private set }        // keytype
  CType v { private set }        // value type
}

**************************************************************************
** FuncType
**************************************************************************

**
** FuncType models a parameterized Func type.
**
class FuncType : ParameterizedType
{
  new make(CType[] params, Str[] names, CType ret)
    : super(ret.ns.funcType, [ret].addAll(params))
  {
    this.params = params
    this.names  = names
    this.ret    = ret
  }

  new makeItBlock(CType itType)
    : this.make([itType], ["it"], itType.ns.voidType)
  {
    // sanity check
    if (itType.isThis) throw Err("Invalid it-block func signature: $this")
  }

  override Bool fits(CType ty)
  {
    t := ty.deref.raw.toNonNullable
    if (this == t) return true
    if (t.qname == "sys::Func") return true
    if (t.isObj) return true
    //TODO: not sure
    //if (t.name.size == 1 && t.pod.name == "sys") return true

    that := t as FuncType
    if (that == null) return false

    // match return type (if void is needed, anything matches)
    if (!that.ret.isVoid && !ret.fits(that.ret)) return false

    // match params - it is ok for me to have less than
    // the type params (if I want to ignore them), but I
    // must have no more
    if (params.size > that.params.size) return false
    for (i:=0; i<params.size; ++i)
      if (!that.params[i].fits(params[i])) return false

    // this method works for the specified method type
    return true;
  }

  Int arity() { params.size }

  FuncType toArity(Int num)
  {
    if (num == params.size) return this
    if (num > params.size) throw Err("Cannot increase arity $this")
    return make(params[0..<num], names[0..<num], ret)
  }

  FuncType mostSpecific(FuncType b)
  {
    a := this
    if (a.arity != b.arity) throw Err("Different arities: $a / $b")
    params := a.params.map |p, i| { toMostSpecific(p, b.params[i]) }
    ret := toMostSpecific(a.ret, b.ret)
    return make(params, b.names, ret)
  }

  static CType toMostSpecific(CType a, CType b)
  {
    if (b.hasGenericParameter) return a
    if (a.isObj || a.isVoid || a.hasGenericParameter) return b
    return a
  }

  ParamDef[] toParamDefs(Loc loc)
  {
    p := ParamDef[,]
    p.capacity = params.size
    for (i:=0; i<params.size; ++i)
    {
      p.add(ParamDef(loc, params[i], names[i]))
    }
    return p
  }

  **
  ** Return if this function type has 'This' type in its signature.
  **
  Bool usesThis()
  {
    return ret.isThis || params.any |CType p->Bool| { p.isThis }
  }

  override Bool isValid()
  {
    (ret.isVoid || ret.isValid) && params.all |CType p->Bool| { p.isValid }
  }

  **
  ** Replace any occurance of "sys::This" with thisType.
  **
  override FuncType parameterizeThis(CType thisType)
  {
    if (!usesThis) return this
    f := |CType t->CType| { t.isThis ? thisType : t }
    return FuncType(params.map(f), names, f(ret))
  }

  CType[] params { private set } // a, b, c ...
  Str[] names    { private set } // parameter names
  CType ret      { private set } // return type
  Bool unnamed                   // were any names auto-generated
  Bool inferredSignature   // were one or more parameters inferred
}

**************************************************************************
** GenericParameterType
**************************************************************************

**
** GenericParameterType models the generic parameter types
** sys::V, sys::K, etc.
**

class GenericParamType : ProxyType {
  CType bound() { super.root }
  override Str name() { "${parent.name}^${paramName}" }
  override Str qname() { "${parent.qname}^${paramName}" }
  CType parent
  Str paramName
  Int index

  new make(CNamespace ns, Str name, CType bound, CType parent, Int index) : super(bound) {
    this.parent = parent
    this.paramName = name
    this.index = index
  }

  override CPod pod() { parent.pod }

  override CType raw() {
    raw := bound
    if (isNullable) raw = raw.toNullable
    return raw
  }

  override Bool isNullable() { return true }

  override Bool hasGenericParameter() { true }
}

**************************************************************************
** ParameterizedField
**************************************************************************

class ParameterizedField : CField
{
  new make(ParameterizedType parent, CField generic)
  {
    this.parent = parent
    this.generic = generic
    this.fieldType = parent.parameterize(generic.fieldType)
    this.getter = ParameterizedMethod(parent, generic.getter)
    this.setter = ParameterizedMethod(parent, generic.setter)
  }

  override Str name()  { generic.name }
  override Str qname() { generic.qname }
  override Str signature() { generic.signature }
  override Int flags() { generic.flags }
  override CFacet? facet(Str qname) { generic.facet(qname) }

  override CType fieldType
  override CMethod? getter
  override CMethod? setter
  override CType inheritedReturnType() { fieldType }

  override Bool isParameterized() { true }

  override CType parent { private set }
  private CField generic { private set }
}

**************************************************************************
** ParameterizedMethod
**************************************************************************

**
** ParameterizedMethod models a parameterized CMethod
**
class ParameterizedMethod : CMethod
{
  new make(ParameterizedType parent, CMethod generic)
  {
    this.parent = parent
    this.generic = generic

    this.returnType = parent.parameterize(generic.returnType)
    this.params = generic.params.map |CParam p->CParam|
    {
      if (!p.paramType.hasGenericParameter)
        return p
      else
        return ParameterizedMethodParam(parent, p)
    }

    signature = "$returnType $name(" + params.join(", ") + ")"
  }

  override Str name()  { generic.name }
  override Str qname() { generic.qname }
  override Int flags() { generic.flags }
  override CFacet? facet(Str qname) { generic.facet(qname) }

  override Bool isParameterized()  { true }

  override CType inheritedReturnType()  { generic.inheritedReturnType }

  override CType parent     { private set }
  override Str signature    { private set }
  override CMethod? generic { private set }
  override CType returnType { private set }
  override CParam[] params  { private set }
}

**************************************************************************
** ParameterizedMethodParam
**************************************************************************

class ParameterizedMethodParam : CParam
{
  new make(ParameterizedType parent, CParam generic)
  {
    this.generic = generic
    this.paramType = parent.parameterize(generic.paramType)
  }

  override Str name() { generic.name }
  override Bool hasDefault() { generic.hasDefault }
  override Str toStr() { "$paramType $name" }

  override CType paramType { private set }
  private CParam generic { private set }
}