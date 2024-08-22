//
//  VideoPlayer.swift
//  PopcornVault
//
//  Created by Noga Rotem on 18/08/2024.
//

import Foundation
import SwiftUI
import WebKit

// Displays video on screen
struct VideoPlayer: UIViewRepresentable {
    let videoKey: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoKey)") else { return } 
        uiView.scrollView.isScrollEnabled = false // Disable scrolling for stable results
        uiView.load(URLRequest(url: url))
    }
}

