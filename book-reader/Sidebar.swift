import SwiftUI
import Foundation
import WebKit

import AppKit

extension NSColor {
    func toHex() -> String {
        if let rgbColor = usingColorSpaceName(NSColorSpaceName.calibratedRGB) {
            let red = Int(rgbColor.redComponent * 255)
            let green = Int(rgbColor.greenComponent * 255)
            let blue = Int(rgbColor.blueComponent * 255)
            return String(format: "#%02X%02X%02X", red, green, blue)
        }
        return "#000000" // Default to black if unable to convert
    }
    static func fromHex(_ hex: String) -> NSColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        return NSColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}


struct Sidebar: View {
    let html: String;
    let htmlContent: String
    
    init(html: String) {
        self.html = html
        self.htmlContent = """
            <html>
                <head>
                    <style>
                        body {
                            font-family: "San Francisco", Arial, sans-serif;
                            font-size: 16px;
                            color: #dfdfdf;
                            background-color: #2b2c2a;
                            margin: 16px;
                            cursor: default;
                            -webkit-user-select: none; /* Safari, Chrome, Edge */
                            -moz-user-select: none; /* Firefox */
                            -ms-user-select: none; /* IE 10+ */
                            user-select: none; /* Standard syntax */
                        }

                        strong {
                            font-weight: bold;
                        }
            
                        @media (prefers-color-scheme: light) {
                          body {
                            color: #242424;
                            background-color: #edeeed;
                          }
                        }
                    </style>
                </head>
                <body>
                    \(html)
                </body>
            </html>
            """
    }

    var body: some View {
        WebView(htmlString: htmlContent)
    }
}

struct WebView: NSViewRepresentable {
    let htmlString: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        Task {
            if let data = htmlString.data(using: .utf8) {
                nsView.load(data, mimeType: "text/html", characterEncodingName: "UTF-8", baseURL: Bundle.main.bundleURL)
            }
        }
    }
}
