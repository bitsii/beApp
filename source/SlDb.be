use Db:SQLite:Database as SlDb;
class SlDb(DbDb) {
  
  pathNew(Path _dbp) self {
    super.pathNew(_dbp);
    //String dbAddr = "Data Source=" + dbp.toString("\\") + ";Version=3;";
    String dbAddr = "Data Source=test.db;Version=3;";
    new(dbAddr);
  }
  
  open() self {
    if (dbp.file.exists!) {
      String dbps = dbp.toString();
      emit(cs) {
        """
        SqliteConnection.CreateFile("test.db");
        bevi_conn = new SqliteConnection("Data Source=test.db;Version=3;");
        bevi_conn.Open();
        """
      }
      ("CREATED SQLITE CONN").print();
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

}
