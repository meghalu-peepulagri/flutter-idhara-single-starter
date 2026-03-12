import WidgetKit
import SwiftUI

struct PumpData: Decodable, Identifiable {
    let id: Int
    let name: String
    let isRunning: Bool
    let signalQuality: Int
    let fault: Int
    let faultDesc: String
    let runTimeMinutes: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), pumps: [
            PumpData(id: 1, name: "Pump 1", isRunning: false, signalQuality: 80, fault: 0, faultDesc: "", runTimeMinutes: 40),
            PumpData(id: 2, name: "Pump 2", isRunning: false, signalQuality: 90, fault: 0, faultDesc: "", runTimeMinutes: 55)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), pumps: getPumps())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Update widget every 5 minutes if not updated by Flutter
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let entry = SimpleEntry(date: Date(), pumps: getPumps())
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getPumps() -> [PumpData] {
        // App group ID MUST MATCH what is set in Flutter's WidgetService.appGroupId
        // and also added in Xcode's App Groups capability
        let sharedDefaults = UserDefaults(suiteName: "group.com.idhara.app")
        let widgetDataString = sharedDefaults?.string(forKey: "pump_data") ?? "[]"
        
        guard let data = widgetDataString.data(using: .utf8) else { return [] }
        
        do {
            let pumps = try JSONDecoder().decode([PumpData].self, from: data)
            return pumps
        } catch {
            print("Error decoding pump data: \(error)")
            return []
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let pumps: [PumpData]
}

struct PumpWidgetEntryView : View {
    var entry: Provider.Entry
    
    // UI Colors based on Android design
    let bgDark = Color(red: 44/255, green: 52/255, blue: 64/255)
    let colors: [Color] = [
        Color(red: 0.25, green: 0.64, blue: 0.96), // Blue
        Color(red: 0.40, green: 0.73, blue: 0.41), // Green
        Color(red: 1.00, green: 0.65, blue: 0.14), // Orange
        Color(red: 0.92, green: 0.25, blue: 0.47), // Pink
        Color(red: 0.67, green: 0.27, blue: 0.73)  // Purple
    ]

    var body: some View {
        ZStack {
            bgDark.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                if entry.pumps.isEmpty {
                    Text("No pumps available")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                } else {
                    ForEach(Array(entry.pumps.enumerated()), id: \.element.id) { index, pump in
                        HStack {
                            Text(pump.name)
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 60, alignment: .leading)
                            
                            // Fake progress UI or real if we track start/end
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.black.opacity(0.3))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colors[index % colors.count])
                                        .frame(
                                            width: pump.isRunning ? max(geometry.size.width * 0.1, geometry.size.width * CGFloat(min(max(pump.runTimeMinutes, 20), 100)) / 100.0) : 0,
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)
                            
                            if pump.fault != 0 {
                                Text("FAULT")
                                    .foregroundColor(.red)
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 30, alignment: .center)
                            } else {
                                Text(pump.isRunning ? "ON" : "OFF")
                                    .foregroundColor(pump.isRunning ? .white : .gray)
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 30, alignment: .center)
                            }
                            
                            Text("\(pump.signalQuality)%")
                                .foregroundColor(colors[index % colors.count])
                                .font(.system(size: 10, weight: .bold))
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

@main
struct PumpWidget: Widget {
    let kind: String = "PumpWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PumpWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("i Dhara Pumps")
        .description("View your pump statuses natively.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
