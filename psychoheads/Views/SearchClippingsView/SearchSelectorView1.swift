//
//  SearchSelectorView1.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//


//
//  SearchSelectorView1.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 9/17/23.
//

import SwiftUI

struct SearchSelectorView1: View {
    
    @Binding var searchHeads: Bool
    @Binding var searchTags: Bool
    @Binding var searchAllHeads: Bool
    @Binding var searchAllBodies: Bool
    @Binding var lookingDirection: LookingDirection?
    
    // Filter bindings
    @Binding var filterMan: Bool
    @Binding var filterWoman: Bool
    @Binding var filterTrans: Bool
    @Binding var filterWhite: Bool
    @Binding var filterBlack: Bool
    @Binding var filterLatino: Bool
    @Binding var filterAsian: Bool
    @Binding var filterIndian: Bool
    @Binding var filterNative: Bool
    @Binding var filterBlackAndWhite: Bool
    @Binding var filterAnimal: Bool
    
    // Height range slider bindings
    @Binding var minHeight: Double
    @Binding var maxHeight: Double
    @Binding var heightRange: ClosedRange<Double>
    
    var body: some View {
        
        VStack(spacing: 12) {
            
            // Search Type Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Search Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(.systemGray5))
                        .frame(height: 35)
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color(.systemGray3))
                            .frame(width: 1, height: 25)
                        Spacer()
                    }.padding(.horizontal, 2)
                        
