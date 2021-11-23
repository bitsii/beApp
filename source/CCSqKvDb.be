// Copyright 2015 The BraceApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

use IO:File:Path;
use Db:SqlKeyValue as SqKvDb;
use Db:CCSqlKeyValue as CCSqKvDb;
class CCSqKvDb(SqKvDb) {
  
emit(cc_classHead) {
   """

  sqlite3 *bevi_db;

   """
}

  pathNew(Path _dbp, String _tableName) self {
    new();
    fields {
      Path dbp = _dbp;
      Int busyTimeout = 1000;
      tableName = _tableName;
    }
  }

  dbCheck() {
    lastUsed = Time:Interval.now().seconds;
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
    String fp = dbp.toString();
    if (dbp.parent.file.exists!) {
      dbp.parent.file.mkdirs();
    }
    
emit(cc) {
"""

int rc = sqlite3_open(bevl_fp->bems_toCcString().c_str(), &bevi_db);

if (rc) {
  bevi_db = nullptr;
"""
}
    if (true) { throw(Exception.new("open failed")); }
emit(cc) {
"""
} else {
"""
}

  //"open good".print();
  
emit(cc) {
"""
}
"""
}

  if (def(busyTimeout) && busyTimeout > 0) {
      runQuery("pragma busy_timeout=" + busyTimeout);
    }
  }
  
  close() self {
emit(cc) {
"""
sqlite3_close(bevi_db);
bevi_db = nullptr;
"""
}
  }
  
  runQuery(String qs) {
      
      emit(cc) {
      """
        int res;
        sqlite3_stmt *stmt;
        res = sqlite3_prepare_v2(bevi_db, beva_qs->bems_toCcString().c_str(), -1, &stmt, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on prep for qs");
        }
        int row = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
          row++;
        }
        sqlite3_finalize(stmt);
      """
      }
  }
  
  create() self {
    runQuery("CREATE TABLE IF NOT EXISTS " + tableName + "( KVKEY VARCHAR(512), KVVALUE VARCHAR(4096), "
    + " constraint " + tableName + "_k primary key (KVKEY) )");
  }
  
  drop() self {
    runQuery("DROP TABLE " + tableName);
  }
  
  getSet() Set {
      Set res = Set.new();
      String qs = "SELECT KVKEY FROM " + tableName;
      String mk;
      emit(cc) {
      """
      sqlite3_stmt *stmt;
      sqlite3_prepare_v2(bevi_db, bevl_qs->bems_toCcString().c_str(), -1, &stmt, NULL);
      while (sqlite3_step(stmt) == SQLITE_ROW) {
        const unsigned char * key;
        key  = sqlite3_column_text (stmt, 0);
        string keys(reinterpret_cast<const char*>(key));
        bevl_mk = (new BEC_2_4_6_TextString())->bems_ccsnew(keys);
      """
      }
      
      res.put(mk);
      
      emit(cc) {
      """
      }
      sqlite3_finalize(stmt);
      """
      }
    return(res);
  }
  
  getMap() Map {
      Map res = Map.new();
      String qs = "SELECT KVKEY, KVVALUE FROM " + tableName;
      String mk;String mv;
      emit(cc) {
      """
      sqlite3_stmt *stmt;
      sqlite3_prepare_v2(bevi_db, bevl_qs->bems_toCcString().c_str(), -1, &stmt, NULL);
      while (sqlite3_step(stmt) == SQLITE_ROW) {
        const unsigned char * key;
        const unsigned char * val;
        key  = sqlite3_column_text (stmt, 0);
        val  = sqlite3_column_text (stmt, 1);
        string keys(reinterpret_cast<const char*>(key));
        string vals(reinterpret_cast<const char*>(val));
        bevl_mk = (new BEC_2_4_6_TextString())->bems_ccsnew(keys);
        bevl_mv = (new BEC_2_4_6_TextString())->bems_ccsnew(vals);
      """
      }
      
      res.put(mk, mv);
      
      emit(cc) {
      """
      }
      sqlite3_finalize(stmt);
      """
      }
    return(res);
  }
  
  getMap(String prefix) Map {
      Map res = Map.new();
      String qs = "SELECT KVKEY, KVVALUE FROM " + tableName + " WHERE KVKEY LIKE ?";
      String mk;String mv;
      prefix = prefix + "%";
      emit(cc) {
      """
      int res;
      sqlite3_stmt *stmt;
      res = sqlite3_prepare_v2(bevi_db, bevl_qs->bems_toCcString().c_str(), -1, &stmt, NULL);
      if (res != SQLITE_OK) {
        printf("nogood on prep for getMap");
      }
      res = sqlite3_bind_text(stmt, 1, beva_prefix->bems_toCcString().c_str(), -1, NULL);
      if (res != SQLITE_OK) {
        printf("nogood on bind for getMap 1");
      }
      while (sqlite3_step(stmt) == SQLITE_ROW) {
        const unsigned char * key;
        const unsigned char * val;
        key  = sqlite3_column_text (stmt, 0);
        val  = sqlite3_column_text (stmt, 1);
        string keys(reinterpret_cast<const char*>(key));
        string vals(reinterpret_cast<const char*>(val));
        bevl_mk = (new BEC_2_4_6_TextString())->bems_ccsnew(keys);
        bevl_mv = (new BEC_2_4_6_TextString())->bems_ccsnew(vals);
      """
      }
      
      res.put(mk, mv);
      
      emit(cc) {
      """
      }
      sqlite3_finalize(stmt);
      """
      }
    return(res);
  }

