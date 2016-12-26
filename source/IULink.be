// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Container:Queue;
use IO:File:Path;
use IO:File;
use System:Random;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use Db:Derby:Database as Derby;
use System:Thread:Lock;
use System:Thread:ContainerLocker as CLocker;
use System:Command as Com;
use Time:Sleep;

use Container:Map:MapNode as MNode;

use App:Alert;

emit(jv) {
"""
//import java.io.*;
//import java.net.*;
"""
}

use class IULink:Background {

  new(LinkPlugin _link) self {
    fields {
      any app;
      IO:Log log = IO:Logs.get(self);
      LinkPlugin link = _link;
    }
  }
  
  runMyTasks() {
    fields {
      Int lastLinkUpdate;
      Int linkUpdateSeconds =@ 300;
    }
    if (def(lastLinkUpdate)) {
      Int ns = Time:Interval.now().seconds;
      if (ns - lastLinkUpdate > linkUpdateSeconds) {
        //do it to it
        link.updateUrls();
        lastLinkUpdate = ns;
      }
    } else {
      lastLinkUpdate = 0;
    }
  }
  
  runTasks() {
    //log.log("Running tasks");
    runMyTasks();
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
      Int sleepTime = 60;
    }
    String bkdis = app.configManager.get("LINK.bk.disable");
    if (TS.notEmpty(bkdis) && Bool.new(bkdis)) {
      return(self);
    }
    Int _sleepTime = app.configManager.get("LINK.bk.sleepTime");
    if (def(_sleepTime) && _sleepTime > 0) {
      sleepTime = _sleepTime;
    }
    myThread = System:Thread.new(self);
    myThread.start();
  }

}

use App:AuthenticatedLocalApp;
use App:AuthenticatedApp as AuthedApp;

