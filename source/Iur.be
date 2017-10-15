// Copyright 2015 Craig Welch
// All rights reserved

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
use Container:Pair;

use App:Alert;

use App:AuthenticatedWebApp;
use App:AuthenticatedApp as AuthedApp;
use Text:String;
use App:CallBackUI;

use System:Thread:Lock;
use System:Thread:ObjectLocker as OLocker;

use Crypto:Symmetric as Crypt;
emit(jv) {
"""
import java.util.Properties;
"""
}

use class Iur:AGSStart {

   new() self {
      fields {
          IO:Log log =@ IO:Logs.get(self);
          Bool ownBackground = true;
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
    
    getPlugins(Bool bkg) List {
      AGSPlugin hub = AGSPlugin.new();
      hub.runBackground = bkg;
      log.log("adding plugins");
      List plugins = List.new();
      plugins += hub;
      plugins += App:AuthPlugin.new();
      return(plugins);
    }
    
    innerMain(List args) {
      ifEmit(iuDebug) {
        IO:Logs.turnOnAll();
      }
      //Web:Client:CertificateManager.validateHosts = false;
      if (args.length > 0) {
        String mode = args[0]; //lui, wui, both, [absent]
        log.log("mode " + mode);
      } else {
        log.log("mode empty");
      }
      
      if (TS.isEmpty(mode)) {
        mode = "wui";
      }
      log.log("making nopa");
      if (mode == "wui") {
        AuthenticatedWebApp wuiapp = AuthenticatedWebApp.new();
        wuiapp.plugins = getPlugins(ownBackground);
      }
      if (def(wuiapp)) {
        log.log("starting wui");
        wuiapp.main();
      }
      if (mode == "cmd") {
        log.log("running cmd");
        AuthedApp aapp = AuthedApp.new();
        aapp.plugins = getPlugins(false);
        aapp.cmdMain(args);
      }
      
    }   
}

use class Iur:AGSPlugin {

     new() self {
       fields {
          IO:Log log =@ IO:Logs.get(self);
          any app;
          String name = "Iur";
          String homePage = "/App/Iur/Iur.html";
          Bool runBackground = true;
          Lock wcl = Lock.new();
        }
     }
     
     appSet(_app) {
      app = _app;
     }
     
     clearTracking() {
      log.log("clearing tracking");
      app.trackingManager.clear();
     }
     
     start() {
      if (Logic:Bools.fromString(app.configManager.get("logs.turnOnAll"))) {
        IO:Logs.turnOnAll();
      }
      log.log("in hubplugin start");
    }
  
  profileGet() String {
    return("ags");
  }
  
  loggedIn(Account a, Map res, Map arg, request) {
      res["action"] = "updateResponse";
      res["profile"] = self.profile;
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["appVersion"] = self.version;
      res["loginUri"] = self.getLoginUri(request);
      res["flyers"] = getFlyers(request);
      return(res);
    }
    
    getFlyers(request) {
      Account a = app.accountManager.getAccountForRequest(request);
      auto unmar = Json:Unmarshaller.new();
      String flyers = "";
      if (def(a)) {
        Map flsmap = self.flyerManager.getMap("USID|" + a.user + "|");
        for (any fle in flsmap.nodes) {
          Map flmap = unmar.unmarshall(fle.value);
          flyers += "<p> id " += flmap["id"] += " url " +=flmap["url"] += "</p>";
        }
      }
      return(flyers);
    }
    
    versionGet() String {
      fields {
        String version =@ "0.0.1";
      }
      return(version);
    }
   
   restartRequest(Map arg, request) Map {
     if (app.requestFromAdmin(request)) {
        log.log("Restarting as requested, will have exit code 3 by login " + app.accountManager.getAccountForRequest(request).user);
        System:Process.exit(3);
     }
     return(null);
   }
   
   checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js") || pas.ends(".svg") || pas.ends(".txt"))) {
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
     if (ref.has("?") && ref.has("&")! && ref.has("?onceToken=")) {
      ref = ref.substring(0, ref.find("?"));
     }
     log.log("okForPageToken second " + ref);
     if (ref == "/App/Iur/Iur.html") {
      return(true);
     }
     return(false);
   }
   
   getLoginUri(request) String {
     String loginBookmark = "/App/Iur/Iur.html";
     return(loginBookmark);
   }
   
   aboutRequest(request) Map {
     String about = "<p>Flyertogo<p>";
     return(CallBackUI.setElementsInnerHTMLResponse(Maps.from("aboutDivMsg", about)))
   }
   
   flyerManagerGet() CLocker {
    fields {
      CLocker flyerManager;
    }
    if (undef(flyerManager)) {
      Path db;
      KvDb flyerManagerKv;
      db = app.paths.dataPath.addStep("FLYERDB");
      flyerManagerKv = KvDb.apNew(db, "FLYERS");
      flyerManagerKv.createOpen();
      flyerManager = CLocker.new(flyerManagerKv);
    }
    return(flyerManager);
  }
  
  addFlyerRequest(String flyerUrl, request) Map {
    Account a = app.accountManager.getAccountForRequest(request);
    if (undef(a)) { return(CallBackUI.toLoginResponse()); }
    log.log("adding flyer request " + a.user + " " + flyerUrl);
    while (undef(flid)) {
      String id = System:Random.getString(3 + System:Random.getIntMax(2)).lowerValue();
      String flid = "ID|" += id;
      if (def(self.flyerManager.get(flid))) {
        flid = null;
      }
    }
    log.log("flyer is " + flid);
    String fmd = Json:Marshaller.marshall(Maps.from("id", id, "url", flyerUrl, "user", a.user));
    self.flyerManager.put(flid, fmd);
    self.flyerManager.put("USID|" += a.user += "|" += id, fmd); 
    return(CallBackUI.flyersResponse(getFlyers(request)));;
  }
   
}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;
