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
  let seriesPosition: SeriesPosition?
  let comments: String?
  let number: Float?
  let fileUrl: URL?
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
    seriesPosition = fromLibraryBook.seriesPosition
    number = Float?.none
    comments = fromLibraryBook.comments
    fileUrl = fromLibraryBook.fileUrl
    if let coverImageUrl = fromLibraryBook.coverImageUrl {
      cover = genBookCoverImage(imageUrl: coverImageUrl)
    } else {
      cover = Image?.none
    }
  }

  init(
    title: String, customTitleSort: String?, authorList: [String], customAuthorSort: String?,
    seriesPosition: SeriesPosition?, number: Float?, fileUrl: URL? = URL?.none, cover: Image?,
    comments: String?
  ) {
    self.title = title
    self.sortableTitle = customTitleSort ?? title
    self.authorList = authorList
    self.sortableAuthorList = customAuthorSort ?? authorList.joined(separator: ", ")
    self.seriesPosition = seriesPosition
    self.number = number
    self.fileUrl = fileUrl
    self.cover = cover
    self.comments = comments
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
  @State private var sortOrder = [KeyPathComparator(\Book.id)]
  @State private var selection: Book.ID?

  var body: some View {
    HSplitView {
      Table(of: Book.self, selection: $selection, sortOrder: $sortOrder) {
        TableColumn("Cover") { book in
          VStack {
            let possibleCover = book.loadCover()
            if let cover = possibleCover {
              cover
                .resizable()
                .interpolation(Image.Interpolation.high)
                .aspectRatio(contentMode: .fit)
            }

          }.frame(maxWidth: 180)
        }
        .width(min: 35, max: 180)
        .alignment(TableColumnAlignment.center)
        TableColumn("Title", value: \.sortableTitle) { book in
          Text(book.title)
        }
        TableColumn("Authors", value: \.sortableAuthorList) { book in
          Text(book.authors())
        }
        TableColumn("Series") { book in
          if let seriesInfo = book.seriesPosition {
            Link(
              "\(seriesInfo.seriesName) #\(seriesInfo.position)",
              destination: URL(string: "https://www.goodreads.com/search")!.appending(queryItems: [
                URLQueryItem(name: "q", value: seriesInfo.seriesName)
              ]))
          }
        }
      } rows: {
        ForEach(bookList, id: \.id) { book in
          TableRow(book)
        }
      }
      .onAppear {
        initCalibreLibrary()
      }
      .onChange(of: sortOrder) { sortOrder in
        bookList.sort(using: sortOrder)
      }
      if let selection = selection,
        let selectedBook = bookList.first(where: { $0.id == selection })
      {
        VStack {
          GeometryReader { geometry in
            VSplitView {
              VStack {
                let possibleCover = selectedBook.loadCover()
                if let cover = possibleCover {
                  cover
                    .resizable()
                    .interpolation(Image.Interpolation.medium)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, alignment: .top)
                }
              }.frame(
                minHeight: geometry.size.height * 1 / 4, idealHeight: geometry.size.height * 2 / 3,
                maxHeight: .infinity)
              VStack(alignment: .leading) {
                Text(selectedBook.title).font(.largeTitle)
                Text(selectedBook.authors())
                Button {
                  if let url = selectedBook.fileUrl {
                    NSWorkspace.shared.open(url)
                  }
                } label: {
                  Label("Read", systemImage: "square.and.arrow.up")
                }
                Sidebar(html: selectedBook.comments ?? "")
              }
              .padding()
              .frame(
                minWidth: geometry.size.width, minHeight: geometry.size.height * 1 / 4,
                maxHeight: .infinity,
                alignment: .topLeading
              )
            }
            .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
          minWidth: 80, idealWidth: .infinity * 2 / 5, maxWidth: .infinity * 2 / 3
        )
      }
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
