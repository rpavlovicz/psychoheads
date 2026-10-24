//
//  SearchHeadCollageView.swift
//  psychoheads
//

import SwiftUI
import UIKit

struct PlacedClipping: Identifiable {
    let clipping: Clipping
    let frame: CGRect
    var id: String { clipping.id }
}

enum SearchCollageLayout {
    static let gap: CGFloat = 12
    static let cmToPoints: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 52.85 : 60.8

    /// Shelf-packs heads in the given order at life size. Rows use equal gaps across the canvas, unless a gap would be wider than the average head in that row. Those rows are packed with the normal gap and centered.
    static func pack(_ clippings: [Clipping]) -> (items: [PlacedClipping], canvas: CGSize) {
        let sized: [(Clipping, CGSize)] = clippings.compactMap { clipping in
            guard clipping.width > 0, clipping.height > 0 else { return nil }
            return (clipping, CGSize(
                width: CGFloat(clipping.width) * cmToPoints,
                height: CGFloat(clipping.height) * cmToPoints
            ))
        }
        guard !sized.isEmpty else { return ([], .zero) }

        let totalArea = sized.reduce(CGFloat(0)) { $0 + ($1.1.width * $1.1.height) }
        let widest = sized.map(\.1.width).max() ?? 0
        let targetWidth = max(sqrt(totalArea), widest)

        var rows: [[(Clipping, CGSize)]] = []
        var current: [(Clipping, CGSize)] = []
        var currentWidth: CGFloat = 0
        for item in sized {
            let needed = current.isEmpty ? item.1.width : currentWidth + gap + item.1.width
            if !current.isEmpty && needed > targetWidth {
                rows.append(current)
                current = [item]
                currentWidth = item.1.width
            } else {
                current.append(item)
                currentWidth = needed
            }
        }
        if !current.isEmpty {
            rows.append(current)
        }

        let widestRow = rows.map { row in row.reduce(CGFloat(0)) { $0 + $1.1.width } }.max() ?? 0
        let canvasWidth = max(targetWidth, widestRow)

        var y = gap
        var items: [PlacedClipping] = []
        for row in rows {
            let used = row.reduce(CGFloat(0)) { $0 + $1.1.width }
            let averageWidth = used / CGFloat(row.count)
            let stretchedSpacing = max(0, (canvasWidth - used) / CGFloat(row.count + 1))
            let spacing: CGFloat
            let startX: CGFloat
            if stretchedSpacing > averageWidth {
                spacing = gap
                let groupWidth = used + gap * CGFloat(row.count - 1)
                startX = max(0, (canvasWidth - groupWidth) / 2)
            } else {
                spacing = stretchedSpacing
                startX = spacing
            }
            var x = startX
            let rowHeight = row.map(\.1.height).max() ?? 0
            for (clipping, size) in row {
                let centeredY = y + (rowHeight - size.height) / 2
                items.append(PlacedClipping(
                    clipping: clipping,
                    frame: CGRect(x: x, y: centeredY, width: size.width, height: size.height)
                ))
                x += size.width + spacing
            }
            y += rowHeight + gap
        }

        return (items, CGSize(width: canvasWidth, height: y))
    }
}

/// Lets the zoom badge call into the scroll view without owning it.
final class CollageZoomControl {
    fileprivate weak var controller: CollageZoomController?

    func toggleLifeSize() {
        controller?.toggleLifeSize()
    }
}

struct SearchHeadCollageView: View {
    let clippings: [Clipping]
    let placeholder: UIImage
    let onSelect: (Clipping) -> Void

    /// 1.0 is life size: the centimeters-to-points scale used to lay out the canvas.
    @State private var zoomScale: CGFloat = 1
    @State private var zoomControl = CollageZoomControl()

    var body: some View {
        let layout = SearchCollageLayout.pack(clippings)
        ZStack(alignment: .bottomTrailing) {
            SearchCollageZoomRepresentable(
                items: layout.items,
                canvasSize: layout.canvas,
                placeholder: placeholder,
                zoomControl: zoomControl,
                onSelect: onSelect,
                onZoomScaleChange: { zoomScale = $0 }
            )
            zoomBadge
        }
    }

