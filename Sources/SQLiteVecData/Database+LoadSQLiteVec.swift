import CSQLiteVec
import GRDB
import SQLite3

extension Database {
  public func loadSQLiteVecExtension() throws {
    let code = sqlite3_vec_init(self.sqliteConnection, nil, nil)
    let resultCode = ResultCode(rawValue: code)
    if resultCode != .SQLITE_OK {
      throw DatabaseError(resultCode: resultCode, message: "Failed to load SQLiteVec extension.")
    }
  }
}
