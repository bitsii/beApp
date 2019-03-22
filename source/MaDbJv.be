// Copyright 2015 Craig Welch
//
// Licensed under the MIT license. See LICENSE.txt file in the project root 
// for full license information.

use Db:SQLite:Database as SlDb;
use Db:Relational:Database as DbDb;
use IO:File:Path;
use Db:Maria:Database as MaDb;

class MaDb(DbDb) {
  
  new() self {
    fields {
      String host;
      String port;
      String user;
      String pass;
      System:Parameters params;
    }
  }
  
  paramsNew(System:Parameters _params) self {
    //("in paramsnew").print();
    params = _params;
    host = params.getFirst("maDbHost");
    port = params.getFirst("maDbPort");
    db = params.getFirst("maDbDb");
    user = params.getFirst("maDbUser");
    pass = params.getFirst("maDbPass");
    if (TS.isEmpty(db)) {
      ("db empty").print();
    }
    if (TS.isEmpty(user) || TS.isEmpty(pass)) {
      ("user, pass empty").print();
    }
    if (TS.isEmpty(host)) {
      host = "localhost";
    }
    if (TS.isEmpty(port)) {
      port = "3306";
    }
    if (TS.notEmpty(user)) {
      String userbit = "user=" + user;
    } else {
      userbit = "";
    }
    if (TS.notEmpty(pass)) {
      String passbit = "password=" + pass;
    } else {
      passbit = "";
    }
    if (TS.notEmpty(userbit) || TS.notEmpty(passbit)) {
      String q = "?";
    } else {
      q = "";
    }
    if (TS.notEmpty(userbit) && TS.notEmpty(passbit)) {
      String a = "&";
    } else {
      a = "";
    }
    String dbAddr = "jdbc:mariadb://" + host + ":" + port + "/" + db + q + userbit + a + passbit;
    //("dbAddr mariadb " + dbAddr).print();
    new(dbAddr);
  }
  
  open() self {
    emit(jv) {
    """
      //Class.forName("");
    """
    }
    super.open();
  }
  
  copy() self {
    return(MaDb.paramsNew(params));
  }
  
  timeoutGet() Int {
    //28800
    //return(28000);
    //return(14000);
    return(600);
  }

}
