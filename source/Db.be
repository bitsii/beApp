/*
 * Copyright (c) 2015-2023, the Bennt App Authors.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Licensed under the BSD 2-Clause License (the "License").
 * See the LICENSE file in the project root for more information.
 *
 */

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
      Map kvDbNxt = Map.new();
      IO:Log log = IO:Logs.get(self);
      Path dataPath = _dataPath;
    }
  }
  
  get(String name) KvDb {
    fields {
      Int appKvPoolSize;
    }
    try {
      lock.lock();
      List kdbl = kvDbs.get(name);
      if (undef(kdbl)) {
        if (undef(appKvPoolSize)) {
          String appKvPoolSizeS = params.getFirst("appKvPoolSize");
          if (TS.notEmpty(appKvPoolSizeS)) {
            appKvPoolSize = Int.new(appKvPoolSizeS);
          } else {
            appKvPoolSize = 1;
          }
        }
        kdbl = List.new();
        String sdbClass = params.getFirst("sdbClass");
        if (TS.isEmpty(sdbClass)) {
          sdbClass = "Db:MemFileStoreKeyValue";
        }
        for (Int i = 0;i < appKvPoolSize;i++) {
          any cckdb = System:Objects.createInstance(sdbClass);
          KvDb kdb = KvDb.sdbNew(cckdb.pathParamsNew(dataPath.copy(), params, name).open());
          kdb.create();
          kdbl[i] = kdb;
        }
        kvDbs.put(name, kdbl);
      }
      Int nv = kvDbNxt[name];
      if (undef(nv)) {
        nv = 0;
        kvDbNxt[name] = nv;
      } else {
        nv++;
        if (nv >= kdbl.length) {
          nv.setValue(0);
        }
      }
      kdb = kdbl[nv];
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
