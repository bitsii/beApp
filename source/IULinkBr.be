// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Text:String;
use Logic:Bool;
use Math:Int;
use System:Exception as Exc;
use Container:Array;
use Container:Map;
use Container:Set;
use Container:LinkedList;
use Container:Queue;
use IO:File:Path;
use IO:File;
use System:Random;
use Text:Strings as TS;

use UI:HtmlDom:Document as HD;
use UI:HtmlDom:Element as HE;
use UI:HtmlDom:Call as HC;

emit(js) {
"""

var eui;
//ui startup
var startup = function() {
  eui = new be_BEL_4_Base_BEC_3_8_AppIULinkBr();
  eui.bem_new_0();
  eui.bem_main_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      eui.bem_handleCallback_1(bevs_resjs);
    }
}

var openIntLink = function(devid) {
    var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(devid);
    eui.bem_openIntLinkRequest_1(bevs_resjs);
}

var openExtLink = function(devid) {
    var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(devid);
    eui.bem_openExtLinkRequest_1(bevs_resjs);
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
        }
    }
    
    main() {
      urlsRequest();
    }
    
    handleCallback(String res) {
      HC.new(self).handleCallback(res);
    }
   
   urlsRequest() {
      Map arg = Map.new();
      arg["action"] = "urlsRequest";
      HC.new(self).call(arg);
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
      HC.new(self).call(arg);
   }
   
   openExtLinkRequest(String did) {
      Map arg = Map.new();
      arg["action"] = "openLinkRequest";
      arg["deviceId"] = did;
      arg["from"] = "ext";
      HC.new(self).call(arg);
   }
   
   hiRequest() {
      Map arg = Map.new();
      arg["action"] = "hiRequest";
      arg["who"] = HD.getElementById("who").value;
      HC.new(self).call(arg);
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
      HC.new(self).call(arg);
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
    HC.new(self).call(arg);
    } else {
      fail("Passwords don't match");
    }
   }
   
   fail(String r) {
     if (TS.notEmpty(r)) {
      HD.getElementById("failMessageDiv").innerHTML = r;
      HD.getElementById("failDiv").display = "block";
     }
   }
   
   hideFail() {
     HD.getElementById("failDiv").display = "none";
   }
   
}
