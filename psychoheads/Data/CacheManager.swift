//
//  CacheManager.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 3/9/24.
//

import Foundation
import UIKit

class CacheManager {
    static let shared = CacheManager() // Singleton instance

    private init() {}

    private var memoryCache = NSCache<NSString, UIImage>()

    private func documentDirectoryPath() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    func cacheImage(image: UIImage, forKey key: String) {
        let key = NSString(string: key)
        memoryCache.setObject(image, forKey: key)

        // Save to disk using PNG to preserve transparency
        if let data = image.pngData(),
           let filePath = documentDirectoryPath()?.appendingPathComponent(key as String) {
            try? data.write(to: filePath)
        }
    }

    func getCachedImage(forKey key: String) -> UIImage? {
        let key = NSString(string: key)

        // Check memory cache
        if let image = memoryCache.object(forKey: key) {
            return image
        }

        // Check disk cache
        if let filePath = documentDirectoryPath()?.appendingPathComponent(key as String),
           let imageData = try? Data(contentsOf: filePath),
           let image = UIImage(data: imageData) {
            // Image found on disk, caching it in memory for faster access next time
            memoryCache.setObject(image, forKey: key)
            return image
        }

        return nil
    }

    func removeCachedImage(forKey key: String) {
        let nsKey = NSString(string: key)
        memoryCache.removeObject(forKey: nsKey)
        if let filePath = documentDirectoryPath()?.appendingPathComponent(key) {
            try? FileManager.default.removeItem(at: filePath)
        }
    }
    
    // Function to print the total cache usage
    func printTotalCacheUsage() {
        guard let cacheDirectory = documentDirectoryPath() else {
            print("Cache directory not found.")
            return
        }

        do {
            // Get the directory contents
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)

            // Calculate the total size by summing up file sizes
            let totalSize = contents.reduce(0) { total, url in
                do {
                    let attributes = try url.resourceValues(forKeys: [.fileSizeKey])
                    return total + (attributes.fileSize ?? 0)
                } catch {
                    print("Error getting size for file: \(url.path), error: \(error)")
                    return total
                }
            }

            // Convert total size to a human-readable format
            let formattedSize = ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
            print("Total cache usage on disk: \(formattedSize)")
        } catch {
            print("Error calculating total cache usage: \(error)")
        }
    }
    
    // Function to return the total cache usage as a String
    func totalCacheUsage() -> String {
        guard let cacheDirectory = documentDirectoryPath() else {
            return "Cache directory not found."
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)
            let totalSize = contents.reduce(0) { total, url in
                do {
                    let attributes = try url.resourceValues(forKeys: [.fileSizeKey])
                    return total + (attributes.fileSize ?? 0)
                } catch {
                    return total
                }
            }
            return ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
        } catch {
            return "Error calculating total cache usage."
        }
    }

    // Function to clear all cached images
    func clearCache() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        guard let cacheDirectory = documentDirectoryPath() else {
            print("Cache directory not found.")
            return
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in contents {
                try FileManager.default.removeItem(at: file)
            }
            print("Cache cleared successfully")
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
}
