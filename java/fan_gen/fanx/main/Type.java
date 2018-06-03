//
// Copyright (c) 2018, chunquedong
// Licensed under the Academic Free License version 3.0
//
// History:
//   2018-5-18 Jed Young Creation
//
package fanx.main;

import java.util.List;
import java.util.Map;

import fanx.fcode.FConst;
import fanx.fcode.FType;

public abstract class Type {

	public Map<String, Object> slots = null;
	public Map<String, List<Object>> jslots = null;

	public Object emptyList;

	public abstract String podName();

	public abstract String name();

	public abstract String qname();

	public abstract String signature();

	public abstract boolean isNullable();

	public abstract Class<?> getJavaClass();

	public abstract void precompiled(Class<?> clz);

	public boolean fits(Type t) {
		return is(this.toNonNullable(), t.toNonNullable());
	}

	public static boolean is(Type self, Type type) {
		// we don't take nullable into account for fits
		if (type instanceof NullableType)
			type = ((NullableType) type).root;

		if (type == self || (type.isObj()))
			return true;
		//TODO
//		List inheritance = inheritance(self);
//		for (int i = 0; i < inheritance.size(); ++i)
//			if (inheritance.get(i) == type)
//				return true;
		return false;
	}

	public abstract boolean isObj();

	public abstract long flags();

	public Type toNonNullable() {
		return this;
	}

	public Type toNullable() {
		return new NullableType(this);
	}

	public boolean isConst() {
		return (flags() & FConst.Const) != 0;
	}

	public boolean isGenericType() {
		return false;
	}

	@Override
	public String toString() {
		return signature();
	}

	public FType ftype() {
		return null;
	}

	public static Type fromFType(FType ftype) {
		if (ftype.reflectType == null) {
			ClassType ct = new ClassType(ftype);
			ftype.reflectType = ct;
		}
		Type res = (Type) ftype.reflectType;
		return res;
	}

}
