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

use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
use class KRouter:RouterPlugin(HubPlugin) {

   new() self {
     fields {
      //App:Background bfw = App:Background.new();
      //App:Background bup = App:Background.new();
      String profile = "router";
     }
     super.new();
     
   }
   
   nameGet() String {
       String name =@ "KRouter";
       return(name);
     }
   
   runBackgroundTasks() {
      //bfw.runMyTasks();
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
   
   handleCmd(Parameters params) Bool {
      String mode = params.getFirst("bridgeCmd");
      if (TS.isEmpty(mode)) {
        return(super.handleCmd(params));
      }
      return(true);
    }
   
   start() {
      super.start();
      
      //bfw.startDelay = Time:Interval.new(20, 0);
      //bfw.repeatDelay = Time:Interval.new(1200, 0);
      //bfw.minimumDelay = Time:Interval.new(600, 0);
      //bfw.toInvoke = getInvocation("doForward", List.new());
      
      //bup.startDelay = Time:Interval.new(30, 0);
      //bup.repeatDelay = Time:Interval.new(86400, 0);
      //bup.minimumDelay = Time:Interval.new(43200, 0);
      //bup.toInvoke = getInvocation("checkUpgrade", List.new());
      
      if (runBackground) {
        //bfw.start();
        //bup.start();
      }
   }

   updateActionLinks(String actionLinks, Account a, Map arg, request) String {
      super.updateActionLinks(actionLinks, a, arg, request);
      return(actionLinks);
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
      res["doCam"] = "true";
    } else {
      res["doCam"] = "true";
    }
    return(res);
   }
   
   profileGet() String {
    return(profile);
  }
  
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
