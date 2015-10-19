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
      Map arg = Map.new();
      arg["action"] = "sayHelloRequest";
      CH.new(self).call(arg);
   }
   
   sayHelloResponse(Map arg) {
     String msg = arg["msg"];
     emit(js) {
     """
     document.getElementById("infotxt").value = bevl_msg.bems_toJsString();
     """
     }
   }
}

use UI:CallWebHandler as CH;

class CH {

  new(_callback) self {
    vars {
      Json:Marshaller mar = Json:Marshaller.new();
      Json:Unmarshaller unmar = Json:Unmarshaller.new();
      var callback = _callback;
    }
  }

  call(Map arg) {
    String argjs = mar.marshall(arg);
    String resjs;
    emit(js) {
    """
    var res = window.external.HandleCall(bevl_argjs.bems_toJsString());
    //document.getElementById("infotxt").value = res;
    if (res !== null) {
      bevl_resjs = new be_BEL_4_Base_BEC_4_6_TextString().bems_new(res);
      //document.getElementById("infotxt").value = bevl_resjs.bems_toJsString();
    }
    """
    }
    if (def(resjs)) {
      Map resm = unmar.unmarshall(resjs);
      String mname = resm["action"];
      Array rargs = Array.new(1);
      rargs[0] = resm;
      if (callback.can(mname, rargs.length)) {
        callback.invoke(mname, rargs);
      }
    }
  }
}