  get(String name) String {
      String qs = "SELECT KVVALUE FROM " + tableName + " WHERE KVKEY=?";
      String value;
      emit(cc) {
      """
      sqlite3_stmt *stmt;
      int res;
      sqlite3_prepare_v2(bevi_db, bevl_qs->bems_toCcString().c_str(), -1, &stmt, NULL);
      res = sqlite3_bind_text(stmt, 1, beva_name->bems_toCcString().c_str(), -1, NULL);
      if (res != SQLITE_OK) {
        printf("nogood on bind for qsd");
      }
      while (sqlite3_step(stmt) == SQLITE_ROW) {
        const unsigned char * val;
        val  = sqlite3_column_text (stmt, 0);
        string vals(reinterpret_cast<const char*>(val));
        bevl_value = (new BEC_2_4_6_TextString())->bems_ccsnew(vals);
      }
      sqlite3_finalize(stmt);
      """
      }
      return(value);
  }
  
  insert(String name, String value) {
      String qsi = "INSERT INTO " + tableName + " (KVKEY, KVVALUE) VALUES (?, ?)";
      
      emit(cc) {
      """
        int res;
        sqlite3_stmt *stmt;
        res = sqlite3_prepare_v2(bevi_db, bevl_qsi->bems_toCcString().c_str(), -1, &stmt, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on prep for upsert");
        }
        res = sqlite3_bind_text(stmt, 1, beva_name->bems_toCcString().c_str(), -1, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on bind for upsert 1");
        }
        res = sqlite3_bind_text(stmt, 2, beva_value->bems_toCcString().c_str(), -1, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on bind for upsert 2");
        }
        int row = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
          row++;
        }
        sqlite3_finalize(stmt);
      """
      }
      
  }
  
  update(String name, String value) {
      String qsu = "UPDATE " + tableName + " SET KVVALUE=? WHERE KVKEY=?";
      
      emit(cc) {
      """
        int res;
        sqlite3_stmt *stmt;
        res = sqlite3_prepare_v2(bevi_db, bevl_qsu->bems_toCcString().c_str(), -1, &stmt, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on prep for update");
        }
        res = sqlite3_bind_text(stmt, 1, beva_name->bems_toCcString().c_str(), -1, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on bind for upsert 1");
        }
        res = sqlite3_bind_text(stmt, 2, beva_value->bems_toCcString().c_str(), -1, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on bind for upsert 2");
        }
        int row = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
          row++;
        }
        sqlite3_finalize(stmt);
      """
      }
      
      
  }
  
  put(String name, String value) {      
      String qsq = "SELECT KVKEY, KVVALUE FROM " + tableName + " WHERE KVKEY=?";
      String qsu = "UPDATE " + tableName + " SET KVVALUE=? WHERE KVKEY=?";
      String qsi = "INSERT INTO " + tableName + " (KVKEY, KVVALUE) VALUES (?, ?)";
      
      emit(cc) {
      """
        int res;
        sqlite3_stmt *stmt;
        res = sqlite3_prepare_v2(bevi_db, bevl_qsq->bems_toCcString().c_str(), -1, &stmt, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on prep for qsq");
        }
        res = sqlite3_bind_text(stmt, 1, beva_name->bems_toCcString().c_str(), -1, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on bind for qsq");
        }
        int row = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
          row++;
        }
        sqlite3_finalize(stmt);
        if (row > 0) {
          res = sqlite3_prepare_v2(bevi_db, bevl_qsu->bems_toCcString().c_str(), -1, &stmt, NULL);
        } else {
          res = sqlite3_prepare_v2(bevi_db, bevl_qsi->bems_toCcString().c_str(), -1, &stmt, NULL);
        }
        if (res != SQLITE_OK) {
          printf("nogood on prep for upsert");
        }
        res = sqlite3_bind_text(stmt, 1, beva_name->bems_toCcString().c_str(), -1, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on bind for upsert 1");
        }
        res = sqlite3_bind_text(stmt, 2, beva_value->bems_toCcString().c_str(), -1, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on bind for upsert 2");
        }
        row = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
          row++;
        }
        sqlite3_finalize(stmt);
      """
      }
      
  }
  
  testAndPut(String name, String oldValue, String value) Bool {
    Bool result = false;
    return(result);
  }
  
  delete(String name) {
    
      String qsd = "DELETE FROM " + tableName + " WHERE KVKEY=?";
      
      emit(cc) {
      """
        int res;
        sqlite3_stmt *stmt;
        res = sqlite3_prepare_v2(bevi_db, bevl_qsd->bems_toCcString().c_str(), -1, &stmt, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on prep for qsd");
        }
        res = sqlite3_bind_text(stmt, 1, beva_name->bems_toCcString().c_str(), -1, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on bind for qsd");
        }
        int row = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
          row++;
        }
        sqlite3_finalize(stmt);
      """
      }
  }
  
  clear() {
    
      String qsd = "DELETE FROM " + tableName;
      
      emit(cc) {
      """
        int res;
        sqlite3_stmt *stmt;
        res = sqlite3_prepare_v2(bevi_db, bevl_qsd->bems_toCcString().c_str(), -1, &stmt, NULL);
        if (res != SQLITE_OK) {
          printf("nogood on prep for qscl");
        }
        int row = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
          row++;
        }
        sqlite3_finalize(stmt);
      """
      }
  }

}


