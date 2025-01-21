import SwiftUI
import MapKit

struct BikeMapContentView: View {
    @Binding var region: MKCoordinateRegion
    let bikes: [Bike]
    @Binding var selectedBike: Bike?
    @Binding var showingBikeDetail: Bool
    let locationManager: LocationManager
    
    private var bikeAnnotations: [MapAnnotationItem] {
        bikes.map { MapAnnotationItem.bike($0) }
    }
    
    private var parkingAnnotations: [MapAnnotationItem] {
        parkingZones.map { zone in
            MapAnnotationItem.parkingIcon(name: zone.name, coordinate: zone.iconCoordinate)
        }
    }
    
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: [.all],
            showsUserLocation: true,
            annotationItems: bikeAnnotations + parkingAnnotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                switch item {
                case .bike(let bike):
                    BikeMapAnnotation(bike: bike, isSelected: bike.id == selectedBike?.id)
                        .onTapGesture {
                            selectedBike = bike
                            showingBikeDetail = true
                        }
                case .parkingIcon(let name, _):
                    ParkingIconView(name: name)
                }
            }
        }
        .overlay(ParkingZonesOverlayView(region: region))
        .edgesIgnoringSafeArea(.all)
    }
}

private struct ParkingIconView: View {
    let name: String
    
    var body: some View {
        VStack {
            Image(systemName: "p.circle.fill")
                .font(.title)
                .foregroundColor(.blue)
                .background(Circle().fill(.white))
                .shadow(radius: 2)
            Text(name)
                .font(.caption)
                .padding(4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)
                .shadow(radius: 2)
        }
    }
}

private struct ParkingZonesOverlayView: View {
    let region: MKCoordinateRegion
    
    var body: some View {
        GeometryReader { proxy in
            ForEach(parkingZones, id: \.name) { zone in
                ParkingZoneOverlay(
                    coordinates: zone.coordinates,
                    mapRect: MKMapRect(region),
                    frameSize: proxy.frame(in: .local).size
                )
            }
        }
    }
}

private struct ParkingZoneOverlay: View {
    let coordinates: [CLLocationCoordinate2D]
    let mapRect: MKMapRect
    let frameSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            guard !coordinates.isEmpty else { return }
            
            let points = coordinates.map { coordinate -> CGPoint in
                let mapPoint = MKMapPoint(coordinate)
                let x = (mapPoint.x - mapRect.origin.x) * size.width / mapRect.size.width
                let y = (mapPoint.y - mapRect.origin.y) * size.height / mapRect.size.height
                return CGPoint(x: x, y: y)
            }
            
            var path = Path()
            path.move(to: points[0])
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.closeSubpath()
            
            context.stroke(path, with: .color(.blue.opacity(0.3)), lineWidth: 2)
            context.fill(path, with: .color(.blue.opacity(0.1)))
        }
    }
} 