import LumiUI
import ProviderFirewallEvents
import ProviderViewEnvironment
import SwiftUI

struct ChartView: View {
    /// 可选：指定应用ID时仅统计该应用
    let appId: String?
    /// 可选：自定义标题
    let title: String?
    @Environment(\.eventsProvider) private var eventRepo: FirewallEventsProviding?
    @State private var points: [DataPoint] = []
    @State private var smoothed: [DataPoint] = []
    @State private var range: RangeOption = .hour
    @LumiTheme private var theme

    private var total: Int {
        points.reduce(0) { $0 + $1.count }
    }

    private var selection: Binding<Int> {
        Binding(
            get: { RangeOption.allCases.firstIndex(of: range) ?? 0 },
            set: { range = RangeOption.allCases[$0] }
        )
    }

    var body: some View {
        AppCard(
            style: .subtle,
            cornerRadius: DesignTokens.Radius.md,
            showShadow: false
        ) {
            VStack(alignment: .leading, spacing: AppUI.Spacing.sm) {
                HStack {
                    Text(title ?? (appId == nil ? String(localized: "Connection Count") : String(localized: "App Connection Count")))
                        .font(.appSectionTitle)
                        .foregroundStyle(theme.textPrimary)

                    Spacer()

                    Text("Total \(total)")
                        .font(.appCaption)
                        .foregroundStyle(theme.textSecondary)
                }

                AppSegmentedControl(
                    RangeOption.allCases.map(\.title),
                    selection: selection,
                    maxWidth: 240
                )
                .onChange(of: range) { _, _ in
                    Task { await loadData() }
                }

                AppLineChart(
                    points: smoothed.map { AppLineChartPoint(date: $0.time, value: Double($0.count)) },
                    accessibilityLabel: String(localized: "Connection Count Trend"),
                    pointStyle: .automatic,
                    showsArea: true
                )
                .frame(height: 160)
            }
        }
        .task(loadData)
    }
}

// MARK: - Action
extension ChartView {
    private func loadData() async {
        let calendar = Calendar.current
        do {
            guard let eventRepo else { return }
            let now = Date()
            let startDate = range.startDate(from: now, calendar: calendar)
            var events = try await eventRepo.fetchByTimeRange(from: startDate, to: now, appIdentifier: nil)
            if let appId { events = events.filter { $0.sourceAppIdentifier == appId } }

            guard !events.isEmpty else {
                setPoints([])
                return
            }

            // 归一化到桶起始（按分钟/小时/天）
            func bucketStart(_ date: Date) -> Date {
                switch range.unit {
                case .minute:
                    if let iv = calendar.dateInterval(of: .minute, for: date) { return iv.start }
                    var c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                    c.second = 0; c.nanosecond = 0
                    return calendar.date(from: c) ?? date
                case .hour:
                    if let iv = calendar.dateInterval(of: .hour, for: date) { return iv.start }
                    var c = calendar.dateComponents([.year, .month, .day, .hour], from: date)
                    c.minute = 0; c.second = 0; c.nanosecond = 0
                    return calendar.date(from: c) ?? date
                case .day:
                    return calendar.startOfDay(for: date)
                }
            }

            let allBuckets = events.map { bucketStart($0.time) }
            guard let minBucket = allBuckets.min(), let maxBucket = allBuckets.max() else {
                setPoints([])
                return
            }

            // 初始化桶（包含两端）
            var buckets: [Date: Int] = [:]
            var cursor = bucketStart(minBucket)
            while cursor <= maxBucket {
                buckets[cursor] = 0
                switch range.unit {
                case .minute:
                    guard let next = calendar.date(byAdding: .minute, value: 1, to: cursor) else { break }
                    cursor = next
                case .hour:
                    guard let next = calendar.date(byAdding: .hour, value: 1, to: cursor) else { break }
                    cursor = next
                case .day:
                    guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                    cursor = next
                }
            }

            // 聚合到对应粒度
            for e in events {
                let key = bucketStart(e.time)
                buckets[key, default: 0] += 1
            }

            // 输出
            let sortedKeys = buckets.keys.sorted()
            let newPoints: [DataPoint] = sortedKeys.enumerated().map { idx, d in
                DataPoint(index: idx, time: d, count: buckets[d] ?? 0)
            }

            setPoints(newPoints)
        } catch {
            setPoints([])
        }
    }
}

// MARK: - Setter
extension ChartView {
    @MainActor
    private func setPoints(_ newValue: [DataPoint]) {
        self.points = newValue
        self.smoothed = movingAverage(newValue, window: range.smoothingWindow)
    }
}

// MARK: - Private Helpers
extension ChartView {
    private func movingAverage(_ input: [DataPoint], window: Int) -> [DataPoint] {
        guard window > 1, !input.isEmpty else { return input }
        var result: [DataPoint] = []
        var sum = 0
        var queue: [Int] = []
        for (idx, p) in input.enumerated() {
            sum += p.count
            queue.append(p.count)
            if queue.count > window { sum -= queue.removeFirst() }
            let avg = Double(sum) / Double(queue.count)
            result.append(DataPoint(index: idx, time: p.time, count: Int(avg.rounded())))
        }
        return result
    }
}

// MARK: - Types
extension ChartView {
    struct DataPoint: Identifiable {
        let id = UUID()
        let index: Int
        let time: Date
        let count: Int
    }
    enum BucketUnit { case minute, hour, day }
    enum RangeOption: String, CaseIterable, Identifiable {
        case hour
        case last7
        case last30

        var id: String { rawValue }
        var title: String {
            switch self {
            case .hour: return String(localized: "By Hour")
            case .last7: return String(localized: "Last 7 Days")
            case .last30: return String(localized: "Last 30 Days")
            }
        }
        var unit: BucketUnit {
            switch self {
            case .hour: return .minute
            case .last7: return .hour
            case .last30: return .day
            }
        }
        var smoothingWindow: Int {
            switch self {
            case .hour: return 5
            case .last7: return 3
            case .last30: return 1
            }
        }

        func startDate(from now: Date, calendar: Calendar) -> Date {
            switch self {
            case .hour:
                return calendar.date(byAdding: .hour, value: -1, to: now) ?? now
            case .last7:
                return calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .last30:
                return calendar.date(byAdding: .day, value: -30, to: now) ?? now
            }
        }
    }
}

// MARK: - Preview

#Preview("DailyTrafficChartView") {
    ChartView(appId: nil, title: nil)
        .dashboardPreviewRoot()
        .frame(width: 600, height: 200)
}

#Preview("APP") {
    ContentView().dashboardPreviewRoot()
        .frame(height: 600)
}
