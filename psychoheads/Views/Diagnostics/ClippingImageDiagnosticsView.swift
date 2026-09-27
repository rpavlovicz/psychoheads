//
//  ClippingImageDiagnosticsView.swift
//  psychoheads
//

import SwiftUI
import FirebaseStorage

struct ClippingImageDiagnosticRow: Identifiable {
    let id: String
    let clipping: Clipping
    let sourceTitle: String
    let sourceId: String
    var hasThumb: Bool?
    var hasMid: Bool?
    var hasFull: Bool?
    var previewImage: UIImage?
    var isScanned: Bool = false
    
    var missingCount: Int {
        guard isScanned else { return 0 }
        return [hasThumb, hasMid, hasFull].filter { $0 != true }.count
    }
    
    var isIncomplete: Bool {
        isScanned && missingCount > 0
    }
    
    /// Full image is present; thumb and/or mid missing with non-empty target paths.
    var isRegenerable: Bool {
        guard isScanned, hasFull == true else { return false }
        let thumbPath = clipping.imageUrlThumb.trimmingCharacters(in: .whitespacesAndNewlines)
        let midPath = clipping.imageUrlMid.trimmingCharacters(in: .whitespacesAndNewlines)
        let needsThumb = hasThumb != true && !thumbPath.isEmpty
        let needsMid = hasMid != true && !midPath.isEmpty
        return needsThumb || needsMid
    }
}

private struct PersistedDiagnosticResult: Codable {
    let clippingId: String
    let hasThumb: Bool
    let hasMid: Bool
    let hasFull: Bool
}

private struct PersistedDiagnosticsStore: Codable {
    var results: [String: PersistedDiagnosticResult]
    var lastScanDate: Date?
}

enum DiagnosticScanMode {
    case all
    case incompleteOnly
}

@MainActor
final class ClippingImageDiagnosticsViewModel: ObservableObject {
    @Published var rows: [ClippingImageDiagnosticRow] = []
    @Published var isScanning = false
    @Published var scannedCount = 0
    @Published var totalCount = 0
    @Published var scanTargetCount = 0
    @Published var showIncompleteOnly = true
    @Published var repairingRowId: String?
    @Published var repairErrorMessage: String?
    @Published var showRepairError = false
    @Published var lastScanDate: Date?
    
    private var scanTask: Task<Void, Never>?
    private var repairTask: Task<Void, Never>?
    
