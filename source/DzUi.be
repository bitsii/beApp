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
use Db:Derby:Database as Derby;
use Db:HSQLDb:Database as HsDb;
use System:Thread:Lock;

use App:Alert;

use class Dz:Lui(Ui) {

  new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
        bg.startBackground();
    }

    main() {
      webr = WeBr.new();
      webr.webHandler = self;
      webr.height = 450;
      webr.width = 320;
      
      String mypwd = System:Environment.getVariable("MYPWD");
      webr.location = "file:///" + mypwd + "/App/Dz/Dz.html";
      
      webr.setup();
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
        bg.startBackground();
    }
    
    startWeb() {
      var e;
      String ports = self.configManager.get("wui.port");
      if (TS.isEmpty(ports)) {
        ports = "5000";
        self.configManager.insert("wui.port", ports);
      }
      Int port = Int.new(ports);
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
    Path cerPath = Path.apNew("Data/Dz/cert");
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
   
   checkWritePath(Path p, String accountName) Bool {
    var e;
    Bool isOk = false;
    if (undef(accountName)) { accountName = ""; }
    try {
      Path pa = p.file.absPath;
      if (TS.notEmpty(accountName)) {
        Path h = Path.apNew("Home/" + accountName).file.absPath;
      }
      String pas = pa.toString();
      if (def(h) && pas.begins(h.toString())) {
        isOk = true;
      }
    } catch (e) {
      log.log(lvl, "Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
    }
    //log.log(lvl, "checkPath isOk " + isOk);
    return(isOk);
   }
   
   checkReadPath(Path p, String accountName) Bool {
    var e;
    Bool isOk = false;
    if (undef(accountName)) { accountName = ""; }
    try {
      Path pa = p.file.absPath;
      Path adz = Path.apNew("App/Dz").file.absPath;
      if (TS.notEmpty(accountName)) {
        Path h = Path.apNew("Home/" + accountName).file.absPath;
      }
      String pas = pa.toString();
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js"))) {
        isOk = true;
      } elif (def(h) && pas.begins(h.toString())) {
        isOk = true;
      }
    } catch (e) {
      log.log(lvl, "Path " + p + " accountName " + accountName + " excepted in checkPath " + e);
    }
    //log.log(lvl, "checkPath isOk " + isOk);
    return(isOk);
   }

   handleWeb(request) {
     //log.log(lvl, "in hw");
     String accountName = request.getSession("account.name");
     String rmtd = request.inputMethod;
     //log.log(lvl, "rmtd is " + rmtd);
     if (TS.isEmpty(rmtd) || rmtd != "PUT") {
        Map arg = request.scriptArg;
     }
     if (TS.isEmpty(accountName)) {
       String ln = request.getParameter("loginName");
       String lp = request.getParameter("loginPass");
       if (TS.notEmpty(ln) && TS.notEmpty(lp)) {
          log.log(lvl, "doing svc login");
          Account a = self.accountManager.getAccount(ln);
          if (def(a)) {
            log.log(lvl, "Found account " + ln);
            if (a.checkPass(lp)) {
              log.log(lvl, "svc login ok");
              request.putSession("account.name", ln);
              accountName = ln;
            }
          }
        }
     }
     if (undef(arg)) {
       String uri = request.uri;
       log.log(lvl, "uri " + uri);
       File imgfile = File.apNew(uri.substring(1));
       if (TS.notEmpty(rmtd) && rmtd == "PUT") {
         if (checkWritePath(imgfile.path, accountName)) {
           log.log(lvl, "put for " + imgfile.path);
            String rwbuf1 = String.new(4096);
            String rwbuf2 = String.new(4096);
            String accum = String.new(8192);
            outw = imgfile.writer.open();
            inr = request.openInput();
            String firstLine = inr.readBufferLine();
            String firstChar = firstLine.substring(0,1);
            //log.log(lvl, "first char |" + firstChar + "|");
            String line = firstLine;
            firstLine = firstLine.substring(0, firstLine.size - 2);
            //log.log(lvl, "first line " + firstLine.size + " " + firstLine);
            while (def(line) && line != "\n" && line != "\r\n") {
              line = inr.readBufferLine();
            }
            Bool found = false;
            while (found! && inr.readIntoBuffer(rwbuf2) > 0) {
              pos = null;
              if (rwbuf1.has(firstChar) || rwbuf2.has(firstLine)) {
                accum.clear();
                accum += rwbuf1;
                accum += rwbuf2;
                Int pos = accum.find(firstLine);
              }
              if (def(pos)) {
                //log.log(lvl, "foundFirst");
                found = true;
                accum = accum.substring(0, pos);
                outw.write(rwbuf1);
              } else {
                outw.write(rwbuf1);
                String tb = rwbuf1;
                rwbuf1 = rwbuf2;
                rwbuf2 = tb;
                rwbuf2.clear();
              }
            }
            request.closeInputReader();
            outw.close();
            request.outputContent = "UPLOAD COMPLETE";
         }
       } elif (checkReadPath(imgfile.path, accountName)) {
         log.log(lvl, "imgfile " + imgfile.path);
         if (imgfile.exists) {
          String mtype;
          if (uri.ends(".html")) {
            mtype = "text/html";
          } elif (uri.ends(".jpg")) {
            mtype = "image/jpeg";
          } elif (uri.ends(".js")) {
            mtype = "text/javascript";
          } else {
            mtype = "application/octet-stream";
          }
          request.outputContentType = mtype;
          String rwbuf = String.new(4096);
          IO:Writer outw = request.openOutput();
          IO:Reader inr = imgfile.reader.open();
          while (inr.readIntoBuffer(rwbuf) > 0) {
            outw.write(rwbuf);
          }
          request.closeOutputWriter();
          inr.close();
         }
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

use class Dz:DnsUpdate {

  new() self {
  
    vars {
      String duckDomain;
      String duckToken;
      var app;
      Int lvl;
      IO:Log log;
      Int lastSec = 0;
      Int pollSecs = 3600;
    }
  
  }
  
  updateOnInterval() {
    Int currSec = Time:Interval.now().seconds;
    if (currSec - lastSec > pollSecs) {
      lastSec = currSec;
      doUpdate();
    }
  }
  
  doUpdate() {
    //log.log(lvl, "In doUpdate");
    if (TS.notEmpty(duckDomain) && TS.notEmpty(duckToken)) {
      log.log(lvl, "Hitting Duck");
      String url =  "https://duckdns.org/update/" + duckDomain + "/" + duckToken;
      Web:Client client = Web:Client.new();
      Web:Client:CertificateManager.validateCertificates = false;
      client.method = "GET";
      client.url = url;
      String res = client.openInput().readString();
      client.close();
      Web:Client:CertificateManager.validateCertificates = true;
      client = null;
    }
  }
  
  init() {
    duckDomain = app.configManager.get("dns.duckDomain");
    duckToken = app.configManager.get("dns.duckToken");
    //if (TS.isEmpty(duckDomain)) { duckDomain = ""; }
    //if (TS.isEmpty(duckToken)) { duckToken = ""; }
    //log.log(lvl, "dns.duckDomain " + duckDomain + " dns.duckToken " + duckToken);
    Int _pollSecs = app.configManager.get("dns.pollSecs");
    if (def(_pollSecs) && _pollSecs > 0) {
      pollSecs = _pollSecs;
    }
  }

}

use class Dz:Background {

  new() self {
    vars {
      var app;
      Int lvl;
      IO:Log log;
      DnsUpdate du = DnsUpdate.new();
    }
  }
  
  runTasks() {
    //log.log(lvl, "Running tasks");
    //duck, in app, last update/update now, get from config / set to config on change, etc
    du.updateOnInterval();
  }
  
  main() {
    var e;
    while (true) {
      try {
        runTasks();
      } catch (e) {
        log.log(lvl, "Caught exception running tasks " + e);
      }
      try {          
        Time:Sleep.sleepMilliseconds(sleepTime);
      } catch (e) {
        log.log(lvl, "Caught exception sleeping " + e);
      }
    }
  }
  
  startBackground() {
    vars {
      System:Thread myThread;
      Int sleepTime = 500;
    }
    Int _sleepTime = app.configManager.get("bk.sleepTime");
    if (def(_sleepTime) && _sleepTime > 0) {
      sleepTime = _sleepTime;
    }
    du.app = app;
    du.lvl = lvl;
    du.log = log;
    du.init();
    myThread = System:Thread.new(self);
    myThread.start();
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
        Background bg = Background.new();
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
      
      bg.log = log;
      bg.lvl = lvl;
      bg.app = self;
      //bg.startBackground();
      
  }
  
  pathsGet() App:Paths {
    vars {
      App:Paths paths;
    }
    if (undef(paths)) {
      paths = App:Paths.new();
    }
    return(paths);
  }
  
  configManagerGet() KvDb {
    vars {
      KvDb configManager;
    }
    if (undef(configManager)) {
      Path db = self.paths.dataPath.addStep("Dz").addStep("DDZDB");
      configManager = KvDb.new(Derby.pathNew(db), "CONFIG");
      //configManager = KvDb.new(HsDb.pathNew(db), "CONFIG");
      configManager.createOpen();
    }
    return(configManager);
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
    
    getHomeDir(request) Path {
      String accountName = request.getSession("account.name");
      Path homeDir = Path.apNew("Home/" + accountName);
      return(homeDir);
    }
    
    accountManagerGet() AccountManager {
      properties {
        AccountManager am;
      }
      if (undef(am)) {
        am = AccountManager.new(self.configManager, "ACCOUNTS.");
      }
      return(am);
    }
    
    loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["camLinks"] = modules.get("MediaIO").camLinksForAccount(a);
      log.log(lvl, "CamLinks " + res["camLinks"]);
      return(res);
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
        Lui.new().main();
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
      main(System:Process.new().args);
    }
    
    main(Array args) {
      outerMain(System:Process.new().args);
      try {
        self.configManager.close();
      } catch (var e) {
        log.log(lvl, "Exception closing db in CmdUi, error is " + e);
      }
    }
    
    outerMain(Array args) {
      try {
        innerMain(System:Process.new().args);
      } catch (var e) {
        log.log(lvl, "Exception in CmdUi, error is " + e);
      }
    }

    innerMain(Array args) {
      if (args.length > 1) {
        String mode = args[1]; //ui, svc, both, [absent]
        log.log(lvl, "cmd " + mode);
      } else {
        log.log(lvl, "cmd empty");
      }
      if (TS.isEmpty(mode) || mode == "help") {
        log.log(lvl, "Help");
        log.log(lvl, "listLogins, createAccount, getAccount, setPermsString, setPass, deleteAccount, updateConfig, showConfig, createConfig, deleteConfig");
      }
      if (TS.notEmpty(mode) && mode == "listLogins") {
        foreach (String login in self.accountManager.getLogins()) {
          log.log(lvl, "Account login " + login);
        }
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
      }
      if (TS.notEmpty(mode) && mode == "getAccount") {
        user = args[2];
        log.log(lvl, "Get Account " + user);
        ac = self.accountManager.getAccount(user);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPermsString") {
        user = args[2];
        String ps = args[3];
        log.log(lvl, "Set Perms " + user);
        ac = self.accountManager.getAccount(user);
        ac.permsString = ps;
        self.accountManager.updateAccount(ac);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPass") {
        user = args[2];
        pass = args[3];
        log.log(lvl, "Set Pass " + user);
        ac = self.accountManager.getAccount(user);
        ac.pass = pass;
        self.accountManager.updateAccount(ac);
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
      }
      if (TS.notEmpty(mode) && mode == "updateConfig") {
        String key = args[2];
        String value = args[3];
        log.log(lvl, "Updating config " + key + " " + value);
        self.configManager.update(key, value);
      }
      if (TS.notEmpty(mode) && mode == "showConfig") {
        foreach (var kv in self.configManager.getMap()) {
          log.log(lvl, "Config name " + kv.key + " value " + kv.value);
        }
      }
      if (TS.notEmpty(mode) && mode == "createConfig") {
        key = args[2];
        value = args[3];
        log.log(lvl, "Creating config " + key + " " + value);
        self.configManager.insert(key, value);
      }
      if (TS.notEmpty(mode) && mode == "deleteConfig") {
        key = args[2];
        log.log(lvl, "Deleting config " + key);
        self.configManager.delete(key);
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
          var app;
        }
     }

     updateImageRequest(Map arg, request) {
      Path pp = app.getHomeDir(request).addStep("WebCam");
      String cam = arg["cam"];
      Account a = app.accountManager.getAccountForRequest(request);
      String an = a.user;
      unless (camOkForAccount(cam, a)) {
        throw(Exception.new("Account " + an + " not authorized for cam " + cam));
      }
      if (pp.file.exists!) {
        pp.file.makeDirs();
      }
      String countKey = "image.count." + cam + "." + an;
      String c = app.configManager.get(countKey);
      if (def(c)) {
        log.log(lvl, "count def " + c);
        count = Int.new(c);
      } else {
        log.log(lvl, "count undef");
        Int count = 0;
        app.configManager.insert(countKey, count.toString());
      }
      String rv = app.configManager.get("cam." + cam + ".label");
      if (undef(rv)) {
        rv = System:Random.getString(6);
      }
      String myhn = System:Environment.getVariable("MYHN");
      String picBaseName = "Pic-" + myhn + "-" + rv + "-";
      Int tries = 5;
      Int maxPics = 4;
      Bool updatedCount = false;
      while (tries > 0 && updatedCount!) {
        count = Int.new(app.configManager.get(countKey));
        tries--=;
        Int nxcount = count++;
        if (nxcount > maxPics) {
          nxcount = 0;
        }
        updatedCount = app.configManager.testAndUpdate(countKey, count.toString(), nxcount.toString());
      }
      if (tries <= 0) {
        throw(System:Exception.new("Unable to get a count option"));
      }
      String picName = picBaseName + count + ".jpg";
      File picFile = pp.copy().addStep(picName).file;
      picFile.delete();
      if (System:CurrentPlatform.name == "mswin") {
        String piccmd = "App\\Dz\\uppic.bat";
      } else {
        piccmd = "App/Dz/uppic.sh";
      }
      log.log(lvl, "pic path " + picFile.path);
      System:Command.new(piccmd + " " + cam + " " + picFile.path).run();
      tries = 60;
      while (picFile.exists! && tries > 0) {
        Time:Sleep.sleepMilliseconds(500);
        tries--=;
      }
      Time:Sleep.sleepMilliseconds(500);
      log.log(lvl, "In load image");
      Map res = Map.new();
      res["action"] = "updateImageResponse";
      //res["imghtm"] = "<img src=\"" + picFile.path.toStringWithSeparator("/") + "\" >";
      res["imghtm"] = "<img src=\"../../" + picFile.path.toStringWithSeparator("/") + "?cbust=" + Time:Interval.now().seconds + System:Random.getString(6) + "\" >";
      return(res);
   }
   
   playSoundRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      unless (a.perms.has("admin")) {
        log.log(lvl, "Account not admin, not playing sound");
        return(null);
      }
      log.log(lvl, "playing sound");
      System:Command.new("playsound.sh").run();
      return(null);
   }
   
   runCommandRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      unless (a.perms.has("admin")) {
        log.log(lvl, "Account not admin, not running command");
        return(null);
      }
      String cmd = arg["cmd"];
      log.log(lvl, "running command " + cmd);
      System:Command.new(cmd).run();
      return(null);
   }
   
   detectCamsRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      unless (a.perms.has("admin")) {
        log.log(lvl, "Account not admin, not detecting cams");
        return(null);
      }
      //TODO for real, ls /dev/video* with a script into a file
      updateCams();
      Map res = Map.new();
      res["action"] = "updateResponse";
      res["camLinks"] = app.modules.get("MediaIO").camLinksForAccount(a);
      return(res);
   }
   
   updateCams() {
     updateCams("/dev/video0,/dev/video1");
   }
   
   getCams() Set {
      Set ecm = Set.new();
      String ecps = app.configManager.get("cam.paths");
      if (def(ecps)) {
        foreach (String cp in ecps.split(",")) {
          ecm.put(cp);
        }
      }
      return(ecm);
   }
   
   updateCams(String dcs) {
      Set ecm = getCams();
      if (TS.notEmpty(dcs)) {
        foreach (String cp in dcs.split(",")) {
          if (ecm.has(cp)!) {
            app.configManager.delete("cam." + cp + ".label");
            app.configManager.insert("cam." + cp + ".label", Path.apNew(cp).steps.last);
          }
        }
      }
      app.configManager.delete("cam.paths");
      app.configManager.insert("cam.paths", dcs);
   }
   
   camOkForAccount(String c, Account a) {
    if (a.perms.has("admin") || a.perms.has("allcam") || 
        a.perms.has("cam." + c)) {
      return(true);
    }
    return(false);
   }
   
   camLinksForAccount(Account a) String {
     String camLinks = String.new();
     Set ecm = getCams();
     foreach (String c in ecm) {
       if (camOkForAccount(c, a)) {
          String clabel = app.configManager.get("cam." + c + ".label");
          camLinks += "<p><a href=\"#\" onclick=\"updateImage('" + c + "');return false;\">Take Picture with " + clabel + "</a></p>";
        }
     }
     return(camLinks);
   }

}

use App:Account;
use App:AccountManager;

//web thing
use class Dz:Accounts {

  new() self {
     properties {
        IO:Log log;
        Int lvl;
        var app;
      }
   }
   
   checkLoggedInRequest(Map arg, request) {
    String accountName = request.getSession("account.name");
    if (TS.notEmpty(accountName)) {
      Account a = app.accountManager.getAccount(accountName);
      if (def(a)) {
        log.log(lvl, "Found logged in account " + accountName);
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = accountName;
        return(app.loggedIn(a, res, arg, request));
      } else {
        log.log(lvl, "No such account " + accountName);
      }
    }
    return(logoutRequest(arg, request));
  }

  loginRequest(Map arg, request) {
    Account a = app.accountManager.getAccount(arg["loginName"]);
    if (def(a)) {
      log.log(lvl, "Found account " + arg["loginName"]);
      if (a.checkPass(arg["loginPass"])) {
        log.log(lvl, "Login ok");
        request.putSession("account.name", arg["loginName"]);
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = arg["loginName"];
        return(app.loggedIn(a, res, arg, request));
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



use Db:KeyValue as KvDb;

use class Dz:ConfigTest(Assert) {
  
  testConfig() {
    Ui ui = Ui.new();
    KvDb cm = ui.configManager;
    cm.delete("test.blarg");
    assertNull(cm.get("test.blarg"));
    cm.insert("test.blarg", "test");
    assertEqual(cm.get("test.blarg"), "test");
    cm.update("test.blarg", "foo");
    assertEqual(cm.get("test.blarg"), "foo");
    assertFalse(cm.testAndUpdate("test.blarg", "test", "la"));
    assertNotEqual(cm.get("test.blarg"), "la");
    assertTrue(cm.testAndUpdate("test.blarg", "foo", "la"));
    assertEqual(cm.get("test.blarg"), "la");
  }
  
  main() {
    "Begin ConfigTest".print();
    testConfig();
    "End ConfigTest".print();
  }
  
}

use class Dz:MediaIOTest(Assert) {
  
  testCamUpdate() {
  
    Ui app = Ui.new();
    app.configManager.delete("cam.paths");
    app.configManager.delete("cam./dev/video0.label");
    app.configManager.delete("cam./dev/video1.label");
    MediaIO mio = app.modules["MediaIO"];
    mio.updateCams();
    assertEqual(app.configManager.get("cam.paths"), "/dev/video0,/dev/video1");
    assertEqual(app.configManager.get("cam./dev/video0.label"), "video0");
    
    mio.updateCams();
    assertEqual(app.configManager.get("cam.paths"), "/dev/video0,/dev/video1");
    assertEqual(app.configManager.get("cam./dev/video1.label"), "video1");
    
  }
  
  main() {
    "Begin MediaIOTest".print();
    testCamUpdate();
    "End MediaIOTest".print();
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

