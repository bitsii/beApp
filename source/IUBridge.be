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
use System:Parameters;

use App:Alert;
use App:AppStart;

use Net:UPnP as Upnp;

use App:LocalWebApp;
use App:RemoteWebApp;
use App:WebApp;
use IUHub:HubPlugin;

emit(jv) {
"""
//import java.io.*;
import java.net.*;
"""
}
use class IUBridge:BridgeStart {

   new() self {
      fields {
          IO:Log log =@ IO:Logs.get(self);
        }
    }
    
}

use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
use class IUBridge:BridgePlugin(HubPlugin) {

   new() self {
     fields {
      Ssh ssh;
      Set rforwarded;
      App:Background bfw = App:Background.new();
      //App:Background bup = App:Background.new();
      String profile = "bridge";
     }
     super.new();
     
   }
   
   runBackgroundTasks() {
      bfw.runMyTasks();
      //bup.runMyTasks();
   }
   
   checkUpgrade() {
    log.log("in checkupgrade");
    String autoUp = app.configManager.get("hub.autoUpgrade");
    unless (TS.isEmpty(autoUp) || autoUp == "true") {
      log.log("autoUpgrade disabled");
      return(null);
    }
    Web:Client client = Web:Client.new();
    client.url = "https://bitbucket.org/ioturl/ioturl/downloads/latestVersion.json";
    String res = client.openInput().readString();
    log.log("in checkupgrade response is " + res);
    client.close();
    if (TS.notEmpty(res)) {
      Map resMap = Json:Unmarshaller.unmarshall(res);
      String ver = resMap.get("latestVersion");
      log.log("latestVersion is " + ver);
      if (ver == app.plugin.version) {
        log.log("already on latest version");
      } else {
        log.log("need to upgrade");
        String latestUrl = resMap.get("latestUrl");
        log.log("latest url is " + latestUrl);
        Path dld = app.paths.dataPath.addStep("Downloads");
        if (dld.file.exists!) {
          dld.file.makeDirs();
        }
        dld = dld.addStep("IUBHub.zip");
        if (dld.file.exists) {
          dld.file.delete();
        }
        client = Web:Client.new();
        client.url = latestUrl;
        auto prd = client.openInput();
        IO:Writer pwr = dld.file.writer.open();
        prd.copyData(pwr);
        pwr.close();
        client.close();
        Bool doUpgrade = true;
        ifEmit(iuDebug) {
          doUpgrade = false;
        }
        if (doUpgrade) {
          log.log("doing upgrade to " + ver);
          app.plugin.upgrade(dld.toString());
        } else {
          log.log("not upgrading, is debug");
        }
      }
    }
   }
   
   start() {
      super.start();
      
      bfw.startDelay = Time:Interval.new(20, 0);
      bfw.repeatDelay = Time:Interval.new(1200, 0);
      bfw.minimumDelay = Time:Interval.new(600, 0);
      bfw.toInvoke = getInvocation("doForward", List.new());
      
      //bup.startDelay = Time:Interval.new(30, 0);
      //bup.repeatDelay = Time:Interval.new(86400, 0);
      //bup.minimumDelay = Time:Interval.new(43200, 0);
      //bup.toInvoke = getInvocation("checkUpgrade", List.new());
      
      if (runBackground) {
        bfw.start();
        //bup.start();
      }
   }

   updateActionLinks(String actionLinks, Account a, Map arg, request) String {
      super.updateActionLinks(actionLinks, a, arg, request);
      return(actionLinks);
   }
   
   imapSettingsRequest(Map arg, request) {
     Map res = super.imapSettingsRequest(arg, request);
     System:Thread.new(app.plugin.getInvocation("updateNetAddresses", List.new())).start();
     return(res);
   }
   
   loggedIn(Account a, Map res, Map arg, request) Map {
    res = super.loggedIn(a, res, arg, request);
    String dnso = app.configManager.get("deviceNameSetOnce");
    if (TS.isEmpty(dnso) || dnso != "true") {
      //res["deviceNameSetOnce"] = "false";
    }
    String anso = app.configManager.get("accountSetOnce");
    if (TS.isEmpty(anso) || anso != "true") {
      //res["accountSetOnce"] = "false";
    }
    String dc = app.configManager.get("doCam");
    if (TS.isEmpty(dc) || dc != "true") {
      res["doCam"] = "false";
    } else {
      res["doCam"] = "true";
    }
    return(res);
   }
   
   profileGet() String {
    return(profile);
  }
    
    
    doForward() {
      try {
        wcl.lock();
        doForwardInner();
        wcl.unlock();
      } catch(any e) {
        wcl.unlock();
      }
    }
    
     doForwardInner() {
      log.log("wc forwarding ports");
      log.log("getting wc");
      loadWc();
      WebConnect wc = app.plugin.wcol.o;
      if (def(wc)) {
        log.log("wc from wcol");
      } else {
        log.log("new wc");
        wc = WebConnect.new();
        app.plugin.wcol.o = wc;
        oapp.plugin.wcol.o = wc;
        wc.extraPorts = app.configManager.get("upnp.extraPorts");
      }
      String sshHost = app.configManager.get("il.sshHost");
      String sshLogin = app.configManager.get("il.sshLogin");
      String sshPass = app.configManager.get("il.sshPass");
      try {
        if (TS.notEmpty(sshHost) && TS.notEmpty(sshLogin) && TS.notEmpty(sshPass)) {
          wc.hostedAddress = sshHost;
          if (undef(ssh) || ssh.isClosed) {
            log.log("ssh connecting " + sshHost + " " + sshLogin);
            ssh = Ssh.new(sshHost, sshLogin, sshPass);
            ssh.open();
            rforwarded = Set.new();
          } else {
            ssh.sendKeepAlive();
          }
        }
      } catch (any sshe) {
        log.log("Error during ssh op " + sshe);
        try {
           ssh.close();
           ssh = null;
         } catch (sshe) {
           ssh = null;
         }
      }
      wc.updateExternal();
      forwardPorts(wc, ssh, rforwarded);
      log.log("updating addresses");
      app.plugin.updateNetAddresses();
      app.plugin.updateUrls();
      log.log("saving");
      app.configManager.put("hub.webConnect", Json:Marshaller.marshall(wc.toMap()));
      log.log("upnp doForward done");
  }
  
  
  forwardPorts(WebConnect wc, Net:Ssh ssh, Set rforwarded) {
      if (TS.notEmpty(wc.externalAddress)) {
        log.log("Forwarding");
        Int fwdSecs = 7200;//fwd upnp for how long
        Upnp upnp = Upnp.new();
        upnp.netGw = upnp.gatewayAddress;
        upnp.forwardPort(fwdSecs, Int.new(wc.externalPort), Int.new(wc.internalPort));
        if (TS.notEmpty(wc.extraPorts)) {
          for (String ep in wc.extraPorts.split(",")) {
            String currPortS = wc.extraPortMap.get(ep);
            if (TS.isEmpty(currPortS)) {
              currPortS = wc.getAPort();
              wc.extraPortMap.put(ep, currPortS);
            }
            log.log("Forwarding extraport external " + currPortS + " to " + ep);
            upnp.forwardPort(fwdSecs, Int.new(currPortS), Int.new(ep));
          }
        }
        if (def(ssh) && def(wc.hostedAddress)) {
          if (rforwarded.has(wc.externalPort)!) {
            ssh.forwardPortR(Int.new(wc.externalPort), "127.0.0.1", Int.new(wc.internalPort));
          }
          rforwarded += wc.externalPort;
          if (TS.notEmpty(wc.extraPorts)) {
            for (ep in wc.extraPorts.split(",")) {
              currPortS = wc.extraPortMap.get(ep);
              if (TS.notEmpty(currPortS)) {
                if (rforwarded.has(currPortS)!) {
                  ssh.forwardPortR(Int.new(currPortS), "127.0.0.1", Int.new(ep));
                }
                rforwarded += currPortS;
              }
            }
          }
        }
      }
    }
     
   
}

