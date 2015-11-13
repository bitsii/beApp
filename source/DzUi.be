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
        mode = "wui";
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
      if (mode == "wui") {
        Wui.new().main();
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

emit(jv) {
"""
import java.security.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import java.io.*;
import java.sql.*;
import org.bouncycastle.x509.*;
import java.math.BigInteger;
import java.security.cert.X509Certificate;
import org.bouncycastle.jce.X509Principal;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
"""
}
use class Dz:Wui(Ui) {

  emit(jv) {
  """
  static { Security.addProvider(new BouncyCastleProvider());  }
  """
  }

  new() self {
        properties {
        }
        super.new();
    }
    
    startWeb() {
      var e;
      Int port = 5000;
      String cerPath = assureCert(port);
      //portL.o = port;
      Web:Server vw = Web:Server.new();
      //vwL.o = vw;
      vw.port = port;
      vw.ssl = true;
      vw.sslPath = cerPath;
      vw.app = self;
      vars {
        System:Thread myThread = System:Thread.new(vw);
      }
      log.log(lvl, "Starting Web");
      myThread.start();
    }
    
    
  assureCert(Int port) String {
    ifEmit(jv) {
      return(assureCertJv(port));
    }
  }
  
  assureCertJv(Int port) String {
    Path cerPath = Path.apNew("cert");
    String cerPathS = cerPath.toString();
    log.log(lvl, "cerPath " + cerPathS);
    if (cerPath.file.exists) {
      log.log(lvl, "cer exist");
      return(cerPathS);
    } else {
      log.log(lvl, "cer not exist");
    }
    log.log(lvl, "Start gencert");
    emit(jv) {
    """ 
    String domainName = "test";
    KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
    keyPairGenerator.initialize(1024);
    KeyPair KPair = keyPairGenerator.generateKeyPair();
    X509V3CertificateGenerator v3CertGen = new X509V3CertificateGenerator();
    v3CertGen.setSerialNumber(BigInteger.valueOf(new SecureRandom().nextInt(Integer.MAX_VALUE)));
        v3CertGen.setIssuerDN(new X509Principal("CN=" + domainName + ", OU=None, O=None L=None, C=None"));
        v3CertGen.setNotBefore(new Date(System.currentTimeMillis() - 1000L * 60 * 60 * 24 * 30));
        v3CertGen.setNotAfter(new Date(System.currentTimeMillis() + (1000L * 60 * 60 * 24 * 365*10)));
        v3CertGen.setSubjectDN(new X509Principal("CN=" + domainName + ", OU=None, O=None L=None, C=None"));
    v3CertGen.setPublicKey(KPair.getPublic());
    v3CertGen.setSignatureAlgorithm("MD5WithRSAEncryption"); 
    X509Certificate PKCertificate = v3CertGen.generateX509Certificate(KPair.getPrivate());
    
    KeyStore privateKS = KeyStore.getInstance("JKS");
    privateKS.load(null);
    privateKS.setKeyEntry("jetty", KPair.getPrivate(),
                   //new char[]{'e', 'n', 't', 'r', 'y', 'p', 'a', 's', 's'},
                   "kp".toCharArray(),
                   new java.security.cert.Certificate[]{PKCertificate});
    privateKS.store( new FileOutputStream(bevl_cerPathS.bems_toJvString()), "kp".toCharArray());

    """
    }
    log.log(lvl, "End gencert");
    return(cerPathS);
  }
  
    main() {
      Array args = System:Process.new().args;

      startWeb();
   }

   initWeb() {

   }

   handleWeb(request) {
   
     String accountName = request.getSession("account.name");
     Map arg = request.scriptArg;
     if (undef(arg)) {
       String uri = request.uri;
       log.log(lvl, "uri " + uri);
       if (uri.ends(".jpg") && TS.notEmpty(accountName)) {
         File imgfile = File.new(Path.apNew(uri).name);
         if (imgfile.exists) {
          content = imgfile.reader.open().readString();
         }
       } else {
        String content = IO:File.new("DzA.html").reader.open().readString()
          + IO:File.new("BEL_4_Base.js").reader.open().readString()
          //+ IO:File.new("Dzmid.js").reader.open().readString()
          + IO:File.new("DzB.html").reader.open().readString();
          //content.print();
        }
      if (def(content)) {
        request.outputContent = content;
      }
      return(null);
     }
     return(super.handleWeb(request, arg));
   }
   
    exitRequest(Map arg, request) Map {
      exit();
      return(null);
    }

    exit() {
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
      
      MediaIO i = MediaIO.new();
      i.log = log;
      i.lvl = log.level;
      i.configManager = ConfigManager.new(self, "CONFIG");
      modules["MediaIO"] = i;
      
      Accounts a = Accounts.new();
      a.log = log;
      a.lvl = log.level;
      a.accountManager = self.accountManager;
      modules["Accounts"] = a;
      
  }

  handleWeb(request, Map arg) {
        try {
            String mname = arg.get("module");
            String aname = arg.get("action");
            if (undef(aname) || aname.ends("Request")! || undef(mname) || modules.has(mname)!) {
              throw(Exception.new("Invalid request"));
            }
            String accountName = request.getSession("account.name");
            if (TS.isEmpty(accountName)) {
              unless (mname == "Accounts" && aname == "loginRequest") {
                return(null);
              }
            }
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
          db.execute("CREATE TABLE IF NOT EXISTS CONFIG( NAME VARCHAR(110), VALUE VARCHAR(500), "
            + " constraint CONFIG_k primary key (NAME) )");
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

use class Dz:MediaIO {

     new() self {
       properties {
          IO:Log log;
          Int lvl;
          Int count = 0;
          var configManager;
        }
     }

     updateImageRequest(Map arg, request) {
      String c = configManager.get("image.count");
      if (def(c)) {
        log.log(lvl, "count def " + c);
        count = Int.new(c);
      } else {
        log.log(lvl, "count undef");
        configManager.create("image.count", count.toString());
      }
      String picName = "pic" + count + ".jpg";
      String lastPicName = "pic" + (count - 1) + ".jpg";
      File.apNew(picName).delete();
      File.apNew(lastPicName).delete();
      System:Command.new("uppic.sh " + picName).run();
      log.log(lvl, "In load image");
      Map res = Map.new();
      res["action"] = "updateImageResponse";
      res["imghtm"] = "<img src=\"" + picName + "\" >";
      count++=;
      log.log(lvl, "updating count " + count);
      configManager.update("image.count", count.toString());
      return(res);
   }
   
   playSoundRequest(Map arg, request) {
      log.log(lvl, "playing sound");
      System:Command.new("playsound.sh").run();
      return(null);
   }

}

// create, create if none, get, check pass, type, update, delete

//web thing
use class Dz:Accounts {

  new() self {
     properties {
        IO:Log log;
        Int lvl;
        var accountManager;
      }
   }

  loginRequest(Map arg, request) {
    Account a = accountManager.getAccount(arg["loginName"]);
    if (def(a)) {
      log.log(lvl, "Found account " + arg["loginName"]);
      if (a.checkPass(arg["loginPass"])) {
        log.log(lvl, "Login ok");
        request.putSession("account.name", arg["loginName"]);
      } else {
        log.log(lvl, "Login notok");
      }
    } else {
      log.log(lvl, "No such account " + arg["loginName"]);
    }
    //request.putSession("account.name", arg["loginName"]);
  }
  
  logoutRequest(Map arg, request) {
    request.putSession("account.name", "");
  }
  
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
      db.begin();
      foreach (DbSt ares in db.executeQuery("SELECT USER, PASS, SALT FROM " + tableName + " WHERE USER='" + user + "'")) {
        Account a = Account.new(ares.getString(0), ares.getString(1), ares.getString(2));
      }
      //ares.close();
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
    return(a);
  }
  
  deleteAccount(Account a) {
    try {
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("DELETE FROM " + tableName + " WHERE USER='" + a.user + "'");
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
  }
  
  createAccount(Account a) {
    try {
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("INSERT INTO " + tableName + " (USER, PASS, SALT) VALUES ('" + a.user + "', '" + a.pass + "', '" + a.salt + "')");
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
  }
  
  updateAccount(Account a) {
    try {
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("UPDATE " + tableName + " SET PASS='" + a.pass + "', SALT='" + a.salt +  "' WHERE USER='" + a.user + "'");
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
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

use class Dz:ConfigManager {

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

  get(String name) String {
    try {
      DbDb db = dbProvider.db;
      db.begin();
      foreach (DbSt ares in db.executeQuery("SELECT VALUE FROM " + tableName + " WHERE NAME='" + name + "'")) {
        String value = ares.getString(0);
      }
      //ares.close();
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
    return(value);
  }
  
  delete(String name) {
    try {
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("DELETE FROM " + tableName + " WHERE NAME='" + name + "'");
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
  }
  
  create(String name, String value) {
    try {
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("INSERT INTO " + tableName + " (NAME, VALUE) VALUES ('" + name + "', '" + value + "')");
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
  }
  
  update(String name, String value) {
    try {
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("UPDATE " + tableName + " SET VALUE='" + value +  "' WHERE NAME='" + name + "'");
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
  }

}
