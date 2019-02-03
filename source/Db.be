// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use IO:File:Path;
use IO:File;
use Test:Assertions as Assert;
use System:Thread:Lock;
use System:Parameters;
use Container:LinkedList;
use Container:LinkedList:Node;

emit(jv) {
"""
import java.sql.*;
"""
}
emit(cs) {
"""
using System;
using System.Data;
using System.Data.Common;
"""
}
use Db:Relational:Database as DbDb;
class Db:Relational:Database {

emit(cs) {
"""
public DbConnection bevi_conn = null;
public DbTransaction bevi_trans = null;
"""
}
emit(jv) {
"""
public Connection bevi_conn = null;
public Connection bevi_trans = null;
"""
}

  new(String _db) self {
    fields {
      String db = _db;
    }
  }
  
  pathNew(IO:File:Path _dbp) self {
    fields {
      IO:File:Path dbp = _dbp;
      //idle timeout, -1 to disable (default)
    }
  }
  
  open() self {
    emit(jv) {
    """
      bevi_conn = DriverManager.getConnection(
        bevp_db.bems_toJvString()
        );
    """
    }
  }

  begin() self {
    emit(cs) {
    """
    if (bevi_trans != null) {
    """
    }
    emit(jv) {
    """
    if (bevi_trans != null) {
    """
    }
    ifEmit(cs) {
    throw(Exception.new("Transaction in progress, cannot begin until " +
      "existing transaction is committed or rolled back"));
    }
    ifEmit(jv) {
    throw(Exception.new("Transaction in progress, cannot begin until " +
      "existing transaction is committed or rolled back"));
    }
    emit(cs) {
    """
    }
    bevi_trans = bevi_conn.BeginTransaction();
    """
    }
    emit(jv) {
    """
    }
    bevi_conn.setAutoCommit(false);
    bevi_trans = bevi_conn;
    """
    }
    }
    
    commit() self {
      emit(cs) {
      """
      try {
      bevi_trans.Commit();
      } finally {
      bevi_trans = null;
      }
      """
      }
      emit(jv) {
      """
      try {
      bevi_conn.commit();
      } finally {
      bevi_trans = null;
      bevi_conn.setAutoCommit(false);
      }
      """
      }
    }
    
    rollback() self {
      emit(cs) {
      """
      try {
      bevi_trans.Rollback();
      } finally {
      bevi_trans = null;
      }
      """
      }
      emit(jv) {
      """
      try {
      bevi_conn.rollback();
      } finally {
      bevi_trans = null;
      }
      """
      }
    }
  
  close() self {
    emit(cs) {
    """
      bevi_conn.Close();
    """
    }
    emit(jv) {
    """
      bevi_conn.close();
    """
    }
  }
  
  getStatement(String _stmt) DbSt {
    DbSt st = DbSt.new(_stmt, self);
    emit(jv) {
    """
    bevl_st.bevi_stmt = bevi_conn.createStatement();
    """
    }
    return(st);
  }
  
  getStatement(String _stmt, List vals) DbSt {
    DbSt st = DbSt.new(_stmt, self, vals);
    emit(jv) {
    """
    bevl_st.bevi_stmt = bevi_conn.prepareStatement(beva__stmt.bems_toJvString());
    """
    }
    return(st);
  }
  
  addParam(DbSt st, Int pos, String paramName, String paramValue) this {
    return(self);
  }
  
  execute(String stmt) DbSt {
    DbSt fbstmt = getStatement(stmt);
    return(fbstmt.execute());
  }
  
  execute(String stmt, List vals) DbSt {
    DbSt fbstmt = getStatement(stmt, vals);
    return(fbstmt.executeParameterized());
  }
  
  executeQuery(String stmt) DbSt {
    DbSt fbstmt = getStatement(stmt);
    return(fbstmt.executeQuery());
  }
  
  executeQuery(String stmt, List vals) DbSt {
    DbSt fbstmt = getStatement(stmt, vals);
    return(fbstmt.executeQueryParameterized());
  }

}

use Db:Relational:DatabasePool as DbP;
class DbP {
  new(DbDb base) {
    //get and put with lock
    fields {
      Lock lock = Lock.new();
    }
  }
}

use Db:Relational:Statement as DbSt;
class Db:Relational:Statement {

emit(cs) {
"""
public DbCommand bevi_cmd = null;
public DbDataReader bevi_reader = null;
"""
}

emit(jv) {
"""
public Statement bevi_stmt = null;
public ResultSet bevi_res = null;
"""
}
  
   new(String _stmt, DbDb _db) self {
     fields {
        String stmt = _stmt;
        DbDb db = _db;
        Bool nextWaiting = false;
        List paramNames;
      }
   }
   
