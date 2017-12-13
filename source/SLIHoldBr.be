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
  uiStartup(new be_$class/SLIHold:Wui$());
}

window.onload = startup;
"""
}

use class SLIHold:Wui {

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
      hc.handleCallback(res);
    }
    
   startup() {
      IO:Logs.turnOnAll();
      log.log("sanbr started");
      //handleCallOut(arg);
   }
   
}
