//
//  ClippingSummaryBar.swift
//  psychoheads
//

import SwiftUI

/// Fixed-height source, name, and tag row shown under a clipping.
struct ClippingSummaryBar: View {
    @ObservedObject var clipping: Clipping
    let source: Source?
    /// When this matches the source on screen behind the clipping sheet, Source closes the sheet.
    var dismissToSourceID: String? = nil
    @EnvironmentObject private var sourceModel: SourceModel
    @Environment(\.dismiss) private var dismiss

    private var isPureHead: Bool {
        clipping.isHead && !clipping.isBody
    }

    private func closesPresentingSource(_ source: Source) -> Bool {
        guard let dismissToSourceID, !dismissToSourceID.isEmpty, !source.id.isEmpty else { return false }
        return source.id == dismissToSourceID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Text("Source:")
                    .bold()
                if let source {
                    if closesPresentingSource(source) {
                        Button {
                            dismiss()
                        } label: {
                            SourceFormView(source: source)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: SelectionState.sourceView(source)) {
                            SourceFormView(source: source)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

            HStack(spacing: 6) {
                Text("Name:")
                    .bold()
                    .opacity(isPureHead ? 1 : 0)
                if isPureHead {
                    let clippingNameSource = sourceModel.createSourceFromClippingName(clippingName: clipping.name)
                    NavigationLink(value: SelectionState.sourceView(clippingNameSource)) {
                        Text(clipping.name)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(clipping.tags.enumerated()), id: \.offset) { _, tag in
                        NavigationLink(value: SelectionState.searchForTag(tag)) {
                            Text(tag)
                        }
                        .buttonStyle(TagChipButtonStyle())
                    }
                }
            }
            .frame(height: 36)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

/// Measurements and traits opened by a long-press on the clipping image.
struct ClippingDetailsSheet: View {
    @ObservedObject var clipping: Clipping
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(traits, id: \.self) { trait in
                            ClippingTraitChip(title: trait)
                        }
                    }
                }
                .frame(height: 32)

                labeledRow("Date Added", formatDate(clipping.added))
                labeledRow("Width", centimeters(clipping.width))
                labeledRow("Height", centimeters(clipping.height))
                if let headWidth = clipping.headWidth {
                    labeledRow("Head Width", centimeters(headWidth))
                }
                if let headHeight = clipping.headHeight {
                    labeledRow("Head Height", centimeters(headHeight))
                }
                if let direction = clipping.lookingDirection, !direction.isEmpty {
                    labeledRow("Looking Direction", directionLabel(direction))
                }

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                    GridRow {
                        Text("clipping id:")
                        Text(clipping.id)
                    }
                    GridRow {
                        Text("source id:")
                        Text(clipping.sourceId)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onEdit) {
                    Label("Edit Clipping", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: onDelete) {
                    Label("Delete Clipping", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
        }
    }

    private var traits: [String] {
        var names: [String] = []
        if clipping.isHead { names.append("Head") }
        if clipping.isBody { names.append("Body") }
        if clipping.isAnimal { names.append("Animal") }
        if clipping.isMan { names.append("Man") }
        if clipping.isWoman { names.append("Woman") }
        if clipping.isTrans { names.append("Trans") }
        if clipping.isWhite { names.append("White") }
        if clipping.isBlack { names.append("Black") }
        if clipping.isLatino { names.append("Latino") }
        if clipping.isAsian { names.append("Asian") }
        if clipping.isIndian { names.append("Indian") }
        if clipping.isNative { names.append("Native") }
        if clipping.isBlackAndWhite { names.append("B&W") }
        if let direction = clipping.lookingDirection, !direction.isEmpty {
            names.append(directionMark(direction))
        }
        return names
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .bold()
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func centimeters(_ value: Double) -> String {
        String(format: "%.2f cm", value)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func directionMark(_ raw: String) -> String {
        switch LookingDirection(rawValue: raw) {
        case .upperLeft: return Constants.lookingUpperLeft
        case .up: return Constants.lookingUp
        case .upperRight: return Constants.lookingUpperRight
        case .left: return Constants.lookingLeft
        case .fullFace: return Constants.lookingFullFace
        case .right: return Constants.lookingRight
        case .lowerLeft: return Constants.lookingLowerLeft
        case .down: return Constants.lookingDown
        case .lowerRight: return Constants.lookingLowerRight
        case nil: return raw
        }
    }

    private func directionLabel(_ raw: String) -> String {
        let mark = directionMark(raw)
        return mark == raw ? raw : "\(mark)  \(raw)"
    }
}

private struct TagChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(configuration.isPressed
                    ? Color(.systemGray3)
                    : Color(red: 0.75, green: 0.87, blue: 1.0))
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ClippingTraitChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.primary.opacity(0.55), lineWidth: 1)
            )
    }
}
