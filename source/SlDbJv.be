// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use Db:SQLite:Database as SlDb;
use Db:Relational:Database as DbDb;
use IO:File:Path;

emit(jv) {
"""
import java.util.HashMap;
import java.sql.*;
//import com.mchange.v2.c3p0.ComboPooledDataSource;
import org.sqlite.javax.SQLiteConnectionPoolDataSource;
import biz.source_code.miniConnectionPoolManager.MiniConnectionPoolManager;
"""
}

class SlDb(DbDb) {

emit(jv) {
"""
/*public static HashMap<String, ComboPooledDataSource> dataSources = new HashMap<String, ComboPooledDataSource>();
public static synchronized Connection getConnection(String url) throws Exception {
  try {
    ComboPooledDataSource ds = dataSources.get(url);
    if (ds == null) {
      ds = new ComboPooledDataSource();
      ds.setDriverClass("org.h2.Driver");
      ds.setJdbcUrl(url);
      dataSources.put(url, ds);
    }
    return ds.getConnection();
  } catch (Exception e) {
    System.out.println("exception in getConnection " + e.getMessage());
    e.printStackTrace();
    throw e;
  }
}*/

public static HashMap<String, MiniConnectionPoolManager> dataSources = new HashMap<String, MiniConnectionPoolManager>();
public static synchronized Connection getConnection(String url) throws Exception {
  try {
    MiniConnectionPoolManager ds = dataSources.get(url);
    if (ds == null) {
      SQLiteConnectionPoolDataSource dataSource = new SQLiteConnectionPoolDataSource();
      dataSource.setUrl(url);
      ds = new MiniConnectionPoolManager(dataSource, 5);
      dataSources.put(url, ds);
    }
    return ds.getConnection();
   
  } catch (Exception e) {
    System.out.println("exception in getConnection " + e.getMessage());
    e.printStackTrace();
    throw e;
  }
}

"""
}
  
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
      bevi_conn = getConnection(bevp_db.bems_toJvString());
    """
    }
    //super.open();
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
