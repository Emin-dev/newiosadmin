import SwiftUI

// MARK: - Tone

/// Semantic colour of a status, number or tile. One vocabulary for the whole app.
public enum Tone: Sendable, Hashable {
    case neutral, brand, good, warn, bad, info

    public var color: Color {
        switch self {
        case .neutral: Theme.inkSoft
        case .brand: Theme.goldText
        case .good: Theme.success
        case .warn: Theme.brandSolid
        case .bad: Theme.danger
        case .info: Color.accentColor
        }
    }
}

// MARK: - Press style

/// Press 0.97 with the snappy curve, as in the main app.
public struct PressScale: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}

// MARK: - Card surface

extension View {
    /// The opaque bento surface: card colour, tile radius, soft shadow.
    public func bentoSurface(radius: CGFloat = Theme.Radius.tile) -> some View {
        background(Theme.card, in: .rect(cornerRadius: radius))
            .shadow(color: .black.opacity(0.05), radius: 9, x: 0, y: 4)
    }
}

// MARK: - Status chip

public struct StatusChip: View {
    let label: String
    let tone: Tone

    public init(_ label: String, tone: Tone) {
        self.label = label
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: 5) {
            Circle().fill(tone.color).frame(width: Theme.Size.statusDot, height: Theme.Size.statusDot)
            Text(label)
                .font(Theme.Font.caption2)
                .foregroundStyle(tone == .neutral ? Theme.inkSoft : tone.color)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tone.color.opacity(0.12), in: .capsule)
    }
}

// MARK: - Symbol badge

public struct SymbolBadge: View {
    let symbol: String
    var tone: Tone = .brand
    var size: CGFloat = Theme.Size.smallBadge

    public init(_ symbol: String, tone: Tone = .brand, size: CGFloat = Theme.Size.smallBadge) {
        self.symbol = symbol
        self.tone = tone
        self.size = size
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(tone == .brand ? Theme.brandSolid : tone.color)
            .frame(width: size, height: size)
            .background(tone == .brand ? Theme.brandTint : tone.color.opacity(0.14), in: .circle)
            .accessibilityHidden(true)
    }
}

// MARK: - Stat tile

/// A bento number tile: label on top, big rounded number, one supporting line.
public struct StatTile: View {
    let title: String
    let value: String
    let caption: String?
    let symbol: String?
    let tone: Tone
    let trend: [Double]

    public init(_ title: String, value: String, caption: String? = nil,
                symbol: String? = nil, tone: Tone = .neutral, trend: [Double] = []) {
        self.title = title
        self.value = value
        self.caption = caption
        self.symbol = symbol
        self.tone = tone
        self.trend = trend
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                if let symbol { SymbolBadge(symbol, tone: tone == .neutral ? .brand : tone, size: 28) }
                Text(title.uppercased())
                    .font(Theme.Font.caption2)
                    .tracking(0.6)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
            Text(value)
                .font(Theme.Font.tileNumber)
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if !trend.isEmpty {
                Sparkline(values: trend, tone: tone == .neutral ? .brand : tone)
                    .frame(height: 22)
            }
            if let caption {
                Text(caption)
                    .font(Theme.Font.caption)
                    .foregroundStyle(tone == .bad || tone == .warn ? tone.color : Theme.inkSoft)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .bentoSurface()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Page tile

/// A tile that opens a page. Shows a live count when something waits.
public struct PageTile: View {
    let title: String
    let symbol: String
    let detail: String?
    let badge: Int?
    let badgeTone: Tone

    public init(_ title: String, symbol: String, detail: String? = nil,
                badge: Int? = nil, badgeTone: Tone = .warn) {
        self.title = title
        self.symbol = symbol
        self.detail = detail
        self.badge = badge
        self.badgeTone = badgeTone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                SymbolBadge(symbol)
                Spacer(minLength: 0)
                if let badge, badge > 0 {
                    Text(badge, format: .number)
                        .font(Theme.Font.footnote)
                        .foregroundStyle(badgeTone == .warn ? Theme.onGold : .white)
                        .padding(.horizontal, 8)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(badgeTone == .warn ? Theme.accentAmber : badgeTone.color, in: .capsule)
                }
            }
            Spacer(minLength: 10)
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if let detail {
                Text(detail)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .bentoSurface()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Section header

public struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.ink)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.goldText)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Sparkline

public struct Sparkline: View {
    let values: [Double]
    let tone: Tone

    public init(values: [Double], tone: Tone = .brand) {
        self.values = values
        self.tone = tone
    }

    public var body: some View {
        GeometryReader { geo in
            let points = Self.points(values, in: geo.size)
            ZStack {
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: CGPoint(x: first.x, y: geo.size.height))
                    points.forEach { path.addLine(to: $0) }
                    if let last = points.last { path.addLine(to: CGPoint(x: last.x, y: geo.size.height)) }
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [tone.color.opacity(0.22), tone.color.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    points.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(tone.color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityHidden(true)
    }

    static func points(_ values: [Double], in size: CGSize) -> [CGPoint] {
        guard values.count > 1, let lo = values.min(), let hi = values.max() else { return [] }
        let span = max(hi - lo, 0.0001)
        let step = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { index, value in
            CGPoint(x: CGFloat(index) * step,
                    y: size.height - CGFloat((value - lo) / span) * (size.height - 2) - 1)
        }
    }
}

// MARK: - Bar chart (small, labelled)

public struct MiniBars: View {
    public struct Bar: Identifiable, Sendable {
        public let id: String
        public let label: String
        public let value: Double
        public init(label: String, value: Double) {
            self.id = label
            self.label = label
            self.value = value
        }
    }

    let bars: [Bar]
    let tone: Tone

    public init(_ bars: [Bar], tone: Tone = .brand) {
        self.bars = bars
        self.tone = tone
    }

    public var body: some View {
        let top = max(bars.map(\.value).max() ?? 1, 0.0001)
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(bars) { bar in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(tone == .brand ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(tone.color))
                        .frame(height: max(4, 90 * bar.value / top))
                    Text(bar.label)
                        .font(Theme.Font.caption2)
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(bar.label): \(bar.value.formatted())")
            }
        }
        .frame(height: 112, alignment: .bottom)
    }
}

// MARK: - Key-value row

public struct FieldRow: View {
    let label: String
    let value: String
    let tone: Tone

    public init(_ label: String, value: String, tone: Tone = .neutral) {
        self.label = label
        self.value = value
        self.tone = tone
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.Font.subheadline)
                .foregroundStyle(tone == .neutral ? Theme.ink : tone.color)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Logo

public struct LogoMark: View {
    var size: CGFloat
    public init(size: CGFloat = 40) { self.size = size }
    public var body: some View {
        Image("Logo", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size * 0.225, style: .continuous))
            .accessibilityLabel("Rentbutik")
    }
}

// MARK: - Primary button

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.headline)
            .foregroundStyle(Theme.onGold)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.button)
            .background(Theme.goldGradient, in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}
