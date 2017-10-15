// Copyright 2015 Craig Welch
// All rights reserved

use System:Exception as Exc;
use IO:File:Path;
use IO:File;
use System:Random;

use UI:HtmlDom:Document as HD;
use UI:HtmlDom:Element as HE;
use UI:HtmlDom:Call as HC;

emit(js) {
"""

//ui startup
var startup = function() {
  uiStartup(new be_$class/Iur:Eui$());
}

var endSession = function(forId) {
  callUI('endSessionRequest', forId);
}

function handleFileSelect(evt) {
  callUI('inform','in hfs');
  //var dpath = callUI('browsingDirGet').bems_toJsString();
  //var dpath = 'Home/dev/';
  var dpath = 'tmp';
  var files = evt.target.files; // FileList object
  for (var i = 0, f; f = files[i]; i++) {
    var req = new XMLHttpRequest();
    req.open("PUT", "/".concat(dpath.concat("/".concat(escape(f.name)))).concat("?pageToken=").concat(pageToken));
    req.setRequestHeader("Content-type", "application/octet-stream");
    callUI('inform', dpath);
    callUI('inform', 'calling');
    req.send(f);
  }
  callUI('inform', 'called');
  document.getElementById("files").value = '';
}

window.onload = startup;
"""
}

use class Iur:Eui {

  new() self {
        fields {
          String name = "Iur";
          IO:Log log =@ IO:Logs.get(self);
          List callbacks = Lists.from(self); //plugins
          HC hc = HC.new(callbacks);
        }
    }
    
    handleCallOut(Map arg) {
      hc.call(arg);
    }
    
    main() {
    
    }
    
    handleCallback(String res) {
      hideInform();
      hc.handleCallback(res);
    }
   
   endSessionRequest(String theKey) {
      Map arg = Map.new();
      arg["action"] = "endSessionRequest";
      arg["sessionKey"] = theKey;
      handleCallOut(arg);
   }
   
   startup() {
      IO:Logs.turnOnAll();
      Map arg = Map.new();
      arg["action"] = "pageTokenRequest";
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      //log.log("href at startup " + HD.href);
      handleCallOut(arg);
   }
   
   toLoginResponse() {
      HD.getElementById("logindiv").display = "block";
      HD.getElementById("loggedindiv").display = "none";
      HD.getElementById("spinnerdiv").display = "none";
      HD.getElementById("loginmsgdiv").innerHTML = "";
   }
   
   pageTokenResponse(Map arg) {
      hc.pageToken = arg["pageToken"];
      Map carg = Map.new();
      carg["action"] = "checkLoggedInRequest";
      String ot = HD.href;
      if (ot.has("?onceToken=") && ot.has("&")!) {
        ot = ot.substring(ot.find("=") + 1, ot.size);
        carg["onceToken"] = ot;
      }
      //log.log("href at startup " + HD.href);
      handleCallOut(carg);
   }
   
   login() {
      Map arg = Map.new();
      arg["action"] = "loginRequest";
      arg["accountName"] = HD.getElementById("accountName").value;
      arg["accountPass"] = HD.getElementById("accountPass").value;
      arg["sessionName"] = HD.getElementById("sessionName").value;
      arg["sessionLength"] = HD.getElementById("sessionLength").value;
      if (HD.getElementById("sessionNeverExpires").checked) {
        arg["sessionLength"] = "-1";
        //log.log("set sel neg");
      } else {
         //log.log("set sel neg not");
      }
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      HD.getElementById("sessionName").value = "";
      handleCallOut(arg);
   }
   
   logout() {
      Map arg = Map.new();
      arg["action"] = "logoutRequest";
      handleCallOut(arg);
   }
   
   flyersResponse(String flyers) {
    HD.getEle("flyersDiv").innerHTML = flyers;
    HD.setDis("flyersDiv", "block");
   }
   
   updateResponse(Map arg) {
     fields {
       Set perms = Set.new();
     }
     if (arg.has("justLoggedIn") && arg["justLoggedIn"]) {
      //HD.getElementById("loginmsgdiv").innerHTML = lmsg;
      HD.getElementById("logindiv").display = "none";
      HD.getElementById("loggedindiv").display = "block";
      HD.getElementById("spinnerdiv").display = "none";
    }
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      if (TS.notEmpty(permsString)) {
        for (String perm in permsString.split(",")) {
          perms.put(perm);
        }
      }
    }
    if (arg.has("flyers")) {
      flyersResponse(arg["flyers"]);
    }
    String oinf = "";
    if (TS.notEmpty(oinf)) {
      inform(oinf);
    }
   }
   
   logoutResponse(Map arg) {
     HD.reload();
   }
   
   changePassRequest() {
    String op = HD.getElementById("changePassOld").value;
    String np = HD.getElementById("changePassNew").value;
    String np2 = HD.getElementById("changePassNew2").value;
    HD.getElementById("changePassOld").value = "";
    HD.getElementById("changePassNew").value = "";
    HD.getElementById("changePassNew2").value = "";
    if (np == np2) {
    Map arg = Map.new();
    arg["action"] = "changePassRequest";
    arg["oldPass"] = op;
    arg["newPass"] = np;
    handleCallOut(arg);
    } else {
      inform("New passwords don't match");
    }
   }
   
   showSessionsRequest() {
    if (HD.getElementById("sessionsListDiv").display == "block") {
      HD.getElementById("sessionsListDiv").display = "none";
    } else {
      Map arg = Map.new();
      arg["action"] = "showSessionsRequest";
      handleCallOut(arg);
    }
   }
   
   showSessionsResponse(Map arg) {
    if (TS.notEmpty(arg["sessionsList"])) {
      HD.getElementById("sessionsListDiv").innerHTML = arg["sessionsList"];
      HD.getElementById("sessionsListDiv").display = "block";
    }
   }
   
   informResponse(String info) {
    inform(info);
   }
   
   inform(String r) {
     log.log("informing " + r);
     if (TS.notEmpty(r)) {
      HD.getElementById("informMessageDiv").innerHTML = r;
      HD.getElementById("informDiv").display = "block";
     }
   }
   
   hideInform() {
     HD.getElementById("informDiv").display = "none";
   }
  
}
