import Foundation
import SQLite3

struct CalibreBook: Identifiable {
  let id: Int
  let title: String
  let sortableTitle: String
  let sortableAuthorList: String
  let path: String
  let hasCover: Bool
  let orderInSeries: String
}

struct CalibreAuthor: Identifiable {
  let id: Int
  let name: String
  let nameSort: String
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
    let authorSortIndex = columnIndexByName["author_sort"],
    let pathIndex = columnIndexByName["path"],
    let seriesIndexIndex = columnIndexByName["series_index"],
    let hasCoverIndex = columnIndexByName["has_cover"],
    let title = sqlite3_column_text(statement, titleIndex),
    let titleSort = sqlite3_column_text(statement, titleSortIndex),
    let authorSort = sqlite3_column_text(statement, authorSortIndex),
    let path = sqlite3_column_text(statement, pathIndex)
  {
    let id = sqlite3_column_int(statement, idIndex)
    let hasCover = sqlite3_column_int(statement, hasCoverIndex)
    let orderInSeries = sqlite3_column_double(statement, seriesIndexIndex)

    let titleString = String(cString: title)
    let titleSortString = String(cString: titleSort)
    let authorSortString = String(cString: authorSort)
    let pathString = String(cString: path)
    let hasCoverBool = hasCover == 1

    return CalibreBook(
      id: Int(id),
      title: titleString,
      sortableTitle: titleSortString,
      sortableAuthorList: authorSortString,
      path: pathString,
      hasCover: hasCoverBool,
      orderInSeries: formatDouble(orderInSeries)
    )
  } else {
    return nil
  }
}

private func authorFromRow(statement: OpaquePointer, columnIndexByName: [String: Int32])
  -> CalibreAuthor?
{
  if let idIndex = columnIndexByName["id"],
    let nameIndex = columnIndexByName["name"],
    let nameSortIndex = columnIndexByName["sort"],
    let name = sqlite3_column_text(statement, nameIndex),
    let nameSort = sqlite3_column_text(statement, nameSortIndex)
  {
    let id = sqlite3_column_int(statement, idIndex)

    let nameString = String(cString: name)
    let nameSortString = String(cString: nameSort)

    return CalibreAuthor(id: Int(id), name: nameString, nameSort: nameSortString)
  } else {
    return nil
  }
}

