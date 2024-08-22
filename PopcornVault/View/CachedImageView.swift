//
//  CachedImageView.swift
//  PopcornVault
//
//  Created by Noga Rotem on 21/08/2024.
//

import SwiftUI

// View that display cached image if exist. If no cached image - gets image from url.
struct CachedImageView: View {
     let imageCacher: ImageCacher
     let urlPrefix: String
     let urlID: String

    var body: some View {
        let id = stripFileType(from: urlID) // Removed image type from string if exists
        if let image = imageCacher.loadImage(id: id){ // If image cached - display the cached image
            image
                .resizable()
        } else { // if image not cached - Download from url. If can't - display a placeholder image
            AsyncImage(url: URL(string: urlPrefix + urlID)) { phase in
                switch phase{
                case .empty:
                    Image("placeHolder").resizable()
                case .success(let image):
                    image.resizable()
                        .onAppear{
                            imageCacher.cacheImage(image: image, id: id) // Once image successfully downloaded - cache it.
                        }
                case .failure(_):
                    Image("placeHolder").resizable()
                @unknown default:
                    Image("placeHolder").resizable()
                }
            }
        }
    }
}