use class IULink:LinkStart {

   new() self {
      fields {
          IO:Log log = IO:Logs.get(self);
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
        mode = "lui";
      }
      if (mode == "lui" || mode == "cmd") {
        log.log("making cam");
        LinkPlugin link = LinkPlugin.new();
        if (mode == "cmd") {
          link.runBackground = false;
        }
        log.log("adding plugins");
        List plugins = List.new();
        plugins += link;
        plugins += App:AuthPlugin.new();
        plugins += App:ConfigPlugin.new();
        //plugins += App:FileManagerPlugin.new();
        if (mode == "lui") {
          AuthenticatedLocalApp.new(plugins).main();
        }      
        if (mode == "cmd") {
          cmdMain(args, plugins);
        }
      }
    }

    cmdMain(List args, plugins) {
      AuthedApp ui = AuthedApp.new(plugins);
      
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
emit(jv) {
"""
import java.util.Properties;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.Folder;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.InternetAddress;
import javax.mail.Transport;
import javax.mail.Message;
import javax.mail.Address;
import javax.mail.Flags.Flag;
"""
}
use class IULink:LinkPlugin {

     new() self {
       fields {
          IO:Log log = IO:Logs.get(self);
          any app;
          String name = "IULink";
          String homePage = "/App/IULink/IULink.html";
          Background bg = Background.new(self);
          Bool runBackground = true;
          OLocker urls = OLocker.new();
        }
     }
     
    start() {
      if (runBackground) {
      bg.app = app;
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
      Map ures = urlsRequest(arg, request);
      res["urlsHtml"] = ures["urlsHtml"];
      res["action"] = "updateResponse";
      res["justLoggedIn"] = true;
      res["permsString"] = a.permsString;
      res["actionLinks"] = getActionLinks(a, arg, request);
      res["appVersion"] = self.majorVer.toString() + "." + self.minorVer.toString();
      res["deviceName"] = self.deviceName;
      log.log("sending updateResponse from loggedIn");
      return(res);
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
    
    checkPublicReadPath(Path pa, request) Bool {
      String pas = pa.toString();
      Path adz = Path.apNew("App/" + self.name).file.absPath;
      if (pas.begins(adz.toString()) && (pas.ends(".html") || pas.ends(".js"))) {
        return(true);
      }
      return(false);
   }
  
   getActionLinks(Account a, Map arg, request) String {
     String actionLinks = String.new();
     
     String showCam = app.configManager.get("PLUGIN.hub");
     if (TS.notEmpty(showCam) && showCam == "enabled") {
       actionLinks += "<p><a href=\"IUHub.html\">Go to IUHub</a></p>";
     }
     return(actionLinks);
   }
   
   fakeUrls() {
    log.log("fakeUrls");
    Map furls = Map.new();
    Map furl = Map.new();
    furl.put("deviceId", "did");
    furl.put("deviceName", "dname");
    furl.put("gw", "10.10.10.10");
    String intUrl = "https://127.0.0.1:5000/App/IUHub/IUHub.html";
    String extUrl = "https://10.10.10.10:5000/App/IUHub/IUHub.html";
    String intLink = "<a href=\"" + intUrl + "\">dname did internal Link, use on same network as the device is on.</a>";
    String extLink = "<a href=\"" + extUrl + "\">dname did external Link, use from the internet or outside the network the device is on.</a>";
    furl.put("intLink", intLink);
    furl.put("extLink", extLink);
    furl.put("intUrl", intUrl);
    furl.put("extUrl", extUrl);
    furls.put(furl["deviceId"], furl);
    urls.o = furls;
  }
  
  urlsMapGet() Map {
    Map urlsm = urls.o;
    if (undef(urlsm) || urlsm.isEmpty) {
      updateUrls();
      urlsm = urls.o;
    }
    return(urlsm);
  }
  
  updateUrls() {
    if (true) {
      fakeUrls();
      return(self);
    }
    log.log("updateUrls");
    String user = app.configManager.get("imap.user");
    String endpoint = app.configManager.get("imap.endpoint");
    String pass = app.configManager.get("imap.pass");
    Map nurls = Map.new();
    if (TS.notEmpty(user) && TS.notEmpty(endpoint) && TS.notEmpty(pass)) {
      log.log("have imap info");
      any e;
      try {
          String prot = app.configManager.get("imap.protocol");
          if (TS.isEmpty(prot)) {
            prot = "imaps";
          }
          String subf = app.configManager.get("imap.subFolder");
          if (undef(subf)) {
            subf = "IotUrls";
          } elseIf (TS.isEmpty(subf)) {
            subf = null;
          }
          Json:Unmarshaller unmar = Json:Unmarshaller.new();
          //msg += "<p><input type=\"hidden\" value=\"" += Encode:Hex.encode(json) += "\"/></p>\n";
          String subjPref = "DeviceLinks ";
          //List froms = List.new();
          List contents = List.new();
          List devices = List.new();
          emit(jv) {
          """
          Properties props = new Properties();
          props.setProperty("mail.store.protocol", bevl_prot.bems_toJvString());
            Session session = Session.getDefaultInstance(props, null);
            Store store = session.getStore(bevl_prot.bems_toJvString());
            if (!store.isConnected()) {
              store.connect(bevl_endpoint.bems_toJvString(), bevl_user.bems_toJvString(), bevl_pass.bems_toJvString());
            }
            Folder f = store.getFolder("Inbox");
            if (bevl_subf != null) {
              Folder f2 = f.getFolder(bevl_subf.bems_toJvString());
              if (!f2.exists()) {
                f2.create(Folder.HOLDS_MESSAGES);
              }
              f = f2;
            }
            f.open(Folder.READ_WRITE);
            
            if (bevl_subjPref != null) {
            
              String ls = bevl_subjPref.bems_toJvString();
              
              Message[] messages = f.getMessages();
              if (messages != null) {
                for(int i = 0; i < messages.length; i++)
                {
                  String subj = messages[i].getSubject();
                  if (subj != null && subj.startsWith(ls)) {
                    System.out.println("found message");
                    Message message = messages[i];
                    if (message != null) {
                      Address[] adda = message.getFrom();
                      if (adda != null && adda.length > 0) {
                        Address add = adda[0];
                        if (add != null) {
                          //String adds = add.toString();
                          //System.out.println("address " + adds);
                        }
                      }
                      Object con = message.getContent();
                      if (con != null) {
                        String mc = con.toString();
                        if (mc != null) {
                          //System.out.println("mc " + mc);
                          bevl_contents.bem_addValue_1(new $class/Text:String$(mc));
                        }
                      }
                    }
                  }
                }
              }            
            }
            
            f.close(true);
            store.close();
          """
          }
          for (String con in contents) {
            //log.log("got con " + con);
            try {
              String beg = "type=\"hidden\" value=\"";
              Int d = con.find(beg);
              if (def(d)) {
                con = con.substring(d + beg.size);
                d = con.find("\"");
                if (def(d)) {
                  con = con.substring(0, d);
                  //log.log("final con " + con);
                  String conjs = Encode:Hex.decode(con);
                  log.log("conjs " + conjs);
                  Map lm = unmar.unmarshall(conjs);
                  if (def(lm) && TS.notEmpty(lm["deviceId"])) {
                    log.log("putting into nurls " + lm["deviceId"]);
                    nurls.put(lm["deviceId"], lm);
                  }
                  //log.log("done with unmar " + lm.get("extAddress"));
                }
              }
            } catch (e) {
             log.log("Exception during imap stuff " );
            }
          }
          urls.o = nurls;
          log.log("Done with imap stuff");
      } catch (e) {
        if(def(e)) {
          log.log("Exception during imap stuff ");
        }
      }
    }
  }

  hiRequest(Map arg, request) {
      log.log("In hi");
      Map res = Map.new();
      res["action"] = "hiResponse";
      res["msg"] = "hello2 " + arg["who"];
      return(res);
    }
    
    showImapRequest(Map arg, request) {
      Map res = Map.new();
      res["action"] = "showImapResponse";
      String user = app.configManager.get("imap.user");
      if (TS.notEmpty(user)) {
        res["imapAccount"] = user;
      }
      String ep = app.configManager.get("imap.endpoint");
      if (TS.notEmpty(ep)) {
        res["imapEndpoint"] = ep;
      }
      return(res);
   }
   
   imapSettingsRequest(Map arg, request) {
      app.configManager.put("imap.user", arg["imapAccount"]);
      app.configManager.put("imap.endpoint", arg["imapEndpoint"]);
      app.configManager.put("imap.pass", arg["imapPass"]);
      Map res = Map.new();
      res["action"] = "hideImapResponse";
      return(res);
   }
   
   urlsRequest(Map arg, request) {
      Map urls = self.urlsMap;
      String uh = String.new();
      log.log("in urlsreq 1");
      for (MNode kv in urls) {
          log.log("in urlsreq 2");
          //uh += "<p>" += kv.value["intLink"] += "</p>";
          //uh += "<p>" += kv.value["extLink"] += "</p>";
          
          String mygw = Net:Gateway.defaultAddress;
          log.log( " mygw " + mygw);
          log.log("dev gw is " + kv.value["gw"]);
          
          String extLink = "<p><a href=\"#\" onclick=\"openExtLink('" += kv.value["deviceId"] += "');return false;\">Go to  " += kv.value["deviceName"] += " " += kv.value["deviceId"] += " from the internet or outside the network the device is on</a></p>";
          
          String intLink = "<p><a href=\"#\" onclick=\"openIntLink('" += kv.value["deviceId"] += "');return false;\">Go to  " += kv.value["deviceName"] += " " += kv.value["deviceId"] += " from the same network the device is on</a></p>";
          
          if (def(mygw) && def(kv.value["gw"]) && mygw == kv.value["gw"]) {
            uh += intLink;
          } else {
            uh += extLink;
          }
          
          log.log("in urlsreq 3");
          
          String ldiv = "shLinkDiv" + kv.value["deviceId"];
          uh += "<p><a href=\"#\" onclick=\"showADiv('" += ldiv += "');return false;\">+" += kv.value["deviceName"] += "</a></p>";
          uh += "<div id=\"" += ldiv += "\" style=\"display: none;\">";
          uh += "<p><a href=\"#\" onclick=\"hideADiv('" += ldiv += "');return false;\">-" += kv.value["deviceName"] += "</a></p>";
          uh += extLink;
          uh += intLink;
          uh += "</div>";
      }
      Map res = Map.new();
      res["action"] = "urlsResponse";
      res["urlsHtml"] = uh;
      return(res);
   }
   
   openLinkRequest(Map arg, request) {
    log.log("Open link request " + arg["deviceId"] + " from " + arg["from"]);
    Map urlsm = self.urlsMap;
    if (def(urlsm)) {
      Map md = urlsm.get(arg["deviceId"]);
      if (def(md)) {
        if (arg["from"] == "int") {
          String tourl = md["intUrl"];
        } else {
          tourl = md["extUrl"];
        }
        log.log("opening in browser: " + tourl);
        UI:ExternalBrowser.openToUrl(tourl);
      }
    }
    return(null);
   }

}

use App:Account;
use App:AccountManager;
   
use Db:KeyValue as KvDb;

