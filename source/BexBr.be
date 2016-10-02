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

var ui;
//ui startup

var startup = function() {
  uiStartup(new be_$class/App:BexBr$());
}

var handleCallback = function(res) {
    if (res != null) {
      var bevs_resjs = new be_$class/Text:String$().bems_new(res);
      ui.bem_handleCallback_1(bevs_resjs);
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