func makeSqlQuery<TResult>(
  dbPointer: OpaquePointer, query: String,
  genResultFromRow: (OpaquePointer, [String: Int32]) -> TResult
) -> [TResult] {
  var statement: OpaquePointer? = nil
  var resultCollector = [TResult]()

  if sqlite3_prepare_v2(dbPointer, query, -1, &statement, nil) == SQLITE_OK {
    let columnIndexByName = getColumnIndexByName(statement: statement)

    while sqlite3_step(statement) == SQLITE_ROW {
      let rowResult = genResultFromRow(statement!, columnIndexByName)
      resultCollector.append(rowResult)
    }

    sqlite3_finalize(statement)
  } else {
    if let errorMessage = String(validatingUTF8: sqlite3_errmsg(dbPointer)) {
      print("Error executing query. Error: \(errorMessage)")
    }
  }

  return resultCollector
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

struct DbInitError: Error {
  let message: String
}

struct CalibreLibrary: Library {
  let libraryUrl: URL

  var bookList: [CalibreBook] = []
  var authorList: [CalibreAuthor] = []
  var db: OpaquePointer? = nil

  init(fromUrl: URL) throws {
    self.libraryUrl = fromUrl

    let dbUrl = buildMetadataDbUrl(libraryUrl: fromUrl)
    let dbOpenResult = sqlite3_open(dbUrl.path, &db)
    if dbOpenResult != SQLITE_OK {
      if let errorMessage = String(validatingUTF8: sqlite3_errmsg(db)) {
        print("Unable to open the database. Error: \(errorMessage)")
      }
      throw DbInitError(message: "Failed to open database at \(self.libraryUrl)")
    }

    let loadedBooks = loadBooksFromDb()
    bookList = loadedBooks
    let loadedAuthors = loadAuthorsFromDb()
    authorList = loadedAuthors
  }

  private func loadAuthorsFromDb() -> [CalibreAuthor] {
    let query = """
        SELECT
          id,
          name,
          sort
        FROM
          authors;
      """
    let authorResults = makeSqlQuery(dbPointer: db!, query: query) {
      (statement, columnIndexByName) -> CalibreAuthor in
      return authorFromRow(statement: statement, columnIndexByName: columnIndexByName)!
    }
    return authorResults
  }

  private func loadBooksFromDb() -> [CalibreBook] {
    let query = "SELECT * FROM books;"
    let bookResults = makeSqlQuery(dbPointer: db!, query: query) {
      (statement, columnIndexByName) -> CalibreBook in
      return calibreBookFromRow(statement: statement, columnIndexByName: columnIndexByName)!
    }
    return bookResults
  }

  private func fileUrlForBook(book: CalibreBook) -> URL? {
    let query = """
        SELECT
          id,
          book,
          format,
          name
        FROM
          data
        WHERE
          book = \(book.id)
        LIMIT 1;
      """
    let fileNamesAndTypesResults = makeSqlQuery(dbPointer: db!, query: query) {
      (statement, columnIndexByName) -> URL? in
      if let nameIndex = columnIndexByName["name"],
        let formatIndex = columnIndexByName["format"],
        let name = sqlite3_column_text(statement, nameIndex),
        let format = sqlite3_column_text(statement, formatIndex)
      {
        let nameStr = String(cString: name)
        let formatStr = String(cString: format)
        return libraryUrl.appending(component: book.path).appending(component: nameStr)
          .appendingPathExtension(formatStr)
      } else {
        return URL?.none
      }
    }
    let firstResult = fileNamesAndTypesResults.first
    if let firstResult {
      return firstResult
    } else {
      return URL?.none
    }
  }
  private func comments(bookId: Int) -> String? {
    let query = """
        SELECT
          text
        FROM
          comments
        WHERE
          book = \(bookId)
        LIMIT 1;
      """
    let commentsResults = makeSqlQuery(dbPointer: db!, query: query) {
      (statement, columnIndexByName) -> String? in
      if let textIndex = columnIndexByName["text"],
        let text = sqlite3_column_text(statement, textIndex)
      {
        return String(cString: text)
      } else {
        return String?.none
      }
    }
    if let firstResult = commentsResults.first {
      return firstResult
    } else {
      return String?.none
    }
  }

  private func seriesName(bookId: Int) -> String? {
    let query = """
      SELECT
          series.name as name,
          series.sort as sort
      FROM
          books_series_link
          INNER JOIN series ON books_series_link.series = series.id
      WHERE
          books_series_link.book = \(bookId)
      LIMIT 1;
      """
    let seriesResults = makeSqlQuery(dbPointer: db!, query: query) {
      (statement, columnIndexByName) -> String in
      if let nameIndex = columnIndexByName["name"],
        let name = sqlite3_column_text(statement, nameIndex)
      {
        return String(cString: name)
      } else {
        return ""
      }
    }
    return seriesResults.first
  }

  private func authorsForBook(bookId: Int) -> [String] {
    let query = """
        SELECT
          authors.name
        FROM
          books_authors_link
        INNER JOIN
          authors
        ON
          books_authors_link.author = authors.id
        WHERE
          books_authors_link.book = \(bookId);
      """
    let authorResults = makeSqlQuery(dbPointer: db!, query: query) {
      (statement, columnIndexByName) -> String in
      if let nameIndex = columnIndexByName["name"],
        let name = sqlite3_column_text(statement, nameIndex)
      {
        return String(cString: name)
      } else {
        return ""
      }
    }
    return authorResults
  }

  func listBooks() -> [LibraryBook] {
    return bookList.map { cb in
      let authors = authorsForBook(bookId: cb.id)
      var sp = SeriesPosition?.none

      if let seriesName = seriesName(bookId: cb.id) {
        sp = SeriesPosition(seriesName: seriesName, position: cb.orderInSeries)
      }

      return LibraryBook(
        title: cb.title,
        authorList: authors,
        libraryId: String(cb.id),
        coverImageUrl: libraryUrl.appending(component: cb.path).appending(component: "cover.jpg"),
        fileUrl: fileUrlForBook(book: cb),
        sortableTitle: cb.sortableTitle,
        sortableAuthorList: cb.sortableAuthorList,
        comments: comments(bookId: cb.id),
        seriesPosition: sp
      )
    }
  }

  func listAuthors() -> [LibraryBook] {
    return []
  }
}
