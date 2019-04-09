// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use IO:File:Path;
use IO:File;
use Db:SqlKeyValue as SqKvDb;
use Db:MemFileStoreKeyValue as MFSKvDb;
use Encode:Hex as Hex;
class MFSKvDb(SqKvDb) {

  pathNew(Path _dbp, String _tableName) self {
    new();
    fields {
      Path dbp = _dbp;
      tableName = _tableName;
      Path tbp = dbp.copy().addStep(Hex.encode(tableName));
      Set names = Set.new();
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
    for (File f in tbp.file) {
      String ls = f.path.lastStep;
      if (ls != "." && ls != "..") {
        names.put(eh.decode(ls));
      }
    }
  }
  
  close() self {
    names.clear();
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
    return(names.copy());
  }
  
  getMap() Map {
    Map res = Map.new();
    for (String k in names) {
      res.put(k, get(k));
    }  
    return(res);
  }
  
  getMap(String prefix) Map {
    Map res = Map.new();
    for (String k in names) {
      if (k.begins(prefix)) {
        res.put(k, get(k));
      }
    }
    return(res);
  }

  get(String name) String {
    Path np = tbp.copy().addStep(Hex.encode(name));
    if (np.file.exists) {
      return(np.file.contents);
    }
    return(null);
  }
  
  has(String name) Bool {
    return(names.has(name));
  }
  
  insert(String name, String value) {
    put(name, value);
  }
  
  update(String name, String value) {
    put(name, value);
  }
  
  put(String name, String value) {      
    names.put(name);
    Path np = tbp.copy().addStep(Hex.encode(name));
    np.file.contents = value;
  }
  
  testAndPut(String name, String oldValue, String value) Bool {
    Bool result = false;
    String cv = get(name);
    if (oldValue == cv) {
      put(name, value);
      names.put(name);
    }
    return(result);
  }
  
  delete(String name) {
    Path np = tbp.copy().addStep(Hex.encode(name));
    if (np.file.exists) { np.file.delete(); }
    names.delete(name);
  }
  
  clear() {
    //iterate/delete all keys, rmdir
    for (String k in names) {
      delete(k);
    }
    names.clear();
  }

}
