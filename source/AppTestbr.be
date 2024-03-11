/*
 * Copyright (c) 2015-2023, the Brace App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

import System:Parameters;

import Test:Assertions;
import Test:Failure;

class AppTestbr:Tests {
   
   main() {
     try {
       Int howManyTimes = 1;
       for (Int i = 0;i < howManyTimes;i++=) {
        innerMain();
      }
     } catch (dyn e) {
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
   
      ("AppTestsbr:Tests:innerMain").print();
      
  }
  
}
