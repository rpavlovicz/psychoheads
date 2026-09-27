//
//  ImageHelperFunctions.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/25/25.
//


//
//  ImageHelperFunctions.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 3/27/23.
//

import Foundation
import SwiftUI
import FirebaseStorage
import Combine

struct ImageHelperFunctions {
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    enum ImageUploadError: LocalizedError {
        case pngConversionFailed(path: String)
        case resizeFailed(kind: String)
        case storageFailed(path: String, underlying: Error?)
        
        var errorDescription: String? {
            switch self {
            case .pngConversionFailed(let path):
                return "Could not convert image to PNG for \(path)."
            case .resizeFailed(let kind):
                return "Could not create \(kind) image."
            case .storageFailed(let path, let underlying):
                if let underlying {
                    return "Failed to upload \(path): \(underlying.localizedDescription)"
                }
                return "Failed to upload \(path)."
            }
        }
    }
    
    func uploadSourceImages(image: UIImage, docName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let imagePath = "sourceImages/\(docName).png"
        let thumbPath = "sourceImages/\(docName)_thumb.png"
        let midsizedPath = "sourceImages/\(docName)_mid.png"
        uploadImageSet(
            image: image,
            fullPath: imagePath,
            thumbPath: thumbPath,
            midPath: midsizedPath,
            completion: completion
        )
    }
    
    func uploadClippingImages(image: UIImage, docName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let imagePath = "clippingImages/\(docName).png"
        let thumbPath = "clippingImages/\(docName)_thumb.png"
        let midsizedPath = "clippingImages/\(docName)_mid.png"
        uploadImageSet(
            image: image,
            fullPath: imagePath,
            thumbPath: thumbPath,
            midPath: midsizedPath,
            completion: completion
        )
    }
    
