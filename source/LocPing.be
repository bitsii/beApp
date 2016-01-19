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
use Db:KeyValue as KvDb;
use Db:HSQLDb:Database as HsDb;

use App:Alert;

use class MP:Hello {

     new() self {
       properties {
          IO:Log log;
          Int lvl;
          var app;
        }
     }

     sayHelloRequest(Map arg, request) {
      "in say hello".print();
      log.log(lvl, "In say hello");
      Map res = Map.new();
      res["action"] = "sayHelloResponse";
      res["msg"] = "hello 1 " + System:Random.getString(3);
      return(res);
   }

}

use class MP:Configure {

     new() self {
       properties {
          IO:Log log;
          Int lvl;
          var app;
        }
     }

     saveRequest(Map arg, request) {
      log.log(lvl, "In save");
      String locRcvUrl = arg["locRcvUrl"];
      if (undef(locRcvUrl)) {
        locRcvUrl = "";
      }
      app.configManager.put("locRcvUrl", locRcvUrl);
    }
   
     loadRequest(Map arg, request) {
      log.log(lvl, "In load");
      String locRcvUrl = app.configManager.get("locRcvUrl");
      if (undef(locRcvUrl)) {
        locRcvUrl = "";
      }
      Map res = Map.new();
      res["action"] = "loadResponse";
      res["locRcvUrl"] = locRcvUrl;
      return(res);
    }

}

use class App:LocPing {
    
       
   new() self {
        properties {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
          IO:Log log = IO:Log.new();
          log.level = log.info;
          Int lvl = log.level;
          Map modules = Map.new();
        }
        
        Hello h = Hello.new();
        h.log = log;
        h.lvl = lvl;
        h.app = self;
        modules["Hello"] = h;
        
        Configure c = Configure.new();
        c.log = log;
        c.lvl = lvl;
        c.app = self;
        modules["Configure"] = c;
        
    }
    
    configManagerGet() KvDb {
      vars {
        KvDb configManager;
      }
      if (undef(configManager)) {
        Path db = self.paths.dataPath.addStep("LocPing").addStep("DDZDB");
        //configManager = KvDb.new(Derby.pathNew(db), "CONFIG");
        configManager = KvDb.new(HsDb.pathNew(db), "CONFIG");
        configManager.createOpen();
      }
      return(configManager);
    }

    main() {
      webr = WeBr.new();
      webr.webHandler = self;
      webr.height = 450;
      webr.width = 320;
      
      String mypwd = System:Environment.getVariable("MYPWD");
      ifNotEmit(platDroid) {
        webr.location = "file:///" + mypwd + "/App/LocPing/LocPing.html";
      }
      ifEmit(platDroid) {
        webr.location = "file:///android_asset/App/LocPing/LocPing.html";
      }
      
      webr.setup();
   }

   initWeb() {

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

   handleWeb(request) {
     
     Map arg = request.scriptArg;
     return(handleWeb(request, arg));
   }

  handleWeb(request, Map arg) {
        try {
            String mname = arg.get("module");
            String aname = arg.get("action");
            if (undef(aname) || aname.ends("Request")! || undef(mname) || modules.has(mname)!) {
              throw(Exception.new("Invalid request"));
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

}