    private var zoomBadge: some View {
        Button {
            zoomControl.toggleLifeSize()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: zoomScale > 1.01 ? "square.resize.up" : "square.resize.down")
                    .font(.caption)
                Text(zoomLabel)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemBackground).opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.trailing, 10)
        .padding(.bottom, 10)
        .accessibilityLabel("Zoom \(zoomLabel) of real size")
    }

    private var zoomLabel: String {
        if abs(zoomScale - 1) < 0.01 {
            return "1x"
        }
        return String(format: "%.2fx", zoomScale)
    }
}

private struct CollageCanvas: View {
    let items: [PlacedClipping]
    let canvasSize: CGSize
    let placeholder: UIImage
    var pressedID: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(items) { item in
                AsyncImage2(
                    clipping: item.clipping,
                    placeholder: placeholder,
                    imageUrlMid: item.clipping.imageUrlMid,
                    frameHeight: item.frame.height
                )
                .frame(width: item.frame.width, height: item.frame.height)
                .opacity(item.id == pressedID ? 0.5 : 1)
                .position(x: item.frame.midX, y: item.frame.midY)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
}

private struct SearchCollageZoomRepresentable: UIViewControllerRepresentable {
    let items: [PlacedClipping]
    let canvasSize: CGSize
    let placeholder: UIImage
    let zoomControl: CollageZoomControl
    let onSelect: (Clipping) -> Void
    let onZoomScaleChange: (CGFloat) -> Void

    func makeUIViewController(context: Context) -> CollageZoomController {
        let controller = CollageZoomController()
        zoomControl.controller = controller
        return controller
    }

    func updateUIViewController(_ controller: CollageZoomController, context: Context) {
        zoomControl.controller = controller
        controller.onSelect = onSelect
        controller.onZoomScaleChange = onZoomScaleChange
        controller.setContent(items: items, canvasSize: canvasSize, placeholder: placeholder)
    }
}

final class CollageZoomController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    let scrollView = UIScrollView()
    var onSelect: ((Clipping) -> Void)?
    var onZoomScaleChange: ((CGFloat) -> Void)?

    private var host: UIHostingController<CollageCanvas>?
    private var canvasContainer: CanvasContainer?
    private var items: [PlacedClipping] = []
    private var canvasSize: CGSize = .zero
    private var placeholder = UIImage()
    private var pressedID: String?
    private var pressOrigin: CGPoint = .zero
    private var contentSignature = ""
    private var lastBoundsSize: CGSize = .zero
    private var didSetInitialZoom = false

    override func loadView() {
        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .clear

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTap.require(toFail: doubleTap)
        let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        press.minimumPressDuration = 0
        press.cancelsTouchesInView = false
        press.delaysTouchesEnded = false
        press.delegate = self
        scrollView.addGestureRecognizer(doubleTap)
        scrollView.addGestureRecognizer(singleTap)
        scrollView.addGestureRecognizer(press)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer is UILongPressGestureRecognizer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard scrollView.bounds.width > 0, scrollView.bounds.height > 0 else { return }
        guard scrollView.bounds.size != lastBoundsSize else { return }
        lastBoundsSize = scrollView.bounds.size
        applyZoomLimits(reset: !didSetInitialZoom)
        didSetInitialZoom = true
    }

