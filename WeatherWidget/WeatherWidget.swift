    //
    //  WeatherWidget.swift
    //  WeatherWidget
    //
    //  Created by Philipp Bolte on 22.09.20.
    //
    
    import WidgetKit
    import SwiftUI
    import Intents
    import MapKit
    import CoreLocation
    
    extension UIImage {
        public static func loadFrom(url: URL, completion: @escaping (_ image: UIImage?) -> ()) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        completion(UIImage(data: data))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    struct Provider: TimelineProvider {
        let locationManager = CLLocationManager()
        let defaultCoordinate = CLLocationCoordinate2D.init(latitude: 52.42, longitude: 12.52)

        func placeholder(in context: Context) -> RadarEntry {
            RadarEntry(date: Date(), image: Image(uiImage: UIImage(named: "rain")!))
        }
        
        func getSnapshot(in context: Context, completion: @escaping (RadarEntry) -> ()) {
            let entry = RadarEntry(date: Date(), image: Image(uiImage: UIImage(named: "rain")!))
            completion(entry)
        }
        
        func getTimeline(in context: Context, completion: @escaping (Timeline<RadarEntry>) -> ()) {
            let currentDate = Date()
            let coordinate = locationManager.location?.coordinate ?? self.defaultCoordinate
            print(locationManager.authorizationStatus.rawValue)
            locationManager.requestAlwaysAuthorization()
            
            guard let url = URL(string: "https://.../mapshot/\(coordinate.latitude)/\(coordinate.longitude)/mapshot.png") else { return }
            
            UIImage.loadFrom(url: url) { image in
                if let image = image {
                    let date = Date()
                    
                    let img = Image(uiImage: image)
                    let entry = RadarEntry(
                        date: date,
                        image: img
                    )
                    
                    let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: date)!
                    
                    let timeline = Timeline(
                        entries:[entry],
                        policy: .after(nextUpdateDate)
                    )
                    
                    completion(timeline)
                } else {
                    let entry = RadarEntry(date: currentDate, image: Image(uiImage: UIImage(named: "rain")!))
                    let timeline = Timeline(entries: [entry], policy: .atEnd)
                    completion(timeline)
                }
            }
        }
    }
    
    struct RadarEntry: TimelineEntry {
        let date: Date
        let image: Image
    }
    
    struct WeatherWidgetEntryView : View {
        var entry: Provider.Entry
        
        var body: some View {
            ZStack {
                entry.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(
                        ZStack {
                            Circle()
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                                .frame(width: 15, height: 15)
                            Circle()
                                .foregroundColor(.blue)
                                .frame(width: 10, height: 10)
                        }
                    )
                /*
                GeometryReader { geometry in
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            ZStack {
                                Capsule()
                                    .fill(Color.white)
                                    .opacity(0.8)
                                    .frame(width: 50, height: 25)
                                Text("15:45")
                                    .font(.footnote)
                                    .fontWeight(.light)
                                    .padding()
                            }
                        }
                    }
                    .padding(.trailing, geometry.size.width * 0.03)
                }
                */
            }
        }
    }
    
    @main
    struct WeatherWidget: Widget {
        let kind: String = "WeatherWidget"
        
        var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: Provider()) { entry in
                WeatherWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("Regenradar")
            .description("Regenradar für aktuellen Standort")
        }
    }
    
    struct WeatherWidget_Previews: PreviewProvider {
        static var previews: some View {
            WeatherWidgetEntryView(entry: RadarEntry(date: Date(), image: Image(uiImage: UIImage(named: "rain")!)))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
    }
