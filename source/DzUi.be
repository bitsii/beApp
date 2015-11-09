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
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use Db:Firebird:Database as FbDb;
use Db:SQLite:Database as SlDb;
use System:Thread:RecycledResource as Recyc;
use System:Thread:Lock;

use Dz:Alert;

use class Dz:Lui(Ui) {

  new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
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
      }
   }

   initWeb() {

   }

   handleWeb(request) {
     
     Map arg = request.scriptArg;
     return(super.handleWeb(request, arg));
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

use class Dz:Ui {

  new() self {
      properties {
        IO:Log log = IO:Log.new();
        log.level = log.debug;
        Int lvl = log.info;
        Map modules = Map.new();
        Lock lock = Lock.new();
        Recyc dbRecyc = Recyc.new();
      }
      
      Hello h = Hello.new();
      h.log = log;
      h.lvl = lvl;
      modules["Hello"] = h;
      
      Image i = Image.new();
      i.log = log;
      i.lvl = log.level;
      modules["Image"] = i;
      
      modules["Accounts"] = Accounts.new();
  }

  handleWeb(request, Map arg) {
        try {
            String mname = arg.get("module");
            String aname = arg.get("action");
            if (undef(aname) || aname.ends("Request")! || undef(mname) || modules.has(mname)!) {
              throw(Exception.new("Invalid request"));
            }
            //String accountName = request.getSession("account.name");
            //log.log(lvl, "module " + module + " action " + action);
            Array args = Array.new(2);
            args[0] = arg;
            args[1] = request;
            var module = modules.get(mname);
            if (module.can(aname, args.length)) {
              var res = module.invoke(aname, args);
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
    
    dbDone(DbDb db) {
      dbRecyc.done(db);
    }
    
    dbFailed(DbDb db) {
      dbRecyc.failed(db);
    }
    
    dbGet() DbDb {
      
      properties {
        Path dbp;
      }
      
      DbDb db = dbRecyc.get();
      
      if (undef(db)) {
        try {
          lock.lock();
          ifEmit(jv) {
            dbp = Path.apNew("../dzdata/SDZDB");
            db = SlDb.pathNew(dbp);
          }
          ifEmit(cs) {
            dbp = Path.apNew("../dzdata/FDZDB");
            db = FbDb.pathNew(dbp);
          }
          dbRecyc.templateResource = db;
          db = dbRecyc.get();
          db.open();
          db.begin();
          db.execute("CREATE TABLE IF NOT EXISTS ACCOUNTS( USER VARCHAR(110), PASS VARCHAR(500), SALT VARCHAR(64), "
            + " constraint ACCOUNTS_k primary key (USER) )");
          db.commit();
          dbRecyc.done(db);
          lock.unlock();
        } catch (var e) {
          lock.unlock();
          dbRecyc.failed(db);
          throw(e);
        }
      }
      return(db);
      
    }
    
    accountManagerGet() AccountManager {
      properties {
        AccountManager am;
      }
      if (undef(am)) {
        am = AccountManager.new(self, "ACCOUNTS");
      }
      return(am);
    }

}

use class Dz:CmdUi(Ui) {

  new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
    }
    
    main() {
      return(main(System:Process.new().args));
    }

    main(Array args) {
      if (args.length > 0) {
        String mode = args[0]; //ui, svc, both, [absent]
        log.log(lvl, "cmd " + mode);
      } else {
        log.log(lvl, "cmd empty");
      }
      if (TS.notEmpty(mode) && mode == "createAccount") {
        String user = args[1];
        String pass = args[2];
        log.log(lvl, "Creating Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        self.accountManager.createAccount(ac);
      }
    }
}

use class Dz:Hello {

     new() self {
       properties {
          IO:Log log;
          Int lvl;
        }
     }

     sayHelloRequest(Map arg, request) {
      "in say hello".print();
      log.log(lvl, "In say hello");
      Map res = Map.new();
      res["action"] = "sayHelloResponse";
      res["msg"] = "hello";
      return(res);
   }

}

use class Dz:Image {

     new() self {
       properties {
          IO:Log log;
          Int lvl;
          Int count = 0;
        }
     }

     updateImageRequest(Map arg, request) {
      log.log(lvl, "In load image");
      Map res = Map.new();
      res["action"] = "updateImageResponse";
      res["imghtm"] = "<h1>hi " + count + "</h1>";
      count++=;
      return(res);
   }

}

// create, create if none, get, check pass, type, update, delete

//web thing
use class Dz:Accounts {

}

//logic
use class Dz:AccountManager {

  new() self {
    properties {
      var dbProvider;
      String tableName;
    }
  }
  
  new(_dbProvider, _tableName) {
    new();
    dbProvider = _dbProvider;
    tableName = _tableName;
  }

  getAccount(String user) {
    try {
      DbDb db = dbProvider.db;
      foreach (DbSt ares in db.executeQuery("SELECT USER, PASS, SALT FROM " + tableName + " WHERE USER='" + user + "'")) {
        Account a = Account.new(ares.getString(0), ares.getString(1), ares.getString(2));
      }
      //ares.close();
      dbProvider.dbDone(db);
    } catch (var e) {
      dbProvider.dbFailed(db);
      throw(e);
    }
    return(a);
  }
  
  deleteAccount(Account a) {
    try {
      DbDb db = dbProvider.db;
      db.execute("DELETE FROM " + tableName + " WHERE USER='" + a.user + "'");
      dbProvider.dbDone(db);
    } catch (var e) {
      dbProvider.dbFailed(db);
      throw(e);
    }
  }
  
  createAccount(Account a) {
    try {
      DbDb db = dbProvider.db;
      db.execute("INSERT INTO " + tableName + " (USER, PASS, SALT) VALUES ('" + a.user + "', '" + a.pass + "', '" + a.salt + "')");
      dbProvider.dbDone(db);
    } catch (var e) {
      dbProvider.dbFailed(db);
      throw(e);
    }
  }
  
  updateAccount(Account a) {
    try {
      DbDb db = dbProvider.db;
      db.execute("UPDATE " + tableName + " SET PASS='" + a.pass + "', SALT='" + a.salt +  "' WHERE USER='" + a.user + "'");
      dbProvider.dbDone(db);
    } catch (var e) {
      dbProvider.dbFailed(db);
      throw(e);
    }
  }

}

use class Dz:Account {
  new(String _user, String _hashPass, String _salt) self {
    properties {
      String user = _user;
      String pass = _hashPass;
      String salt = _salt;
    }
  }
  
  passSet(String _pass) {
    salt = System:Random.getString(16);
    pass = passToHash(_pass, salt);
  }
  
  passToHash(String pass, String salt) String {
    if (TS.isEmpty(salt) || TS.isEmpty(pass)) {
      return(null);
    }
    pass = salt + pass;
    Digest:SHA256 ds = Digest:SHA256.new();
    for (Int i = 0;i < 7;i++=) {
      pass = ds.digest(pass);
    }
    pass = Encode:Hex.encode(pass);
    return(pass);
  }
  
  checkPass(String _pass) Bool {
    _pass = passToHash(_pass, salt);
    if (_pass == pass) {
      return(true);
    }
    return(false);
  }
  
}

use class Dz:AccountTest(Assert) {
  
  testAccounts() {
    Ui ui = Ui.new();
    Account atest = Account.new();
    atest.user = "test";
    atest.pass = "pass";
    AccountManager am = ui.accountManager;
    am.deleteAccount(atest);
    Account a = am.getAccount(atest.user);
    assertNull(a);
    am.createAccount(atest);
    a = am.getAccount(atest.user);
    assertNotNull(a);
    assertTrue(a.checkPass("pass"));
    assertFalse(a.checkPass("notpass"));
    a.pass = "yo";
    assertTrue(a.checkPass("yo"));
    am.updateAccount(a);
    a = am.getAccount(a.user);
    assertEqual(a.user, "test");
    assertTrue(a.checkPass("yo"));
    am.deleteAccount(atest);
  }
  
  main() {
    "Begin AccountTest".print();
    testAccounts();
    "End AccountTest".print();
  }
  
}
