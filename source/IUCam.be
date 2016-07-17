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
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;

use App:Alert;

use class IUCam:Lui(Ui) {

  new() self {
        fields {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
        }
        super.new();
        bg.startBackground(); //normally on
    }

    main() {
      webr = WeBr.new();
      webr.webHandler = self;
      webr.height = 450;
      webr.width = 320;
      
      String mypwd = System:Environment.getVariable("MYPWD");
      webr.location = "file:///" + mypwd + "/App/IUCam/IUCam.html";
      
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
use class IUCam:Wui(Ui) {

  emit(jv) {
  """
  static { Security.addProvider(new BouncyCastleProvider());  }
  """
  }

  new() self {
        fields {
        }
        super.new();
        bg.startBackground(); //normally on
    }
    
    startWeb() {
      var e;
      String ports = self.internalPort;
      Int port = Int.new(ports);
      String cerPath = assureCert(port);
      //portL.o = port;
      
      Web:Server vw = Web:Server.new(self.sessionManager);
      
      //vwL.o = vw;
      vw.port = port;
      vw.ssl = true;
      vw.sslPath = cerPath;
      vw.app = self;
      //vw.gzipOutput = true;//security issues
      fields {
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
  
  handleStartWeb() {
    log.log(lvl, "In handleStartWeb!!");
  }
  
  assureCertJv(Int port) String {
    emit(jv) {
    """
    java.security.cert.Certificate cert;
    """
    }
    Path cerPath = Path.apNew("Data/IUCam/cert");
    String cerPathS = cerPath.toString();
    log.log(lvl, "cerPath " + cerPathS);
    if (cerPath.file.exists) {
      log.log(lvl, "cer exist");
      emit(jv) {
      """
      KeyStore privateKS = KeyStore.getInstance("JKS");
      privateKS.load( new FileInputStream(bevl_cerPathS.bems_toJvString()), "kp".toCharArray());
      cert = privateKS.getCertificate("jetty");
      """
      }
    } else {
      log.log(lvl, "cer not exist");
      log.log(lvl, "Start gencert");
      if (cerPath.parent.file.exists!) {
        cerPath.parent.file.makeDirs();
      }
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
      cert = privateKS.getCertificate("jetty");
      """
      }
      log.log(lvl, "End gencert");
    }
    emit(jv) {
    """
    bevp_certificateThumbprint = new BEC_4_6_TextString(
                 BEC_3_6_18_WebClientCertificateManager.bevs_inst.bems_getThumbprint(((X509Certificate) cert))
              );
    """
    }
    fields {
      String certificateThumbprint;
    }
    log.log(lvl, "certificateThumbprint " + certificateThumbprint);
    return(cerPathS);
  }
  
    main() {
      Array args = System:Process.new().args;

      startWeb();
   }

   initWeb() {

   }
   
   checkWritePath(Path p, request) Bool {
    Account a = self.accountManager.getAccountForRequest(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    String accountName = request.getSession("account.name");
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
   
   checkReadPath(Path p, request) Bool {
    Account a = self.accountManager.getAccountForRequest(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    String accountName = request.getSession("account.name");
    var e;
    Bool isOk = false;
    if (undef(accountName)) { accountName = ""; }
    try {
      Path pa = p.file.absPath;
      Path adz = Path.apNew("App/IUCam").file.absPath;
      if (TS.notEmpty(accountName)) {
        Path h = Path.apNew("Home/" + accountName).file.absPath;
      }
      String pas = pa.toString();
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js"))) {
        isOk = true;
      } elif (def(h) && pas.begins(h.toString())) {
        isOk = true;
      } elif (a.perms.has("allcam") && pas.begins(Path.apNew("Shared/WebCam").file.absPath.toString())) {
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
     unless (checkRequest(request)) {
      return(null);
     }
     String accountName = request.getSession("account.name");
     String rmtd = request.inputMethod;
     //log.log(lvl, "rmtd is " + rmtd);
     if (TS.isEmpty(rmtd) || rmtd != "PUT") {
        Map arg = request.scriptArg;
     }
     if (TS.isEmpty(accountName)) {
       String ln = request.getParameter("accountName");
       String lp = request.getParameter("accountPass");
       if (TS.notEmpty(ln) && TS.notEmpty(lp)) {
          log.log(lvl, "doing svc login");
          Account a = self.accountManager.getAccount(ln);
          if (def(a) && preLoginCheck(request)) {
            log.log(lvl, "Found account " + ln);
            if (a.checkPass(lp)) {
              log.log(lvl, "svc login ok");
              request.putSession("account.name", ln);
              request.putSession("ip", request.remoteAddress);
              goodLogin(request);
              accountName = ln;
            } else {
              badLogin(request);
            }
          } else {
            badLogin(request);
          }
        }
     }
     if (undef(arg)) {
       String uri = request.uri;
       log.log(lvl, "uri " + uri);
       File imgfile = File.apNew(Encode:Url.decode(uri.substring(1)));
       if (TS.notEmpty(rmtd) && rmtd == "PUT") {
         if (checkWritePath(imgfile.path, request)) {
           log.log(lvl, "put for " + imgfile.path);
           if (imgfile.path.parent.file.exists!) {
            imgfile.path.parent.file.makeDirs();
           }
           if (imgfile.exists) { imgfile.delete(); }
            outw = imgfile.writer.open();
            inr = request.openInput();
            inr.copyData(outw);
            request.closeInputReader();
            outw.close();
            request.outputContent = "UPLOAD COMPLETE";
         }
       } elif (checkReadPath(imgfile.path, request)) {
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
          IO:Writer outw = request.openOutput();
          IO:Reader inr = imgfile.reader.open();
          inr.copyData(outw);
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


emit(jv) {
"""
//import java.io.*;
//import java.net.*;
"""
}

use class IUCam:MotionUpdate {

  new() self {
  
    fields {
      Set mocams = Set.new();
      Set configuredMocams = Set.new();
      var app;
      Int lvl;
      IO:Log log;
      Int lastPoll = 0;
      Int pollSecs = 10800;
      Int lastClean = 0;
      Int cleanSecs = 10800;
    }
  
  }
  
  updateOnInterval() {
    Int currSec = Time:Interval.now().seconds;
    if (currSec - lastPoll > pollSecs) {
      lastPoll = currSec;
      doUpdate();
    }
    if (currSec - lastClean > cleanSecs) {
      lastClean = currSec;
      doClean();
    }
  }
  
  doClean() {
    log.log(lvl, "in mocams clean");
    String cps = app.configManager.get("cam.cleanDays");
    if (TS.notEmpty(cps)) {
      Int dz = Int.new(cps);
      if (dz > 0) {
        String cmd = "App/IUCam/camclean.sh " + cps;
        log.log(lvl, "running clean cmd " + cmd);
        Com.run(cmd);
      }
    }
  }
  
  doUpdate() {
    //log.log(lvl, "in mocams update");
    getMocams();
    configureMocams();
  }
  
  configureMocams() {
    //stop all motion
    if (System:CurrentPlatform.name == "mswin") {
      Bool runit = false;
    } else {
      runit = true;
    }
    if (runit) {
      Com.run("killall motion");
      Sleep.sleepSeconds(3);
      Com.run("killall -9 motion");
    }
    configuredMocams = Set.new();
    //make sure configs present
    foreach (String cp in mocams) {
      log.log(lvl, cp + " is a mocam not setup yet");
      Path p = Path.apNew(cp);
      String mcn = p.steps.last;
      log.log(lvl, "mocam name " + mcn);
      Path confp = Path.apNew("Data/IUCam/WebCamConfig/MOCAM-" + mcn + ".conf");
      if (confp.file.exists!) {
        log.log(lvl, "no conf, creating " + confp);
        Path.apNew("App/IUCam/MOCAM.conf").file.copyFile(confp.file);
        IO:File:Writer cw = confp.file.writer.openAppend();
        cw.write("videodevice " + cp + "\n");
        cw.write("target_dir Shared/WebCam\n");
        Int intPorti = System:Random.getInt(Int.new(), 6000);
        intPorti += 9001;
        String currPortS = intPorti.toString();
        app.configManager.put("cam." + cp + ".motionPort", currPortS);
        cw.write("webcontrol_port " + currPortS + "\n");
        cw.write("picture_filename PICDIR_%Y-%m-%d_%H/PIC-mo-" + mcn + "-%Y-%m-%d_%H:%M:%S\n");
        //cw.write("picture_filename PIC-mo-" + mcn + "-%Y-%m-%d_%H:%M\n");
      }
      //start it in background
      String toRun = "App/IUCam/motionrun.sh " + confp;
      log.log(lvl, "motion torun " + toRun);
      if (runit) {
        Com.run(toRun);
      }
      configuredMocams.put(cp);
    }
  }
  
  getMocams() {
    //log.log(lvl, "Doing getmocams");
    mocams = Set.new();
    String cps = app.configManager.get("cam.paths");
    if (TS.notEmpty(cps)) {
      foreach (String cp in cps.split(",")) {
        String mcp = app.configManager.get("cam." + cp + ".motion");
        if (TS.notEmpty(mcp) && Bool.new(mcp)) {
          mocams.put(cp);
        }
      }
    }
  }
  
  init() {
    getMocams();
  }

}

use class IUCam:Background {

  new() self {
    fields {
      var app;
      Int lvl;
      IO:Log log;
      MotionUpdate mu = MotionUpdate.new();
    }
  }
  
  runMyTasks() {
    fields {
      Int lastTrackClear;
      Int clearSeconds =@ 7200;
    }
    if (def(lastTrackClear)) {
      Int ns = Time:Interval.now().seconds;
      if (ns - lastTrackClear > clearSeconds) {
        app.trackingManager.clear();
        lastTrackClear = ns;
      }
    } else {
      lastTrackClear = 0;
    }
  }
  
  runTasks() {
    //log.log(lvl, "Running tasks");
    runMyTasks();
    mu.updateOnInterval();
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
    fields {
      System:Thread myThread;
      Int sleepTime = 500;
    }
    String bkdis = app.configManager.get("bk.disable");
    if (TS.notEmpty(bkdis) && Bool.new(bkdis)) {
      return(self);
    }
    Int _sleepTime = app.configManager.get("bk.sleepTime");
    if (def(_sleepTime) && _sleepTime > 0) {
      sleepTime = _sleepTime;
    }
    mu.app = app;
    mu.lvl = lvl;
    mu.log = log;
    mu.init();
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

use System:Thread:ObjectLocker as OLocker;
use class IUCam:Ui {

  new() self {
      fields {
        IO:Log log = IO:Log.new();
        log.level = log.info;
        Int lvl = log.level;
        Lock lock = Lock.new();
        Background bg = Background.new();
        OLocker links = OLocker.new();
        OLocker lastLoginBad = OLocker.new(false);
        HHandler requestHandler;
      }
      
      requestHandler = HHandler.new();
      requestHandler.log = log;
      requestHandler.lvl = lvl;
      requestHandler.app = self;
      
      bg.log = log;
      bg.lvl = lvl;
      bg.app = self;
      //bg.startBackground();
      
  }
  
  badRequest(request) {
  
  }
  
  checkRequest(request) Bool {
  
    Int maxBad =@ 40;
    Int clearSecs =@ 40;
    Int updateSecs =@ 20;
  
  /*
    Int maxBad =@ 5;
    Int clearSecs =@ 10;
    Int updateSecs =@ 5;
  */
    
    String ip = request.remoteAddress;
    String sip = request.getSession("ip");
    String accountName = request.getSession("account.name");
    if (TS.notEmpty(ip) && TS.notEmpty(sip) && TS.notEmpty(accountName)) {
      if (ip == sip) {
        return(true);
      }
    }
  
    Int ns = Time:Interval.now().seconds;
    
    if (TS.notEmpty(ip)) {
      String ct = self.trackingManager.get("IP." + ip);
      if (TS.notEmpty(ct)) {
        String ltm = self.trackingManager.get("LB." + ip);
        if (TS.notEmpty(ltm)) {
          Int ltmi = Int.new(ltm);
          if (ns - ltmi > clearSecs) {
            log.log(lvl, "clear bad " + ip);
            badcount = 0;
          } else {
            badcount = Int.new(ct);
          }
        } else {
          Int badcount = Int.new(ct);
        }
      } else {
        badcount = 0;
      }
    }
    if (badcount > maxBad) {
      log.log(lvl, "toomany bad " + ip);
      if (def(ltmi) && ns - ltmi > updateSecs) {
        log.log(lvl, "lp update");
        self.trackingManager.put("LB." + ip, ns.toString());
      } else {
        log.log(lvl, "no update");
      }
      return(false);
    }
    if (TS.isEmpty(accountName)) {
      log.log(lvl, "upping bad");
      badcount++=;
      self.trackingManager.put("IP." + ip, badcount.toString());
      self.trackingManager.put("LB." + ip, ns.toString());
    } else {
      self.trackingManager.delete("IP." + ip);
      self.trackingManager.delete("LB." + ip);
      //self.trackingManager.clear();
    }
    return(true);
  }
  
  requestFromAdmin(request) Bool {
    Account a = self.accountManager.getAccountForRequest(request);
    if (def(a) && a.perms.has("admin")) {
      return(true);
    }
    badRequest(request);
    return(false);
  }
  
  preLoginCheck(request) Bool {
    if (lastLoginBad.o) {
      Int slptime = System:Random.getInt(Int.new(), 500);
      Time:Sleep.sleepMilliseconds(slptime);
    }
    return(true);
  }
  
  goodLogin(request) {
    lastLoginBad.o = false;
  }
  
  badLogin(request) {
    badRequest(request);
    lastLoginBad.o = true;
  }
  
  deviceNameGet() String {
    fields {
      String deviceName;
    }
    if (TS.isEmpty(deviceName)) {
      deviceName = self.configManager.get("deviceName");
      if (TS.isEmpty(deviceName)) {
        deviceName = "Device-" + System:Random.getString(4);
        self.configManager.put("deviceName", deviceName);
      }
    }
    return(deviceName);
  }
  
  deviceIdGet() String {
    fields {
      String deviceId;
    }
    if (TS.isEmpty(deviceId)) {
      deviceId = self.configManager.get("deviceId");
      if (TS.isEmpty(deviceId)) {
        deviceId = System:Random.getString(16);
        self.configManager.put("deviceId", deviceId);
      }
    }
    return(deviceId);
  }
  
  internalPortGet() String {
      fields {
        String intPort;
      }
      if (TS.isEmpty(intPort)) {
        intPort = self.configManager.get("wui.port");
        if (TS.isEmpty(intPort)) {
          Int intPorti = System:Random.getInt(Int.new(), 6000);
          intPorti += 3000;
          intPort = intPorti.toString();
          self.configManager.put("wui.port", intPort);
        }
      }
      return(intPort);
    }
    
    externalPortGet() String {
      fields {
        String extPort;
      }
      if (TS.isEmpty(extPort)) {
        extPort = self.configManager.get("wui.extPort");
        if (TS.isEmpty(extPort)) {
          Int extPorti = System:Random.getInt(Int.new(), 6000);
          extPorti += 3000;
          extPort = extPorti.toString();
          self.configManager.put("wui.extPort", extPort);
        }
      }
      return(extPort);
    }
  
  pathsGet() App:Paths {
    fields {
      App:Paths paths;
    }
    if (undef(paths)) {
      paths = App:Paths.new();
    }
    return(paths);
  }
  
  configManagerGet() CLocker {
    fields {
      CLocker configManager;
    }
    if (undef(configManager)) {
      Path db = self.paths.dataPath.addStep("IUCam").addStep("CONFDB");
      //KvDb configManagerKv = KvDb.new(Derby.pathNew(db), "CONFIG");
      KvDb configManagerKv = KvDb.new(HsDb.pathNew(db), "CONFIG");
      configManagerKv.createOpen();
      configManager = CLocker.new(configManagerKv);
    }
    return(configManager);
  }
  
  sessionManagerGet() Web:SessionManager {
    fields {
      Web:SessionManager sessionDb;
    }
    if (undef(sessionDb)) {
      Path db = self.paths.dataPath.addStep("IUCam").addStep("SESSDB");
      //KvDb sessionDbKv = KvDb.new(Derby.pathNew(db), "SESSIONS");
      KvDb sessionDbKv = KvDb.new(HsDb.pathNew(db), "SESSIONS");
      sessionDbKv.createOpen();
      sessionDb = Web:SessionManager.new(CLocker.new(sessionDbKv), "GsSess" + self.deviceId);
    }
    ("got sessionmanager").print();
    return(sessionDb);
  }
  
  getSessionsForAccount(Account a) String {
    //a.user
    String res = String.new();
    String accountName = a.user;
    Map all = self.sessionManager.sessions.getMap();
    foreach (var kv in all) {
      if (kv.key.ends("account.name") && kv.value == accountName) {
        log.log(lvl, "Found session " + kv.key);
        var kp = kv.key.split(".");
        String sessLabel = String.new();
        String name = self.sessionManager.sessions.get(kp.first + ".session.name");
        if (def(name)) {
          log.log(lvl, "sess name " + name);
          sessLabel += "Session named " += name;
        }
        String ip = self.sessionManager.sessions.get(kp.first + ".ip");
        if (def(ip)) {
          log.log(lvl, "sess ip " + ip);
          if (TS.notEmpty(sessLabel)) {
            sessLabel += " from ";
          } else {
            sessLabel += "Session from "
          }
          sessLabel += "IP Address " + ip;
        }
        if (TS.notEmpty(sessLabel)) {
          res += "<p>" += sessLabel += " <a href=\"#\" onclick=\"endSession('"
          += kp.first += "');return false;\">End Session (Log it out)</a></p>";
        }
      }
    }
    return(res);
  }
  
  trackingManagerGet() CLocker {
    fields {
      CLocker trackingManager;
    }
    if (undef(trackingManager)) {
      Path db = self.paths.dataPath.addStep("IUCam").addStep("TMDB");
      KvDb trackingManagerKv = KvDb.new(HsDb.pathNew(db), "TRACKING");
      trackingManagerKv.createOpen();
      trackingManager = CLocker.new(trackingManagerKv);
    }
    return(trackingManager);
  }
  
  

  handleWeb(request, Map arg) {
    unless (checkRequest(request)) {
      return(null);
     }
        try {
            String aname = arg.get("action");
            if (undef(aname) || aname.ends("Request")!) {
              throw(Exception.new("Invalid request"));
            }
            String accountName = request.getSession("account.name");
            if (TS.isEmpty(accountName)) {
              unless (aname == "loginRequest") {
                return(null);
              }
            }
            log.log(lvl, "here");
            Array args = Array.new(2);
            args[0] = arg;
            args[1] = request;
            if (requestHandler.can(aname, args.length)) {
              var res = requestHandler.invoke(aname, args);
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
      fields {
        AccountManager am;
      }
      if (undef(am)) {
        am = AccountManager.new(self.configManager, "ACCOUNTS.");
      }
      return(am);
    }
    
    assureVers() {
      fields {
        Int majorVer = 5@;
        Int minorVer = 0@;
      }
    }
    
    majorVerGet() Int {
      assureVers();
      return(majorVer);
    }
    
    minorVerGet() Int {
      assureVers();
      return(minorVer);
    
    }
    
    loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["camLinks"] = requestHandler.camLinksForAccount(a);
      res["appVersion"] = self.majorVer.toString() + "." + self.minorVer.toString();
      res["deviceName"] = self.deviceName;
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
      if (mode == "cmd") {
        CmdUi.new().main(args);
      }
   }

}

use class IUCam:CmdUi(Ui) {

  new() self {
        fields {
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
        log.log(lvl, "listLogins, putAccount, getAccount, setPermsString, setPass, deleteAccount, updateConfig, showConfig, createConfig, deleteConfig");
      }
      if (TS.notEmpty(mode) && mode == "portForward") {
        Net:PortForward pf = Net:PortForward.new(args[2], Int.new(args[3]), args[4], Int.new(args[5]));
        pf.log = log;
        pf.lvl = lvl;
        pf.start();
      }
      if (TS.notEmpty(mode) && mode == "listLogins") {
        foreach (String login in self.accountManager.getLogins()) {
          log.log(lvl, "Account login " + login);
        }
      }
      if (TS.notEmpty(mode) && (mode == "putAccount" || mode == "createAccount")) {
        String user = args[2];
        String pass = args[3];
        log.log(lvl, "Putting Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        if (args.length > 4) {
          ac.permsString = args[4];
        }
        self.accountManager.putAccount(ac);
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
        self.accountManager.putAccount(ac);
        log.log(lvl, "Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPass") {
        user = args[2];
        pass = args[3];
        log.log(lvl, "Set Pass " + user);
        ac = self.accountManager.getAccount(user);
        ac.pass = pass;
        self.accountManager.putAccount(ac);
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
        self.configManager.put(key, value);
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
        self.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "deleteConfig") {
        key = args[2];
        log.log(lvl, "Deleting config " + key);
        self.configManager.delete(key);
      }
    }
}

use Crypto:Symmetric as Crypt;
use class IUCam:HHandler {

     new() self {
       fields {
          IO:Log log;
          Int lvl;
          var app;
        }
     }
     
  tryThingRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        app.updateNetAddresses();
     }
     return(null);
   }
   
   restartRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Restarting as requested, will have exit code 3 by login " + app.accountManager.getAccountForRequest(request).user);
        System:Process.exit(3);
     }
     return(null);
   }
   
   clearAllSessionsRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Clearing all sessions request by login " + app.accountManager.getAccountForRequest(request).user);
        app.sessionManager.sessions.clear();
     }
     return(null);
   }
   
   clearAllTrackingRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log(lvl, "Clearing all tracking requested by login "  + app.accountManager.getAccountForRequest(request).user);
        app.trackingManager.clear();
     }
     return(null);
   }
   
   endSessionRequest(Map arg, request) Map {
     if (TS.notEmpty(arg["sessionKey"])) {
      app.sessionManager.deleteSessionByKey(arg["sessionKey"]);
     }
     return(showSessionsRequest(arg, request));
   }

     updateImageRequest(Map arg, request) {
      //Path pp = app.getHomeDir(request).addStep("WebCam");
      Path pp = Path.apNew("Shared/WebCam");
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
        app.configManager.put(countKey, count.toString());
      }
      String rv = app.configManager.get("cam." + cam + ".label");
      if (undef(rv)) {
        rv = System:Random.getString(6);
      }
      String myhn = System:Environment.getVariable("MYHN");
      String picBaseName = "Pic-" + myhn + "-" + rv + "-";
      Int tries = 5;
      String maxPicsS = app.configManager.get("cam." + cam + ".maxPics");
      if (TS.notEmpty(maxPicsS)) {
        maxPics = Int.new(maxPicsS);
      } else {
        Int maxPics = 4;
      }
      Bool updatedCount = false;
      while (tries > 0 && updatedCount!) {
        count = Int.new(app.configManager.get(countKey));
        tries--=;
        Int nxcount = count++;
        if (nxcount > maxPics) {
          nxcount = 0;
        }
        updatedCount = app.configManager.testAndPut(countKey, count.toString(), nxcount.toString());
      }
      if (tries <= 0) {
        throw(System:Exception.new("Unable to get a count option"));
      }
      String mcp = app.configManager.get("cam." + cam + ".motion");
      if (TS.notEmpty(mcp) && Bool.new(mcp)) {
        Bool isMo = true;
      } else {
        isMo = false;
      }
      if (isMo) {
        picName = "lastsnap.jpg";
      } else {
        String picName = picBaseName + count + ".jpg";
      }
      File picFile = pp.copy().addStep(picName).file;
      picFile.delete();
      if (System:CurrentPlatform.name == "mswin") {
        String piccmd = "App\\IUCam\\uppic.bat";
      } else {
        piccmd = "App/IUCam/uppic.sh";
      }
      log.log(lvl, "pic path " + picFile.path);
      //curl http://127.0.0.1:10994/0/action/snapshot
      if (isMo) {
        mcp = app.configManager.get("cam." + cam + ".motionPort");
        Web:Client client = Web:Client.new();
        client.url = "http://127.0.0.1:" + mcp + "/0/action/snapshot";
        String received = client.openInput().readString();
        client.close();
      } else {
        System:Command.new(piccmd + " " + cam + " " + picFile.path).run();
      }
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
   
   changePassRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      unless (TS.notEmpty(arg["newPass"]) && a.checkPass(arg["oldPass"])) {
        log.log(lvl, "incorrect old pass");
        throw(Alert.new("Old password incorrect"));
      }
      a.pass = arg["newPass"];
      app.accountManager.putAccount(a);
   }
   
   loadAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (def(a)) {
        Map res = Map.new();
        res["action"] = "loadAccountResponse";
        res["accountName"] = a.user;
        res["admin"] = a.perms.has("admin");
        res["allcam"] = a.perms.has("allcam");
        return(res);
      } elif (true) {
        throw(Alert.new("No such account"));
      }
      return(null);
   }
   
   showAccountAdminRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      String accountLinks = String.new();
      Array logins = app.accountManager.getLogins();
      foreach (String login in logins) {
        accountLinks += "<p><a href=\"#\" onclick=\"loadAccountRequest('" += login += "');return false;\">Modify " += login += "</a></p>";
      }
      Map res = Map.new();
      res["action"] = "showAccountAdminResponse";
      res["accountLinks"] = accountLinks;
      return(res);
   }
   
   deleteAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (def(a)) {
        if (a.user == app.accountManager.getAccountForRequest(request).user) {
          throw(Alert.new("Cannot delete own account"));
        }
      }
      app.accountManager.deleteAccount(a);
      return(showAccountAdminRequest(arg, request));
  }
      
   
   saveAccountRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      Account a = app.accountManager.getAccount(arg["accountName"]);
      if (undef(a)) {
        log.log(lvl, arg["accountName"] + " not found, creating new");
        a = Account.new();
        a.user = arg["accountName"];
      } else {
        if (a.user == app.accountManager.getAccountForRequest(request).user) {
          throw(Alert.new("Cannot change own account"));
        }
        log.log(lvl, arg["accountName"] + " found, use existing");
      }
      if (TS.notEmpty(arg["accountPass"])) {
        log.log(lvl, "pass set, changing");
        a.pass = arg["accountPass"];
      }
      if (arg["admin"]) {
        a.perms.put("admin");
      } else {
        a.perms.delete("admin");
      }
      if (arg["allcam"]) {
        a.perms.put("allcam");
      } else {
        a.perms.delete("allcam");
      }
      app.accountManager.putAccount(a);
   }
   
   imapSettingsRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        throw(Alert.new("Must be administrator"));
      }
      app.configManager.put("imap.user", arg["imapAccount"]);
      app.configManager.put("imap.endpoint", arg["imapEndpoint"]);
      app.configManager.put("imap.pass", arg["imapPass"]);
      Map res = Map.new();
      res["action"] = "hideImapResponse";
      return(res);
   }
   
   showSessionsRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      Map res = Map.new();
      res["action"] = "showSessionsResponse";
      res["sessionsList"] = app.getSessionsForAccount(a);
      return(res);
   }
   
   detectCamsRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        log.log(lvl, "Account not admin, not detecting cams");
        return(null);
      }
      Account a = app.accountManager.getAccountForRequest(request);
      updateCams();
      Map res = Map.new();
      res["action"] = "updateResponse";
      res["camLinks"] = app.requestHandler.camLinksForAccount(a);
      return(res);
   }
   
   localBrowseRequest(Map arg, request) Map {
     log.log(lvl, "in local browse req");
     String accountName = request.getSession("account.name");
     if (TS.isEmpty(accountName)) {
      throw(Alert.new("must be authenticated"));
     }
      Encode:Hex hex = Encode:Hex.new();
      Encode:Url urle = Encode:Url.new();
      Encode:Html htmle = Encode:Html.new();
      Map ret = Map.new();
      String path = arg["path"];
      Account a = app.accountManager.getAccountForRequest(request);
      Bool adminLinks = false;
      Bool camLinks = false;
      if (a.perms.has("admin")) {
        adminLinks = true;
      } elif (a.perms.has("allcam")) {
        camLinks = true;
      }
      if (TS.isEmpty(path)) {
        dirFile = app.getHomeDir(request).file;
        if (dirFile.exists!) {
          dirFile.makeDirs();
        }
      } else {
        File dirFile = File.apNew(hex.decode(path));
      }
      String dirListHtml = String.new();
      dirListHtml += "<input type=\"hidden\" id=\"browsingDirId\" value=\"" += hex.encode(dirFile.path.toString()) += "\"/>";
      if (dirFile.exists && app.checkReadPath(dirFile.path, request)) {
        dirListHtml += "<p>Listing for " += htmle.encode(dirFile.path.toString()) += "</p>";
        dirListHtml += "<table>";
        if (adminLinks || camLinks) {
          dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode("Shared/WebCam") += "');return false;\">WEBCAM</a></td></tr>";
        }
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(dirFile.path.toString()) += "');return false;\">.  (REFRESH)</a></td></tr>";
        IO:File:Path parent = dirFile.path.parent;
        if (def(parent) && TS.notEmpty(parent.toString())) {
        dirListHtml += "<tr><td>DIR</td><td><a href=\"#\" onclick=\"localBrowseRequest('"
          += hex.encode(parent.toString()) += "');return false;\">.. (UP)</a></td></tr>";
        }
        if (dirFile.isDir) {
          var dit = dirFile.iterator;
          dit.open();
          Array olist = Array.new();
          Map omap = Map.new();
          while (dit.hasNext) {
            File entry = dit.next;
            Path p = entry.path;
            olist += p.steps.last;
            omap.put(p.steps.last, entry);
          }
          olist = olist.sort();
          foreach (String ole in olist) {
            entry = omap.get(ole);
            p = entry.path;
            if (entry.isDirectory) {
              dirListHtml += "<tr>";
              dirListHtml += "<td>DIR</td><td><a href=" + TS.quote + "#" + TS.quote + " onclick=\"localBrowseRequest('"
          += hex.encode(p.toString()) += "');return false;\">" += htmle.encode(p.name) += "</a></td>";
              dirListHtml += "</tr>";   
            } else {
              if (p.toString().ends(".jpg")) {
                String jscall = " onclick=\"localBrowseRequest('" += hex.encode(p.toString()) += "');return false;\"";
              } else {
                jscall = "";
              }
              dirListHtml += "<tr>";
              dirListHtml += "<td>FILE</td><td><a href=" += TS.quote += "../../" += urle.encode(p.toString()) += TS.quote + jscall + ">" += htmle.encode(p.name) += "</a></td><td>" += entry.size += "</td>";
              dirListHtml += "</tr>";
            }
          }
          dit.close();
        } elif (dirFile.path.toString().ends(".jpg")) {
          Map res = Map.new();
          res["action"] = "updateImageResponse";
          res["imghtm"] = "<img src=\"../../" + dirFile.path.toStringWithSeparator("/") + "?cbust=" + Time:Interval.now().seconds + System:Random.getString(6) + "\" >";
          return(res);
        }
        dirListHtml += "</table>";
      }
      ret.put("action", "localBrowseResponse");
      ret.put("dirListHtml", dirListHtml);
      return(ret);
    }
   
   updateCams() {
      if (System:CurrentPlatform.name == "mswin") {
        String gccmd = "App\\IUCam\\getcams.bat";
      } else {
        gccmd = "App/IUCam/getcams.sh";
      }
      String res = System:Command.new(gccmd).open().output.readStringClose();
      log.log(lvl, "res from cmd " + res);
      if (TS.notEmpty(res)) {
        //res.swap("\r", "\n");
        String cres = String.new();
        foreach (String v in res.split("\n")) {
          log.log(lvl, "v is " + v);
          if (TS.notEmpty(v)) {
            if (v.ends("\r")) {
              log.log(lvl, "ends r");
              v = v.substring(0, v.size - 1);
              log.log(lvl, "now |" + v + "|");
            }
            if (TS.notEmpty(cres)) {
              log.log(lvl, "cres v is " + cres);
              cres += ",";
              log.log(lvl, "cres v v is " + cres);
            }
            cres += v;
            log.log(lvl, "v v v cres is " + cres);
          }
        }
        log.log(lvl, "commares " + cres);
        updateCams(cres);
      }
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
      app.configManager.delete("cam.paths");
      app.configManager.put("cam.paths", dcs);
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
          if (TS.isEmpty(clabel)) {
            clabel = Path.apNew(c).steps.last;
            app.configManager.put("cam." + c + ".label", clabel);
          }
          camLinks += "<p><a href=\"#\" onclick=\"eui.bem_updateImage_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new('" + c + "'));return false;\">Take Picture with " + clabel + "</a></p>";
        }
     }
     return(camLinks);
   }
   
   showConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
       String conf = String.new();
       Map ecm = app.configManager.getMap();
       if (ecm.isEmpty!) {
         conf += "<table>";
         foreach (var kv in ecm) {
           unless(kv.value.has("\"")) {
              String ckey = "configKey" + kv.key;
              conf += "<tr><td>" + kv.key + "</td><td><input type=\"text\" id=\"" + ckey + "\" value=\"" + kv.value + "\"></td><td><a href=\"#\" onclick=\"eui.bem_deleteConfig_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new('" + kv.key + "'));return false;\">Delete</a></td><td><a href=\"#\" onclick=\"updateConfig('" + kv.key + "', '" + ckey + "');return false;\">Save</a></td></tr>";
            }
         }
      }
      conf += "<tr><td>Add New:&nbsp;<input type=\"text\" id=\"addConfigKeyId\" value=\"\"></td><td><a href=\"#\" onclick=\"eui.bem_addConfig_0();return false;\">+</a><input type=\"hidden\" id=\"addConfigValId\" value=\"\"></td></tr>";
      conf += "</table>";
       Map res = Map.new();
      res["action"] = "showConfigResponse";
      res["configs"] = conf;
      return(res);
    }
    return(null);
   }
   
   updateConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
      log.log(lvl, "update for " + arg["configKey"] + " value " + arg["configValue"]);
      app.configManager.put(arg["configKey"], arg["configValue"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
   }
   
   deleteConfigRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
      log.log(lvl, "delete for " + arg["configKey"]);
      app.configManager.delete(arg["configKey"]);
      return(showConfigRequest(arg, request));
      }
      return(null);
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
    Account a = app.accountManager.getAccount(arg["accountName"]);
    if (def(a) && app.preLoginCheck(request)) {
      log.log(lvl, "Found account " + arg["accountName"]);
      if (a.checkPass(arg["accountPass"])) {
        log.log(lvl, "Login ok");
        request.putSession("account.name", arg["accountName"]);
        request.putSession("ip", request.remoteAddress);
        if (TS.notEmpty(arg["sessionName"])) {
          request.putSession("session.name", arg["sessionName"]);
        }
        Map res = Map.new();
        res["action"] = "loggedInResponse";
        res["name"] = arg["accountName"];
        app.goodLogin(request);
        return(app.loggedIn(a, res, arg, request));
      } else {
        log.log(lvl, "Login notok");
        app.badLogin(request);
      }
    } else {
      log.log(lvl, "No such account " + arg["accountName"]);
      app.badLogin(request);
    }
    return(logoutRequest(arg, request));
  }
  
  logoutRequest(Map arg, request) {
    //log.log(lvl, "logging out");
    request.deleteSession();
    Map res = Map.new();
    res["action"] = "logoutResponse";
    //log.log(lvl, "logged out, returning");
    return(res);
  }


}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

use class IUCam:ConfigTest(Assert) {
  
  testConfig() {
    Ui ui = Ui.new();
    KvDb cm = ui.configManager.container;
    cm.delete("test.blarg");
    assertNull(cm.get("test.blarg"));
    cm.insert("test.blarg", "test");
    assertEqual(cm.get("test.blarg"), "test");
    cm.update("test.blarg", "foo");
    assertEqual(cm.get("test.blarg"), "foo");
    assertFalse(cm.testAndPut("test.blarg", "test", "la"));
    assertNotEqual(cm.get("test.blarg"), "la");
    assertTrue(cm.testAndPut("test.blarg", "foo", "la"));
    assertEqual(cm.get("test.blarg"), "la");
  }
  
  main() {
    "Begin ConfigTest".print();
    testConfig();
    "End ConfigTest".print();
  }
  
}

use class IUCam:HHandlerTest(Assert) {
  
  testCamUpdate() {
  
    Ui app = Ui.new();
    app.configManager.delete("cam.paths");
    app.configManager.delete("cam./dev/video0.label");
    app.configManager.delete("cam./dev/video1.label");
    HHandler mio = app.requestHandler;
    mio.updateCams();
    assertEqual(app.configManager.get("cam.paths"), "/dev/video0,/dev/video1");
    assertEqual(app.configManager.get("cam./dev/video0.label"), "video0");
    
    mio.updateCams();
    assertEqual(app.configManager.get("cam.paths"), "/dev/video0,/dev/video1");
    assertEqual(app.configManager.get("cam./dev/video1.label"), "video1");
    
  }
  
  main() {
    "Begin HHandlerTest".print();
    //testCamUpdate();
    "End HHandlerTest".print();
  }
  
}


use class IUCam:AccountTest(Assert) {
  
  testAccounts() {
    Ui ui = Ui.new();
    Account atest = Account.new();
    atest.user = "test";
    atest.pass = "pass";
    AccountManager am = ui.accountManager;
    am.deleteAccount(atest);
    Account a = am.getAccount(atest.user);
    assertNull(a);
    am.putAccount(atest);
    a = am.getAccount(atest.user);
    assertNotNull(a);
    assertFalse(a.perms.has("admin"));
    assertTrue(a.checkPass("pass"));
    assertFalse(a.checkPass("notpass"));
    a.pass = "yo";
    assertTrue(a.checkPass("yo"));
    a.perms.put("admin");
    am.putAccount(a);
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

