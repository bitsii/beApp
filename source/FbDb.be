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
using FirebirdSql.Data.FirebirdClient;
"""
}
//not really working atm :-(

use Db:Firebird:Database as FbDb;
class FbDb(DbDb) {
  
  pathNew(Path _dbp) self {
    super.pathNew(_dbp);
    fields {
      String dbAddr = "ServerType=1;User=SYSDBA;" + 
        "Password=masterkey;Dialect=3;Database=" + dbp.toString("\\");
      //String dbAddr = "User=SYSDBA;Password=masterkey;Database=SampleDatabase.fdb;DataSource=localhost;Port=3050;Dialect=3;Charset=NONE;Role=;Connection lifetime=15;Pooling=true;MinPoolSize=0;MaxPoolSize=50;Packet Size=8192;ServerType=1;"
    }
    new(dbAddr);
  }
  
  open() self {
    if (dbp.file.exists!) {
      String dbps = dbp.toString();
      ("dbaddr " + dbAddr).print();
      ("dbps " + dbps).print();
      emit(cs) {
        """
        FbConnection.CreateDatabase(bevp_dbAddr.bems_toCsString());
        bevi_conn = new FbConnection(bevp_dbAddr.bems_toCsString());
        bevi_conn.Open();
        """
      }
      //("CREATED CONN").print();
    }
    super.open();
  }
  
  copy() self {
    return(FbDb.pathNew(dbp));
  }
  
  getStatement(String _stmt) DbSt {
    DbSt st = super.getStatement(_stmt);
    emit(cs) {
    """
    if (bevi_trans == null) {
      bevl_st.bevi_cmd = new FbCommand(
        beva__stmt.bems_toCsString(),
        (FbConnection)bevi_conn
        );
     } else {
       bevl_st.bevi_cmd = new FbCommand(
        beva__stmt.bems_toCsString(),
        (FbConnection)bevi_conn,
        (FbTransaction)bevi_trans
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
    ("STMT " + _stmt).print();
    DbSt st = super.getStatement(_stmt, vals);
    st.paramNames = paramNames;
    emit(cs) {
    """
    if (bevi_trans == null) {
      bevl_st.bevi_cmd = new FbCommand(
        beva__stmt.bems_toCsString(),
        (FbConnection)bevi_conn
        );
     } else {
       bevl_st.bevi_cmd = new FbCommand(
        beva__stmt.bems_toCsString(),
        (FbConnection)bevi_conn,
        (FbTransaction)bevi_trans
        );
     }
     """
     }
     return(st);
   }
   
   addParam(DbSt st, Int pos, String paramName, String paramValue) this {
      emit(cs) {
         """
         FbCommand fbc = (FbCommand) beva_st.bevi_cmd;
         fbc.Parameters.AddWithValue(beva_paramName.bems_toCsString(), beva_paramValue.bems_toCsString());
         """
         }
  }

}