emit(jv) {
"""
import com.jcraft.jsch.*;
"""
}
local use Net:Ssh {

  emit(jv) {
  """
  JSch bevi_jsch;
  Session bevi_session;
  """
  }
  
  new() self {
    fields {
    }
  }
  
  new(String _host, String _user, String _pass) this {
    fields {
      String host = _host;
      String user = _user;
      String pass = _pass; 
    }
  }
  
  forwardPortR(Int rport, String host, Int lport) this {
    emit(jv) {
    """
    bevi_session.setPortForwardingR(beva_rport.bevi_int, beva_host.bems_toJvString(), beva_lport.bevi_int);
    """
    }
  }
  
  isClosedGet() Bool {
    Bool fval =@ false;
    emit(jv) {
    """
    if (bevi_session != null && bevi_session.isConnected()) {
      return bevl_fval;
    }
    """
    }
    return(true);
  }
  
  open() this {
    emit(jv) {
    """
    bevi_jsch = new JSch();
    bevi_session = bevi_jsch.getSession(bevp_user.bems_toJvString(), bevp_host.bems_toJvString(), 22);
    bevi_session.setPassword(bevp_pass.bems_toJvString());
    bevi_session.setConfig("StrictHostKeyChecking", "no");
    bevi_session.connect();
    """
    }
  }
  
  close() this {
    emit(jv) {
    """
    bevi_session.disconnect();
    bevi_session = null;
    bevi_jsch = null;
    """
    }
  }
  
  sendKeepAlive() this {
    emit(jv) {
    """
    bevi_session.sendKeepAliveMsg();
    """
    }
  }

}

use Net:Ssh:Forward {

  new() self {
    fields {
      Int inPort;
      String host;
      Int outPort;
    }
  }
  
  new(Int _inPort, String _host, Int _outPort) {
    inPort = _inPort;
    host = _host;
    outPort = _outPort;
  }
  
}


use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