                    HStack(spacing: 5) {
                        Button("Heads") {
                            searchHeads.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: searchHeads ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                        Button("Tags") {
                            searchTags.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: searchTags ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                    } // HStack
                    .padding(.horizontal,4)
                } // ZStack
                
                // Help text for search types
                VStack(alignment: .leading, spacing: 2) {
                    if searchHeads {
                        Text("• Heads: Search clipping names")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    if searchTags {
                        Text("• Tags: Search clipping tags")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    if !searchHeads && !searchTags {
                        Text("Select search type to filter by text input")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 4)
            }
            
            // Display Filter Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Filter")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(.systemGray5))
                        .frame(height: 35)
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color(.systemGray3))
                            .frame(width: 1, height: 25)
                        Spacer()
                        Rectangle()
                            .fill(Color(.systemGray3))
                            .frame(width: 1, height: 25)
                        Spacer()
                        Rectangle()
                            .fill(Color(.systemGray3))
                            .frame(width: 1, height: 25)
                        Spacer()
                    }.padding(.horizontal, 2)
                        
                    HStack(spacing: 5) {
                        Button("Heads") {
                            searchAllHeads.toggle()
                            if searchAllHeads {
                                searchAllBodies = false // Ensure only one is selected
                            }
                        }
                        .buttonStyle(ButtonStyle2(inputColor: searchAllHeads ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                        Button("Bodies") {
                            searchAllBodies.toggle()
                            if searchAllBodies {
                                searchAllHeads = false // Ensure only one is selected
                            }
                        }
                        .buttonStyle(ButtonStyle2(inputColor: searchAllBodies ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                        Button("Animal") {
                            filterAnimal.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterAnimal ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                        Button("B&W") {
                            filterBlackAndWhite.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterBlackAndWhite ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                    } // HStack
                    .padding(.horizontal,4)
                } // ZStack
                
                // Help text for Display Filter
                VStack(alignment: .leading, spacing: 2) {
                    if searchAllHeads {
                        Text("• Showing only head clippings")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else if searchAllBodies {
                        Text("• Showing only body clippings")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    } else {
                        Text("• Showing all clippings (heads, bodies, etc.)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if filterAnimal {
                        Text("• Filtering for animal clippings")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    if filterBlackAndWhite {
                        Text("• Filtering for black & white clippings")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
                .padding(.leading, 4)
            }
            
            // Gender Filter Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Gender Filter")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(.systemGray5))
                        .frame(height: 35)
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color(.systemGray3))
                            .frame(width: 1, height: 25)
                        Spacer()
                        Rectangle()
                            .fill(Color(.systemGray3))
                            .frame(width: 1, height: 25)
                        Spacer()
                    }.padding(.horizontal, 2)
                        
                    HStack(spacing: 5) {
                        Button(Constants.man) {
                            filterMan.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterMan ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                        Button(Constants.woman) {
                            filterWoman.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterWoman ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                        Button(Constants.trans) {
                            filterTrans.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterTrans ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                    } // HStack
                    .padding(.horizontal,4)
                } // ZStack
                
                // Help text for gender filters
                VStack(alignment: .leading, spacing: 2) {
                    let activeGenderFilters = [filterMan, filterWoman, filterTrans].filter { $0 }
                    if !activeGenderFilters.isEmpty {
                        Text("• Filtering by selected genders")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    } else {
                        Text("• No gender filter applied")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 4)
            }
            
            // Race Filter Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Race Filter")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(.systemGray5))
                        .frame(height: 35)
                    HStack {
                        Group {
                            Spacer()
                            Rectangle()
                                .fill(Color(.systemGray3))
                                .frame(width: 1, height: 25)
                            Spacer()
                            Rectangle()
                                .fill(Color(.systemGray3))
                                .frame(width: 1, height: 25)
                            Spacer()
                            Rectangle()
                                .fill(Color(.systemGray3))
                                .frame(width: 1, height: 25)
                            Spacer()
                        }
                    }.padding(.horizontal, 2)
                        
                    HStack(spacing: 5) {
                        Button(Constants.white) {
                            filterWhite.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterWhite ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                        Button(Constants.black) {
                            filterBlack.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterBlack ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                        Button(Constants.latino) {
                            filterLatino.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterLatino ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))
                        
                        Button(Constants.asian) {
                            filterAsian.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterAsian ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))
                        
                        Button(Constants.indian) {
                            filterIndian.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterIndian ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))
                        
                        Button(Constants.native) {
                            filterNative.toggle()
                        }
                        .buttonStyle(ButtonStyle2(inputColor: filterNative ? Color(.secondarySystemGroupedBackground) : Color(.systemGray5)))

                    } // HStack
                    .padding(.horizontal,4)
                } // ZStack
                
                // Help text for race filters
                VStack(alignment: .leading, spacing: 2) {
                    let activeRaceFilters = [filterWhite, filterBlack, filterLatino, filterAsian, filterIndian, filterNative].filter { $0 }
                    if !activeRaceFilters.isEmpty {
                        Text("• Filtering by selected races")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else {
                        Text("• No race filter applied")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 4)
            }
            

            
            // Height Range Filter Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Clipping Height")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Height: \(String(format: "%.1f", minHeight)) - \(String(format: "%.1f", maxHeight)) cm")
                            .font(.caption2)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Available: \(String(format: "%.1f", heightRange.lowerBound)) - \(String(format: "%.1f", heightRange.upperBound)) cm")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    RangeSlider2(
                        minValue: $minHeight,
                        maxValue: $maxHeight,
                        range: heightRange,
                        step: 0.1,
                        accentColor: .green
                    )
                }
                .padding(.horizontal, 4)
                
                // Help text for height filter
                VStack(alignment: .leading, spacing: 2) {
                    let hasHeightFilter = minHeight > heightRange.lowerBound || maxHeight < heightRange.upperBound
                    if hasHeightFilter {
                        Text("• Filtering by height range")
                            .font(.caption2)
                            .foregroundColor(.indigo)
                    } else {
                        Text("• No height filter applied")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 4)
            }
            
            //Section(header: Text("Looking Direction")) {
                
                HStack {
                    DirectionSelectorView(lookingDirection: $lookingDirection)
//                        .onChange(of: lookingDirection) { newValue in
//                            lookingDirection = newValue?.rawValue ?? ""
//                        }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Looking:").bold()
                        if let direction = lookingDirection {
                            Text("\(direction.rawValue)")
                        } else {
                            Text("None")
                        }
                    }
                    .padding(.leading,30)
                    
                }
                
            //}
            
            //DirectionSelectorView()
            
        } // VStack
        .background(Color.clear)
        
    }
}

struct SearchSelectorView1_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            // Default state - Heads selected, no direction
            SearchSelectorView1(
                searchHeads: .constant(true),
                searchTags: .constant(false),
                searchAllHeads: .constant(false),
                searchAllBodies: .constant(false),
                lookingDirection: .constant(nil),
                filterMan: .constant(false),
                filterWoman: .constant(false),
                filterTrans: .constant(false),
                filterWhite: .constant(false),
                filterBlack: .constant(false),
                filterLatino: .constant(false),
                filterAsian: .constant(false),
                filterIndian: .constant(false),
                filterNative: .constant(false),
                filterBlackAndWhite: .constant(false),
                filterAnimal: .constant(false),
                minHeight: .constant(3.0),
                maxHeight: .constant(15.0),
                heightRange: .constant(3.0...15.0)
            )
            .previewDisplayName("SearchSelectorView1 - Default (Heads)")
            
            // Tags selected
            SearchSelectorView1(
                searchHeads: .constant(false),
                searchTags: .constant(true),
                searchAllHeads: .constant(false),
                searchAllBodies: .constant(false),
                lookingDirection: .constant(nil),
                filterMan: .constant(false),
                filterWoman: .constant(false),
                filterTrans: .constant(false),
                filterWhite: .constant(false),
                filterBlack: .constant(false),
                filterLatino: .constant(false),
                filterAsian: .constant(false),
                filterIndian: .constant(false),
                filterNative: .constant(false),
                filterBlackAndWhite: .constant(false),
                filterAnimal: .constant(false),
                minHeight: .constant(3.0),
                maxHeight: .constant(15.0),
                heightRange: .constant(3.0...15.0)
            )
            .previewDisplayName("SearchSelectorView1 - Tags Selected")
            
            // All Heads selected
            SearchSelectorView1(
                searchHeads: .constant(false),
                searchTags: .constant(false),
                searchAllHeads: .constant(true),
                searchAllBodies: .constant(false),
                lookingDirection: .constant(nil),
                filterMan: .constant(false),
                filterWoman: .constant(false),
                filterTrans: .constant(false),
                filterWhite: .constant(false),
                filterBlack: .constant(false),
                filterLatino: .constant(false),
                filterAsian: .constant(false),
                filterIndian: .constant(false),
                filterNative: .constant(false),
                filterBlackAndWhite: .constant(false),
                filterAnimal: .constant(false),
                minHeight: .constant(3.0),
                maxHeight: .constant(15.0),
                heightRange: .constant(3.0...15.0)
            )
            .previewDisplayName("SearchSelectorView1 - All Heads")
            
            // All Heads + Heads search
            SearchSelectorView1(
                searchHeads: .constant(true),
                searchTags: .constant(false),
                searchAllHeads: .constant(true),
                searchAllBodies: .constant(false),
                lookingDirection: .constant(nil),
                filterMan: .constant(false),
                filterWoman: .constant(false),
                filterTrans: .constant(false),
                filterWhite: .constant(false),
                filterBlack: .constant(false),
                filterLatino: .constant(false),
                filterAsian: .constant(false),
                filterIndian: .constant(false),
                filterNative: .constant(false),
                filterBlackAndWhite: .constant(false),
                filterAnimal: .constant(false),
                minHeight: .constant(3.0),
                maxHeight: .constant(15.0),
                heightRange: .constant(3.0...15.0)
            )
            .previewDisplayName("SearchSelectorView1 - All Heads + Heads Search")
            
            // All Heads + Tags search
            SearchSelectorView1(
                searchHeads: .constant(false),
                searchTags: .constant(true),
                searchAllHeads: .constant(true),
                searchAllBodies: .constant(false),
                lookingDirection: .constant(nil),
                filterMan: .constant(false),
                filterWoman: .constant(false),
                filterTrans: .constant(false),
                filterWhite: .constant(false),
                filterBlack: .constant(false),
                filterLatino: .constant(false),
                filterAsian: .constant(false),
                filterIndian: .constant(false),
                filterNative: .constant(false),
                filterBlackAndWhite: .constant(false),
                filterAnimal: .constant(false),
                minHeight: .constant(3.0),
                maxHeight: .constant(15.0),
                heightRange: .constant(3.0...15.0)
            )
            .previewDisplayName("SearchSelectorView1 - All Heads + Tags Search")
            
            // All Heads + Both search types
            SearchSelectorView1(
                searchHeads: .constant(true),
                searchTags: .constant(true),
                searchAllHeads: .constant(true),
                searchAllBodies: .constant(false),
                lookingDirection: .constant(.left),
                filterMan: .constant(false),
                filterWoman: .constant(false),
                filterTrans: .constant(false),
                filterWhite: .constant(false),
                filterBlack: .constant(false),
                filterLatino: .constant(false),
                filterAsian: .constant(false),
                filterIndian: .constant(false),
                filterNative: .constant(false),
                filterBlackAndWhite: .constant(false),
                filterAnimal: .constant(false),
                minHeight: .constant(3.0),
                maxHeight: .constant(15.0),
                heightRange: .constant(3.0...15.0)
            )
            .previewDisplayName("SearchSelectorView1 - All Heads + Both + Left Direction")
            
            // Full face direction
            SearchSelectorView1(
                searchHeads: .constant(true),
                searchTags: .constant(false),
                searchAllHeads: .constant(false),
                searchAllBodies: .constant(false),
                lookingDirection: .constant(.fullFace),
                filterMan: .constant(false),
                filterWoman: .constant(false),
                filterTrans: .constant(false),
                filterWhite: .constant(false),
                filterBlack: .constant(false),
                filterLatino: .constant(false),
                filterAsian: .constant(false),
                filterIndian: .constant(false),
                filterNative: .constant(false),
                filterBlackAndWhite: .constant(false),
                filterAnimal: .constant(false),
                minHeight: .constant(3.0),
                maxHeight: .constant(15.0),
                heightRange: .constant(3.0...15.0)
            )
            .previewDisplayName("SearchSelectorView1 - Full Face Direction")
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
