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
    let titleWords = title.split(separator: " ")
    if titleWords.first == "The" {
      return titleWords.suffix(from: 1).joined(separator: " ").appending(", The")
    }
    return title
  }
  func loadCover() -> Image? {
    return cover
  }
}

struct ContentView: View {
  @State private var bookList = [
    Book(
      title: "Atomic Habits", customTitleSort: String?.none,
      authorList: Array?.some(["James Clear"]), customAuthorSort: String?.none,
      series: String?.none, number: Float?.none, path: String?.none, cover: Image("atomic-habits")),
    Book(
      title: "The Sad Bastard Cookbook", customTitleSort: String?.none,
      authorList: Array?.some(["Rachel A. Rosen", "Zilla Novikov"]), customAuthorSort: String?.none,
      series: String?.none, number: Float?.none, path: String?.none, cover: Image?.none),
  ]

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
      // Perform your asynchronous task here, which updates bookList
      readLibraryMetadata()
      requestImagePermissions()
    }
  }

  func addImagesToBooks(imageUrls: [URL]) {
    imageUrls.forEach({ url in
      // You can now read the selected image file using the URL
      do {
        let imageData = try Data(contentsOf: url)
        if let image = NSImage(data: imageData) {
          DispatchQueue.global().async {
            // Update your view with the loaded image on the main thread

            var updatedBook = bookList.last
            updatedBook?.cover = Image(nsImage: image)

            updatedBook?.id = UUID()
            let newBookList = [bookList[0], updatedBook!]
            DispatchQueue.main.async {
              self.bookList = newBookList
            }
          }
        }
      } catch {
        // Handle any errors while reading the file
        print("errored trying to requrest image perms")
      }
    })
  }

  func requestImagePermissions() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Select your calibre library folder"
    openPanel.showsResizeIndicator = true
    openPanel.showsHiddenFiles = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.canChooseFiles = false
    openPanel.allowsMultipleSelection = false

    return openPanel.begin { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        let directory = openPanel.url
        print(openPanel.urls)
        addImagesToBooks(imageUrls: openPanel.urls)
      }
    }
  }

  func addCalibreBookToList(cb: CalibreBook) {

  }

  func readLibraryMetadata() {
    let calibreBookList = x()
    let newBooks: [Book] = calibreBookList.map { cb in
      var cover: Image? = nil

      if cb.hasCover {
        let coverUrl = calibreLibraryPath.appendingPathComponent(cb.path).appendingPathComponent(
          "cover.jpg")
        do {
          let imageData = try Data(contentsOf: coverUrl)
          if let image = NSImage(data: imageData) {
            cover = Image(nsImage: image)
          }
        } catch {
          print("errored trying to read cover")
        }
      }

      return Book(
        title: cb.title, customTitleSort: String?.none, authorList: [String]?.none,
        customAuthorSort: String?.none, series: String?.none, number: Float?.none, path: cb.path,
        cover: cover)
    }

    let updatedBookList = bookList + newBooks
    DispatchQueue.main.async {
      self.bookList = updatedBookList
    }
  }
}

#Preview {
  ContentView()
}
