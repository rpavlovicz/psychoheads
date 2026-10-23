//
//  RangeSlider2.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 7/6/25.
//

import SwiftUI

struct RangeSlider2: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    let step: Double
    let accentColor: Color
    var onUserAdjust: () -> Void = {}

    private let thumbSize: CGFloat = 28
    private let trackSpace = "clippingHeightTrack"
    @State private var dragStart: (isMin: Bool, value: Double)?

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let minX = xPosition(for: minValue, width: width)
            let maxX = xPosition(for: maxValue, width: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: max(0, width - thumbSize), height: 4)
                    .offset(x: thumbSize / 2)

                Capsule()
                    .fill(accentColor)
                    .frame(width: max(0, maxX - minX), height: 4)
                    .offset(x: minX)

                thumb(isMin: true, width: width)
                thumb(isMin: false, width: width)
            }
            .frame(width: width, height: thumbSize, alignment: .leading)
            .coordinateSpace(name: trackSpace)
        }
        .frame(height: thumbSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clipping height")
        .accessibilityValue("\(formatted(minValue)) to \(formatted(maxValue)) centimeters")
    }

    private func thumb(isMin: Bool, width: CGFloat) -> some View {
        let value = isMin ? minValue : maxValue
        return Circle()
            .fill(accentColor)
            .frame(width: 22, height: 22)
            .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
            .frame(width: thumbSize, height: thumbSize)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(trackSpace))
                    .onChanged { gesture in
                        onUserAdjust()
                        let start: (isMin: Bool, value: Double)
                        if let dragStart, dragStart.isMin == isMin {
                            start = dragStart
                        } else {
                            start = (isMin, value)
                            dragStart = start
                        }
                        let raw = valueForX(
                            xPosition(for: start.value, width: width) + gesture.translation.width,
                            width: width
                        )
                        if isMin {
                            minValue = limited(snap(raw), ceiling: maxValue - separation)
                        } else {
                            maxValue = limited(snap(raw), floor: minValue + separation)
                        }
                    }
                    .onEnded { _ in
                        dragStart = nil
                    }
            )
            .offset(x: xPosition(for: value, width: width) - thumbSize / 2)
    }

    private var separation: Double {
        let span = range.upperBound - range.lowerBound
        guard step > 0, span >= step else { return 0 }
        return step
    }

    private func xPosition(for value: Double, width: CGFloat) -> CGFloat {
        let inset = thumbSize / 2
        let usable = max(width - thumbSize, 0)
        let span = range.upperBound - range.lowerBound
        guard span > 0, usable > 0 else { return width / 2 }
        let progress = min(max((value - range.lowerBound) / span, 0), 1)
        return inset + CGFloat(progress) * usable
    }

    private func valueForX(_ x: CGFloat, width: CGFloat) -> Double {
        let inset = thumbSize / 2
        let usable = max(width - thumbSize, 1)
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return range.lowerBound }
        let progress = min(max(Double((x - inset) / usable), 0), 1)
        return range.lowerBound + progress * span
    }

    private func snap(_ raw: Double) -> Double {
        let lower = range.lowerBound
        let upper = range.upperBound
        guard step > 0, upper > lower else { return lower }
        if raw <= lower + step / 2 { return lower }
        if raw >= upper - step / 2 { return upper }
        let snapped = (raw / step).rounded() * step
        let cleaned = (snapped * 1000).rounded() / 1000
        return min(max(cleaned, lower), upper)
    }

    private func limited(_ value: Double, ceiling: Double? = nil, floor: Double? = nil) -> Double {
        var result = min(max(value, range.lowerBound), range.upperBound)
        if let ceiling {
            result = min(result, ceiling)
        }
        if let floor {
            result = max(result, floor)
        }
        return min(max(result, range.lowerBound), range.upperBound)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

#Preview {
    struct PreviewHost: View {
        @State var minValue = 4.0
        @State var maxValue = 12.0

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(String(format: "%.1f", minValue)) – \(String(format: "%.1f", maxValue)) cm")
                    .font(.caption2)
                RangeSlider2(
                    minValue: $minValue,
                    maxValue: $maxValue,
                    range: 3.2...18.4,
                    step: 0.1,
                    accentColor: .green
                )
            }
            .padding()
        }
    }

    return PreviewHost()
}