   new(String _stmt, DbDb _db, List _vals) self {
     new(_stmt, _db);
     fields {
      List vals = _vals;
     }
   }
        
   execute() self {
     emit(cs) {
     """
     bevi_cmd.ExecuteNonQuery();
     """
     }
     emit(jv) {
     """
     bevi_stmt.executeUpdate(bevp_stmt.bems_toJvString());
     """
     }
   }
   
   executeParameterized() self {
     emit(jv) {
     """
     PreparedStatement bevi_pstmt = (PreparedStatement) bevi_stmt;
     """
     }
     Int i = 1;
     for (any v in vals) {
       String sv = v;
       emit(jv) {
       """
       bevi_pstmt.setString(bevl_i.bevi_int, bevl_sv.bems_toJvString());
       """
       } 
       ifEmit(cs) {
         String pn = paramNames.get(i - 1);
         db.addParam(self, i, pn, sv);
       }
       i++=;    
     }
     emit(jv) {
     """
     bevi_pstmt.executeUpdate();
     """
     }
     emit(cs) {
     """
     bevi_cmd.ExecuteNonQuery();
     """
     }
   }
   
   executeQueryParameterized() self {
     emit(jv) {
     """
     PreparedStatement bevi_pstmt = (PreparedStatement) bevi_stmt;
     """
     }
     Int i = 1;
     for (any v in vals) {
       String sv = v;
       emit(jv) {
       """
       bevi_pstmt.setString(bevl_i.bevi_int, bevl_sv.bems_toJvString());
       """
       } 
       ifEmit(cs) {
         String pn = paramNames.get(i - 1);
         db.addParam(self, i, pn, sv);
       }
       i++=;    
     }
     emit(jv) {
     """
     bevi_res = bevi_pstmt.executeQuery();
     """
     }
     emit(cs) {
     """
     bevi_reader = bevi_cmd.ExecuteReader();
     """
     }
   }
   
   executeQuery() self {
     emit(cs) {
     """
     bevi_reader = bevi_cmd.ExecuteReader();
     """
     }
     emit(jv) {
     """
     bevi_res = bevi_stmt.executeQuery(bevp_stmt.bems_toJvString());
     """
     }
   }
   
   hasNextGet() Bool {
     if (nextWaiting) {
      return(true);
     }
     emit(cs) {
     """
     if (bevi_reader.Read()) {
     """
     }
     emit(jv) {
     """
     if (bevi_res.next()) {
     """
     }
     nextWaiting = true;
     emit(cs) {
     """
     }
     """
     }
     emit(jv) {
     """
     }
     """
     }
     return(nextWaiting);
   }
   
   nextGet() self {
     if (nextWaiting) {
       nextWaiting = false;
     }
     return(self);
   }
   
   //get col as string for current row
   getString(Int col) String {
      String res;
      emit(cs) {
      """
      bevl_res = new $class/Text:String$(bevi_reader[beva_col.bevi_int].ToString());
      """
      }
      emit(jv) {
      """
      bevl_res = new $class/Text:String$(bevi_res.getString(beva_col.bevi_int + 1));
      """
      }
      return(res);
   }
   
   getInt(Int col) Int {
      Int res;
      emit(cs) {
      """
      bevl_res = new $class/Math:Int$((int)bevi_reader[beva_col.bevi_int]);
      """
      }
      emit(jv) {
      """
      bevl_res = new $class/Math:Int$(bevi_res.getInt(beva_col.bevi_int + 1));
      """
      }
      return(res);
   }
   
   iteratorGet() any {
    //to support for
    return(self);
   }
   
   close() {
   emit(jv) {
   """
   if (bevi_res != null) {
    bevi_res.close();
   }
   if (bevi_stmt != null) {
     bevi_stmt.close();
   }
   """
   }
   }
}

use Db:HSQLDb:Database as HsDb;
class HsDb(DbDb) {
  
  pathNew(Path _dbp) self {
    super.pathNew(_dbp); //dbp.toStringWithSeparator("/")
    String dbAddr = "jdbc:hsqldb:file:" + dbp.toString();
    new(dbAddr);
  }
  
  open() self {
    emit(jv) {
    """
      Class.forName("org.hsqldb.jdbcDriver");
    """
    }
    super.open();
  }
  
  copy() self {
    return(HsDb.pathNew(dbp));
  }

}

use Db:Derby:Database as Derby;
class Db:Derby:Database(DbDb) {
  
  pathNew(Path _dbp) self {
    super.pathNew(_dbp);
    String dbAddr = "jdbc:derby:" + dbp.toString() + ";create=true";
    new(dbAddr);
  }
  
