// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Container:Queue;
use IO:File:Path;
use IO:File;
use System:Random;
use Text:Strings as TS;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use Db:SQLite:Database as SlDb;

use class IUHub:Test(Assert) {
 
  main() {
    "Begin Dz Test".print();
    try {
      //Db:Relational:Test.new().main();
      IUHub:AccountTest.new().main();
      IUHub:ConfigTest.new().main();
      //IUHub:HHandlerTest.new().main();
    } catch (any e) {
      "Exception during test".print();
      e.print();
    }
    "End Dz Test".print();
  }

}
