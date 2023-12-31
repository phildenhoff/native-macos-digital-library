import Foundation

struct SeriesPosition {
  let seriesName: String
  let position: String
}

public struct LibraryBook {
  let title: String
  let authorList: [String]
  let coverImageUrl: URL?
  let fileUrl: URL?
  let comments: String?
  let seriesPosition: SeriesPosition?

  // ID of the book within the library
  private let libraryId: String
  private let customSortTitle: String?
  private let customSortAuthorList: String?

  init(
    title: String, authorList: [String], libraryId: String, coverImageUrl: URL? = URL?.none,
    fileUrl: URL? = URL?.none,
    sortableTitle: String? = String?.none, sortableAuthorList: String? = String?.none,
    comments: String? = String?.none, seriesPosition: SeriesPosition? = SeriesPosition?.none
  ) {
    self.title = title
    self.authorList = authorList
    self.libraryId = libraryId
    self.coverImageUrl = coverImageUrl
    self.fileUrl = fileUrl
    self.customSortTitle = sortableTitle
    self.customSortAuthorList = sortableAuthorList
    self.comments = comments
    self.seriesPosition = seriesPosition
  }

  func sortableTitle() -> String {
    return customSortTitle ?? title
  }

  func sortableAuthorList() -> String {
    return customSortAuthorList ?? authorList.joined(separator: ", ")
  }
}

protocol Library {
  func listBooks() -> [LibraryBook]
  func listAuthors() -> [LibraryBook]
}
