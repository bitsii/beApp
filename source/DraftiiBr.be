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
  uiStartup(new be_$class/Draftii:Wui$());
}

function imChange(dropdown) {
    var myindex  = dropdown.selectedIndex
    var SelValue = dropdown.options[myindex].value
    callUI('fillImap', SelValue);
}

window.onload = startup;
"""
}

use class Draftii:Wui {

  new() self {
        fields {
          IO:Log log =@ IO:Logs.get(self);
          List callbacks = Lists.from(self); //plugins
          HC hc = HC.new(callbacks);
          fields {
            List wasOpen = List.new();;
          }
        }
    }
    
    handleCallOut(Map arg) {
      hc.call(arg);
    }
    
    main() {
    
    }
    
    handleCallback(String res) {
      log.log("got callback");
      hc.handleCallback(res);
    }
    
   startup() {
      IO:Logs.turnOnAll();
      log.log("sanbr started");
      HC.callApp(Lists.from("getDraftListRequest"));
   }
   
   informResponse(String r) {
     log.log("in inform res");
     if (TS.notEmpty(r)) {
      HD.getElementById("informMessageDiv").innerHTML = r;
      HD.getElementById("informDiv").display = "block";
     }
   }
   
   toggleDivCI(String toOpen) Bool {
     HD.getElementById("informDiv").display = "none";
     return(toggleDiv(toOpen));
   }
   
   toggleDiv(String toOpen) Bool {
    Bool didOpen = HC.toggleDisplay(toOpen);
    if (didOpen) {
      wasOpen = List.new();
      List divs =@ Lists.from("imapSettingsDiv", "dComposeDiv", "dListDiv", "informDiv");
      for (String div in divs) {
        if (div != toOpen && HD.getElementById(div).display == "block") {
          wasOpen += div;
          HD.getElementById(div).display = "none";
        }
      }
    } else {
      for (div in wasOpen) {
        HD.getElementById(div).display = "block";
      }
    }
    return(didOpen);
   }
   
   fillImap(String forService) {
      //(
      if (forService.ends("Disable)")) {
        HD.getElementById("advancedImap").display = "none";
        HD.getElementById("imapChosen").value = "";
        HD.getElementById("imDitty").innerHTML = "";
      } elseIf (forService.ends("GMail")) {
        HD.getElementById("advancedImap").display = "none";
        HD.getElementById("imapChosen").value = "GMail";
        HD.getElementById("imapEndpoint").value = "imap.gmail.com";
        HD.getElementById("imDitty").innerHTML = "<p>Use an account you already have, or create one here: <a href='https://accounts.google.com/SignUp?service=mail'>GMail Signup</a>";
      } elseIf (forService.ends("GMX Mail")) {
        HD.getElementById("advancedImap").display = "none";
        HD.getElementById("imapChosen").value = "GMXMail";
        HD.getElementById("imapEndpoint").value = "imap.gmx.com";
        HD.getElementById("imDitty").innerHTML = "<p>Use an account you already have, or create one here: <a href='https://service.gmx.com/registration.html'>GMX Signup</a>";
      } elseIf (forService.ends("Yahoo Mail")) {
        HD.getElementById("advancedImap").display = "none";
        HD.getElementById("imapChosen").value = "YahooMail";
        HD.getElementById("imapEndpoint").value = "imap.mail.yahoo.com";
        HD.getElementById("imDitty").innerHTML = "<p>Use an account you already have, or create one here: <a href='https://login.yahoo.com/account/create'>Yahoo Signup</a>";
      } elseIf (forService.ends("Advanced")) {
          HD.getElementById("advancedImap").display = "block";
          HD.getElementById("imapChosen").value = "Custom";
          HD.getElementById("imDitty").innerHTML = "<p>Set your secure IMAP endpoint, enter account information, and optionally provide a custom folder for notes.";
      } elseIf (forService.ends("Disable")) {
          HD.getElementById("advancedImap").display = "none";
          HD.getElementById("imapChosen").value = "Disable";
          HD.getElementById("imDitty").innerHTML = "<p>Syncing will be Disabled";
      }
   }
   
}
