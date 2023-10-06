//
//  library.swift
//  book-reader
//
//  Created by Phil Denhoff on 2023-10-05.
//

import Foundation
import SwiftUI

func coverImageUrl() -> URL? {
  //    let directoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  //    let fileUrl = directoryUrl.appendingPathComponent("cover.jpeg")
  //    let fileUrl = URL(fileURLWithPath: "cover", relativeTo: directoryUrl).appendingPathExtension("jpeg")

  do {
    let directoryUrl = try FileManager.default
      .url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let fileURL =
      directoryUrl
      .appendingPathComponent("cover.jpeg")
    return fileURL
  } catch {
    print("error reading data")
    return URL?.none
  }
}

func coverImage() -> NSImage? {
  let maybeImageUrl = coverImageUrl()
  if let imgUrl = maybeImageUrl {
    print("absoluteString: \(imgUrl.absoluteString)")
    return NSImage(byReferencing: imgUrl)
  } else {
    print("maybeImageUrl is none", maybeImageUrl == nil)
    return NSImage?.none
  }
}
