package fan.reflect;

import fan.sys.ArgErr;
import fan.sys.FanObj;
import fan.sys.List;
import fan.sys.FanObj.InvokeTrapper;
import fanx.main.Type;

public class ReflectInvoker implements InvokeTrapper {
	@Override
	public Object doTrap(Object self, String name, List args, Type type) {
		if (self != null && name.equals("typeof")) {
			return FanObj.typeof(self);
		}
		Slot slot = FanType.slot(type, name);
		if (slot instanceof Method) {
			Method m = (Method)slot;
			if (m.isStatic() || m.isCtor()) {
				return m.callList(args);
			}
			return m.callOn(self, args);
		}
		else if (slot instanceof Field) {
			Field f = (Field)slot;
			int argc = args == null ? 0 : (int)args.size();
			if (argc == 0) {
				return f.get(self);
			}
			else if (argc == 1) {
				f.set(self, args.get(0));
				return null;
			}
		}
		throw ArgErr.make("Invalid number of args to get or set field '" + name + "'("+args+")");
	}
}