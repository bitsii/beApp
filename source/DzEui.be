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

emit(js) {
"""
//Here's some js
var startup = function() {
  var mc1 = new be_BEL_4_Base_BEC_2_3_DzEui();
  mc1.bem_new_0();
  mc1.bem_main_0();
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
      String val = "<h2>boo</h2>";
      emit(js) {
      """
        document.getElementById("msgdiv").innerHTML = this.bems_stringToJsString_1(bevl_val);
      """
      }
      //Map arg = Map.new();
      //arg["boo"] = 1;
      //arg["action"] = "sayHelloRequest";
      //UI:CallWebHandler.new().call(arg);
   }
}

use UI:CallWebHandler {

  default() self {
    vars {
      //Json:Marshaller mar = Json:Marshaller.new();
      //Json:Unmarshaller unmar = Json:Unmarshaller.new();
    }
  }

  call(Map arg) {
    //String argjs = mar.marshall(arg);
    emit(js) {
    """
    //var res = window.external.HandleCall(this.bems_stringToJsString_1(bev_argjs));
    """
    }
  }

}

/*
var callAppEmb = function(arg) {
    var res = window.external.HandleCall(JSON.stringify(arg));
    //alert(res);
    if (res != null) {
        var evjs = JSON.parse(res);
        //alert(evjs.action);
        if (evjs && evjs.action) {
            var afunc = eval(evjs.action);
            var args = new Array(1);
            args[0] = evjs;
            afunc.apply(null, args);
        }
    }
}
*/
