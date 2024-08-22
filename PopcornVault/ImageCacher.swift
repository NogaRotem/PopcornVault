//
//  ImageCacher.swift
//  PopcornVault
//
//  Created by Noga Rotem on 21/08/2024.
//

import Foundation
import SwiftUI

// Caches images for time period
class ImageCacher{
    private let fileManager = FileManager.default
    private let appCacheDir: URL?
    private var cacherOperatable = true // If cacher can't open a cache dir - it will become unfunctional
    
    // Enum for expiration period of caching
    enum TimeUnit{
        case seconds
        case minutes
        case hours
        case days
        
        var durationInSecs: Double{
            switch self{
            case .seconds:
                return 1
            case .minutes:
                return 60
            case .hours:
                return 3600
            case .days:
                return 86400
            }
        }
    }
    
    // Find built-in cache dir. If not found - cache in Documets dir. if not found - diactivate cacher
    init(cacheDirName: String, expirationTimeUnit: TimeUnit, amount: Double) {
        if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            appCacheDir = cacheDir.appendingPathComponent(cacheDirName)
            deleteExpiredFiles(olderThan: expirationTimeUnit, amount: amount)

        } else{
            if let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first{
                appCacheDir = documentsDir.appendingPathComponent(cacheDirName)
                deleteExpiredFiles(olderThan: expirationTimeUnit, amount: amount)
            } else{
                cacherOperatable = false
                appCacheDir = nil
            }
        }
        
        // If path for new cache dir found - create dir. If failed to create - diactivate cacher
        if cacherOperatable{
            // Check if the directory exists, create it if it doesn't
            if !fileManager.fileExists(atPath: appCacheDir!.path) {
                do {
                    try fileManager.createDirectory(at: appCacheDir!, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    cacherOperatable = false // If can't create cache dir - deactivate cache
                    return
                }
            }
        }
    }
    
    // Caches image in app's cache dir
    func cacheImage(image: Image, id: String) {
        if cacherOperatable {
            // Convert SwiftUI Image to UIImage in order to save it on disk
            let uiImage: UIImage = image.asUIImage()

            // Convert UIImage to Data
            guard let imageData = uiImage.pngData() else {
                return
            }

            // Create a unique path for image
            let fileURL = appCacheDir!.appendingPathComponent(id + ".png")

            do {
                // Write the image data to disk
                try imageData.write(to: fileURL)
            } catch {
                return // If failed to cache - move on
                
            }
        }
    }


    // Uploads image from app's cache dir
    func loadImage(id: String) -> Image? {
        if cacherOperatable{
            // Get the URL for the image
            let imageURL = appCacheDir!.appendingPathComponent(id + ".png")
            
            // Check if the image exists
            if fileManager.fileExists(atPath: imageURL.path) {
                // Try to load the image data from the file
                if let imageData = try? Data(contentsOf: imageURL),
                   let uiImage = UIImage(data: imageData) {
                    return Image(uiImage: uiImage)
                }
            }
            return nil
        }
        return nil
    }
    
    // Runs upon init and delete all images preceeding the expiration date
    private func deleteExpiredFiles(olderThan timeUnit: TimeUnit, amount: Double) {
        let currentDate = Date()
        let expirationDate = currentDate.addingTimeInterval(-(amount * timeUnit.durationInSecs))
        
        do {
            // Get the list of files in the directory
            let fileURLs = try fileManager.contentsOfDirectory(at: appCacheDir!, includingPropertiesForKeys: [.contentModificationDateKey], options: [])
            
            // Iterate through the file URLs
            for fileURL in fileURLs {
                // Get the file attributes
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let modificationDate = attributes[.modificationDate] as? Date {
                    // Check if the file is older than the expiration date
                    if modificationDate < expirationDate {
                        do {
                            // Delete the file
                            try fileManager.removeItem(at: fileURL)
                        } catch {}
                    }
                }
            }
        } catch {}
    }
}
