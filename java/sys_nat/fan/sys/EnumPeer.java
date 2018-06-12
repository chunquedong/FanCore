package fan.sys;

import fanx.fcode.FConst;
import fanx.main.Type;

public class EnumPeer {
	protected static Enum doFromStr(Type t, String name, boolean checked) {
		if ((t.flags() & FConst.Enum) != 0) {
			try {
				Class<?> jclass = t.getJavaClass();
				java.lang.reflect.Field field = jclass.getField(name);
				Object val = field.get(null);
				if (val instanceof Enum) {
					return (Enum) val;
				}
			} catch (Exception e) {
//				e.printStackTrace();
			}
		}
		if (!checked)
			return null;
		throw ParseErr.make(name);
	}
}
