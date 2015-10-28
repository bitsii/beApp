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
use System:Random;
use Text:Strings as TS;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;

use class Dz:Lui {

  new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
          IO:Log log = IO:Log.new();
          Int lvl = log.info;
        }
    }

    main() {
      Array args = System:Process.new().args;

      Web:Client:CertificateManager.validateHosts = false;

      if (args.length > 0) {
        String mode = args[0]; //ui, svc, both, [absent]
        log.log(lvl, "mode " + mode);
      } else {
        log.log(lvl, "mode empty");
      }
      if (TS.isEmpty(mode)) {
        mode = "ui";
      }
      if (mode == "ui") {
        webr = WeBr.new();
        webr.webHandler = self;
        webr.height = 450;
        webr.width = 320;
        //webr.content = Ve:App.new().readHtml("Dz.html");
        //webr.content = "<html><body><h1>hi</h1></body></html>";
        //put together string from 3 files, middle generated bejs
        String content = IO:File.new("DzA.html").reader.open().readString()
        + IO:File.new("BEL_4_Base.js").reader.open().readString()
        //+ IO:File.new("Dzmid.js").reader.open().readString()
        + IO:File.new("DzB.html").reader.open().readString();
        //content.print();
        webr.content = content;
        //webr.content = IO:File.new("Dz.html").reader.open().readString();
        webr.setup();
      } elif (mode == "test") {
        Dz:Test.new().main();
      }
   }

   initWeb() {

   }

   sayHelloRequest(Map arg, request) {
      "in say hello".print();
      log.log(lvl, "In say hello");
      Map res = Map.new();
      res["action"] = "sayHelloResponse";
      res["msg"] = "hello";
      return(res);
   }

    handleWeb(request) {
        try {
            Map arg = request.scriptArg;
            String mname = arg.get("action");
            if (undef(mname) || mname.ends("Request")!) {
              throw(Exception.new("Invalid request"));
            }
            String accountName = request.getSession("account.name");
            Array args = Array.new(2);
            args[0] = arg;
            args[1] = request;
            if (self.can(mname, args.length)) {
              var res = self.invoke(mname, args);
            }
            request.scriptReturn = res;
        } catch (var e) {
           arg = Map.new();
           log.log(lvl, "Caught exception during handleWeb B");
           if (def(e)) {
            log.log(lvl, "Error was " + e);
           }
            arg["action"] = "failResponse";
            if (e.sameClass(Alert.new()@)) {
              arg["reason"] = e.description;
            } else {
              arg["reason"] = "Sorry, unable to handle request";
            }
            request.scriptReturn = arg;
        }
    }

    exitRequest(Map arg, request) Map {
      exit();
      return(null);
    }

    exit() {
      webr.close();
      webr.exit();
    }

}

use class Dz:App {

  dbPathGet() IO:File:Path {
    String dbp = "TDB";
    ifEmit(jv) {
      dbp += "JV";
    }
    ifEmit(cs) {
      dbp += "CS";
    }
    return(IO:File:Path.new(dbp));
  }
  
  dbGet() DbDb {
        DbDb db;
        IO:File:Path dbfp = self.dbPath;
        if (dbfp.file.exists!) {
          Bool createDb = true;
          if (dbfp.parent.file.exists!) {
            dbfp.parent.file.makeDirs();
          }
        } else {
          createDb = false;
        }
        String dbAddr;
        ifEmit(cs) {
          dbAddr = "ServerType=1;User=SYSDBA;" + 
          "Password=masterkey;Dialect=3;Database=" + dbfp.toString("\\");
          //log.log(lvl, "new db dbAddr " + dbAddr);
          db = FbDb.new(dbAddr);
          if (createDb) {
            db.createDatabase();
          }
          db.open();
        }
        ifEmit(jv) {
          //dbAddr = "jdbc:derby:" + dbfp.toString() + ";create=true";
          //db = DbDb.new(dbAddr);
          //db.driverOpen("org.apache.derby.jdbc.EmbeddedDriver");
          
          dbAddr = "jdbc:sqlite:" + dbfp.toString();
          db = DbDb.new(dbAddr);
          db.driverOpen("org.sqlite.JDBC");
        }
        if (createDb) {
          db.begin();
          db.execute("CREATE TABLE CONFIGS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint CONFIGS_k primary key (P,K) )");
          db.execute("CREATE TABLE DRAFTS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint DRAFTS_k primary key (P,K) )");
          db.execute("CREATE TABLE ACCOUNTS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint ACCOUNTS_k primary key (P,K) )");
         db.execute("CREATE TABLE LINKS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint LINKS_k primary key (P,K) )");
         db.execute("CREATE TABLE GATEWAYS( P VARCHAR(110), K VARCHAR(110), V VARCHAR(500),"
         + " constraint GATEWAYS_k primary key (P,K) )");
          db.commit();
        }
        return(db);
    }

}

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
  
  createDatabase() self {
    if (true) {
      throw(Exception.new("No Capability to create database"));
    }
    return(self);
  }
  
  open() self {
    emit(cs) {
    """
      bevi_conn.Open();
    """
    }
    emit(jv) {
    """
      bevi_conn = DriverManager.getConnection(
        bevp_db.bems_toJvString()
        );
    """
    }
  }
  
  driverOpen(String driver) self {
    ifEmit(cs) {
      open();
    }
    emit(jv) {
    """
      Class.forName(beva_driver.bems_toJvString());
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
  
  execute(String stmt) DbSt {
    DbSt fbstmt = getStatement(stmt);
    return(fbstmt.execute());
  }
  
  executeQuery(String stmt) DbSt {
    DbSt fbstmt = getStatement(stmt);
    return(fbstmt.executeQuery());
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
}

use Db:Firebird:Database as FbDb;
class Db:Firebird:Database(DbDb) {

  new(String _db) self {
    super.new(_db);
    emit(cs) {
    """
      bevi_conn = new FbConnection(bevp_db.bems_toCsString());
    """
    }
  }

  createDatabase() self {
    emit(cs) {
      """
      FbConnection.CreateDatabase(bevp_db.bems_toCsString());
      """
    }
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

use class Dz:Test(Assert) {

  testTest() {
  
  }
 
  main() {
    "Begin Test".print();
    testTest();
    "End Test".print();
  }

}

use class Dz:Alert(Exception) { }