  open() self {
    emit(jv) {
    """
      Class.forName("org.apache.derby.jdbc.EmbeddedDriver");
    """
    }
    super.open();
  }
  
  copy() self {
    return(Derby.pathNew(dbp));
  }

}

use System:Thread:ContainerLocker as CLocker;
use Db:KeyValue as KvDb;
class KvDb(CLocker) {
  
  new(DbDb _db, String _tableName) self {
    SqKvDb sdb = SqKvDb.new(_db, _tableName);
    super.new(sdb);
  }
  
  create() self {
    container.create();
  }
  
  open() self {
    container.open();
  }
  
  drop() self {
    container.drop();
  }
  
}

use Db:KeyValueDbs as KvDbs;

class KvDbs {

  new(Parameters _params, Path _dataPath) self {
    fields {
      Parameters params = _params;
      Lock lock = Lock.new();
      Map kvDbs = Map.new();
      IO:Log log =@ IO:Logs.get(self);
      Path dataPath = _dataPath;
    }
  }
  
  dbGet() DbDb {
      fields {
        String appDbClass;
      }
      String appDbClass = params.getFirst("appDbClass");
      if (TS.isEmpty(appDbClass)) {
        appDbClass = "Db:SQLite:Database";
      }
      //log.log("appDbClass " + appDbClass);
      DbDb appDb = createInstance(appDbClass);
      if (appDbClass == "Db:SQLite:Database") {
        Path appDbPath = dataPath.copy();
        appDb.pathNew(appDbPath);
      } elseIf(appDbClass == "Db:Maria:Database") {
        //log.log("doing mariadb");
        appDb.invoke("paramsNew", Lists.from(params));
      } else {
        appDb.new();
      }
      appDb.open();
      return(appDb);
  }
  
  get(String name) KvDb {
    fields {
      Int appKvPoolSize;
    }
    try {
      lock.lock();
      if (undef(appKvPoolSize)) {
        String appKvPoolSizeS = params.getFirst("appKvPoolSize");
        if (TS.notEmpty(appKvPoolSizeS)) {
          appKvPoolSize = Int.new(appKvPoolSizeS);
        } else {
          appKvPoolSize = 3;
        }
      }
      LinkedList kdbl = kvDbs.get(name);
      if (undef(kdbl)) {
        kdbl = LinkedList.new();
        for (Int i = 0;i < appKvPoolSize;i++=) {
          KvDb kdb = KvDb.new(self.db, name);
          kdb.create();
          kdbl.addValueWhole(kdb);
        }
        kvDbs.put(name, kdbl);
      }
      Node an = kdbl.firstNode;
      kdbl.deleteNode(an);
      kdbl.appendNode(an);
      kdb = an.held;
      lock.unlock();
    } catch (any e) {
      lock.unlock();
      log.error("exception during getKvDb");
      if (def(e)) { log.error("ex " + e); }
    }
    return(kdb);
  }
  
  close() {
    log.log("closing kvdbs");
    try {
      lock.lock();
      for (any kvle in kvDbs) {
        for (any kv in kvle.value) {
          kv.close();
        }
      }
      kvDbs = Map.new();
      lock.unlock();
    } catch (any e) {
      lock.unlock();
      log.error("exception during closeKvDbs");
      if (def(e)) { log.error("ex " + e); }
    }
  }

}

use Db:SqlKeyValue as SqKvDb;
class SqKvDb {

  new() self {
    fields {
      DbDb db;
      String tableName;
      Int lastUsed = Time:Interval.now().seconds;
    }
  }
  
  dbCheck() {
    if (self.timeout > -1) {
      if (Time:Interval.now().seconds - lastUsed > self.timeout) {
        dbFailed();
      }
      lastUsed = Time:Interval.now().seconds;
    }
  }
  
  timeoutGet() Int {
    return(-1);
  }
    
  new(DbDb _db, String _tableName) self {
    new();
    db = _db;
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
    db.open();
  }
  
  close() self {
    db.close();
  }
  
  create() self {
    //("creating kvdbdb").print();
    //db.className.print();
    try {
    db.begin();
    if (db.className == "Db:Maria:Database") {
      //("doing mariadb").print();
      db.execute("CREATE TABLE IF NOT EXISTS " + tableName + "( KVKEY VARCHAR(512), KVVALUE VARCHAR(4096), "
      + " constraint " + tableName + "_k primary key (KVKEY(100)) )").close();
    } else {
      db.execute("CREATE TABLE IF NOT EXISTS " + tableName + "( KVKEY VARCHAR(512), KVVALUE VARCHAR(4096), "
      + " constraint " + tableName + "_k primary key (KVKEY) )").close();
    }
    db.commit();
    } catch (any e) {
    db.rollback();
    dbFailed();
    throw(e);
    }
  }
  
