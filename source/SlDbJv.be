// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use Db:SQLite:Database as SlDb;
use Db:Relational:Database as DbDb;
use IO:File:Path;

class SlDb(DbDb) {
  
  pathNew(Path _dbp) self {
    super.pathNew(_dbp); //dbp.toStringWithSeparator("/")
    String dbAddr = "jdbc:sqlite:" + dbp.toString();
    new(dbAddr);
    fields {
      Int busyTimeout = 30000;
    }
  }
  
  open() self {
    emit(jv) {
    """
      //Class.forName("");
    """
    }
    super.open();
    execute("PRAGMA journal_mode=WAL").close();
    execute("PRAGMA cache=shared").close();
    execute("PRAGMA read_uncommitted = true;").close();
    if (def(busyTimeout) && busyTimeout > 0) {
      execute("pragma busy_timeout=" + busyTimeout).close();
    }
  }
  
  copy() self {
    return(SlDb.pathNew(dbp));
  }

}
