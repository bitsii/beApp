// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use IO:File:Path;
use IO:File;
use Test:Assertions as Assert;
use System:Thread:Lock;
use System:Parameters;
use Container:LinkedList;
use Container:LinkedList:Node;

use System:Thread:ContainerLocker as CLocker;
use Db:KeyValue as KvDb;
class KvDb(CLocker) {
  
  sdbNew(any _sdb) {
    super.new(_sdb);
  }
  
  create() self {
    container.create();
  }
  
  open() self {
    container.open();
  }
  
  drop() self {
    container.drop();
  }
  
}

use Db:KeyValueDbs as KvDbs;

class KvDbs {

  new(Parameters _params, Path _dataPath) self {
    fields {
      Parameters params = _params;
      Lock lock = Lock.new();
      Map kvDbs = Map.new();
      IO:Log log =@ IO:Logs.get(self);
      Path dataPath = _dataPath;
    }
  }
  
  get(String name) KvDb {
    fields {
      Int appKvPoolSize;
    }
    try {
      lock.lock();
      if (undef(appKvPoolSize)) {
        String appKvPoolSizeS = params.getFirst("appKvPoolSize");
        if (TS.notEmpty(appKvPoolSizeS)) {
          appKvPoolSize = Int.new(appKvPoolSizeS);
        } else {
          appKvPoolSize = 3;
        }
      }
      LinkedList kdbl = kvDbs.get(name);
      if (undef(kdbl)) {
        kdbl = LinkedList.new();
        String sdbClass = params.getFirst("sdbClass");
        if (TS.isEmpty(sdbClass)) {
          sdbClass = "Db:MemFileStoreKeyValue";
        }
        for (Int i = 0;i < appKvPoolSize;i++=) {
          any cckdb = createInstance(sdbClass);
          KvDb kdb = KvDb.sdbNew(cckdb.pathNew(dataPath.copy(), name).open());
          kdb.create();
          kdbl.addValueWhole(kdb);
        }
        kvDbs.put(name, kdbl);
      }
      Node an = kdbl.firstNode;
      kdbl.deleteNode(an);
      kdbl.appendNode(an);
      kdb = an.held;
      lock.unlock();
    } catch (any e) {
      lock.unlock();
      log.error("exception during getKvDb");
      if (def(e)) { log.error("ex " + e); }
    }
    return(kdb);
  }
  
  close() {
    log.log("closing kvdbs");
    try {
      lock.lock();
      for (any kvle in kvDbs) {
        for (any kv in kvle.value) {
          kv.close();
        }
      }
      kvDbs = Map.new();
      lock.unlock();
    } catch (any e) {
      lock.unlock();
      log.error("exception during closeKvDbs");
      if (def(e)) { log.error("ex " + e); }
    }
  }

}
