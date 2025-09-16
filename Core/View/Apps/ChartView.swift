import SwiftUI
import MagicCore
import Charts

struct ChartView: View {
    /// 可选：指定应用ID时仅统计该应用
    let appId: String?
    /// 可选：自定义标题
    let title: String?
    @EnvironmentObject private var eventRepo: EventRepo
    @State private var points: [DataPoint] = []
    @State private var smoothed: [DataPoint] = []
    @State private var hoverIndex: Int? = nil
    @State private var lockedIndex: Int? = nil
    @State private var range: RangeOption = .hour

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title ?? (appId == nil ? "联网次数" : "应用联网次数"))
                    .font(.headline)
                Spacer()
                let total = points.reduce(0) { $0 + $1.count }
                Text("合计 \(total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Picker("范围", selection: $range) {
                ForEach(RangeOption.allCases) { opt in
                    Text(opt.title).tag(opt)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: range) { _, _ in
                Task { await loadData() }
            }

            Chart {
                ForEach(smoothed) { p in
                    LineMark(
                        x: .value("Time", p.time),
                        y: .value("Count", p.count)
                    )
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                ForEach(smoothed) { p in
                    AreaMark(
                        x: .value("Time", p.time),
                        y: .value("Count", p.count)
                    )
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0)]), startPoint: .top, endPoint: .bottom))
                }
            }
            .chartLegend(.hidden)
            .chartXScale(domain: (smoothed.first?.time ?? Date())...(smoothed.last?.time ?? Date()))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel() {
                        if let date = value.as(Date.self) {
                            formattedXLabel(for: date)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 160)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(loadData)
    }
}

// MARK: - Action
extension ChartView {
    private func loadData() async {
        let calendar = Calendar.current
        do {
            let now = Date()
            let startDate = range.startDate(from: now, calendar: calendar)
            var events = try await eventRepo.fetchByTimeRange(from: startDate, to: now)
            if let appId { events = events.filter { $0.sourceAppIdentifier == appId } }

            guard events.isNotEmpty else {
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
            let formatter = DateFormatter()
            formatter.dateFormat = range.dateFormat
            let sortedKeys = buckets.keys.sorted()
            let newPoints: [DataPoint] = sortedKeys.enumerated().map { idx, d in
                DataPoint(index: idx, time: d, count: buckets[d] ?? 0, label: formatter.string(from: d))
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
    private func colorForBar(index: Int) -> Color {
        let isSelected = (lockedIndex ?? hoverIndex) == index
        return isSelected ? Color.accentColor : Color.accentColor.opacity(0.7)
    }

    private func tooltipText(for index: Int) -> String {
        guard smoothed.indices.contains(index) else { return "" }
        let item = smoothed[index]
        return "\(item.label) · \(item.count)"
    }

    private func nearestIndex(to date: Date) -> Int? {
        guard smoothed.isNotEmpty else { return nil }
        var bestIdx = 0
        var bestDist = abs(smoothed[0].time.timeIntervalSince(date))
        for i in 1..<smoothed.count {
            let d = abs(smoothed[i].time.timeIntervalSince(date))
            if d < bestDist { bestDist = d; bestIdx = i }
        }
        return bestIdx
    }

    private func movingAverage(_ input: [DataPoint], window: Int) -> [DataPoint] {
        guard window > 1, input.isNotEmpty else { return input }
        var result: [DataPoint] = []
        var sum = 0
        var queue: [Int] = []
        for (idx, p) in input.enumerated() {
            sum += p.count
            queue.append(p.count)
            if queue.count > window { sum -= queue.removeFirst() }
            let avg = Double(sum) / Double(queue.count)
            result.append(DataPoint(index: idx, time: p.time, count: Int(avg.rounded()), label: p.label))
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
        let label: String
    }
    enum BucketUnit { case minute, hour, day }
    enum RangeOption: String, CaseIterable, Identifiable {
        case hour
        case last7
        case last30

        var id: String { rawValue }
        var title: String {
            switch self {
            case .hour: return "按小时"
            case .last7: return "近7天"
            case .last30: return "近30天"
            }
        }
        var unit: BucketUnit {
            switch self {
            case .hour: return .minute
            case .last7: return .hour
            case .last30: return .day
            }
        }
        var dateFormat: String {
            switch self {
            case .hour: return "HH:mm"
            case .last7: return "MM/dd HH"
            case .last30: return "MM/dd"
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

// MARK: - Label helpers
private extension ChartView {
    func formattedXLabel(for date: Date) -> Text {
        switch range {
        case .hour:
            return Text(date, format: .dateTime.hour().minute())
        case .last7:
            // 月/日 小时
            let f = DateFormatter(); f.dateFormat = "MM/dd HH"
            return Text(f.string(from: date))
        case .last30:
            let f = DateFormatter(); f.dateFormat = "MM/dd"
            return Text(f.string(from: date))
        }
    }
}

// MARK: - Preview

#Preview("DailyTrafficChartView") {
    ChartView(appId: nil, title: nil)
        .inRootView()
        .frame(width: 600, height: 200)
}

#Preview("APP") {
    ContentView().inRootView()
        .frame(height: 600)
}
