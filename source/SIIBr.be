// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
  uiStartup(new be_$class/IUHub:Eui$());
}

window.onload = startup;
"""
}

use class IUHub:Eui {

  new() self {
        fields {
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
   
   startup() {
      IO:Logs.turnOnAll();
      //hideNShowMenuResponse(Sets.from("secretMe"));
      //hideNShowResponse(Sets.from("secretDiv"));
      Map arg = Map.new();
      arg["action"] = "pageTokenRequest";
      HD.getElementById("accountName").value = "";
      HD.getElementById("accountPass").value = "";
      //log.log("href at startup " + HD.href);
      handleCallOut(arg);
   }
   
   hideNShowOneResponse(String val) {
    hideNShowResponse(Set.new().put(val));
   }
   
   hideNShowListResponse(List toShow) {
    hideNShowResponse(Sets.from(toShow));
   }
    
   hideNShowResponse(Set toShow) {
    List allElems =@ Lists.from("secretDiv", "loginDiv");
    for (String el in allElems) {
      if (toShow.has(el)) {
        HD.getElementById(el).display = "block";
      } else {
        HD.getElementById(el).display = "none";
      }
    }
    //HD.getElementById("loginmsgdiv").innerHTML = "";
   }
   
   hideNShowMenuResponse(Set toShow) {
    List allElems =@ Lists.from("secretMe", "loginMe", "logoutMe");
    for (String el in allElems) {
      if (toShow.has(el)) {
        HD.getElementById(el).display = "block";
      } else {
        HD.getElementById(el).display = "none";
      }
    }
    //HD.getElementById("loginmsgdiv").innerHTML = "";
   }
   
   pageTokenResponse(Map arg) {
      hc.pageToken = arg["pageToken"];
      Map carg = Map.new();
      carg["action"] = "checkLoggedInRequest";
      //log.log("href at startup " + HD.href);
      handleCallOut(carg);
   }
   
   logoutResponse() {
    HD.reload();
   }
   
   toLoginResponse() {
      hideNShowResponse(Sets.from("loginDiv"));
      hideNShowMenuResponse(Sets.from("loginMe"));
   }
   
   loggedInResponse(Map arg) {
     hideNShowResponse(Sets.from("secretDiv"));
     hideNShowMenuResponse(Sets.from("logoutMe", "secretMe"));
     fields {
       String ivFirst = arg["ivfirst"];
       String pcFirst = arg["pcfirst"];
     }
     if (TS.isEmpty(ivFirst) || TS.isEmpty(pcFirst)) {
       logout();
     }
   }
   
   saveSecret() {
     HC.callApp(Lists.from("saveSecretRequest", HD.getEle("secName").value, HD.getEle("secAccount").value, HD.getEle("secPass").value, ivFirst, pcFirst));
   }
   
   login() {
      Map arg = Map.new();
      arg["action"] = "getCredsRequest";
      arg["accountName"] = HD.getElementById("accountName").value;
      arg["accountPass"] = HD.getElementById("accountPass").value;
      arg["sessionName"] = HD.getElementById("sessionName").value;
      //arg["sessionLength"] = HD.getElementById("sessionLength").value;
      if (HD.getElementById("sessionNeverExpires").checked) {
        arg["sessionLength"] = "-1";
        //log.log("set sel neg");
      } else {
         arg["sessionLength"] = "60";
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
      HD.reload();
   }
   
   informResponse(String info) {
    inform(info);
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
}
