// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

class App:RunClassMethod {

  doWhatsNeeded(String clmtd) {
  
  "in dowhatsneeded".print();
  
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

