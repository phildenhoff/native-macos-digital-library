import Foundation
import SQLite3

let calibreLibraryPath = URL(filePath: "/Users/phil/dev/macos-book-app/sample-library/")

struct CalibreBook {
  let id = UUID()
  let title: String
  let path: String
  let hasCover: Bool
}

func buildMetadataDbUrl(libraryPath: URL) -> URL {
  let metadataPath = libraryPath.appending(path: "/metadata.db")
  return metadataPath
}

func calibreBookFromRow(statement: OpaquePointer, columnIndexByName: [String: Int32])
  -> CalibreBook?
{
  if let titleIndex = columnIndexByName["title"],
    let pathIndex = columnIndexByName["path"],
    let hasCoverIndex = columnIndexByName["has_cover"],
    let title = sqlite3_column_text(statement, titleIndex),
    let path = sqlite3_column_text(statement, pathIndex)
  {
    let hasCover = sqlite3_column_int(statement, hasCoverIndex)
    let titleString = String(cString: title)
    let pathString = String(cString: path)
    let hasCoverBool = hasCover == 1
    return CalibreBook(title: titleString, path: pathString, hasCover: hasCoverBool)
  } else {
    return nil
  }
}

func genBookCoverUrl(book: CalibreBook) -> URL {
  return calibreLibraryPath.appendingPathComponent(book.path).appendingPathComponent("cover.jpg")
}

func readBooksFromCalibreDb() -> [CalibreBook] {
  let metadataDbUrl = buildMetadataDbUrl(libraryPath: calibreLibraryPath)
  var db: OpaquePointer? = nil

  if sqlite3_open(metadataDbUrl.path, &db) == SQLITE_OK {
    let query = "SELECT * FROM books;"
    var statement: OpaquePointer? = nil

    if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
      var calibreBooks = [CalibreBook]()
      // Get the number of columns in the result set
      let columnCount = sqlite3_column_count(statement)

      // Create a dictionary to map column names to their indices
      var columnIndexByName = [String: Int32]()
      for i in 0..<columnCount {
        if let columnName = sqlite3_column_name(statement, i) {
          let columnNameString = String(cString: columnName)
          columnIndexByName[columnNameString] = Int32(i)
        }
      }

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
