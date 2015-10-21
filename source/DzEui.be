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
      HD.getElementById("msgdiv").innerHTML = "<h2>boo</h2>";
      Map arg = Map.new();
      arg["action"] = "sayHelloRequest";
      HC.new(self).call(arg);
   }
   
   sayHelloResponse(Map arg) {
     HD.getElementById("infotxt").value = arg["msg"];
   }
}

//UI:HtmlDom:Document :Element .getElementById

use UI:HtmlDom:Document as HD;

class HD {
  default() self {
    
  }
  
  getElementById(String id) {
    return(HE.new(id));
  }
}

use UI:HtmlDom:Element as HE;

class HE {
  new(String id) self {
    emit(js) {
    """
    this.bevi_element = document.getElementById(beva_id.bems_toJsString());
    """
    }
  }
  
  valueSet(String val) self {
    emit(js) {
    """
    this.bevi_element.value = beva_val.bems_toJsString();
    """
    }
  }
  
  innerHTMLSet(String val) self {
    emit(js) {
    """
    this.bevi_element.innerHTML = beva_val.bems_toJsString();
    """
    }
  }
  
}

use UI:HtmlDom:Call as HC;

class HC {

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

