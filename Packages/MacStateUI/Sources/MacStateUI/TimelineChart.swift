import SwiftUI

public struct TimelineChart: View {
    private let values: [Double]
    private let tint: Color

    public init(
        values: [Double],
        tint: Color
    ) {
        self.values = values
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(
                    cornerRadius: MetricCardStyle.cornerRadius,
                    style: .continuous
                )
                .fill(tint.opacity(0.08))

                if normalizedPoints.count >= 2 {
                    chartGrid

                    areaPath(in: proxy.size)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.28),
                                    tint.opacity(0.04),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    linePath(in: proxy.size)
                        .stroke(
                            tint,
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                } else if let point = normalizedPoints.first {
                    Circle()
                        .fill(tint)
                        .frame(width: 10, height: 10)
                        .position(
                            x: point.x * proxy.size.width,
                            y: (1 - point.y) * proxy.size.height
                        )
                } else {
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: proxy.size.width * 0.8, height: 8)
                }
            }
        }
        .frame(height: 120)
    }

    private var chartGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                Spacer(minLength: 0)

                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
    }

    private func linePath(in size: CGSize) -> Path {
        Path { path in
            let points = scaledPoints(in: size)
            guard let firstPoint = points.first else {
                return
            }

            path.move(to: firstPoint)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func areaPath(in size: CGSize) -> Path {
        Path { path in
            let points = scaledPoints(in: size)
            guard let firstPoint = points.first,
                  let lastPoint = points.last else {
                return
            }

            path.move(to: CGPoint(x: firstPoint.x, y: size.height))
            path.addLine(to: firstPoint)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            path.addLine(to: CGPoint(x: lastPoint.x, y: size.height))
            path.closeSubpath()
        }
    }

    private func scaledPoints(in size: CGSize) -> [CGPoint] {
        normalizedPoints.map { point in
            CGPoint(
                x: point.x * size.width,
                y: (1 - point.y) * size.height
            )
        }
    }

    private var normalizedPoints: [CGPoint] {
        let clampedValues = values.map { max($0, 0) }
        guard clampedValues.isEmpty == false else {
            return []
        }

        let maximumValue = clampedValues.max() ?? 0
        let minimumValue = clampedValues.min() ?? 0
        let valueRange = max(maximumValue - minimumValue, 0.001)

        return clampedValues.enumerated().map { index, value in
            let horizontalPosition: Double
            if clampedValues.count == 1 {
                horizontalPosition = 0.5
            } else {
                horizontalPosition = Double(index) / Double(clampedValues.count - 1)
            }

            return CGPoint(
                x: horizontalPosition,
                y: (value - minimumValue) / valueRange
            )
        }
    }
}
