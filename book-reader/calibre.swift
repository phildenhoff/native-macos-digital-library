import Foundation
import SQLite3

struct CalibreBook {
  let id = UUID()
  let calibreId: Int
  let title: String
  let titleSort: String
  let path: String
  let hasCover: Bool
  let orderInSeries: Int
}

private func buildMetadataDbUrl(libraryUrl: URL) -> URL {
  let metadataPath = libraryUrl.appending(path: "/metadata.db")
  return metadataPath
}

private func calibreBookFromRow(statement: OpaquePointer, columnIndexByName: [String: Int32])
  -> CalibreBook?
{
  if let idIndex = columnIndexByName["id"],
    let titleIndex = columnIndexByName["title"],
    let titleSortIndex = columnIndexByName["sort"],
    let pathIndex = columnIndexByName["path"],
    let seriesIndexIndex = columnIndexByName["series_index"],
    let hasCoverIndex = columnIndexByName["has_cover"],
    let title = sqlite3_column_text(statement, titleIndex),
    let titleSort = sqlite3_column_text(statement, titleSortIndex),
    let path = sqlite3_column_text(statement, pathIndex)
  {
    let id = sqlite3_column_int(statement, idIndex)
    let hasCover = sqlite3_column_int(statement, hasCoverIndex)
    let orderInSeries = sqlite3_column_int(statement, seriesIndexIndex)

    let titleString = String(cString: title)
    let titleSortString = String(cString: titleSort)
    let pathString = String(cString: path)
    let hasCoverBool = hasCover == 1

    return CalibreBook(
      calibreId: Int(id), title: titleString, titleSort: titleSortString, path: pathString,
      hasCover: hasCoverBool, orderInSeries: Int(orderInSeries))
  } else {
    return nil
  }
}

private func getColumnIndexByName(statement: OpaquePointer?) -> [String: Int32] {
  let columnCount = sqlite3_column_count(statement)

  var columnIndexByName = [String: Int32]()
  for i in 0..<columnCount {
    if let columnName = sqlite3_column_name(statement, i) {
      let columnNameString = String(cString: columnName)
      columnIndexByName[columnNameString] = Int32(i)
    }
  }

  return columnIndexByName
}

func genCalibreBookCoverUrl(libraryUrl: URL, bookPath: String) -> URL {
  return libraryUrl.appendingPathComponent(bookPath).appendingPathComponent("cover.jpg")
}

func readBooksFromCalibreDb(libraryUrl: URL) -> [CalibreBook] {
  let metadataDbUrl = buildMetadataDbUrl(libraryUrl: libraryUrl)
  var db: OpaquePointer? = nil

  if sqlite3_open(metadataDbUrl.path, &db) == SQLITE_OK {
    let query = "SELECT * FROM books;"
    var statement: OpaquePointer? = nil

    if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
      var calibreBooks = [CalibreBook]()

      let columnIndexByName = getColumnIndexByName(statement: statement)

      while sqlite3_step(statement) == SQLITE_ROW {
        let possibleBook = calibreBookFromRow(
          statement: statement!, columnIndexByName: columnIndexByName)
        if let cBook = possibleBook {
          calibreBooks.append(cBook)
        }
      }

      sqlite3_finalize(statement)
      return calibreBooks
    } else {
      if let errorMessage = String(validatingUTF8: sqlite3_errmsg(db)) {
        print("Error executing query. Error: \(errorMessage)")
      }
      return []
    }
  } else {
    if let errorMessage = String(validatingUTF8: sqlite3_errmsg(db)) {
      print("Unable to open the database. Error: \(errorMessage)")
    }
    return []
  }
}
