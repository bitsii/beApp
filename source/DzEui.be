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
"""
}

use class Dz:Eui {

  new() self {
        properties {
        }
    }

    main() {
      emit(js) {
      """
        document.getElementById("msgdiv").innerHTML = "<h2>boo</h2>";
      """
      }
   }
}
