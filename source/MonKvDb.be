// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use IO:File:Path;
use IO:File;
use System:Parameters;
use Db:MongoKeyValue as MonKvDb;
use Encode:Hex as Hex;

emit(jv) {
"""
import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;
import com.mongodb.DBCursor;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.MongoClient; 
"""
}

class MonKvDb {

emit(jv) {
"""
    MongoClient mongoClient;
    DB database;
    DBCollection collection;
"""
}

  pathParamsNew(Path _dbp, Parameters _params, String _tableName) self {
    new();
    fields {
      IO:Log log =@ IO:Logs.get(self);
      String tableName = _tableName;
      Parameters params = _params;
      String monDb;
      String monTableName;
    }
    monDb = params.getFirst("monDb");
    monTableName = "kvt" + tableName;
  }

  dbCheck() {
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
    emit(jv) {
    """
    mongoClient = new MongoClient();
    database = mongoClient.getDB(bevp_monDb.bems_toJvString());
    collection = database.getCollection(bevp_monTableName.bems_toJvString());
    """
    }
  }
  
  close() self {
    emit(jv) {
    """
    if (mongoClient != null) {
      mongoClient.close();
      mongoClient = null;
      database = null;
      collection = null;
    }
    """
    }
  }
  
  create() self {
  }
  
  drop() self {
    clear();
  }
  
  getSet() Set {
    Set names = Set.new();
    Map kvs = getMap();
    for (auto kv in kvs) {
      names.put(kv.key);
    }
    return(names);
  }
  
  getMap(String prefix) Map {
      Map res = Map.new();
      String rk;
      String rv;
      emit(jv) {
      """
      try {
      

      } catch (Throwable t) {
        System.out.println("got error getMapping0 from mon");
        System.out.println(t.getMessage());
        System.out.println(t.getStackTrace());
      }
      """
      }
    return(res);
  }
  
  getMap() Map {
      Map res = Map.new();
      String rk;
      String rv;
      emit(jv) {
      """
      try {

      } catch (Throwable t) {
        System.out.println("got error getMapping0 from mon");
        System.out.println(t.getMessage());
        System.out.println(t.getStackTrace());
      }
      """
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
  String res;
  emit(jv) {
  """
  try {
    String kvn = beva_name.bems_toJvString();
    DBObject query = new BasicDBObject("_id", kvn);
    DBCursor cursor = collection.find(query);
    if (cursor.hasNext()) {
      DBObject dbo = cursor.next();
      if (((String) dbo.get("kvdbname")).equals(kvn)) {
        Object kvdbvalueo = dbo.get("kvdbvalue");
        if (kvdbvalueo != null) {
          String kvdbvalue = (String) kvdbvalueo;
          bevl_res = new $class/Text:String$(kvdbvalue);
        }
      }
    }
  } catch (Throwable t) {
    System.out.println("got error reading from mon");
    System.out.println(t.getMessage());
    System.out.println(t.getStackTrace());
  }
  """
  }
    return(res);
  }
  
  put(String name, String value) {
  emit(jv) {
  """
  try {
    String kvn = beva_name.bems_toJvString();
    String kvv = beva_value.bems_toJvString();
    BasicDBObject dbo =  new BasicDBObject("_id", kvn)
    .append("kvdbname", kvn)
    .append("kvdbvalue", kvv);
    collection.save(dbo);
  } catch (Throwable t) {
    System.out.println("got error writing to mon");
    System.out.println(t.getMessage());
    System.out.println(t.getStackTrace());
  }
  """
  }
  }
  
  has(String name) Bool {
    Bool resb = false;
    Bool t = true;
    emit(jv) {
    """
    try {

    } catch (Throwable t) {
      System.out.println("got error hassing mon");
      System.out.println(t.getMessage());
      System.out.println(t.getStackTrace());
    }
    """
    }
    return(resb);
  }
  
  insert(String name, String value) {
    put(name, value);
  }
  
  update(String name, String value) {
    put(name, value);
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
  
    emit(jv) {
    """
    try {

    } catch (Throwable t) {
      System.out.println("got error deleting mon");
      System.out.println(t.getMessage());
      System.out.println(t.getStackTrace());
    }
    """
    }
  
  }
  
  clear() {
    for (String k in getSet()) {
      delete(k);
    }
  }

}
