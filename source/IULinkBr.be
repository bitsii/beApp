// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use System:Exception as Exc;
use Container:Queue;
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
  uiStartup(new be_$class/App:IULinkBr$());
}

var openIntLink = function(devid) {
    var bevs_resjs = new be_$class/Text:String$().bems_new(devid);
    ui.bem_openIntLinkRequest_1(bevs_resjs);
}

var openExtLink = function(devid) {
    var bevs_resjs = new be_$class/Text:String$().bems_new(devid);
    ui.bem_openExtLinkRequest_1(bevs_resjs);
}

var showADiv = function(divid) {
  document.getElementById(divid).style.display = "block";
}

var hideADiv = function(divid) {
  document.getElementById(divid).style.display = "none";
}

window.onload = startup;
"""
}

use class App:IULinkBr {

  new() self {
        fields {
          String name = "link";
        }
    }
    
    main() {
      //urlsRequest();
    }
    
    handleCallOut(Map arg) {
      if (def(arg)) {
        arg["plugin"] = name;
      }
      HC.new(self).call(arg);
    }
    
    handleCallback(String res) {
      HC.new(self).handleCallback(res);
    }
   
   urlsRequest() {
      Map arg = Map.new();
      arg["action"] = "urlsRequest";
      handleCallOut(arg);
   }
   
   urlsResponse(Map arg) {
     HD.getElementById("urlsHtmlDiv").innerHTML = arg["urlsHtml"];
     HD.getElementById("urlsDiv").display = "block";
   }
   
   openIntLinkRequest(String did) {
      Map arg = Map.new();
      arg["action"] = "openLinkRequest";
      arg["deviceId"] = did;
      arg["from"] = "int";
      handleCallOut(arg);
   }
   
   openExtLinkRequest(String did) {
      Map arg = Map.new();
      arg["action"] = "openLinkRequest";
      arg["deviceId"] = did;
      arg["from"] = "ext";
      handleCallOut(arg);
   }
   
   hiRequest() {
      Map arg = Map.new();
      arg["action"] = "hiRequest";
      arg["who"] = HD.getElementById("who").value;
      handleCallOut(arg);
   }
   
   hiResponse(Map arg) {
     HD.getElementById("msgdiv").innerHTML = arg["msg"];
   }
   
   showImapRequest() {
     if (HD.getElementById("imapSettingsDiv").display == "block") {
      HD.getElementById("imapSettingsDiv").display = "none";
     } else {
      Map arg = Map.new();
      arg["action"] = "showImapRequest";
      handleCallOut(arg);
     }
   }
   
   showImapResponse(Map arg) {
     if (arg.has("imapEndpoint")) {
      HD.getElementById("imapEndpoint").value = arg["imapEndpoint"];
     }
     if (arg.has("imapAccount")) {
      HD.getElementById("imapAccount").value = arg["imapAccount"];
     }
     HD.getElementById("imapSettingsDiv").display = "block";
   }
   
   hideImapResponse(Map arg) {
     HD.getElementById("imapSettingsDiv").display = "none";
   }
   
   imapSettingsRequest() {
    String iac = HD.getElementById("imapAccount").value;
    String iep = HD.getElementById("imapEndpoint").value;
    String ip = HD.getElementById("imapPass").value;
    String ip2 = HD.getElementById("imapPass2").value;
    HD.getElementById("imapPass").value = "";
    HD.getElementById("imapPass2").value = "";
    if (ip == ip2) {
    Map arg = Map.new();
    arg["action"] = "imapSettingsRequest";
    arg["imapAccount"] = iac;
    arg["imapEndpoint"] = iep;
    arg["imapPass"] = ip;
    handleCallOut(arg);
    } else {
      inform("Passwords don't match");
    }
   }
   
   informResponse(Map arg) {
    inform(arg["reason"]);
   }
   
   inform(String r) {
     if (TS.notEmpty(r)) {
      HD.getElementById("informMessageDiv").innerHTML = r;
      HD.getElementById("informDiv").display = "block";
     }
   }
   
   hideInform() {
     HD.getElementById("informDiv").display = "none";
   }
   
   login() {
      Map arg = Map.new();
      arg["action"] = "loginRequest";
      arg["accountName"] = HD.getElementById("accountName").value;
      arg["accountPass"] = HD.getElementById("accountPass").value;
      arg["sessionName"] = HD.getElementById("sessionName").value;
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
   
   updateResponse(Map arg) {
     fields {
       Set perms = Set.new();
     }
     if (arg.has("justLoggedIn") && arg["justLoggedIn"]) {
      //String lmsg = "Welcome " + arg["name"] + " to " + arg["deviceName"] + " on Version " + arg["appVersion"];
      String lmsg = "Welcome to " + arg["deviceName"] + " on Version " + arg["appVersion"];
      HD.getElementById("loginmsgdiv").innerHTML = lmsg;
      HD.getElementById("logindiv").display = "none";
      HD.getElementById("loggedindiv").display = "block";
      HC.new(self).pageToken = arg["pageToken"];
      urlsResponse(arg);
    }
    if (arg.has("actionLinks")) {
      HD.getElementById("actionLinksDiv").innerHTML = arg["actionLinks"];
    }
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      if (TS.notEmpty(permsString)) {
        for (String perm in permsString.split(",")) {
          perms.put(perm);
        }
      }
      //HD.getElementById("admindiv").display = "none";
    }
   }
   
   logoutResponse(Map arg) {
     HD.reload();
   }
   
   startup() {
      Map arg = Map.new();
      arg["action"] = "checkLoggedInRequest";
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      handleCallOut(arg);
   }
   
}