    func setContent(items: [PlacedClipping], canvasSize: CGSize, placeholder: UIImage) {
        let signature = items.map { "\($0.id)-\(Int($0.frame.width))x\(Int($0.frame.height))" }.joined(separator: "|")
        let changed = signature != contentSignature || canvasSize != self.canvasSize
        self.items = items

        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        self.canvasSize = canvasSize
        self.placeholder = placeholder

        let canvas = CollageCanvas(items: items, canvasSize: canvasSize, placeholder: placeholder, pressedID: pressedID)
        if let host {
            if changed {
                host.rootView = canvas
            }
        } else {
            let host = UIHostingController(rootView: canvas)
            host.view.backgroundColor = .clear
            host.safeAreaRegions = []
            host.view.insetsLayoutMarginsFromSafeArea = false
            host.view.isUserInteractionEnabled = false
            host.view.translatesAutoresizingMaskIntoConstraints = true
            let container = CanvasContainer(hostedView: host.view, size: canvasSize)
            addChild(host)
            scrollView.addSubview(container)
            host.didMove(toParent: self)
            self.host = host
            canvasContainer = container
        }

        guard changed else { return }
        contentSignature = signature
        // Start from 1x so the next zoom is applied to the life-size canvas.
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1
        scrollView.zoomScale = 1
        canvasContainer?.bounds = CGRect(origin: .zero, size: canvasSize)
        canvasContainer?.frame = CGRect(origin: .zero, size: canvasSize)
        scrollView.contentOffset = .zero
        if scrollView.bounds.width > 0, scrollView.bounds.height > 0 {
            lastBoundsSize = scrollView.bounds.size
            applyZoomLimits(reset: true)
            didSetInitialZoom = true
        } else {
            didSetInitialZoom = false
            lastBoundsSize = .zero
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        canvasContainer
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        reportZoom()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if abs(scale - min(fitScale(), 1)) < 0.02 {
            scrollView.setContentOffset(.zero, animated: false)
            centerContent()
        }
    }

    /// 1.0 is life size. Open at the scale that fits the canvas, without starting larger than life size.
    /// When life size already fits, pinch can continue to 3x.
    private func applyZoomLimits(reset: Bool) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let fit = fitScale()
        let minScale = min(fit, 1)
        let maxScale: CGFloat = fit >= 0.999 ? 3 : 1
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = max(maxScale, minScale)
        if reset {
            scrollView.setZoomScale(min(fit, 1), animated: false)
        } else {
            let clamped = min(max(scrollView.zoomScale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
            if abs(clamped - scrollView.zoomScale) > 0.001 {
                scrollView.setZoomScale(clamped, animated: false)
            }
        }
        centerContent()
        reportZoom()
    }

    private func reportZoom() {
        let scale = scrollView.zoomScale
        DispatchQueue.main.async { [weak self] in
            self?.onZoomScaleChange?(scale)
        }
    }

    private func fitScale() -> CGFloat {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return 1 }
        return min(scrollView.bounds.width / canvasSize.width, scrollView.bounds.height / canvasSize.height)
    }

    private func centerContent() {
        guard let zoomView = canvasContainer else { return }
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        let newCenter = CGPoint(
            x: scrollView.contentSize.width * 0.5 + offsetX,
            y: scrollView.contentSize.height * 0.5 + offsetY
        )
        if abs(zoomView.center.x - newCenter.x) > 0.5 || abs(zoomView.center.y - newCenter.y) > 0.5 {
            zoomView.center = newCenter
        }
    }

    /// Not at life size: animate to 1x. Already at life size: animate to the fit scale.
    func toggleLifeSize() {
        let target: CGFloat = abs(scrollView.zoomScale - 1) < 0.01 ? scrollView.minimumZoomScale : 1
        scrollView.setZoomScale(target, animated: true)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let opening = min(fitScale(), 1)
        scrollView.setZoomScale(opening, animated: true)
    }

    @objc private func handlePress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            pressOrigin = gesture.location(in: scrollView)
            setPressed(clippingID(at: gesture))
        case .changed:
            let location = gesture.location(in: scrollView)
            let moved = hypot(location.x - pressOrigin.x, location.y - pressOrigin.y)
            if moved > 12 {
                setPressed(nil)
            } else {
                setPressed(clippingID(at: gesture))
            }
        case .ended, .cancelled, .failed:
            setPressed(nil)
        default:
            break
        }
    }

    private func clippingID(at gesture: UIGestureRecognizer) -> String? {
        guard let canvasContainer else { return nil }
        let point = gesture.location(in: canvasContainer)
        return items.first(where: { $0.frame.contains(point) })?.id
    }

    private func setPressed(_ id: String?) {
        guard pressedID != id else { return }
        pressedID = id
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        host?.rootView = CollageCanvas(
            items: items,
            canvasSize: canvasSize,
            placeholder: placeholder,
            pressedID: id
        )
    }

    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        guard let canvasContainer else { return }
        let point = gesture.location(in: canvasContainer)
        guard let item = items.first(where: { $0.frame.contains(point) }) else { return }
        onSelect?(item.clipping)
    }
}

private final class CanvasContainer: UIView {
    let hostedView: UIView

    init(hostedView: UIView, size: CGSize) {
        self.hostedView = hostedView
        super.init(frame: CGRect(origin: .zero, size: size))
        backgroundColor = .clear
        addSubview(hostedView)
        hostedView.frame = bounds
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostedView.frame = bounds
    }
}
