// Copyright 2015 Craig Welch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

emit(cs) {
"""
using System;
using System.Data;
using System.Data.Common;
using Mono.Data.Sqlite;
"""
}

use Db:Relational:Database as DbDb;
use Db:Relational:Statement as DbSt;

use Db:SQLite:Database as SlDb;
class SlDb(DbDb) {
  
  pathNew(IO:File:Path _dbp) self {
    super.pathNew(_dbp);
    String dbAddr = "Data Source=" + dbp.toString() + ";Version=3;";
    //String dbAddr = "Data Source=test.db;Version=3;";
    new(dbAddr);
  }
  
  open() self {
    if (dbp.file.exists!) {
      String dbps = dbp.toString();
      emit(cs) {
        """
        SqliteConnection.CreateFile(bevl_dbps.bems_toCsString());
        """
      }
      //("CREATED SQLITE CONN").print();
    }
    emit(cs) {
    """
    bevi_conn = new SqliteConnection(bevp_db.bems_toCsString());
    bevi_conn.Open();
    """
    }
    super.open();
  }
  
  copy() self {
    return(SlDb.pathNew(dbp));
  }
  
  getStatement(String _stmt) DbSt {
    DbSt st = super.getStatement(_stmt);
    emit(cs) {
    """
    if (bevi_trans == null) {
      bevl_st.bevi_cmd = new SqliteCommand(
        beva__stmt.bems_toCsString(),
        (SqliteConnection)bevi_conn
        );
     } else {
       bevl_st.bevi_cmd = new SqliteCommand(
        beva__stmt.bems_toCsString(),
        (SqliteConnection)bevi_conn,
        (SqliteTransaction)bevi_trans
        );
     }
     """
     }
     return(st);
   }
   
   getStatement(String _stmt, List vals) DbSt {
    List paramNames = List.new();
    for (any val in vals) {
      String pname = System:Random.getString(4);
      while (def(_stmt.find(pname))) {
        pname = System:Random.getString(4);
      }
      paramNames += pname;
      _stmt = _stmt.swapFirst("?", "@" + pname);
    }
    //("STMT " + _stmt).print();
    DbSt st = super.getStatement(_stmt, vals);
    st.paramNames = paramNames;
    emit(cs) {
    """
    if (bevi_trans == null) {
      bevl_st.bevi_cmd = new SqliteCommand(
        beva__stmt.bems_toCsString(),
        (SqliteConnection)bevi_conn
        );
     } else {
       bevl_st.bevi_cmd = new SqliteCommand(
        beva__stmt.bems_toCsString(),
        (SqliteConnection)bevi_conn,
        (SqliteTransaction)bevi_trans
        );
     }
     """
     }
     return(st);
   }
   
   addParam(DbSt st, Int pos, String paramName, String paramValue) this {
      emit(cs) {
         """
         SqliteCommand fbc = (SqliteCommand) beva_st.bevi_cmd;
         fbc.Parameters.AddWithValue(beva_paramName.bems_toCsString(), beva_paramValue.bems_toCsString());
         """
         }
  }

}
