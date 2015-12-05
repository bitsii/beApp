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
use Db:Derby:Database as Derby;
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
      if (mode == "lui") {
        webr = WeBr.new();
        webr.webHandler = self;
        webr.height = 450;
        webr.width = 320;
        
        String mypwd = System:Environment.getVariable("MYPWD");
        webr.location = "file:///" + mypwd + "/Dz.html";
        
        webr.setup();
      }
      if (mode == "wui") {
        Wui.new().main();
      }
      if (mode == "test") {
        Dz:Test.new().main();
      }
      if (mode == "cmd") {
        CmdUi.new().main(args);
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
      vw.gzipOutput = true;
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
       if ((uri.ends(".jpg") && TS.notEmpty(accountName)) || uri.ends("/Dz.html") || uri.ends("/BEL_4_Base.js")) {
         if (uri.ends(".jpg")) {
          File imgfile = File.apNew(uri.substring(1));
         } else {
          imgfile = File.new(Path.apNew(uri).name);
         }
         log.log(lvl, "imgfile " + imgfile.path);
         if (imgfile.exists) {
          String content = imgfile.reader.open().readString();
         }
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
        log.level = log.info;
        Int lvl = log.level;
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
      i.lvl = lvl;
      i.app = self;
      modules["MediaIO"] = i;
      
      Accounts a = Accounts.new();
      a.log = log;
      a.lvl = lvl;
      a.app = self;
      modules["Accounts"] = a;
      
  }
  
  configManagerGet() {
    return(ConfigManager.new(self, "CONFIG"));
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
          emit(jv) {
          """
          try {
          """
          }
          lock.lock();
          ifEmit(jv) {
            dbp = Path.apNew("../dzdata/DDZDB");
            db = Derby.pathNew(dbp);
          }
          ifEmit(cs) {
            dbp = Path.apNew("../dzdata/FDZDB");
            db = FbDb.pathNew(dbp);
          }
          Bool createTables = dbp.file.exists!;
          dbRecyc.templateResource = db;
          db = dbRecyc.get();
          db.open();
          if (createTables) {
            db.begin();
            db.execute("CREATE TABLE ACCOUNTS( LOGIN VARCHAR(110), PASS VARCHAR(500), SALT VARCHAR(64), PERMS VARCHAR(256), "
              + " constraint ACCOUNTS_k primary key (LOGIN) )");
            db.execute("CREATE TABLE CONFIG( NAME VARCHAR(110), VALUE VARCHAR(500), "
              + " constraint CONFIG_k primary key (NAME) )");
            db.commit();
          }
          dbRecyc.done(db);
          lock.unlock();
          emit(jv) {
          """
          } catch (Throwable t) {
            System.out.println(t);
            t.printStackTrace();
            throw t;
          }
          """
          }
        } catch (var e) {
          lock.unlock();
          dbRecyc.failed(db);
          throw(e);
        }
      }
      return(db);
      
    }
    
    getHomeDir(request) Path {
      String accountName = request.getSession("account.name");
      Path homeDir = Path.apNew(accountName);
      return(homeDir);
    }
    
    getAccountUser(request) String {
      String accountName = request.getSession("account.name");
      return(accountName);
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
      try {
        return(main(System:Process.new().args));
      } catch (var e) {
        log.log(lvl, "Exception in CmdUi main, error is " + e);
      }
    }

    main(Array args) {
      if (args.length > 1) {
        String mode = args[1]; //ui, svc, both, [absent]
        log.log(lvl, "cmd " + mode);
      } else {
        log.log(lvl, "cmd empty");
      }
      if (TS.notEmpty(mode) && mode == "createAccount") {
        String user = args[2];
        String pass = args[3];
        log.log(lvl, "Creating Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        if (args.length > 4) {
          ac.permsString = args[4];
        }
        self.accountManager.createAccount(ac);
        self.db.close();
      }
      if (TS.notEmpty(mode) && mode == "deleteAccount") {
        user = args[2];
        log.log(lvl, "Deleting Account " + user);
        ac = self.accountManager.getAccount(user);
        if (def(ac)) {
          self.accountManager.deleteAccount(ac);
          log.log(lvl, "Deleted account " + user);
        } else {
          log.log(lvl, "No such account for deletion " + user);
        }
        self.db.close();
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
          var app;
        }
     }

     updateImageRequest(Map arg, request) {
      Path pp = app.getHomeDir(request).addStep("WebCam");
      String an = app.getAccountUser(request);
      String c = app.configManager.get("image.count." + an);
      if (pp.file.exists!) {
        pp.file.makeDirs();
      }
      if (def(c)) {
        log.log(lvl, "count def " + c);
        count = Int.new(c);
      } else {
        log.log(lvl, "count undef");
        app.configManager.create("image.count." + an, count.toString());
      }
      String picName = "pic" + count + ".jpg";
      String lastPicName = "pic" + (count - 1) + ".jpg";
      File picFile = pp.copy().addStep(picName).file;
      picFile.delete();
      pp.copy().addStep(lastPicName).file.delete();
      if (System:CurrentPlatform.name == "mswin") {
        String piccmd = "uppic.bat";
      } else {
        piccmd = "uppic.sh";
      }
      log.log(lvl, "pic path " + picFile.path);
      System:Command.new(piccmd + " " + picFile.path).run();
      Int tries = 60;
      while (picFile.exists! && tries > 0) {
        Time:Sleep.sleepMilliseconds(500);
        tries--=;
      }
      Time:Sleep.sleepMilliseconds(500);
      log.log(lvl, "In load image");
      Map res = Map.new();
      res["action"] = "updateImageResponse";
      res["imghtm"] = "<img src=\"" + picFile.path.toStringWithSeparator("/") + "\" >";
      count++=;
      log.log(lvl, "updating count " + count);
      app.configManager.update("image.count." + an, count.toString());
      return(res);
   }
   
   playSoundRequest(Map arg, request) {
      log.log(lvl, "playing sound");
      System:Command.new("playsound.sh").run();
      return(null);
   }
   
   runCommandRequest(Map arg, request) {
      String cmd = arg["cmd"];
      log.log(lvl, "running command " + cmd);
      System:Command.new(cmd).run();
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
        var app;
      }
   }

  loginRequest(Map arg, request) {
    Account a = app.accountManager.getAccount(arg["loginName"]);
    if (def(a)) {
      log.log(lvl, "Found account " + arg["loginName"]);
      if (a.checkPass(arg["loginPass"])) {
        log.log(lvl, "Login ok");
        request.putSession("account.name", arg["loginName"]);
        Map res = Map.new();
        res["action"] = "loginResponse";
        res["name"] = arg["loginName"];
        return(res);
      } else {
        log.log(lvl, "Login notok");
      }
    } else {
      log.log(lvl, "No such account " + arg["loginName"]);
    }
    return(logoutRequest(arg, request));
  }
  
  logoutRequest(Map arg, request) {
    request.putSession("account.name", "");
    Map res = Map.new();
    res["action"] = "logoutResponse";
    return(res);
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
      Array qa = Array.new(1);
      qa[0] = user;
      DbDb db = dbProvider.db;
      db.begin();
      foreach (DbSt ares in db.executeQuery("SELECT LOGIN, PASS, SALT, PERMS FROM " + tableName + " WHERE LOGIN=?", qa)) {
        Account a = Account.new(ares.getString(0), ares.getString(1), ares.getString(2), ares.getString(3));
      }
      db.commit();
      //ares.close();
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
      Array qa = Array.new(1).put(0, a.user);
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("DELETE FROM " + tableName + " WHERE LOGIN=?", qa);
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
      emit(jv) {
      """
      try {
      """
      }
      Array qa = Array.new(4).put(0, a.user).put(1, a.pass).put(2, a.salt).put(3, a.permsString);
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("INSERT INTO " + tableName + " (LOGIN, PASS, SALT, PERMS) VALUES (?, ?, ?, ?)", qa);
      db.commit();
      dbProvider.dbDone(db);
      emit(jv) {
      """
      } catch (Throwable t) {
        System.out.println(t.getMessage());
        t.printStackTrace();
        throw t;
      }
      """
      }
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
  }
  
  updateAccount(Account a) {
    try {
      Array qa = Array.new(4).put(0, a.pass).put(1, a.salt).put(2, a.permsString).put(3, a.user);
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("UPDATE " + tableName + " SET PASS=?, SALT=?, PERMS=? WHERE LOGIN=?", qa);
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

  new() self {
    properties {
      Set perms = Set.new();
    }
  }

  new(String _user, String _hashPass, String _salt, String _permsString) self {
    new();
    properties {
      String user = _user;
      String pass = _hashPass;
      String salt = _salt;
    }
    self.permsString = _permsString;
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
  
  permsStringSet(String permsString) {
    perms = Set.new();
    if (TS.notEmpty(permsString)) {
      foreach (String perm in permsString.split(",")) {
        perms.put(perm);
      }
    }
  }
  
  permsStringGet() String {
    Bool first = true;
    String permsString = "";
    foreach (String perm in perms) {
      if (first) {
        first = false;
      } else {
        permsString += ",";
      }
      permsString += perm;
    }
    return(permsString);
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
    assertFalse(a.perms.has("admin"));
    assertTrue(a.checkPass("pass"));
    assertFalse(a.checkPass("notpass"));
    a.pass = "yo";
    assertTrue(a.checkPass("yo"));
    a.perms.put("admin");
    am.updateAccount(a);
    a = am.getAccount(a.user);
    assertEqual(a.user, "test");
    assertTrue(a.checkPass("yo"));
    //assertTrue(a.perms.has("admin"));
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
      Array qa = Array.new(1);
      qa[0] = name;
      DbDb db = dbProvider.db;
      db.begin();
      foreach (DbSt ares in db.executeQuery("SELECT VALUE FROM " + tableName + " WHERE NAME=?", qa)) {
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
      Array qa = Array.new(1).put(0, name);
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("DELETE FROM " + tableName + " WHERE NAME=?", qa);
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
      Array qa = Array.new(2).put(0, name).put(1, value);
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("INSERT INTO " + tableName + " (NAME, VALUE) VALUES (?, ?)", qa);
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
      Array qa = Array.new(2).put(0, value).put(1, name);
      DbDb db = dbProvider.db;
      db.begin();
      db.execute("UPDATE " + tableName + " SET VALUE=? WHERE NAME=?", qa);
      db.commit();
      dbProvider.dbDone(db);
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      throw(e);
    }
  }
  
  compareAndUpdate(String name, String oldValue, String value) Bool {
    Bool result = false;
    try {
      DbDb db = dbProvider.db;
      db.begin();
      Array qc = Array.new(1).put(0, name);
      foreach (DbSt ares in db.executeQuery("SELECT VALUE FROM " + tableName + " WHERE NAME=?", qc)) {
        String currValue = ares.getString(0);
      }
      if (currValue == oldValue) {
          Array qa = Array.new(2).put(0, value).put(1, name);
          db.execute("UPDATE " + tableName + " SET VALUE=? WHERE NAME=?", qa);
          db.commit();
          result = true;
          dbProvider.dbDone(db);
      }
    } catch (var e) {
      db.rollback();
      dbProvider.dbFailed(db);
      //expected case, not fatal
    }
    return(result);
  }

}

use class Dz:ConfigTest(Assert) {
  
  testConfig() {
  
  }
  
  main() {
    "Begin ConfigTest".print();
    testConfig();
    "End ConfigTest".print();
  }
  
}
