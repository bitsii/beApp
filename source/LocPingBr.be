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
  dzeui = new be_BEL_4_Base_BEC_3_7_4_AppLocPingLPBr();
  dzeui.bem_new_0();
  dzeui.bem_main_0();
  //sayHi();
}

var sayHi = function() {
  dzeui.bem_sayHi_0();
}

var saveConfig = function() {
  dzeui.bem_saveConfig_0();
}

var loadConfig = function() {
  dzeui.bem_loadConfig_0();
}

var clearConfig = function() {
  dzeui.bem_clearConfig_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      dzeui.bem_handleCallback_1(bevs_resjs);
    }
}


window.onload = startup;
"""
}

use class App:LocPing:LPBr {

  new() self {
        properties {
        }
    }
    
    main() {
    
    }
    
    handleCallback(String res) {
      HC.new(self).handleCallback(res);
    }
    
    sayHi() {
      Map arg = Map.new();
      arg["module"] = "Hello";
      arg["action"] = "sayHelloRequest";
      HC.new(self).call(arg);
   }
   
   saveConfig() {
      Map arg = Map.new();
      arg["module"] = "Configure";
      arg["action"] = "saveRequest";
      arg["locRcvUrl"] = HD.getElementById("locRcvUrl").value;
      HC.new(self).call(arg);
   }
   
   loadConfig() {
      Map arg = Map.new();
      arg["module"] = "Configure";
      arg["action"] = "loadRequest";
      HC.new(self).call(arg);
   }
   
   clearConfig() {
      HD.getElementById("locRcvUrl").value = "";
   }
   
   loadResponse(Map arg) {
     HD.getElementById("locRcvUrl").value = arg["locRcvUrl"];
   }
   
   sayHelloResponse(Map arg) {
     HD.getElementById("msgdiv").innerHTML = arg["msg"];
   }
   
}
