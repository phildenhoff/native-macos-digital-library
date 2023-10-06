//
//  ContentView.swift
//  book-reader
//
//  Created by Phil Denhoff on 2023-10-04.
//

import PhotosUI
import SwiftUI

struct Book: Identifiable {
  let title: String
  let sortableTitle: String
  let authorList: [String]
  let sortableAuthorList: String
  let series: String?
  let number: Float?
  let path: String?
  var cover: Image?
  var id = UUID()

  func authors() -> String {
    return authorList.joined(separator: " & ")
  }
  func loadCover() -> Image? {
    return cover
  }

  init(fromLibraryBook: LibraryBook) {
    title = fromLibraryBook.title
    sortableTitle = fromLibraryBook.sortableTitle()
    authorList = fromLibraryBook.authorList
    sortableAuthorList = fromLibraryBook.sortableAuthorList()
    series = String?.none
    number = Float?.none
    path = String?.none
    if let coverImageUrl = fromLibraryBook.coverImageUrl {
      cover = genBookCoverImage(imageUrl: coverImageUrl)
    } else {
      cover = Image?.none
    }
  }

  init(
    title: String, customTitleSort: String?, authorList: [String], customAuthorSort: String?,
    series: String?, number: Float?, path: String?, cover: Image?
  ) {
    self.title = title
    self.sortableTitle = customTitleSort ?? title
    self.authorList = authorList
    self.sortableAuthorList = customAuthorSort ?? authorList.joined(separator: ", ")
    self.series = series
    self.number = number
    self.path = path
    self.cover = cover
  }
}

func genBookCoverImage(imageUrl: URL) -> Image? {
  do {
    let imageData = try Data(contentsOf: imageUrl)
    if let image = NSImage(data: imageData) {
      return Image(nsImage: image)
    }
  } catch {
    print("errored trying to read cover")
  }
  return Image?.none
}

struct ContentView: View {
  @State private var bookList: [Book] = []

  var body: some View {
    Table(of: Book.self) {
      TableColumn("Cover") { book in
        VStack {
          let possibleCover = book.loadCover()
          if let cover = possibleCover {
            cover
              .resizable()
              .aspectRatio(contentMode: .fit)
          }

        }.frame(maxWidth: 180)
      }
      .width(min: 35, max: 180)
      .alignment(TableColumnAlignment.center)
      TableColumn("Title", value: \.title)
      TableColumn("Title (sort order)") { book in
        Text(book.sortableTitle)
      }
      TableColumn("Authors") { book in
        Text(book.authors())
      }
      TableColumn("Authors (sort order)") { book in
        Text(book.sortableAuthorList)
      }
    } rows: {
      ForEach(bookList, id: \.id) { book in
        TableRow(book)
      }
    }
    .onAppear {
      initCalibreLibrary()
    }
  }

  private func addBooksToBooklist(list: [Book]) {
    let updatedBookList = bookList + list
    DispatchQueue.main.async {
      self.bookList = updatedBookList
    }
  }

  func initCalibreLibrary() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Select your calibre library folder"
    openPanel.showsResizeIndicator = true
    openPanel.showsHiddenFiles = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = false
    openPanel.canChooseFiles = false
    openPanel.allowsMultipleSelection = false

    return openPanel.begin { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        if let calibreLibraryUrl = openPanel.url {
          readLibraryDatabase(libraryUrl: calibreLibraryUrl)
        }
      }
    }
  }

  func readLibraryDatabase(libraryUrl: URL) {
    do {
      let library: Library = try CalibreLibrary(fromUrl: libraryUrl)
      let newBooks: [Book] = library.listBooks().map { lb in
        Book(fromLibraryBook: lb)
      }
      addBooksToBooklist(list: newBooks)
    } catch {
      print("oh")
    }
  }
}

#Preview {
  ContentView()
}
