import Cocoa

class NiftiQuadView: NSView {
    var niftiImage: NiftiImage? {
        didSet { needsDisplay = true }
    }
    // Always show center slices for each orientation
    private var sliceIndices: (x: Int, y: Int, z: Int) = (0, 0, 0)

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let nifti = niftiImage else { return }
        let dims = nifti.dimensions
        guard dims.count >= 3, dims[0] > 0, dims[1] > 0, dims[2] > 0 else { return }

        // Center slices
        sliceIndices = (dims[0] / 2, dims[1] / 2, dims[2] / 2)

        let midX = bounds.midX
        let midY = bounds.midY

        // Quadrant Frames
        let q1 = NSRect(x: 0, y: midY, width: midX, height: bounds.height/2) // Top Left: Axial (Z)
        let q2 = NSRect(x: midX, y: midY, width: midX, height: bounds.height/2) // Top Right: Sagittal (X)
        let q3 = NSRect(x: 0, y: 0, width: midX, height: bounds.height/2) // Bottom Left: Coronal (Y)
        let q4 = NSRect(x: midX, y: 0, width: midX, height: bounds.height/2) // Bottom Right: Info panel

        // Axial (Z) in Q1
        if let slice = nifti.sliceZ(sliceIndices.z) {
            drawSlice(slice: slice, width: dims[0], height: dims[1], in: q1)
        }
        // Sagittal (X) in Q2
        if let slice = nifti.sliceX(sliceIndices.x) {
            drawSlice(slice: slice, width: dims[1], height: dims[2], in: q2)
        }
        // Coronal (Y) in Q3
        if let slice = nifti.sliceY(sliceIndices.y) {
            drawSlice(slice: slice, width: dims[0], height: dims[2], in: q3)
        }
        // Info in Q4
        drawInfo(in: q4)
    }

    func drawSlice(slice: [Float], width: Int, height: Int, in rect: NSRect) {
        guard slice.count == width * height else { return }
        guard let min = slice.min(), let max = slice.max(), max > min else { return }

        let pixels = slice.map { UInt8(255 * (($0 - min) / (max - min))) }
        let data = Data(pixels)
        guard let provider = CGDataProvider(data: data as CFData) else { return }
        guard let cgImage = CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bitsPerPixel: 8,
                                    bytesPerRow: width,
                                    space: CGColorSpaceCreateDeviceGray(),
                                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent) else { return }

        let context = NSGraphicsContext.current!.cgContext
        context.saveGState()
        context.interpolationQuality = .high
        context.draw(cgImage, in: rect)
        context.restoreGState()
    }

    func drawInfo(in rect: NSRect) {
        guard let nifti = niftiImage else { return }
        let dims = nifti.dimensions
        let spacing = nifti.spacing
        let nVolumes = dims.count > 3 ? dims[3] : 1
        let dtype = nifti.dataTypeDescription

        let infoText = """
        NIfTI Image Info

        Dimensions: \(dims.map { "\($0)" }.joined(separator: "×"))
        Spacing: \(spacing.map { String(format: "%.3f", $0) }.joined(separator: ", "))
        Volumes: \(nVolumes)
        Data type: \(dtype)
        """

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]

        // Padding within the rect
        let textRect = rect.insetBy(dx: 10, dy: 10)
        infoText.draw(in: textRect, withAttributes: attrs)
    }
}
