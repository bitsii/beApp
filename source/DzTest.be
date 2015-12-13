// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Text:String;
use Logic:Bool;
use Math:Int;
use System:Exception;
use Container:Array;
use Container:Map;
use Container:Set;
use Container:LinkedList;
use Container:Queue;
use IO:File:Path;
use IO:File;
use System:Random;
use Text:Strings as TS;
use UI:WebBrowser as WeBr;
use Test:Assertions as Assert;
use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;
use Db:Firebird:Database as FbDb;
use Db:SQLite:Database as SlDb;

use class Dz:Test(Assert) {
 
  main() {
    "Begin Dz Test".print();
    try {
      Db:Relational:Test.new().main();
      Dz:AccountTest.new().main();
      Dz:ConfigTest.new().main();
      Dz:MediaIOTest.new().main();
    } catch (var e) {
      "Exception during test".print();
      e.print();
    }
    "End Dz Test".print();
  }

}
