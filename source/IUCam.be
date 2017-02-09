// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use IO:File:Path;
use IO:File;
use System:Random;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;

use App:Alert;
use App:CallBackUI;

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
      any app;
      IO:Log log =@ IO:Logs.get(self);
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
    log.log("in mocams clean");
    String cps = app.configManager.get("cam.cleanDays");
    if (TS.notEmpty(cps)) {
      Int dz = Int.new(cps);
      if (dz > 0) {
        String cmd = app.paths.appPath.copy().addStep("camclean.sh").toString();
        cmd += " " + cps;
        if (System:CurrentPlatform.name != "mswin") {
          log.log("running clean cmd " + cmd);
          Com.run(cmd);
        }
      }
    } else {
      //set sensible default
      app.configManager.put("cam.cleanDays", "7");
    }
  }
  
  doUpdate() {
    //log.log("in mocams update");
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
    for (String cp in mocams) {
      log.log(cp + " is a mocam not setup yet");
      Path p = Path.apNew(cp);
      String mcn = p.steps.last;
      log.log("mocam name " + mcn);
      Path confp = Path.apNew(app.paths.dataPath.toString() + "/WebCamConfig/MOCAM-" + mcn + ".conf");
      if (confp.file.exists!) {
        log.log("no conf, creating " + confp);
        Path.apNew(app.paths.appPath.toString() + "/MOCAM.conf").file.copyFile(confp.file);
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
      String toRun = app.paths.appPath.copy().addStep("motionrun.sh").toString();
      toRun += " " + confp;
      log.log("motion torun " + toRun);
      if (runit) {
        Com.run(toRun);
      }
      configuredMocams.put(cp);
    }
  }
  
  getMocams() {
    //log.log("Doing getmocams");
    mocams = Set.new();
    String cps = app.configManager.get("cam.paths");
    if (TS.notEmpty(cps)) {
      for (String cp in cps.split(",")) {
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
      any app;
      IO:Log log =@ IO:Logs.get(self);
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
    //log.log("Running tasks");
    runMyTasks();
    mu.updateOnInterval();
  }
  
  main() {
    any e;
    while (true) {
      try {
        runTasks();
      } catch (e) {
        log.log("Caught exception running tasks " + e);
      }
      try {          
        Time:Sleep.sleepMilliseconds(sleepTime);
      } catch (e) {
        log.log("Caught exception sleeping " + e);
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
    mu.init();
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

use App:AuthenticatedLocalApp;
use App:AuthenticatedWebApp;
use App:AuthenticatedApp as AuthedApp;

use class IUCam:CamStart {

   new() self {
      fields {
          IO:Log log =@ IO:Logs.get(self);
        }
    }

  main() {
      main(System:Process.new().args);
    }
    
    main(List args) {
      outerMain(System:Process.new().args);
      /*try {
        app.configManager.close();
      } catch (any e) {
        log.log("Exception closing db in CmdUI, error is " + e);
      }*/
    }
    
    outerMain(List args) {
      try {
        innerMain(System:Process.new().args);
      } catch (any e) {
        log.log("Exception in CmdUI, error is " + e);
      }
    }
    
    innerMain(List args) {

      Web:Client:CertificateManager.validateHosts = false;

      if (args.length > 0) {
        String mode = args[0]; //ui, svc, both, [absent]
        log.log("mode " + mode);
      } else {
        log.log("mode empty");
      }
      if (TS.isEmpty(mode)) {
        mode = "wui";
      }
      if (mode == "lui" || mode == "wui" || mode == "cmd") {
        log.log("making cam");
        CamPlugin cam = CamPlugin.new();
        if (mode == "cmd") {
          cam.runBackground = false;
        }
        log.log("adding plugins");
        List plugins = List.new();
        plugins += cam;
        plugins += App:AuthPlugin.new();
        plugins += App:ConfigPlugin.new();
        plugins += App:FileManagerPlugin.new();
        if (mode == "lui") {
          //AuthenticatedLocalApp.new(plugins).main();
        }
        if (mode == "wui") {
          //AuthenticatedWebApp.new(plugins).main();
        }        
        if (mode == "cmd") {
          cmdMain(args, plugins);
        }
      }
    }

    cmdMain(List args, plugins) {
      AuthedApp ui = AuthedApp.new();
      
      if (args.length > 1) {
        String mode = args[1]; //ui, svc, both, [absent]
        log.log("cmd " + mode);
      } 
      if (TS.isEmpty(mode)) {
        log.log("cmd empty");
      }
      if (mode == "help") {
        log.log("Help");
        log.log("listLogins, putAccount, getAccount, setPermsString, setPass, deleteAccount, updateConfig, showConfig, createConfig, deleteConfig");
      }
      if (TS.notEmpty(mode) && mode == "portForward") {
        Net:PortForward pf = Net:PortForward.new(args[2], Int.new(args[3]), args[4], Int.new(args[5]));
        pf.start();
      }
      if (TS.notEmpty(mode) && mode == "listLogins") {
        for (String login in ui.accountManager.getLogins()) {
          log.log("Account login " + login);
        }
      }
      if (TS.notEmpty(mode) && (mode == "putAccount" || mode == "createAccount")) {
        String user = args[2];
        String pass = args[3];
        log.log("Putting Account " + user);
        Account ac = Account.new();
        ac.user = user;
        ac.pass = pass;
        if (args.length > 4) {
          ac.permsString = args[4];
        }
        ui.accountManager.putAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "getAccount") {
        user = args[2];
        log.log("Get Account " + user);
        ac = ui.accountManager.getAccount(user);
        log.log("Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPermsString") {
        user = args[2];
        String ps = args[3];
        log.log("Set Perms " + user);
        ac = ui.accountManager.getAccount(user);
        ac.permsString = ps;
        ui.accountManager.putAccount(ac);
        log.log("Account " + ac);
      }
      if (TS.notEmpty(mode) && mode == "setPass") {
        user = args[2];
        pass = args[3];
        log.log("Set Pass " + user);
        ac = ui.accountManager.getAccount(user);
        ac.pass = pass;
        ui.accountManager.putAccount(ac);
      }
      if (TS.notEmpty(mode) && mode == "deleteAccount") {
        user = args[2];
        log.log("Deleting Account " + user);
        ac = ui.accountManager.getAccount(user);
        if (def(ac)) {
          ui.accountManager.deleteAccount(ac);
          log.log("Deleted account " + user);
        } else {
          log.log("No such account for deletion " + user);
        }
      }
      if (TS.notEmpty(mode) && mode == "updateConfig") {
        String key = args[2];
        String value = args[3];
        log.log("Updating config " + key + " " + value);
        ui.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "showConfig") {
        for (any kv in ui.configManager.getMap()) {
          log.log("Config name " + kv.key + " value " + kv.value);
        }
      }
      if (TS.notEmpty(mode) && mode == "createConfig") {
        key = args[2];
        value = args[3];
        log.log("Creating config " + key + " " + value);
        ui.configManager.put(key, value);
      }
      if (TS.notEmpty(mode) && mode == "deleteConfig") {
        key = args[2];
        log.log("Deleting config " + key);
        ui.configManager.delete(key);
      }
      ui.configManager.close();
    }

}

use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
use class IUCam:CamPlugin {

     new() self {
       fields {
          IO:Log log =@ IO:Logs.get(self);
          any app;
          String name = "IUCam";
          String homePage = "/App/IUCam/IUCam.html";
          Background bg = Background.new();
          Bool runBackground = true;
        }
     }
     
    start() {
      bg.app = app;
      if (runBackground) {
      bg.startBackground();
      }
    }
    
    deviceNameGet() String {
    fields {
      String deviceName;
    }
    if (TS.isEmpty(deviceName)) {
      deviceName = app.configManager.get("deviceName");
      if (TS.isEmpty(deviceName)) {
        deviceName = "Device-" + System:Random.getString(4);
        app.configManager.put("deviceName", deviceName);
      }
    }
    return(deviceName);
  }
  
  deviceNameSet(String _deviceName) {
    if (TS.notEmpty(_deviceName)) {
      deviceName = _deviceName;
      app.configManager.put("deviceName", deviceName);
    }
  }
  
  deviceIdGet() String {
    fields {
      String deviceId;
    }
    if (TS.isEmpty(deviceId)) {
      deviceId = app.configManager.get("deviceId");
      if (TS.isEmpty(deviceId)) {
        deviceId = System:Random.getString(16);
        app.configManager.put("deviceId", deviceId);
      }
    }
    return(deviceId);
  }
  
  loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["actionLinks"] = getActionLinks(a, arg, request);
      res["appVersion"] = self.version;
      res["deviceName"] = self.deviceName;
      return(res);
    }
    
    versionGet() String {
      fields {
        String version =@ "5.6.8";
      }
      return(version);
    }
    
    checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js"))) {
        return(true);
      }
      return(false);
   }
   
   okForPageToken(request) Bool {
     if (request.embedded) {
       return(true);
     }
     String ref = request.getInputHeader("referer");
     if (TS.isEmpty(ref)) {
      return(false);
     }
     Int pos = 0;
     for (Int i = 0;i < 3;i++=) {
       pos = ref.find("/", pos + 1);
     }
     ref = ref.substring(pos);
     log.log("okForPageToken " + ref);
     if (ref == "/App/IUHub/IUHub.html" || ref == "/App/IUHub/IUCam.html") {
      return(true);
     }
     return(false);
   }
   
    toggleMotionRequest(Map arg, request) {
      Account a = app.accountManager.getAccountForRequest(request);
      if (app.requestFromAdmin(request)) {
        String cam = arg["cam"];
        String mcp = app.configManager.get("cam." + cam + ".motion");
        if (TS.notEmpty(mcp) && Bool.new(mcp)) {
          app.configManager.put("cam." + cam + ".motion", "false");
        } else {
          app.configManager.put("cam." + cam + ".motion", "true")
        }
        Map res = Map.new();
        res["action"] = "updateResponse";
        res["actionLinks"] = getActionLinks(a, arg, request);
        bg.mu.doUpdate();
        return(res);
      }
      return(null);
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
        log.log("count def " + c);
        count = Int.new(c);
      } else {
        log.log("count undef");
        Int count = 0;
        app.configManager.put(countKey, count.toString());
      }
      String rv = app.configManager.get("cam." + cam + ".label");
      if (undef(rv)) {
        rv = System:Random.getString(6);
      } else {
        rv = rv.toAlphaNum();
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
        String piccmd = app.paths.appPath.copy().addStep("uppic.bat").toStringWithSeparator("\\");
      } else {
        piccmd = app.paths.appPath.copy().addStep("uppic.sh").toStringWithSeparator("/");
      }
      log.log("pic path " + picFile.path);
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
      log.log("In load image");
      Map res = Map.new();
      res["action"] = "updateImageResponse";
      //res["imghtm"] = "<img src=\"" + picFile.path.toStringWithSeparator("/") + "\" >";
      res["imghtm"] = "<img src=\"../../" + picFile.path.toStringWithSeparator("/") + "?pageToken=" + request.getSession("pageToken") + "&cbust=" + Time:Interval.now().seconds + System:Random.getString(6) + "\" >";
      return(res);
   }
   
   detectCamsRequest(Map arg, request) {
      unless (app.requestFromAdmin(request)) {
        log.log("Account not admin, not detecting cams");
        return(null);
      }
      app.configManager.put("camsDetectedOnce", "true");
      Account a = app.accountManager.getAccountForRequest(request);
      updateCams();
      Map res = Map.new();
      res["action"] = "updateResponse";
      res["actionLinks"] = getActionLinks(a, arg, request);
      return(res);
   }
   
   updateCams() {
      Path appP = app.paths.appPath;
      log.log("app path " + appP);
      if (System:CurrentPlatform.name == "mswin") {
        //String gccmd = "App\\IUCam\\getcams.bat";
        appP = appP.copy().addStep("getcams.bat");
        String gccmd = appP.toStringWithSeparator("\\");
      } else {
        //gccmd = "App/IUCam/getcams.sh";
        appP = appP.copy().addStep("getcams.sh");
        gccmd = appP.toStringWithSeparator("/");
      }
      String res = System:Command.new(gccmd).open().output.readStringClose();
      log.log("res from cmd " + res);
      if (TS.notEmpty(res)) {
        //res.swap("\r", "\n");
        String cres = String.new();
        for (String v in res.split("\n")) {
          log.log("v is " + v);
          if (TS.notEmpty(v)) {
            if (v.ends("\r")) {
              log.log("ends r");
              v = v.substring(0, v.size - 1);
              log.log("now |" + v + "|");
            }
            if (TS.notEmpty(cres)) {
              log.log("cres v is " + cres);
              cres += ",";
              log.log("cres v v is " + cres);
            }
            cres += v;
            log.log("v v v cres is " + cres);
          }
        }
        log.log("commares " + cres);
        updateCams(cres);
      }
   }
   
   getCams() Set {
      Set ecm = Set.new();
      String ecps = app.configManager.get("cam.paths");
      if (def(ecps)) {
        for (String cp in ecps.split(",")) {
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
   
   getActionLinks(Account a, Map arg, request) String {
     Bool showMotion = app.requestFromAdmin(request);
     String actionLinks = String.new();
     String moLinks = String.new();
     Set ecm = getCams();
     for (String c in ecm) {
       if (camOkForAccount(c, a)) {
          String clabel = app.configManager.get("cam." + c + ".label");
          if (TS.isEmpty(clabel)) {
            clabel = Path.apNew(c).steps.last;
            app.configManager.put("cam." + c + ".label", clabel);
          }
          actionLinks += "<p><a href=\"#\" onclick=\"ui.bem_updateImage_1(new be_BEC_2_4_6_TextString().bems_new('" + c + "'));return false;\"><img style=\"margin-top:0px; margin-bottom:0px;margin-left:0px;margin-right:0px;\" src=\"applets-screenshooter.svg\" alt=\"Take Picture\"/>Take Picture with " + clabel + "</a></p>";
          if (showMotion) {
            String mcp = app.configManager.get("cam." + c + ".motion");
            if (TS.notEmpty(mcp) && Bool.new(mcp)) {
             String endis = "Disable";
            } else {
              endis = "Enable";
            }
            moLinks += "<p><a href=\"#\" onclick=\"ui.bem_toggleMotion_1(new be_BEC_2_4_6_TextString().bems_new('" + c + "'));return false;\">" += endis += " motion for " + clabel + "</a></p>";
            moLinks += "<p><label class=\"luiForm\">Rename Cam " += clabel += "</label><input type=\"text\" id=\"camRename" += c += "\" value=\"" += clabel += "\"></input> <a id=\"camRenameLink\" href=\"#\" onclick=\"callApp('renameCamRequest', document.getElementById('camRename" += c += "').value, '" += c += "');return false;\" >Save New Cam Name</a> <a id=\"camRenameCancel\" href=\"#\" onclick=\"callUI('reloadResponse');return false;\" >Cancel</a></p>";
          }
        }
     }
     String showCam = app.configManager.get("PLUGIN.hub");
     if (showMotion) {
      actionLinks += "<div id=\"camSettingsDiv\" style=\"display: none;\">"
      actionLinks += moLinks;
      actionLinks += "<p><a id=\"detectCamsId\" href=\"#\" onclick=\"ui.bem_detectCams_0();return false;\" >Detect WebCams</a></p>";
      String cps = app.configManager.get("cam.cleanDays");
      if (TS.isEmpty(cps)) {
        cps = "7";
      }
      actionLinks += "<p><label class=\"luiForm\">Days before Deleting Cam Pics</label><input type=\"text\" id=\"camCleanDays\" value=\"" += cps += "\"></input> (-1 to disable) <a id=\"setCamCleanId\" href=\"#\" onclick=\"callApp('setCamCleanRequest', document.getElementById('camCleanDays').value);return false;\" >Save Cam Delete Days</a></p>";
      actionLinks += "</div>";
     }
     return(actionLinks);
   }
   
   renameCamRequest(String toName, String c, request) Map {
     if (app.requestFromAdmin(request)) {
        app.configManager.put("cam." + c + ".label", toName);
      }
      return(CallBackUI.reloadResponse());
   }
   
   setCamCleanRequest(String days, request) {
      if (app.requestFromAdmin(request)) {
        Int.new(days);//make sure its int
        app.configManager.put("cam.cleanDays", days);
      }
   }

}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

