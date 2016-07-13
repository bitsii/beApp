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
  eui = new be_BEL_4_Base_BEC_3_5_AppBexBr();
  eui.bem_new_0();
  eui.bem_main_0();
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      eui.bem_handleCallback_1(bevs_resjs);
    }
}


window.onload = startup;
"""
}

use class App:BexBr {

  new() self {
        fields {
        }
    }
    
    main() {
    
    }
    
    handleCallback(String res) {
      HC.new(self).handleCallback(res);
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
   
}