  drop() self {
    try {
    db.begin();
    db.execute("DROP TABLE " + tableName).close();
    db.commit();
    } catch (any e) {
    db.rollback();
    dbFailed();
    }
  }
  
  getSet() Set {
    try {
      Set res = Set.new();
      List qa = List.new(0);
      db.begin();
      DbSt ares = db.executeQuery("SELECT KVKEY FROM " + tableName, qa);
      for (ares in ares) {
        String name = ares.getString(0);
        res.put(name);
      }
      ares.close();
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
    return(res);
  }
  
  getMap() Map {
    try {
      dbCheck();
      Map res = Map.new();
      List qa = List.new(0);
      db.begin();
      DbSt ares = db.executeQuery("SELECT KVKEY, KVVALUE FROM " + tableName, qa);
      for (ares in ares) {
        String name = ares.getString(0);
        String value = ares.getString(1);
        res.put(name, value);
      }
      ares.close();
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
    return(res);
  }
  
  getMap(String prefix) Map {
    try {
      dbCheck();
      Map res = Map.new();
      List qa = List.new(1);
      qa.put(0, prefix + "%");
      db.begin();
      DbSt ares = db.executeQuery("SELECT KVKEY, KVVALUE FROM " + tableName + " WHERE KVKEY LIKE ?", qa);
      for (ares in ares) {
        String name = ares.getString(0);
        String value = ares.getString(1);
        res.put(name, value);
      }
      ares.close();
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
    return(res);
  }

  get(String name) String {
    try {
      dbCheck();
      List qa = List.new(1);
      qa[0] = name;
      db.begin();
      DbSt ares = db.executeQuery("SELECT KVVALUE FROM " + tableName + " WHERE KVKEY=?", qa);
      for (ares in ares) {
        String value = ares.getString(0);
      }
      ares.close();
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
    return(value);
  }
  
  get(String name, String default) String {
    String val = self.get(name);
    if (undef(val)) {
      return(default);
    }
    return(val);
  }
  
  insert(String name, String value) {
    try {
      dbCheck();
      List qa = List.new(2).put(0, name).put(1, value);
      db.begin();
      db.execute("INSERT INTO " + tableName + " (KVKEY, KVVALUE) VALUES (?, ?)", qa).close();
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
  }
  
  update(String name, String value) {
    try {
      dbCheck();
      List qa = List.new(2).put(0, value).put(1, name);
      db.begin();
      db.execute("UPDATE " + tableName + " SET KVVALUE=? WHERE KVKEY=?", qa).close();
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
  }
  
  put(String name, String value) {
    try {
      dbCheck();
      List qa = List.new(1);
      qa[0] = name;
      db.begin();
      Bool exists = false;
      DbSt ares = db.executeQuery("SELECT KVVALUE FROM " + tableName + " WHERE KVKEY=?", qa);
      for (ares in ares) {
        exists = true;
      }
      ares.close();
      if (exists) {
        qa = List.new(2).put(0, value).put(1, name);
        db.execute("UPDATE " + tableName + " SET KVVALUE=? WHERE KVKEY=?", qa).close();
      } else {
        qa = List.new(2).put(0, name).put(1, value);
        db.execute("INSERT INTO " + tableName + " (KVKEY, KVVALUE) VALUES (?, ?)", qa).close();
      }
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
  }
  
  testAndPut(String name, String oldValue, String value) Bool {
    Bool result = false;
    try {
      db.begin();
      List qa = List.new(3).put(0, value).put(1, name).put(2, oldValue);
      db.execute("UPDATE " + tableName + " SET KVVALUE=? WHERE KVKEY=? AND KVVALUE=?", qa).close();
      //db.commit();
      List qc = List.new(1).put(0, name);
      DbSt ares = db.executeQuery("SELECT KVVALUE FROM " + tableName + " WHERE KVKEY=?", qc);
      for (ares in ares) {
        String currValue = ares.getString(0);
        if (currValue == value) {
          result = true;
        }
      }
      ares.close();
      //if (true) { throw(Exception.new("fail")); }
      db.commit();
    } catch (any e) {
      result = false;
      db.rollback();
      //expected case, not fatal
    }
    return(result);
  }
  
  delete(String name) {
    try {
      dbCheck();
      List qa = List.new(1).put(0, name);
      db.begin();
      db.execute("DELETE FROM " + tableName + " WHERE KVKEY=?", qa).close();
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
  }
  
  clear() {
    try {
      dbCheck();
      db.begin();
      db.execute("DELETE FROM " + tableName).close();
      db.commit();
    } catch (any e) {
      db.rollback();
      dbFailed();
      throw(e);
    }
  }

}


