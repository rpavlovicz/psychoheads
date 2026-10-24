//
//  RandomHeadScatterView.swift
//  psychoheads
//
//  Unused random placement of heads. Kept so the earlier scatter layout can be revisited.
//

import SwiftUI

struct RandomHeadScatterView: View {
    let clippings: [Clipping]
    let placeholder: UIImage
    let onSelect: (Clipping) -> Void

    @State private var scatterPositions: [CGPoint] = []
    @State private var scatterDisplaySizes: [CGSize] = []

    private let scatterMargin: CGFloat = 16
    private let cmToPoints: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 52.85 : 60.8

    /// Largest first, so the scale cap uses the biggest head.
    private var sortedClippings: [Clipping] {
        clippings.sorted { $0.size > $1.size }
    }

    /// Display size for one clipping: respects aspect ratio, relative scale to others,
    /// and caps so the largest fits in 1/4 of the view. Never upscales.
    private func scatterDisplaySize(for clipping: Clipping, viewSize: CGSize) -> CGSize {
        let naturalW = CGFloat(clipping.width) * cmToPoints
        let naturalH = CGFloat(clipping.height) * cmToPoints
        let list = sortedClippings
        guard let largest = list.first else { return CGSize(width: naturalW, height: naturalH) }
        let largestW = CGFloat(largest.width) * cmToPoints
        let largestH = CGFloat(largest.height) * cmToPoints
        let largestNaturalArea = largestW * largestH
        let viewArea = viewSize.width * viewSize.height
        let maxArea = viewArea / 4
        let scale: CGFloat
        if largestNaturalArea <= maxArea {
            scale = 1.0
        } else {
            scale = sqrt(maxArea / largestNaturalArea)
        }
        let finalScale = min(scale, 1.0)
        return CGSize(width: naturalW * finalScale, height: naturalH * finalScale)
    }

    /// Generate display sizes and random positions; largest stays within 1/4 of view.
    private func updateScatterPositions(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let list = sortedClippings
        scatterDisplaySizes = list.map { scatterDisplaySize(for: $0, viewSize: size) }
        scatterPositions = list.indices.map { i in
            let sz = scatterDisplaySizes[i]
            let halfW = sz.width / 2
            let halfH = sz.height / 2
            let minX = halfW + scatterMargin
            let maxX = size.width - halfW - scatterMargin
            let minY = halfH + scatterMargin
            let maxY = size.height - halfH - scatterMargin
            let cx: CGFloat
            let cy: CGFloat
            if maxX >= minX, maxY >= minY {
                cx = CGFloat.random(in: minX...maxX)
                cy = CGFloat.random(in: minY...maxY)
            } else {
                cx = size.width / 2
                cy = size.height / 2
            }
            return CGPoint(x: cx, y: cy)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let list = sortedClippings
            ZStack {
                ForEach(list.indices, id: \.self) { index in
                    let clipping = list[index]
                    let displaySize = scatterDisplaySizes.indices.contains(index)
                        ? scatterDisplaySizes[index]
                        : scatterDisplaySize(for: clipping, viewSize: geometry.size)
                    Button(action: {
                        onSelect(clipping)
                    }) {
                        AsyncImage2(
                            clipping: clipping,
                            placeholder: placeholder,
                            imageUrlMid: clipping.imageUrlMid,
                            frameHeight: displaySize.height
                        )
                        .frame(width: displaySize.width, height: displaySize.height)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .position(scatterPositions.indices.contains(index) ? scatterPositions[index] : CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                updateScatterPositions(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                updateScatterPositions(size: newSize)
            }
        }
        .clipped()
    }
}
