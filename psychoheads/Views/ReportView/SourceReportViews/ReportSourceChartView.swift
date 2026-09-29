//
//  ReportSourceChartView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//

import SwiftUI
import Charts

struct ReportSourceChartView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @State private var isScrollable: Bool = false
    @State private var useFixedYScale: Bool = false
    @State private var sourceCoverageFilter: SourceCoverageFilter = .withClippings
    
    private let barWidth: CGFloat = 12
    private let labelXOffset: CGFloat = -20
    private let fixedYMax = 12
    private let fixedYDomain: ClosedRange<Int> = 0...12
    private let fixedYTicks = [0, 5, 10]
    
    private var yearCounts: [(year: Int, count: Int)] {
        sourceModel.sourceYearCounts(for: sourceCoverageFilter)
    }
    
    private var clippedYearCounts: [(year: Int, count: Int)] {
        sourceModel.sourceYearCounts(for: .withClippings)
    }
    
    private var yearDomain: ClosedRange<Int>? {
        guard let minYear = sourceModel.minYear(for: sourceCoverageFilter),
              let maxYear = sourceModel.maxYear(for: sourceCoverageFilter),
              !yearCounts.isEmpty else {
            return nil
        }
        return minYear...maxYear
    }
    
    /// Caps displayed bar height when fixed Y scale is on so overflow is not drawn.
    private func displayCount(_ value: Int) -> Int {
        useFixedYScale ? min(value, fixedYMax) : value
    }

    var body: some View {
        VStack(alignment: .leading) {
            
            if #available(iOS 17.0, *) {
                if let yearDomain {
                    let minYear = yearDomain.lowerBound
                    let maxYear = yearDomain.upperBound
                    // Zoom / Y-scale controls live in bottomControls
                    if isScrollable {
                        Chart {
                            sourceBarsContent()
                        }
                        .chartScrollableAxes(.horizontal)
                        .chartXAxis {
                            AxisMarks(values: Array(minYear...maxYear)) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text(verbatim: "    \(intValue)")
                                            .rotationEffect(.degrees(50))
                                            .font(.caption)
                                            .offset(x: labelXOffset, y: 0)
                                    }
                                }
                            }
                        }
                        .chartXScale(domain: minYear-1...maxYear+3)
                        .modifier(SourceChartYScaleModifier(
                            useFixedYScale: useFixedYScale,
                            fixedDomain: fixedYDomain,
                            fixedTicks: fixedYTicks
                        ))
                        .frame(height: 150)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                        .chartGesture { proxy in
                            SpatialTapGesture()
                                .onEnded { value in
                                    guard let year: Int = proxy.value(atX: value.location.x) else { return }
                                    guard yearDomain.contains(year) else { return }
                                    navigationStateManager.selectionPath.append(
                                        .libraryForYear(year, sourceCoverageFilter)
                                    )
                                }
                        }
                        
                    } else {
                        Chart {
                            sourceBarsContent()
                        }
                        .chartXAxis {
                            AxisMarks(values: Array(stride(from: minYear, through: maxYear, by: 5))) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text(verbatim: "    \(intValue)")
                                            .rotationEffect(.degrees(50))
                                            .font(.caption)
                                            .offset(x: labelXOffset, y: 0)
                                    }
                                }
                            }
                        }
                        .chartXScale(domain: minYear-2...maxYear+7)
                        .modifier(SourceChartYScaleModifier(
                            useFixedYScale: useFixedYScale,
                            fixedDomain: fixedYDomain,
                            fixedTicks: fixedYTicks
                        ))
                        .frame(height: 150)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                    
                    bottomControls
                } else {
                    Text("No data available")
                        .padding()
                    bottomControls
                }
            } else {
                Text("Charts are available only on iOS 17.0 and later")
                    .padding()
            }

        }
        
    }
    
    private var bottomControls: some View {
        HStack(spacing: 10) {
            coverageMenu
            Spacer()
            
            Toggle(isOn: $isScrollable) {}
                .labelsHidden()
                .tint(.blue)
                .scaleEffect(0.8)
                .frame(width: 50)
            Image(systemName: isScrollable ? "arrow.left.and.right.square.fill" : "arrow.left.and.right.square")
                .font(.body)
                .foregroundStyle(isScrollable ? Color.accentColor : Color.secondary)
                .accessibilityHidden(true)
            
            Toggle(isOn: $useFixedYScale) {}
                .labelsHidden()
                .tint(.blue)
                .scaleEffect(0.8)
                .frame(width: 50)
            Image(systemName: useFixedYScale ? "arrow.up.to.line" : "arrow.up.and.down")
                .font(.body)
                .foregroundStyle(useFixedYScale ? Color.accentColor : Color.secondary)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
    
    @ChartContentBuilder
    private func sourceBarsContent() -> some ChartContent {
        if sourceCoverageFilter == .all {
            let clippedByYear = Dictionary(uniqueKeysWithValues: clippedYearCounts.map { ($0.year, $0.count) })
            ForEach(yearCounts, id: \.year) { yearCount in
                let clippedCount = clippedByYear[yearCount.year] ?? 0
                let displayedClipped = displayCount(clippedCount)
                let displayedTotal = displayCount(yearCount.count)
                
                BarMark(
                    x: .value("Year", yearCount.year),
                    y: .value("Count", displayedClipped),
                    width: .fixed(barWidth)
                )
                .foregroundStyle(.blue)
                
                if displayedTotal > displayedClipped {
                    BarMark(
                        x: .value("Year", yearCount.year),
                        yStart: .value("Cut Sources", displayedClipped),
                        yEnd: .value("Total Sources", displayedTotal),
                        width: .fixed(barWidth)
                    )
                    .foregroundStyle(.gray.opacity(0.4))
                }
            }
        } else {
            ForEach(yearCounts, id: \.year) { yearCount in
                BarMark(
                    x: .value("Year", yearCount.year),
                    y: .value("Count", displayCount(yearCount.count)),
                    width: .fixed(barWidth)
                )
            }
        }
    }
    
    private var coverageMenu: some View {
        Menu {
            ForEach(SourceCoverageFilter.allCases) { filter in
                Button {
                    sourceCoverageFilter = filter
                } label: {
                    if sourceCoverageFilter == filter {
                        Label(filter.displayName, systemImage: "checkmark")
                    } else {
                        Text(filter.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(sourceCoverageFilter.displayName)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
    }
}

private struct SourceChartYScaleModifier: ViewModifier {
    let useFixedYScale: Bool
    let fixedDomain: ClosedRange<Int>
    let fixedTicks: [Int]
    
    func body(content: Content) -> some View {
        if useFixedYScale {
            content
                .chartYScale(domain: fixedDomain)
                .chartYAxis {
                    AxisMarks(values: fixedTicks) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.clipped()
                }
        } else {
            content
        }
    }
}

struct ReportSourceChartView_Previews: PreviewProvider {
    static var previews: some View {
        ReportSourceChartView()
            .environmentObject(SourceModel())
            .environmentObject(NavigationStateManager())
    }
}
