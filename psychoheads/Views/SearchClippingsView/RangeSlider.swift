import SwiftUI

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    let step: Double
    let accentColor: Color
    
    @State private var isDraggingMin = false
    @State private var isDraggingMax = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Selected range
                Rectangle()
                    .fill(accentColor)
                    .frame(width: widthForRange(), height: 4)
                    .cornerRadius(2)
                    .offset(x: positionForMin())
                
                // Min thumb
                Circle()
                    .fill(accentColor)
                    .frame(width: 20, height: 20)
                    .position(x: positionForMin(), y: 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingMin = true
                                let newValue = valueForPosition(value.location.x, in: geometry)
                                minValue = min(newValue, maxValue - step)
                            }
                            .onEnded { _ in
                                isDraggingMin = false
                            }
                    )
                    .scaleEffect(isDraggingMin ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isDraggingMin)
                
                // Max thumb
                Circle()
                    .fill(accentColor)
                    .frame(width: 20, height: 20)
                    .position(x: positionForMax(), y: 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingMax = true
                                let newValue = valueForPosition(value.location.x, in: geometry)
                                maxValue = max(newValue, minValue + step)
                            }
                            .onEnded { _ in
                                isDraggingMax = false
                            }
                    )
                    .scaleEffect(isDraggingMax ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isDraggingMax)
            }
        }
        .frame(height: 20)
    }
    
    private func positionForMin() -> CGFloat {
        let rangeSize = range.upperBound - range.lowerBound
        let progress = (minValue - range.lowerBound) / rangeSize
        return CGFloat(progress) * (UIScreen.main.bounds.width - 60) // Approximate available width
    }
    
    private func positionForMax() -> CGFloat {
        let rangeSize = range.upperBound - range.lowerBound
        let progress = (maxValue - range.lowerBound) / rangeSize
        return CGFloat(progress) * (UIScreen.main.bounds.width - 60) // Approximate available width
    }
    
    private func widthForRange() -> CGFloat {
        return positionForMax() - positionForMin()
    }
    
    private func valueForPosition(_ position: CGFloat, in geometry: GeometryProxy) -> Double {
        let rangeSize = range.upperBound - range.lowerBound
        let progress = Double(position / (geometry.size.width - 40)) // Account for thumb width
        let value = range.lowerBound + (progress * rangeSize)
        return max(range.lowerBound, min(range.upperBound, value))
    }
}

#Preview {
    VStack(spacing: 20) {
        RangeSlider(
            minValue: .constant(3.0),
            maxValue: .constant(10.0),
            range: 2.0...15.0,
            step: 0.1,
            accentColor: .blue
        )
        .padding()
        
        RangeSlider(
            minValue: .constant(5.0),
            maxValue: .constant(8.0),
            range: 3.0...12.0,
            step: 0.5,
            accentColor: .green
        )
        .padding()
    }
} 