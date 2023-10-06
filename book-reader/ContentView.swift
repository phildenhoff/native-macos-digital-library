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
  let customTitleSort: String?
  let authorList: [String]?
  let customAuthorSort: String?
  let series: String?
  let number: Float?
  let path: String?
  var cover: Image?
  var id = UUID()

  func authors() -> String {
    return authorList?.joined(separator: " & ") ?? ""
  }
  func titleSort() -> String {
    return customTitleSort ?? title
  }
  func loadCover() -> Image? {
    return cover
  }
}

func genBookCoverImage(libraryUrl: URL, bookPath: String) -> Image? {
  let coverUrl = genCalibreBookCoverUrl(libraryUrl: libraryUrl, bookPath: bookPath)
  do {
    let imageData = try Data(contentsOf: coverUrl)
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
      TableColumn("Title sort") { book in
        Text(book.titleSort())
      }
      TableColumn("Authors") { book in
        Text(book.authors())
      }
    } rows: {
      ForEach(bookList, id: \.id) { book in
        TableRow(book)
      }
    }
    .onAppear {
      openCalibreLibrary()
    }
  }

  func addBooksToBooklist(list: [Book]) {
    let updatedBookList = bookList + list
    DispatchQueue.main.async {
      self.bookList = updatedBookList
    }
  }

  func openCalibreLibrary() {
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
          print("calibreLibraryPath", calibreLibraryUrl)
          readLibraryMetadata(libraryUrl: calibreLibraryUrl)
        }
      }
    }
  }

  func readLibraryMetadata(libraryUrl: URL) {
    let calibreLibraryPath = libraryUrl
    // let calibreLibraryPath = URL(filePath: "/Users/phil/dev/macos-book-app/sample-library/")
    let calibreBookList = readBooksFromCalibreDb(libraryUrl: calibreLibraryPath)
    let newBooks: [Book] = calibreBookList.map { cb in
      var cover: Image? = nil

      if cb.hasCover {
        cover = genBookCoverImage(libraryUrl: calibreLibraryPath, bookPath: cb.path)
      }

      return Book(
        title: cb.title, customTitleSort: cb.titleSort, authorList: [String]?.none,
        customAuthorSort: String?.none, series: String?.none, number: Float?.none, path: cb.path,
        cover: cover)
    }

    addBooksToBooklist(list: newBooks)
  }
}

#Preview {
  ContentView()
}
