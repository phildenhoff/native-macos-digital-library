//
//  ContentView.swift
//  book-reader
//
//  Created by Phil Denhoff on 2023-10-04.
//

import SwiftUI
import PhotosUI

struct Book: Identifiable {
    let title: String
    let customTitleSort: String?
    let authorList: [String]?
    let customAuthorSort: String?
    let series: String?
    let number: Float?
    let cover: Image
    let id = UUID()
    
    func authors() -> String {
        return authorList?.joined(separator: " & ") ?? ""
    }
    func titleSort() -> String {
        let titleWords = title.split(separator: " ")
        if (titleWords.first == "The") {
            return titleWords.suffix(from: 1).joined(separator: " ").appending(", The")
        }
        return title
    }
    func loadCover() -> Image {
        return cover
    }
}

private let bookList = [
    Book(title:"Atomic Habits", customTitleSort: String?.none, authorList:Array?.some(["James Clear"]), customAuthorSort: String?.none, series:String?.none, number:Float?.none, cover:Image("atomic-habits")),
    Book(title:"The Sad Bastard Cookbook", customTitleSort: String?.none, authorList:Array?.some(["Rachel A. Rosen", "Zilla Novikov"]), customAuthorSort: String?.none, series:String?.none, number:Float?.none, cover:Image("sad-bastard-cookbook")),
]

struct ContentView: View {
    var body: some View {
        Table(of: Book.self) {
            TableColumn("Cover") {book in
                VStack {
                    book.loadCover()
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 55, alignment: .topLeading)
                }.frame(maxWidth: 55)
            }
            .width(min: 35, max: 55)
            .alignment(TableColumnAlignment.center)
            TableColumn("Title", value: \.title)
            TableColumn("Title sort") {book in
                Text(book.titleSort())
            }
            TableColumn("Authors") {book in
                Text(book.authors())
            }
        } rows: {
            ForEach(bookList) { book in
                TableRow(book)
            }
        }
    }
}

#Preview {
    ContentView()
}