    private static var persistenceURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("clipping_image_diagnostics.json")
    }
    
    var isBusy: Bool {
        isScanning || repairingRowId != nil
    }
    
    var hasPersistedOrScannedResults: Bool {
        rows.contains(where: \.isScanned) || lastScanDate != nil
    }
    
    var incompleteOrUnscannedCount: Int {
        rows.filter { !$0.isScanned || $0.isIncomplete }.count
    }
    
    var displayedRows: [ClippingImageDiagnosticRow] {
        let filtered = showIncompleteOnly
            ? rows.filter { $0.isIncomplete || !$0.isScanned }
            : rows
        return filtered.sorted { lhs, rhs in
            if lhs.missingCount != rhs.missingCount {
                return lhs.missingCount > rhs.missingCount
            }
            if lhs.isScanned != rhs.isScanned {
                return !lhs.isScanned && rhs.isScanned
            }
            let titleCompare = lhs.sourceTitle.localizedCaseInsensitiveCompare(rhs.sourceTitle)
            if titleCompare != .orderedSame {
                return titleCompare == .orderedAscending
            }
            let nameCompare = lhs.clipping.name.localizedCaseInsensitiveCompare(rhs.clipping.name)
            if nameCompare != .orderedSame {
                return nameCompare == .orderedAscending
            }
            return lhs.id < rhs.id
        }
    }
    
    /// Builds rows from current sources and restores any saved scan statuses.
    func loadRows(from sourceModel: SourceModel) {
        let store = Self.loadStore()
        lastScanDate = store.lastScanDate
        
        var built: [ClippingImageDiagnosticRow] = []
        for source in sourceModel.sources {
            for clipping in source.clippings {
                var row = ClippingImageDiagnosticRow(
                    id: clipping.id,
                    clipping: clipping,
                    sourceTitle: source.title,
                    sourceId: source.id
                )
                if let saved = store.results[clipping.id] {
                    row.hasThumb = saved.hasThumb
                    row.hasMid = saved.hasMid
                    row.hasFull = saved.hasFull
                    row.isScanned = true
                }
                built.append(row)
            }
        }
        rows = built
        totalCount = built.count
        scannedCount = built.filter(\.isScanned).count
    }
    
    func startScan(sourceModel: SourceModel, mode: DiagnosticScanMode) {
        guard !isBusy else { return }
        scanTask?.cancel()
        
        // Refresh clipping list from model while keeping persisted statuses
        loadRows(from: sourceModel)
        guard !rows.isEmpty else { return }
        
        let targets: [ClippingImageDiagnosticRow]
        switch mode {
        case .all:
            targets = rows
        case .incompleteOnly:
            targets = rows.filter { !$0.isScanned || $0.isIncomplete }
        }
        guard !targets.isEmpty else { return }
        
        isScanning = true
        scannedCount = 0
        scanTargetCount = targets.count
        
        scanTask = Task {
            await scanAll(targets)
            lastScanDate = Date()
            persistResults()
            isScanning = false
            scannedCount = rows.filter(\.isScanned).count
        }
    }
    
    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        persistResults()
        scannedCount = rows.filter(\.isScanned).count
    }
    
    func repairRow(_ row: ClippingImageDiagnosticRow) {
        guard !isBusy, row.isRegenerable else { return }
        repairingRowId = row.id
        repairTask = Task {
            do {
                try await Self.repairDerivatives(for: row)
                if let index = rows.firstIndex(where: { $0.id == row.id }) {
                    var updated = rows[index]
                    if row.hasThumb != true {
                        updated.hasThumb = true
                    }
                    if row.hasMid != true {
                        updated.hasMid = true
                    }
                    updated.previewImage = await Self.loadPreview(
                        thumbPath: row.clipping.imageUrlThumb,
                        midPath: row.clipping.imageUrlMid,
                        fullPath: row.clipping.imageUrl
                    )
                    rows[index] = updated
                    persistResults()
                }
            } catch {
                repairErrorMessage = error.localizedDescription
                showRepairError = true
            }
            repairingRowId = nil
        }
    }
    
    private func persistResults() {
        var results: [String: PersistedDiagnosticResult] = [:]
        for row in rows where row.isScanned {
            results[row.id] = PersistedDiagnosticResult(
                clippingId: row.id,
                hasThumb: row.hasThumb == true,
                hasMid: row.hasMid == true,
                hasFull: row.hasFull == true
            )
        }
        let store = PersistedDiagnosticsStore(results: results, lastScanDate: lastScanDate)
        do {
            let data = try JSONEncoder().encode(store)
            try data.write(to: Self.persistenceURL, options: [.atomic])
        } catch {
            print("Failed to persist diagnostics: \(error)")
        }
    }
    
    private static func loadStore() -> PersistedDiagnosticsStore {
        let url = persistenceURL
        guard let data = try? Data(contentsOf: url),
              let store = try? JSONDecoder().decode(PersistedDiagnosticsStore.self, from: data) else {
            return PersistedDiagnosticsStore(results: [:], lastScanDate: nil)
        }
        return store
    }
    
    private func scanAll(_ snapshot: [ClippingImageDiagnosticRow]) async {
        let concurrency = 6
        var index = 0
        
        await withTaskGroup(of: (Int, ClippingImageDiagnosticRow).self) { group in
            func enqueueNext() {
                guard index < snapshot.count else { return }
                let currentIndex = index
                let row = snapshot[currentIndex]
                index += 1
                group.addTask {
                    let scanned = await Self.scanRow(row)
                    return (currentIndex, scanned)
                }
            }
            
            for _ in 0..<min(concurrency, snapshot.count) {
                enqueueNext()
            }
            
            for await (_, scanned) in group {
                if Task.isCancelled { break }
                
                if let rowIndex = rows.firstIndex(where: { $0.id == scanned.id }) {
                    rows[rowIndex] = scanned
                }
                scannedCount = min(scannedCount + 1, scanTargetCount)
                enqueueNext()
            }
        }
    }
    
    private nonisolated static func repairDerivatives(for row: ClippingImageDiagnosticRow) async throws {
        let fullPath = row.clipping.imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fullPath.isEmpty else {
            throw ImageHelperFunctions.ImageUploadError.storageFailed(
                path: "full",
                underlying: NSError(domain: "ClippingRepair", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Full image path is empty."
                ])
            )
        }
        
        // Full originals can be larger than preview downloads
        guard let fullImage = await downloadImage(path: fullPath, maxSize: 40 * 1024 * 1024) else {
            throw ImageHelperFunctions.ImageUploadError.storageFailed(
                path: fullPath,
                underlying: NSError(domain: "ClippingRepair", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Could not download the full-size image."
                ])
            )
        }
        
        let helper = ImageHelperFunctions()
        let thumbPath = row.clipping.imageUrlThumb.trimmingCharacters(in: .whitespacesAndNewlines)
        let midPath = row.clipping.imageUrlMid.trimmingCharacters(in: .whitespacesAndNewlines)
        let needsThumb = row.hasThumb != true && !thumbPath.isEmpty
        let needsMid = row.hasMid != true && !midPath.isEmpty
        
        if needsThumb {
            guard let thumbImage = helper.resizeImage(
                image: fullImage,
                targetSize: CGSize(width: 150.0, height: 150.0)
            ) else {
                throw ImageHelperFunctions.ImageUploadError.resizeFailed(kind: "thumbnail")
            }
            try await uploadImageAsync(helper: helper, image: thumbImage, path: thumbPath)
            let thumbCacheKey = storageCacheKey(from: thumbPath)
            await MainActor.run {
                CacheManager.shared.removeCachedImage(forKey: thumbCacheKey)
            }
        }
        
        if needsMid {
            guard let midImage = helper.resizeImage(
                image: fullImage,
                targetSize: CGSize(width: 500.0, height: 500.0)
            ) else {
                throw ImageHelperFunctions.ImageUploadError.resizeFailed(kind: "mid-size")
            }
            try await uploadImageAsync(helper: helper, image: midImage, path: midPath)
            let midCacheKey = storageCacheKey(from: midPath)
            await MainActor.run {
                CacheManager.shared.removeCachedImage(forKey: midCacheKey)
            }
        }
    }
    
    private nonisolated static func storageCacheKey(from path: String) -> String {
        path.components(separatedBy: "/").last?.split(separator: ".").first.map(String.init) ?? path
    }
    
    private nonisolated static func uploadImageAsync(
        helper: ImageHelperFunctions,
        image: UIImage,
        path: String
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            helper.uploadImage(image: image, imagePath: path) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private nonisolated static func scanRow(_ row: ClippingImageDiagnosticRow) async -> ClippingImageDiagnosticRow {
        var updated = row
        let thumbPath = row.clipping.imageUrlThumb
        let midPath = row.clipping.imageUrlMid
        let fullPath = row.clipping.imageUrl
        
        async let thumbPresent = storageObjectPresent(at: thumbPath)
        async let midPresent = storageObjectPresent(at: midPath)
        async let fullPresent = storageObjectPresent(at: fullPath)
        
        updated.hasThumb = await thumbPresent
        updated.hasMid = await midPresent
        updated.hasFull = await fullPresent
        updated.isScanned = true
        updated.previewImage = await loadPreview(
            thumbPath: thumbPath,
            midPath: midPath,
            fullPath: fullPath
        )
        return updated
    }
    
    private nonisolated static func storageObjectPresent(at path: String) async -> Bool {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let ref = Storage.storage().reference().child(trimmed)
        return await withCheckedContinuation { continuation in
            ref.getMetadata { metadata, error in
                if error == nil, let metadata, metadata.size > 0 {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private nonisolated static func loadPreview(
        thumbPath: String,
        midPath: String,
        fullPath: String
    ) async -> UIImage? {
        let placeholder = UIImage(named: "clipping_thumb") ?? UIImage(named: "broken_image_link")
        let candidates = [thumbPath, midPath, fullPath]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for path in candidates {
            if let image = await downloadImage(path: path) {
                return image
            }
        }
        return placeholder
    }
    
    private nonisolated static func downloadImage(
        path: String,
        maxSize: Int64 = 2 * 1024 * 1024
    ) async -> UIImage? {
        let ref = Storage.storage().reference().child(path)
        return await withCheckedContinuation { continuation in
            ref.getData(maxSize: maxSize) { data, error in
                if error == nil, let data, let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

struct ClippingImageDiagnosticsView: View {
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @StateObject private var viewModel = ClippingImageDiagnosticsViewModel()
    
    private let placeholder = UIImage(named: "clipping_thumb")
        ?? UIImage(named: "broken_image_link")
        ?? UIImage()
    
    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            if viewModel.rows.isEmpty && !viewModel.isScanning {
                ContentUnavailableView(
                    "No clippings loaded",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Load your library, then run a scan.")
                )
            } else if viewModel.displayedRows.isEmpty && viewModel.hasPersistedOrScannedResults {
                ContentUnavailableView(
                    viewModel.showIncompleteOnly ? "No incomplete clippings" : "No results",
                    systemImage: "checkmark.seal",
                    description: Text(
                        viewModel.showIncompleteOnly
                        ? "All scanned clippings have thumb, mid, and full images."
                        : "Nothing to show."
                    )
                )
            } else {
                List(viewModel.displayedRows) { row in
                    diagnosticRow(row)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Image Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.rows.isEmpty {
                viewModel.loadRows(from: sourceModel)
            }
        }
        .onDisappear {
            viewModel.cancelScan()
        }
        .alert("Repair failed", isPresented: $viewModel.showRepairError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.repairErrorMessage ?? "Unknown error")
        }
    }
    
    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.isScanning {
                HStack {
                    ProgressView()
                    Text("Scanning \(viewModel.scannedCount) / \(viewModel.scanTargetCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Cancel") {
                        viewModel.cancelScan()
                    }
                }
            } else if let repairingId = viewModel.repairingRowId {
                HStack {
                    ProgressView()
                    Text("Repairing…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(repairingId.prefix(8) + "…")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 10) {
                    Button {
                        viewModel.startScan(sourceModel: sourceModel, mode: .all)
                    } label: {
                        Label(
                            viewModel.hasPersistedOrScannedResults ? "Rescan all" : "Scan all",
                            systemImage: "magnifyingglass"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isBusy || viewModel.totalCount == 0)
                    
                    Button {
                        viewModel.startScan(sourceModel: sourceModel, mode: .incompleteOnly)
                    } label: {
                        Label("Rescan incomplete", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        viewModel.isBusy
                        || viewModel.incompleteOrUnscannedCount == 0
                    )
                }
                
                HStack {
                    if let date = viewModel.lastScanDate {
                        Text("Last scan \(date, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if viewModel.totalCount > 0 {
                        Text("\(viewModel.displayedRows.count) shown · \(viewModel.totalCount) total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Toggle("Show incomplete only", isOn: $viewModel.showIncompleteOnly)
                .disabled(viewModel.isBusy)
            
            HStack(spacing: 16) {
                legendItem(color: .green, label: "Present")
                legendItem(color: .red, label: "Missing")
                legendItem(color: .secondary, label: "Pending")
            }
            .font(.caption2)
        }
        .padding()
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.fill")
                .foregroundColor(color)
                .font(.system(size: 8))
            Text(label)
                .foregroundColor(.secondary)
        }
    }
    
    private func diagnosticRow(_ row: ClippingImageDiagnosticRow) -> some View {
        HStack(spacing: 10) {
            Button {
                navigateToSource(for: row)
            } label: {
                HStack(spacing: 12) {
                    Image(uiImage: row.previewImage ?? placeholder)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipped()
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.clipping.name.isEmpty ? "(unnamed)" : row.clipping.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(row.sourceTitle.isEmpty ? "Unknown source" : row.sourceTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 4)
                    
                    HStack(spacing: 10) {
                        statusColumn(title: "Thumb", value: row.hasThumb, scanned: row.isScanned)
                        statusColumn(title: "Mid", value: row.hasMid, scanned: row.isScanned)
                        statusColumn(title: "Full", value: row.hasFull, scanned: row.isScanned)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBusy)
            
            if row.isRegenerable {
                if viewModel.repairingRowId == row.id {
                    ProgressView()
                        .frame(width: 64)
                } else {
                    Button("Repair") {
                        viewModel.repairRow(row)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isBusy)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColumn(title: String, value: Bool?, scanned: Bool) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Image(systemName: statusSymbol(value: value, scanned: scanned))
                .foregroundColor(statusColor(value: value, scanned: scanned))
                .font(.body.weight(.semibold))
        }
        .frame(width: 44)
    }
    
    private func statusSymbol(value: Bool?, scanned: Bool) -> String {
        guard scanned, let value else { return "ellipsis.circle" }
        return value ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    private func statusColor(value: Bool?, scanned: Bool) -> Color {
        guard scanned, let value else { return .secondary }
        return value ? .green : .red
    }
    
    private func navigateToSource(for row: ClippingImageDiagnosticRow) {
        guard let source = sourceModel.sources.first(where: { $0.id == row.sourceId }) else {
            return
        }
        navigationStateManager.selectionPath.append(.sourceView(source))
    }
}
