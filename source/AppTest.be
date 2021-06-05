// Copyright 2021 The AbeliiApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

use System:Parameters;

use Test:Assertions;
use Test:Failure;

class AppTest:Tests {
   
   main() {
     try {
       Int howManyTimes = 1;
       for (Int i = 0;i < howManyTimes;i++=) {
        innerMain();
      }
     } catch (any e) {
       if (def(e)) {
        e.print();
        throw(e);
       } else {
        ("failed null execpt").print();
        throw(System:Exception.new("Failed with null exception"));
       }
     }
   }
   
   innerMain() {
   
      ("AppTests:Tests:innerMain").print();
      
  }
  
}