/*
 * Copyright (c) 2015-2023, the Beysant App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

use System:Parameters;

use Test:Assertions;
use Test:Failure;

class AppTest:Tests {
   
   main() {
     try {
       Int howManyTimes = 1;
       for (Int i = 0;i < howManyTimes;i++) {
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
