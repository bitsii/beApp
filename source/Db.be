// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Text:String;
use Logic:Bool;
use Math:Int;
use System:Exception;
use Container:Array;
use Container:Map;
use Container:Set;
use Container:LinkedList;
use Container:Queue;
use IO:File:Path;
use IO:File;
use Text:Strings as TS;
use Test:Assertions as Assert;
use System:Thread:Lock;

emit(jv) {
"""
import java.sql.*;
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
    properties {
      String db = _db;
    }
  }
  
  pathNew(IO:File:Path _dbp) self {
    properties {
      IO:File:Path dbp = _dbp;
    }
  }
  
  open() self {
    ifEmit(cs) {
      emit(cs) {
      """
        bevi_conn = new FbConnection(bevp_db.bems_toCsString());
        bevi_conn.Open();
      """
      }
    }
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
  
  getStatement(String _stmt, Array vals) DbSt {
    DbSt st = DbSt.new(_stmt, self, vals);
    emit(jv) {
    """
    bevl_st.bevi_stmt = bevi_conn.prepareStatement(beva__stmt.bems_toJvString());
    """
    }
    return(st);
  }
  
  execute(String stmt) DbSt {
    DbSt fbstmt = getStatement(stmt);
    return(fbstmt.execute());
  }
  
  execute(String stmt, Array vals) DbSt {
    DbSt fbstmt = getStatement(stmt, vals);
    return(fbstmt.execute(vals));
  }
  
  executeQuery(String stmt) DbSt {
    DbSt fbstmt = getStatement(stmt);
    return(fbstmt.executeQuery());
  }
  
  executeQuery(String stmt, Array vals) DbSt {
    DbSt fbstmt = getStatement(stmt, vals);
    return(fbstmt.executeQuery(vals));
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
     properties {
        String stmt = _stmt;
        DbDb db = _db;
        Bool nextWaiting = false;
      }
   }
   
   new(String _stmt, DbDb _db, Array _vals) self {
     new(_stmt, _db);
     properties {
      Array vals = _vals;
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
   
   execute(Array vals) self {
     emit(jv) {
     """
     PreparedStatement bevi_pstmt = (PreparedStatement) bevi_stmt;
     """
     }
     Int i = 1;
     foreach (var v in vals) {
       String sv = v;
       emit(jv) {
       """
       bevi_pstmt.setString(bevl_i.bevi_int, bevl_sv.bems_toJvString());
       """
       } 
       i++=;    
     }
     emit(jv) {
     """
     bevi_pstmt.executeUpdate();
     """
     }
   }
   
   executeQuery(Array vals) self {
     emit(jv) {
     """
     PreparedStatement bevi_pstmt = (PreparedStatement) bevi_stmt;
     """
     }
     Int i = 1;
     foreach (var v in vals) {
       String sv = v;
       emit(jv) {
       """
       bevi_pstmt.setString(bevl_i.bevi_int, bevl_sv.bems_toJvString());
       """
       } 
       i++=;    
     }
     emit(jv) {
     """
     bevi_res = bevi_pstmt.executeQuery();
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
       return(self);
     }
     if (self.hasNext) {
      return(self);
     }
     return(null);
   }
   
   //get col as string for current row
   getString(Int col) String {
      String res;
      emit(cs) {
      """
      bevl_res = new BEC_4_6_TextString(bevi_reader[beva_col.bevi_int].ToString());
      """
      }
      emit(jv) {
      """
      bevl_res = new BEC_4_6_TextString(bevi_res.getString(beva_col.bevi_int + 1));
      """
      }
      return(res);
   }
   
   getInt(Int col) Int {
      Int res;
      emit(cs) {
      """
      bevl_res = new BEC_4_3_MathInt((int)bevi_reader[beva_col.bevi_int]);
      """
      }
      emit(jv) {
      """
      bevl_res = new BEC_4_3_MathInt(bevi_res.getInt(beva_col.bevi_int + 1));
      """
      }
      return(res);
   }
   
   iteratorGet() {
    //to support foreach
    return(self);
   }
   
   close() {
   emit(jv) {
   """
   bevi_stmt.close();
   """
   }
   }
}

use Db:SQLite:Database as SlDb;
class Db:SQLite:Database(DbDb) {
  
  pathNew(Path _dbp) self {
    super.pathNew(_dbp);
    String dbAddr = "jdbc:sqlite:" + dbp.toString();
    new(dbAddr);
  }
  
  open() self {
    emit(jv) {
    """
      Class.forName("org.sqlite.JDBC");
    """
    }
    super.open();
  }
  
