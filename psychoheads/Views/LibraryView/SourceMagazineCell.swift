//
//  SourceMagazineCell.swift
//  psychoheads
//

import SwiftUI

struct SourceMagazineCell: View {
    
    @ObservedObject var source: Source
    @StateObject private var imageLoader = ImageLoader()
    @State private var displayImage: UIImage?
    
    private let placeholderImage: UIImage = UIImage(named: "source_thumb")
        ?? UIImage(named: "broken_image_link")
        ?? UIImage()
    
    private var preferredImagePath: String {
        if !source.imageUrlMid.isEmpty {
            return source.imageUrlMid
        }
        if !source.imageUrlThumb.isEmpty {
            return source.imageUrlThumb.replacingOccurrences(of: "_thumb", with: "_mid")
        }
        return source.imageUrlThumb
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay {
                    Image(uiImage: displayImage ?? source.imageThumb ?? placeholderImage)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(source.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(source.dateString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(source.clippings.count) clippings")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onAppear {
            loadCoverImageIfNeeded()
        }
    }
    
    private func loadCoverImageIfNeeded() {
        if displayImage != nil { return }
        
        if let thumb = source.imageThumb {
            displayImage = thumb
        }
        
        let path = preferredImagePath
        guard !path.isEmpty else {
            if displayImage == nil {
                displayImage = placeholderImage
            }
            return
        }
        
        imageLoader.load(imagePath: path, useCache: true) { success, downloadedImage in
            if success, let downloadedImage {
                displayImage = downloadedImage
            } else if displayImage == nil {
                if let thumb = source.imageThumb {
                    displayImage = thumb
                } else {
                    displayImage = UIImage(named: "broken_image_link") ?? placeholderImage
                }
            }
        }
    }
}

struct SourceMagazineCell_Previews: PreviewProvider {
    static var previews: some View {
        SourceMagazineCell(source: {
            let source = Source(title: "Rolling Stone", year: "2020", month: "March")
            source.id = "preview"
            return source
        }())
        .frame(width: 120)
        .padding()
    }
}
