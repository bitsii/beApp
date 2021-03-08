// Copyright 2015 The AbeliiApp Authors. All rights reserved.
// Use of this source code is governed by the BSD-3-Clause
// license that can be found in the LICENSE file.

class App:RunClassMethod {

  doWhatsNeeded(String clmtd) {
  
  //"in dowhatsneeded".print();
  
  if (TS.isEmpty(clmtd)) {
    return(self);
  }
  
  ifEmit(apwkui) {
  
     runit(clmtd);
  
  }
  
  return(self);
  
  }

  runit(String clmtd) {
    "in runit".print();
    auto ll = clmtd.split(".");
    any inst = createInstance(ll[0]);
    inst.invoke(ll[1], List.new());
    "runit done".print();
  }

}

