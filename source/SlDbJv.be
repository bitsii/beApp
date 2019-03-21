// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use Db:SQLite:Database as SlDb;
use Db:Relational:Database as DbDb;
use IO:File:Path;

class SlDb(DbDb) {
  
  pathNew(Path _dbp) self {
    super.pathNew(_dbp); //dbp.toStringWithSeparator("/")
    String dbAddr = "jdbc:sqlite:" + dbp.toString();
    new(dbAddr);
    fields {
      Int busyTimeout = 1000;
    }
  }
  
  open() self {
    emit(jv) {
    """
      //Class.forName("");
    """
    }
    super.open();
    if (def(busyTimeout) && busyTimeout > 0) {
      execute("pragma busy_timeout=" + busyTimeout);
    }
  }
  
  copy() self {
    return(SlDb.pathNew(dbp));
  }

}
