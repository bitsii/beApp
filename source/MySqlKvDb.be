/*
 * Copyright (c) 2015-2023, the Beysant App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

use IO:File:Path;
use IO:File;
use System:Parameters;
use Db:MongoKeyValue as MonKvDb;
use Encode:Hex as Hex;

emit(jv) {
"""
import java.util.regex.Pattern;
import java.util.HashMap;

import java.sql.*;
"""
}

class MonKvDb {

emit(jv) {
"""
    MongoClient mongoClient;
    DB database;
    DBCollection collection;
    static HashMap<String, MongoClient> clients = new HashMap<String, MongoClient>();
"""
}

  pathParamsNew(Path _dbp, Parameters _params, String _tableName) self {
    new();
    fields {
      IO:Log log = IO:Logs.get(self);
      String tableName = _tableName;
      Parameters params = _params;
      String monDb;
      String monTableName;
      String monUri;
    }
    monDb = params.getFirst("monDb");
    monTableName = "kvt" + tableName;
    monUri = params.getFirst("monUri");
    if (TS.isEmpty(monUri)) {
      monUri = "mongodb://localhost:27017";
    }
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
    synchronized(clients) {
      String juris = bevp_monUri.bems_toJvString();
      mongoClient = clients.get(juris);
      if (mongoClient == null) {
        mongoClient = new MongoClient(new MongoClientURI(juris));
        clients.put(juris, mongoClient);
      }
    }
    database = mongoClient.getDB(bevp_monDb.bems_toJvString());
    collection = database.getCollection(bevp_monTableName.bems_toJvString());
    """
    }
  }
  
  close() self {
    emit(jv) {
    """
    if (mongoClient != null) {
      //mongoClient.close(); - nope, let mongo handle - connection pooling
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
    for (var kv in kvs) {
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
      /*-attr- -noreplace-*/
      
      BasicDBObject regexQuery = new BasicDBObject();
      regexQuery.put("_id", 
        new BasicDBObject("$regex", "^" + Pattern.quote(beva_prefix.bems_toJvString())));
      """
      }
      emit(jv) {
      """
      try {
        DBCursor cursor = collection.find(regexQuery);
        while (cursor.hasNext()) {
          DBObject dbo = cursor.next();
          bevl_rk = null;
          bevl_rv = null;
          Object kvdbvalueo = dbo.get("kvdbvalue");
          if (kvdbvalueo != null) {
            String kvdbvalue = (String) kvdbvalueo;
            bevl_rv = new $class/Text:String$(kvdbvalue);
          }
          Object kvdbnameo = dbo.get("_id");
          if (kvdbnameo != null) {
            String kvdbname = (String) kvdbnameo;
            bevl_rk = new $class/Text:String$(kvdbname);
            bevl_res.bem_put_2(bevl_rk, bevl_rv);
          }
        }
        cursor.close();
      } catch (Throwable t) {
        System.out.println("got error reading from mon getmap");
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
        DBCursor cursor = collection.find();
        while (cursor.hasNext()) {
          DBObject dbo = cursor.next();
          bevl_rk = null;
          bevl_rv = null;
          Object kvdbvalueo = dbo.get("kvdbvalue");
          if (kvdbvalueo != null) {
            String kvdbvalue = (String) kvdbvalueo;
            bevl_rv = new $class/Text:String$(kvdbvalue);
          }
          Object kvdbnameo = dbo.get("_id");
          if (kvdbnameo != null) {
            String kvdbname = (String) kvdbnameo;
            bevl_rk = new $class/Text:String$(kvdbname);
            bevl_res.bem_put_2(bevl_rk, bevl_rv);
          }
        }
        cursor.close();
      } catch (Throwable t) {
        System.out.println("got error reading from mon getmap");
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
        Object kvdbvalueo = dbo.get("kvdbvalue");
        if (kvdbvalueo != null) {
          String kvdbvalue = (String) kvdbvalueo;
          bevl_res = new $class/Text:String$(kvdbvalue);
        }
    }
    cursor.close();
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
    //.append("kvdbname", kvn)
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
  Bool res = false;
  Bool t = true;
  emit(jv) {
  """
  try {
    String kvn = beva_name.bems_toJvString();
    DBObject query = new BasicDBObject("_id", kvn);
    DBCursor cursor = collection.find(query);
    if (cursor.hasNext()) {
      bevl_res = bevl_t;
    }
    cursor.close();
  } catch (Throwable t) {
    System.out.println("got error hassing from mon");
    System.out.println(t.getMessage());
    System.out.println(t.getStackTrace());
  }
  """
  }
    return(res);
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
  
  remove(String name) {
  emit(jv) {
  """
  try {
    String kvn = beva_name.bems_toJvString();
    DBObject query = new BasicDBObject("_id", kvn);
    collection.remove(query);
  } catch (Throwable t) {
    System.out.println("got error reading from mon");
    System.out.println(t.getMessage());
    System.out.println(t.getStackTrace());
  }
  """
  }
  }
  
  clear() {
    for (String k in getSet()) {
      remove(k);
    }
  }

}
