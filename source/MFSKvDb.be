// Copyright 2015 The BraceApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

use IO:File:Path;
use IO:File;
use System:Parameters;
use Db:MemFileStoreKeyValue as MFSKvDb;
use Encode:Hex as Hex;
class MFSKvDb {

  pathParamsNew(Path _dbp, Parameters _params, String _tableName) self {
    new();
    fields {
      IO:Log log =@ IO:Logs.get(self);
      Path dbp = _dbp;
      String tableName = _tableName;
      Parameters params = _params;
      Path tbp = dbp.copy().addStep(Hex.encode(tableName));
    }
  }

  dbCheck() {
  }
    
  new(String _tableName) self {
    new();
    tableName = _tableName;
  }
  
  dbFailed() {
    any e;
    try {
      close();
    } catch (e) {
    
    }
    open();
  }
  
  open() self {
    Hex eh = Hex.new();
    if (tbp.file.exists!) { tbp.file.makeDirs(); }
    //for (File f in tbp.file) {
    //  String ls = f.path.lastStep;
    //  if (ls != "." && ls != "..") {
    //    names.put(eh.decode(ls));
    //  }
    //}
  }
  
  close() self {
  }
  
  create() self {
    
    if (tbp.file.exists!) {
      tbp.file.mkdirs();
    }
    
  }
  
  drop() self {
    clear();
    tbp.file.delete();
  }
  
  getSet() Set {
    Hex eh = Hex.new();
    Set names = Set.new();
    for (File f in tbp.file) {
      String ls = f.path.lastStep;
      if (ls != "." && ls != "..") {
        names.put(eh.decode(ls));
      }
    }
    return(names);
  }
  
  getMap() Map {
    Hex eh = Hex.new();
    Map res = Map.new();
    for (File f in tbp.file) {
      String ls = f.path.lastStep;
      if (ls != "." && ls != "..") {
        String k = eh.decode(ls);
        res.put(k, get(k));
      }
    }  
    return(res);
  }
  
  getMap(String prefix) Map {
    Hex eh = Hex.new();
    Map res = Map.new();
    for (File f in tbp.file) {
      String ls = f.path.lastStep;
      if (ls != "." && ls != "..") {
        String k = eh.decode(ls);
        if (k.begins(prefix)) {
          res.put(k, get(k));
        }
      }
    }  
    return(res);
  }
  
  get(String name, String default) String {
    String val = self.get(name);
    if (undef(val)) {
      return(default);
    }
    return(val);
  }


  get(String name) String {
    Path np = tbp.copy().addStep(Hex.encode(name));
    if (np.file.exists) {
      return(np.file.contents);
    }
    return(null);
  }
  
  has(String name) Bool {
    Path np = tbp.copy().addStep(Hex.encode(name));
    if (np.file.exists) {
      return(true);
    }
    return(false);
  }
  
  insert(String name, String value) {
    put(name, value);
  }
  
  update(String name, String value) {
    put(name, value);
  }
  
  put(String name, String value) {  
    //log.log("in mfs put2");
    Path np = tbp.copy().addStep(Hex.encode(name));
    np.file.contents = value;
    //log.log("mfs put2 done")
  }
  
  testAndPut(String name, String oldValue, String value) Bool {
    Bool result = false;
    String cv = get(name);
    if (oldValue == cv) {
      put(name, value);
      result = true;
    }
    return(result);
  }
  
  delete(String name) {
    Path np = tbp.copy().addStep(Hex.encode(name));
    if (np.file.exists) { np.file.delete(); }
  }
  
  clear() {
    //iterate/delete all keys, rmdir
    for (String k in getSet()) {
      delete(k);
    }
  }

}
