//
//  format.swift
//  book-reader
//
//  Created by Phil Denhoff on 2023-10-15.
//

import Foundation

func formatDouble(_ value: Double) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  formatter.minimumFractionDigits = 0
  formatter.maximumFractionDigits = 16  // Adjust this value as needed for your specific requirements

  if let formattedString = formatter.string(from: NSNumber(value: value)) {
    return formattedString
  } else {
    return "NaN"  // Handle the case where the conversion fails, if needed
  }
}