  copy() {
    return(SlDb.pathNew(dbp));
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
  
  copy() {
    return(Derby.pathNew(dbp));
  }

}


use Db:Firebird:Database as FbDb;
class Db:Firebird:Database(DbDb) {
  
  pathNew(Path _dbp) self {
    super.pathNew(_dbp);
    String dbAddr = "ServerType=1;User=SYSDBA;" + 
      "Password=masterkey;Dialect=3;Database=" + dbp.toString("\\");
    new(dbAddr);
  }
  
  open() self {
    if (dbp.file.exists!) {
      emit(cs) {
        """
        FbConnection.CreateDatabase(bevp_db.bems_toCsString());
        """
      }
    }
    super.open();
  }
  
  copy() {
    return(FbDb.pathNew(dbp));
  }
  
  getStatement(String _stmt) DbSt {
    DbSt st = super.getStatement(_stmt);
    emit(cs) {
    """
    if (bevi_trans == null) {
      bevl_st.bevi_cmd = new FbCommand(
        beva__stmt.bems_toCsString(),
        (FbConnection)bevi_conn
        );
     } else {
       bevl_st.bevi_cmd = new FbCommand(
        beva__stmt.bems_toCsString(),
        (FbConnection)bevi_conn,
        (FbTransaction)bevi_trans
        );
     }
     """
     }
     return(st);
   }

}

use System:Thread:ObjectLocker as OLocker;
use System:Thread:RecycledResource as Recyc;

class Recyc {

  new() self {
    vars {
      var resource;
      Lock lock = Lock.new();
      OLocker shLocker;
      IO:Log log;
      Int lvl;
    }
    try {
      lock.lock();
      shLocker = OLocker.new();
      log = IO:Log.new();
      lvl = log.debug;
      lock.unlock();
    } catch (var e) {
      lock.unlock();
      throw(e);
    }
  }
  
  templateResourceSet(_resource) self {
    try {
      lock.lock();
      resource = _resource;
      lock.unlock();
    } catch (var e) {
      lock.unlock();
      throw(e);
    }
  }
  
  templateResourceGet() {
    try {
      lock.lock();
      var res = resource;
      lock.unlock();
    } catch (var e) {
      lock.unlock();
      throw(e);
    }
    return(res);
  }
  
  close() {
    var shared = shLocker.getAndClear();
    if (def(shared)) {
      shared.close();
    }
  }
    
  get() {
    log.log(lvl, "Getting");
    var shared = shLocker.getAndClear();
    if (undef(shared)) {
      try {
        lock.lock();
        if (def(resource)) {
          shared = resource.copy();
          //shared = resource;
          shared.open();
        }
        lock.unlock();
      } catch (var e) {
        lock.unlock();
        throw(e);
      }
    }
    return (shared);
  }
  
  done(shared) {
    unless (shLocker.setIfClear(shared)) {
      //shared.close();
    }
  }
  
  failed(shared) {
    if (def(shared)) {
      try {
        //shared.close();
      } catch (var e) {
        log.log(lvl, "Exception closing shared in failed");
      }
    }
  }
  
}

use class Db:Relational:Test(Assert) {

  dbTest() {
    DbDb db;
    Path dbp;
    ifEmit(jv) {
      dbp = Path.new("SLDBT");
      db = SlDb.pathNew(dbp);
    }
    ifEmit(cs) {
      dbp = Path.new("FBDBT");
      db = FbDb.pathNew(dbp);
    }
    db.open();
    
    db.begin();
    db.execute("CREATE TABLE TESTTAB( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
      + " constraint TESTTAB_k primary key (P,K) )");
    db.commit();
    
    db.begin();
    db.execute("insert into TESTTAB(P, K) values ('hi', 'bob')");
    db.commit();
    
    db.begin();
    foreach (DbSt re in db.executeQuery("select * from TESTTAB")) {
      assertEqual(re.getString(0), "hi");
    }
    db.commit();
    
    Array vals2 = Array.new(2);
    vals2[0] = "yo";
    vals2[1] = "adrian";
    db.begin();
    db.execute("insert into TESTTAB(P, K) values (?, ?)", vals2);
    db.commit();
    
    Array vals1 = Array.new(1);
    vals1[0] = "yo";
    db.begin();
    foreach (re in db.executeQuery("select * from TESTTAB where P=?", vals1)) {
      assertEqual(re.getString(1), "adrian");
    }
    db.commit();
    
    db.close();
  }
 
  main() {
    "Begin Relational Test".print();
    try {
      dbTest();
    } catch (var e) {
      e.print();
      throw(e);
    }
    "End Relational Test".print();
  }

}

