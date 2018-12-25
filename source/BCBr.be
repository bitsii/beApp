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
      hideNShowMenuResponse(Sets.from("setupMe"));
      hideNShowResponse(Sets.from("setupDiv"));
   }
   
   hideNShowOneResponse(String val) {
    hideNShowResponse(Set.new().put(val));
   }
   
   hideNShowListResponse(List toShow) {
    hideNShowResponse(Sets.from(toShow));
   }
    
   hideNShowResponse(Set toShow) {
    List allElems =@ Lists.from("setupDiv");
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
    List allElems =@ Lists.from("setupMe");
    for (String el in allElems) {
      if (toShow.has(el)) {
        HD.getElementById(el).display = "block";
      } else {
        HD.getElementById(el).display = "none";
      }
    }
    //HD.getElementById("loginmsgdiv").innerHTML = "";
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
