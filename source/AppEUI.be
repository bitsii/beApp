/*
 * Copyright (c) 2015-2023, the Bennt App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

class App:RunClassMethod {

  doWhatsNeeded(String clmtd) {
  
  //"in dowhatsneeded".print();
  
  if (TS.isEmpty(clmtd)) {
    return(self);
  }
  
  ifEmit(apwk) {
  
     runit(clmtd);
  
  }
  
  return(self);
  
  }

  runit(String clmtd) {
    "in runit".print();
    var ll = clmtd.split(".");
    any inst = System:Objects.createInstance(ll[0]);
    inst.invoke(ll[1], List.new());
    "runit done".print();
  }

}

