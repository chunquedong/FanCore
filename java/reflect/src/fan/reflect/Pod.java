package fan.reflect;

import fan.sys.*;
import fanx.fcode.*;
import fanx.main.*;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import fan.reflect.*;
import fan.std.Log;
import fan.std.Map;

public class Pod extends FanObj {
	FPod fpod;
	Version version;
	List depends;
	Map meta;

	boolean docLoaded;
	String doc;

	Log log;
	List types;

	private static Type typeof;

	public Type typeof() {
		if (typeof == null) {
			typeof = Sys.findType("reflect::Pod");
		}
		return typeof;
	}

	//////////////////////////////////////////////////////////////////////////
	// Management
	//////////////////////////////////////////////////////////////////////////

	private Pod(FPod pod) {
		fpod = pod;
	}
	
	public static Pod fromFPod(FPod fpod) {
		if (fpod.reflectPod == null) {
			fpod.reflectPod = new Pod(fpod);
		}
		return (Pod)fpod.reflectPod;
	}

	public static Pod of(Object obj) {
		if (obj instanceof FanObj) {
			TypeExt.pod(((FanObj) obj).typeof());
		}
		return null;
	}

	public static Pod find(String name) {
		return find(name, true);
	}

	public static Pod find(String name, boolean checked) {
		FPod p = Sys.findPod(name);
		if (p == null) {
			if (checked)
				throw UnknownPodErr.make(name);
			return null;
		}
		return fromFPod(p);
	}

	public static List list() {
		java.util.List<String> names = Sys.listPod();
		List list = List.make(Sys.findType("reflect::Pod"), names.size());
		for (String n : names) {
			list.add(find(n));
		}
		return list;
	}

	//////////////////////////////////////////////////////////////////////////
	// Methods
	//////////////////////////////////////////////////////////////////////////

	public final String name() {
		return fpod.podName;
	}

	public final Version version() {
		if (version == null)
			version = Version.fromStr(fpod.podVersion);
		return version;
	}

	public final List depends() {
		if (depends == null) {
			List dps = (List) List.make(Sys.findType("reflect::Depends"), fpod.depends.length);
			for (String n : fpod.depends) {
				dps.add(Depend.fromStr(n));
			}
			depends = (List) dps.toImmutable();
		}
		return depends;
	}

	// public final Uri uri() {
	// if (uri == null)
	// uri = Uri.fromStr("fan://" + name);
	// return uri;
	// }

	public final String toStr() {
		return name();
	}

	public final Map meta() {
		if (meta == null) {
			Map m = Map.make();
			for (java.util.Map.Entry<String, String> entry : fpod.meta.entrySet()) {
				m.set(entry.getKey(), entry.getValue());
			}
			meta = (Map) m.toImmutable();
		}
		return meta;
	}

	//////////////////////////////////////////////////////////////////////////
	// Types
	//////////////////////////////////////////////////////////////////////////

	public List types() {
		if (types == null) {
			List list = List.make(FanType.type, fpod.types.length);
			for (FType f : fpod.types) {
				if (f.isSynthetic()) continue;
				Type t = Type.fromFType(f);
				list.add(t);
			}
			types = list;
		}
		return types;
	}

	public Type type(String name) {
		return type(name, true);
	}

	public Type type(String name, boolean checked) {
		FType ftype = fpod.type(name, checked);
		Type type = Type.fromFType(ftype);
		if (type != null)
			return type;
		if (checked)
			throw UnknownTypeErr.make(this.name() + "::" + name);
		return null;
	}

	//////////////////////////////////////////////////////////////////////////
	// Documentation
	//////////////////////////////////////////////////////////////////////////

	public String doc() {
		if (!docLoaded) {
			try {
				java.io.InputStream in = fpod.store.read("doc/pod.fandoc");
				if (in != null) {
					BufferedReader br = new BufferedReader(new InputStreamReader(in));
					try {
						StringBuilder sb = new StringBuilder();
						String line = br.readLine();
						while (line != null) {
							sb.append(line);
							sb.append("\n");
							line = br.readLine();
						}
						doc = sb.toString();
					} finally {
						br.close();
					}
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
			docLoaded = true;
		}
		return doc;
	}

	//////////////////////////////////////////////////////////////////////////
	// Files
	//////////////////////////////////////////////////////////////////////////

	// public final List files() {
	// loadFiles();
	// return filesList;
	// }
	//
	// public final fan.sys.File file(Uri uri) {
	// return file(uri, true);
	// }
	//
	// public final fan.sys.File file(Uri uri, boolean checked) {
	// loadFiles();
	// if (!uri.isPathAbs())
	// throw ArgErr.make("Pod.files Uri must be path abs: " + uri);
	// if (uri.auth() != null && !uri.toStr().startsWith(uri().toStr()))
	// throw ArgErr.make("Invalid base uri `" + uri + "` for `" + uri() + "`");
	// else
	// uri = this.uri().plus(uri);
	// fan.sys.File f = (fan.sys.File) filesMap.get(uri);
	// if (f != null || !checked)
	// return f;
	// throw UnresolvedErr.make(uri.toStr());
	// }
	//
	// private void loadFiles() {
	// synchronized (filesMap) {
	// if (filesList != null)
	// return;
	// if (fpod.store == null)
	// throw Err.make("Not backed by pod file: " + name);
	// List list;
	// try {
	// this.filesList = (List) fpod.store.podFiles(uri()).toImmutable();
	// } catch (java.io.IOException e) {
	// e.printStackTrace();
	// throw Err.make(e);
	// }
	// for (int i = 0; i < filesList.sz(); ++i) {
	// fan.sys.File f = (fan.sys.File) filesList.get(i);
	// filesMap.put(f.uri(), f);
	// }
	// }
	// }
	//
	// public fan.sys.File loadFile() {
	// if (loadFile == null) {
	// if (fpod == null)
	// return null;
	// java.io.File jfile = fpod.loadFile();
	// if (jfile == null)
	// return null;
	// loadFile = new LocalFile(jfile).normalize();
	// }
	// return (fan.sys.File) loadFile;
	// }

	//////////////////////////////////////////////////////////////////////////
	// Utils
	//////////////////////////////////////////////////////////////////////////

	public final Log log() {
		if (log == null)
			log = Log.get(name());
		return log;
	}

	// public final Map props(Uri uri, Duration maxAge) {
	// return Env.cur().props(this, uri, maxAge);
	// }
	//
	// public final String config(String key) {
	// return Env.cur().config(this, key);
	// }
	//
	// public final String config(String key, String def) {
	// return Env.cur().config(this, key, def);
	// }
	//
	// public final String locale(String key) {
	// return Env.cur().locale(this, key);
	// }
	//
	// public final String locale(String key, String def) {
	// return Env.cur().locale(this, key, def);
	// }

}
