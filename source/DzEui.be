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

var dzeui;
//ui startup
var startup = function() {
  dzeui = new be_BEL_4_Base_BEC_2_3_DzEui();
  dzeui.bem_new_0();
  dzeui.bem_main_0();
  var ln = getParameter("loginName");
  var lp = getParameter("loginPass");
  if (ln !== null && lp !== null && ln !== '' && lp !== '') {
    dzeui.bem_login_2(new be_BEL_4_Base_BEC_4_6_TextString().bems_new(ln), new be_BEL_4_Base_BEC_4_6_TextString().bems_new(lp));
  }
  dzeui.bem_startup_0();
}

var playSound = function() {
  dzeui.bem_playSound_0();
}

var updateImage = function(cam) {
  dzeui.bem_updateImage_1(new be_BEL_4_Base_BEC_4_6_TextString().bems_new(cam));
}

var runCommand = function() {
  dzeui.bem_runCommand_0();
}

var login = function() {
  dzeui.bem_login_0();
}

var logout = function() {
  dzeui.bem_logout_0();
}

var clearImage = function() {
  dzeui.bem_clearImage_0();
}

var detectCams = function() {
  dzeui.bem_detectCams_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      dzeui.bem_handleCallback_1(bevs_resjs);
    }
}

function getParameter(param) {
    param = param.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + param + "=([^&#]*)"),
        results = regex.exec(location.search);
    return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}


window.onload = startup;
"""
}

use class Dz:Eui {

  new() self {
        properties {
        }
    }
    
    main() {
    
    }
    
    handleCallback(String res) {
      HC.new(self).handleCallback(res);
    }
    
    updateImage(String cam) {
      Map arg = Map.new();
      arg["module"] = "MediaIO";
      arg["action"] = "updateImageRequest";
      arg["cam"] = cam;
      HC.new(self).call(arg);
   }
   
   playSound() {
      Map arg = Map.new();
      arg["module"] = "MediaIO";
      arg["action"] = "playSoundRequest";
      HC.new(self).call(arg);
   }
   
   runCommand() {
      Map arg = Map.new();
      arg["module"] = "MediaIO";
      arg["action"] = "runCommandRequest";
      arg["cmd"] = HD.getElementById("cmd").value;
      HC.new(self).call(arg);
   }
   
   startup() {
      clearImage();
      Map arg = Map.new();
      arg["module"] = "Accounts";
      arg["action"] = "checkLoggedInRequest";
      HD.getElementById("loginName").value = "";
      HD.getElementById("loginPass").value = "";
      HC.new(self).call(arg);
   }
   
   login() {
      login(HD.getElementById("loginName").value, HD.getElementById("loginPass").value);
   }
   
   login(String loginName, String loginPass) {
      clearImage();
      Map arg = Map.new();
      arg["module"] = "Accounts";
      arg["action"] = "loginRequest";
      arg["loginName"] = loginName;
      arg["loginPass"] = loginPass;
      HD.getElementById("loginName").value = "";
      HD.getElementById("loginPass").value = "";
      HC.new(self).call(arg);
   }
   
   logout() {
      clearImage();
      Map arg = Map.new();
      arg["module"] = "Accounts";
      arg["action"] = "logoutRequest";
      HC.new(self).call(arg);
   }
   
   updateImageResponse(Map arg) {
     HD.getElementById("imgdiv").innerHTML = arg["imghtm"];
   }
   
   updateResponse(Map arg) {
     if (arg.has("justLoggedIn") && arg["justLoggedIn"]) {
      HD.getElementById("loginmsgdiv").innerHTML = "Welcome " + arg["name"];
      HD.getElementById("logindiv").display = "none";
      HD.getElementById("loggedindiv").display = "block";
    }
    if (arg.has("camLinks")) {
      HD.getElementById("camLinksDiv").innerHTML = arg["camLinks"];
    }
    if (arg.has("permsString")) {
      String permsString = arg["permsString"];
      Set perms = Set.new();
      if (TS.notEmpty(permsString)) {
        foreach (String perm in permsString.split(",")) {
          perms.put(perm);
        }
      }
      HD.getElementById("runCommandId").display = "none";
      HD.getElementById("playSoundId").display = "none";
      HD.getElementById("detectCamsId").display = "none";
      HD.getElementById("cmd").display = "none";
      if (perms.has("admin")) {
        HD.getElementById("runCommandId").display = "block";
        HD.getElementById("playSoundId").display = "block";
        HD.getElementById("detectCamsId").display = "block";
        HD.getElementById("cmd").display = "block";
      }
    }
   }
   
   logoutResponse(Map arg) {
     HD.getElementById("loginmsgdiv").innerHTML = "";
     HD.getElementById("logindiv").display = "block";
     HD.getElementById("loggedindiv").display = "none";
   }
   
   clearImage() {
     HD.getElementById("imgdiv").innerHTML = "";
   }
   
   detectCams() {
      Map arg = Map.new();
      arg["module"] = "MediaIO";
      arg["action"] = "detectCamsRequest";
      HC.new(self).call(arg);
   }
}
