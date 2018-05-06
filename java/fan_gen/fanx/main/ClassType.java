package fanx.main;

import fanx.fcode.FType;

public class ClassType extends Type
{
	FType ftype;
	Class<?> jtype;
	
	public ClassType(FType t) {
		ftype = t;
	}

	@Override
	public String podName() {
		return ftype.podName();
	}

	@Override
	public String name() {
		return ftype.typeName();
	}

	@Override
	public String qname() {
		return ftype.qname();
	}

	@Override
	public String signature() {
		return ftype.signature();
	}

	@Override
	public boolean isNullable() {
		return false;
	}

	@Override
	public Class<?> getJavaClass() {
		return jtype;
	}

	@Override
	public void precompiled(Class<?> clz) {
		jtype = clz;
	}

	@Override
	public boolean fits(Type t) {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public boolean isObj() {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public long flags() {
		return ftype.flags;
	}

	@Override
	public Type toNullable() {
		return new NullableType(this);
	}

}