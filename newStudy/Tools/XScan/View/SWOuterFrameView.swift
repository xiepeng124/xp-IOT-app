import UIKit

final class SWOuterFrameView: UIView {
    private let cornerColor: UIColor
    private let cornerWidth: CGFloat = 8
    private let cornerLength: CGFloat = 25
    private let inset: CGFloat = 4

    init(frame: CGRect, color: UIColor) {
        cornerColor = color
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let width = SWScannerLayout.scannerWidth(in: UIScreen.main.bounds.size)
        let originX = (bounds.width - width) / 2
        let originY: CGFloat = 0
        let corners: [UIBezierPath] = [
            path(from: CGPoint(x: originX + cornerLength, y: originY + inset),
                 to: CGPoint(x: originX, y: originY + inset),
                 then: CGPoint(x: originX, y: originY + cornerLength)),
            path(from: CGPoint(x: originX + width - cornerLength, y: originY + inset),
                 to: CGPoint(x: originX + width, y: originY + inset),
                 then: CGPoint(x: originX + width, y: originY + cornerLength)),
            path(from: CGPoint(x: originX, y: originY + width - cornerLength),
                 to: CGPoint(x: originX, y: originY + width - inset),
                 then: CGPoint(x: originX + cornerLength, y: originY + width - inset)),
            path(from: CGPoint(x: originX + width - cornerLength, y: originY + width - inset),
                 to: CGPoint(x: originX + width, y: originY + width - inset),
                 then: CGPoint(x: originX + width, y: originY + width - cornerLength))
        ]
        cornerColor.setStroke()
        corners.forEach { $0.stroke() }
    }

    private func path(from: CGPoint, to: CGPoint, then: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = cornerWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: from)
        path.addLine(to: to)
        path.addLine(to: then)
        return path
    }
}
