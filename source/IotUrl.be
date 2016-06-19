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

use System:Thread:ContainerLocker as CLocker;
use System:Thread:ObjectLocker as OLocker;
use Db:KeyValue as KvDb;
use Db:HSQLDb:Database as HsDb;

use App:Alert;

use class IotUrl:IUHandler {

     new() self {
       fields {
          IO:Log log;
          Int lvl;
          var app;
        }
     }
   
     hiRequest(Map arg, request) {
      log.log(lvl, "In hi");
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

}

use App:EventHandlers as AppEv;

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
use class App:IotUrl {
    
       
   new() self {
        fields {
          WeBr webr;
          UI:BrowserScriptRequest request = UI:BrowserScriptRequest.new();
          IO:Log log = IO:Log.new();
          log.level = log.info;
          Int lvl = log.level;
          IUHandler requestHandler;
          Background bg = Background.new();
          OLocker urls = OLocker.new();
        }
        
        requestHandler = IUHandler.new();
        requestHandler.log = log;
        requestHandler.lvl = lvl;
        requestHandler.app = self;
        
        bg.log = log;
        bg.lvl = lvl;
        bg.app = self;
        bg.startBackground();
                
    }
    
    main() {
      AppEv.put("startUi", self);
      ifNotEmit(platDroid) {
        startUi();
      }
    }

    startUi() {
      webr = WeBr.new();
      webr.webHandler = self;
      webr.height = 450;
      webr.width = 320;
      
      String mypwd = System:Environment.getVariable("MYPWD");
      ifNotEmit(platDroid) {
        webr.location = "file:///" + mypwd + "/App/IotUrl/IotUrl.html";
      }
      ifEmit(platDroid) {
        webr.location = "file:///android_asset/App/IotUrl/IotUrl.html";
      }
      
      webr.setup();
   }

   initWeb() {

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

   handleWeb(request) {
     
     Map arg = request.scriptArg;
     return(handleWeb(request, arg));
   }

  handleWeb(request, Map arg) {
        try {
            String aname = arg.get("action");
            if (undef(aname) || aname.ends("Request")!) {
              throw(Exception.new("Invalid request"));
            }
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
    
   configManagerGet() CLocker {
    fields {
      CLocker configManager;
    }
    if (undef(configManager)) {
      Path db = self.paths.dataPath.addStep("IotUrl").addStep("IotUrlDbs");
      KvDb configManagerKv = KvDb.new(HsDb.pathNew(db), "CONFIG");
      configManagerKv.createOpen();
      configManager = CLocker.new(configManagerKv);
    }
    return(configManager);
  }
  
  updateUrls() {
    log.log(lvl, "updateUrls");
    String user = self.configManager.get("imap.user");
    String endpoint = self.configManager.get("imap.endpoint");
    String pass = self.configManager.get("imap.pass");
    Map nurls = Map.new();
    if (TS.notEmpty(user) && TS.notEmpty(endpoint) && TS.notEmpty(pass)) {
      log.log(lvl, "have imap info");
      var e;
      try {
          String prot = self.configManager.get("imap.protocol");
          if (TS.isEmpty(prot)) {
            prot = "imaps";
          }
          String subf = self.configManager.get("imap.subFolder");
          if (undef(subf)) {
            subf = "GossaLinks";
          } elif (TS.isEmpty(subf)) {
            subf = null;
          }
          Json:Unmarshaller unmar = Json:Unmarshaller.new();
          //msg += "<p><input type=\"hidden\" value=\"" += Encode:Hex.encode(json) += "\"/></p>\n";
          String subjPref = "DeviceLinks ";
          //Array froms = Array.new();
          Array contents = Array.new();
          Array devices = Array.new();
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
                          bevl_contents.bem_addValue_1(new BEC_4_6_TextString(mc));
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
          foreach (String con in contents) {
            //log.log(lvl, "got con " + con);
            try {
              String beg = "type=\"hidden\" value=\"";
              Int d = con.find(beg);
              if (def(d)) {
                con = con.substring(d + beg.size);
                d = con.find("\"");
                if (def(d)) {
                  con = con.substring(0, d);
                  //log.log(lvl, "final con " + con);
                  String conjs = Encode:Hex.decode(con);
                  log.log(lvl, "conjs " + conjs);
                  Map lm = unmar.unmarshall(conjs);
                  if (def(lm) && TS.notEmpty(lm["deviceId"])) {
                    log.log(lvl, "putting into nurls " + lm["deviceId"]);
                    nurls.put(lm["deviceId"], lm);
                  }
                  //log.log(lvl, "done with unmar " + lm.get("extAddress"));
                }
              }
            } catch (e) {
              log.log(lvl, "Exception during imap stuff " + e);
            }
          }
          urls.o = nurls;
          log.log(lvl, "Done with imap stuff");
      } catch (e) {
        if(def(e)) {
          log.log(lvl, "Exception during imap stuff " + e);
        }
      }
    }
  }

}

use class Dz:Background {

  new() self {
    fields {
      var app;
      Int lvl;
      IO:Log log;
    }
  }
  
  runMainTasks() {
    log.log(lvl, "Run main tasks");
    app.updateUrls();
  }
  
  schedRunMainTasks() {
    fields {
      Int lastMainPoll;
      Int mainPollSeconds =@ 300;
    }
    Int ns = Time:Interval.now().seconds;
    if (undef(lastMainPoll) || (ns - lastMainPoll > mainPollSeconds)) {
      lastMainPoll = ns;
      //log.log(lvl, "updated lmp " + lastMainPoll + " " + ns);
      runMainTasks();
    }
  }
  
  main() {
    var e;
    while (true) {
      try {
        schedRunMainTasks();
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
      Int sleepTime = 1000;
    }
    String bkdis = app.configManager.get("bk.disable");
    if (TS.notEmpty(bkdis) && Bool.new(bkdis)) {
      return(self);
    }
    myThread = System:Thread.new(self);
    myThread.start();
  }

}