    private func uploadImageSet(
        image: UIImage,
        fullPath: String,
        thumbPath: String,
        midPath: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let thumbImage = resizeImage(image: image, targetSize: CGSize(width: 150.0, height: 150.0)) else {
            DispatchQueue.main.async {
                completion(.failure(ImageUploadError.resizeFailed(kind: "thumbnail")))
            }
            return
        }
        guard let midImage = resizeImage(image: image, targetSize: CGSize(width: 500.0, height: 500.0)) else {
            DispatchQueue.main.async {
                completion(.failure(ImageUploadError.resizeFailed(kind: "mid-size")))
            }
            return
        }
        
        let uploads: [(UIImage, String)] = [
            (image, fullPath),
            (thumbImage, thumbPath),
            (midImage, midPath)
        ]
        
        let group = DispatchGroup()
        let lock = NSLock()
        var firstError: Error?
        
        for (uploadImage, path) in uploads {
            group.enter()
            self.uploadImage(image: uploadImage, imagePath: path) { result in
                if case .failure(let error) = result {
                    lock.lock()
                    if firstError == nil {
                        firstError = error
                    }
                    lock.unlock()
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let firstError {
                completion(.failure(firstError))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Uploads a single image to Storage. Retries once on failure.
    func uploadImage(
        image: UIImage,
        imagePath: String,
        attempt: Int = 0,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let pngData = image.pngData() else {
            completion(.failure(ImageUploadError.pngConversionFailed(path: imagePath)))
            return
        }
        
        let fileRef = Storage.storage().reference().child(imagePath)
        fileRef.putData(pngData, metadata: nil) { metadata, error in
            if error == nil && metadata != nil {
                print("Successfully uploaded image to \(imagePath)")
                completion(.success(()))
            } else if attempt < 1 {
                print("Retrying upload to \(imagePath) after error: \(String(describing: error))")
                self.uploadImage(image: image, imagePath: imagePath, attempt: attempt + 1, completion: completion)
            } else {
                print("Error uploading image to \(imagePath): \(String(describing: error))")
                completion(.failure(ImageUploadError.storageFailed(path: imagePath, underlying: error)))
            }
        }
    }
    
    func flipImageVertically(image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        context.translateBy(x: image.size.width / 2, y: image.size.height / 2)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
        
        image.draw(at: CGPoint.zero)
        
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return flippedImage
    }
    
    func flipImageVerticallyAndHorizontally(image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Translate and scale the context to flip both vertically and horizontally
        context.translateBy(x: image.size.width / 2, y: image.size.height / 2)
        context.scaleBy(x: -1.0, y: -1.0)
        context.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
        
        image.draw(at: CGPoint.zero)
        
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return flippedImage
    }
 
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var dbFuncs = dbFunctions()
    private var cancellable: AnyCancellable?
    
    func load(imagePath: String, useCache: Bool = false, completion: @escaping (Bool, UIImage?) -> Void) {
        let key = extractKeyFromImagePath(imagePath)
        
        if useCache {
            if let cachedImage = CacheManager.shared.getCachedImage(forKey: key) {
                self.image = cachedImage
                completion(true, cachedImage)
                return
            }
        }
        
        if let existingImage = image {
            // If the image is already downloaded and cached, no need to download again
            completion(true, existingImage)
            return
        }

        // Download and cache the image
        cancellable = dbFuncs.getThumbnail(imagePath: imagePath)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionStatus in
                           if case .failure(_) = completionStatus {
                               print("could not download image from \(imagePath)")
                               print("using 'broken_image_link' system image instead")
                               self?.image = UIImage(named: "broken_image_link")
                               completion(false, self?.image)
                           }
                       }, receiveValue: { [weak self] downloadedImage in
                           if useCache {
                               CacheManager.shared.cacheImage(image: downloadedImage, forKey: key)
                           }
                           self?.image = downloadedImage
                           completion(true, downloadedImage)
                       })
    } // load function
    
    func extractKeyFromImagePath(_ imagePath: String) -> String {
        // Assuming the imagePath format is always "sourceImages/<UUID>_thumb.png"
        // This will extract the filename without extension
        let key = imagePath.components(separatedBy: "/").last?.split(separator: ".").first ?? ""
        return String(key)
    }

}

struct AsyncImage1: View {
    @StateObject private var imageLoader = ImageLoader()
    var clipping: Clipping
    var placeholder: UIImage
    
    var body: some View {
        ZStack {
            if clipping.imageThumb != nil {
                Image(uiImage: clipping.imageThumb!)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
            } else {
                    Image(uiImage: placeholder)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
            }
        }
        .onAppear {
            if clipping.imageThumb == nil {
                print("thumbnail not found for \(clipping.id)")
                print("trying to load from \(clipping.imageUrlThumb)")
                
                if clipping.imageUrlThumb == "" {
                    print("****thumbnail url is an empty string!")
                    clipping.imageThumb = UIImage(named: "broken_image_link")
                }
                imageLoader.load(imagePath: clipping.imageUrlThumb, useCache: true) { success, downloadedImage in
                    if success, let validImage = downloadedImage {
                        clipping.imageThumb = downloadedImage
                    } else {
                        clipping.imageThumb = UIImage(named: "broken_image_link")
                    }
                    
                }
            }
        }
    }
}

struct AsyncImage2: View {
    @StateObject private var imageLoader = ImageLoader()
    //var clipping: Clipping
    @ObservedObject var clipping: Clipping
    var placeholder: UIImage
    var imageUrlMid: String
    var frameHeight: CGFloat
    
    var body: some View {
        ZStack {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: frameHeight)
            } else {
                Image(uiImage: placeholder)
                    .resizable()
                    .scaledToFit()
                    .frame(height: frameHeight)
            }
        }
        .onAppear {
            loadImage(url: imageUrlMid)
        }
        .onChange(of: clipping.imageUrlMid) { newValue in
            print("detected change of clipping.imageUrlMid")
            print("new url: \(newValue)")
            imageLoader.image = nil // ** this is key to getting the view to refresh!
            loadImage(url: newValue)
        }
    } // View
    
    private func loadImage(url: String) {
        imageLoader.load(imagePath: url, useCache: true) { success, downloadedImage in
            if success, let validImage = downloadedImage {
                DispatchQueue.main.async {
                    clipping.imageMid = validImage
                    imageLoader.image = validImage
                    print("successful loading of imageUrlMid")
                    print("url: \(url)")
                }
            }
        }
    }
}
