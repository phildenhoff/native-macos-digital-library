import Foundation

public struct LibraryBook {
  let title: String
  let authorList: [String]
  let coverImageUrl: URL?

  // ID of the book within the library
  private let libraryId: String
  private let sortTitle: String? = String?.none
  private let sortAuthorList: [String]? = [String]?.none

  init(title: String, authorList: [String], libraryId: String, coverImageUrl: URL? = URL?.none) {
    self.title = title
    self.authorList = authorList
    self.libraryId = libraryId
    self.coverImageUrl = coverImageUrl
  }

  func sortableTitle() -> String {
    return sortTitle ?? title
  }

  func sortableAuthorList() -> String {
    return (sortAuthorList ?? authorList).joined(separator: ", ")
  }
}

protocol Library {
  func listBooks() -> [LibraryBook]
  func listAuthors() -> [LibraryBook]
}
