// Copyright 2015 The Bennt App Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

use IO:File:Path;
use IO:File;
use System:Parameters;
use Db:FireStoreKeyValue as GFSKvDb;
use Encode:Hex as Hex;

//FIRESTORE IS SLOW, DO NOT RECOMMEND

emit(jv) {
"""
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.FirestoreOptions;

import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import com.google.common.collect.ImmutableMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
"""
}

class GFSKvDb {

emit(jv) {
"""
   public Firestore bevi_db;
"""
}

  pathParamsNew(Path _dbp, Parameters _params, String _tableName) self {
    new();
    fields {
      IO:Log log = IO:Logs.get(self);
      String tableName = _tableName;
      Parameters params = _params;
      String gfsPrefix;
      String gfsProject;
      String gfsTableName;
    }
    gfsPrefix = params.getFirst("gfsPrefix");
    gfsProject = params.getFirst("gfsProject");
    gfsTableName = gfsPrefix + tableName;
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
    emit(jv) {
    """
    FirestoreOptions firestoreOptions =
    FirestoreOptions.getDefaultInstance().toBuilder()
        .setProjectId(bevp_gfsProject.bems_toJvString())
        .build();
    bevi_db = firestoreOptions.getService();
    """
    }
  }
  
  close() self {
    emit(jv) {
    """
    if (bevi_db != null) {
      bevi_db.close();
      bevi_db = null;
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
      
        CollectionReference cr = bevi_db.collection(bevp_gfsTableName.bems_toJvString());
        
        Query query = cr.whereGreaterThanOrEqualTo("kvdbname", beva_prefix.bems_toJvString()).whereLessThanOrEqualTo("kvdbname", beva_prefix.bems_toJvString()+"\uf8ff");
        
        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        
        for (QueryDocumentSnapshot document : querySnapshot.get().getDocuments()) {
          bevl_rk = null;
          bevl_rv = null;
          Map<String, Object> data = document.getData();
          Object kvdbvalueo = data.get("kvdbvalue");
          if (kvdbvalueo != null) {
            String kvdbvalue = (String) kvdbvalueo;
            bevl_rv = new $class/Text:String$(kvdbvalue);
          }
          Object kvdbnameo = data.get("kvdbname");
          if (kvdbnameo != null) {
            String kvdbname = (String) kvdbnameo;
            bevl_rk = new $class/Text:String$(kvdbname);
            bevl_res.bem_put_2(bevl_rk, bevl_rv);
          }
        }
      } catch (Throwable t) {
        System.out.println("got error getMapping0 from gfs");
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
        ApiFuture<QuerySnapshot> future = bevi_db.collection(bevp_gfsTableName.bems_toJvString()).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        for (QueryDocumentSnapshot document : documents) {
          bevl_rk = null;
          bevl_rv = null;
          Map<String, Object> data = document.getData();
          Object kvdbvalueo = data.get("kvdbvalue");
          if (kvdbvalueo != null) {
            String kvdbvalue = (String) kvdbvalueo;
            bevl_rv = new $class/Text:String$(kvdbvalue);
          }
          Object kvdbnameo = data.get("kvdbname");
          if (kvdbnameo != null) {
            String kvdbname = (String) kvdbnameo;
            bevl_rk = new $class/Text:String$(kvdbname);
            bevl_res.bem_put_2(bevl_rk, bevl_rv);
          }
        }
      } catch (Throwable t) {
        System.out.println("got error getMapping0 from gfs");
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
    DocumentReference docRef = bevi_db.collection(bevp_gfsTableName.bems_toJvString()).document(beva_name.bems_toJvString());
    ApiFuture<DocumentSnapshot> future = docRef.get();
    DocumentSnapshot document = future.get();
    if (document.exists()) {
      Map<String, Object> data = document.getData();
      Object kvdbvalueo = data.get("kvdbvalue");
      if (kvdbvalueo != null) {
        String kvdbvalue = (String) kvdbvalueo;
        bevl_res = new $class/Text:String$(kvdbvalue);
      }
    }
  } catch (Throwable t) {
    System.out.println("got error reading from gfs");
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
  DocumentReference docRef = bevi_db.collection(bevp_gfsTableName.bems_toJvString()).document(beva_name.bems_toJvString());
  Map<String, Object> data = new HashMap<>();
  data.put("kvdbname", beva_name.bems_toJvString());
  data.put("kvdbvalue", beva_value.bems_toJvString());
  ApiFuture<WriteResult> result = docRef.set(data);
  result.get().getUpdateTime();
  } catch (Throwable t) {
    System.out.println("got error writing to gfs");
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
      DocumentReference docRef = bevi_db.collection(bevp_gfsTableName.bems_toJvString()).document(beva_name.bems_toJvString());
      ApiFuture<DocumentSnapshot> future = docRef.get();
      DocumentSnapshot document = future.get();
      if (document.exists()) {
        bevl_resb = bevl_t;
      }
    } catch (Throwable t) {
      System.out.println("got error hassing gfs");
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
      DocumentReference docRef = bevi_db.collection(bevp_gfsTableName.bems_toJvString()).document(beva_name.bems_toJvString());
      ApiFuture<WriteResult> result = docRef.delete();
      result.get().getUpdateTime();
    } catch (Throwable t) {
      System.out.println("got error deleting gfs");
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
