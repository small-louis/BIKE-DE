import SwiftUI
import MapKit

// MARK: - Main View
struct BikeMapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.4827, longitude: -0.1277),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var bikes: [Bike]
    @State private var selectedBike: Bike?
    @State private var showingBikeDetail = false
    
    init(bikes: [Bike] = sampleBikes) {
        _bikes = State(initialValue: bikes)
    }
    
    var body: some View {
        let content = BikeMapContentView(
            region: $region,
            bikes: bikes,
            selectedBike: $selectedBike,
            showingBikeDetail: $showingBikeDetail,
            locationManager: locationManager
        )
        
        let locationButton = LocationButtonView(region: $region, locationManager: locationManager)
        
        ZStack {
            content
            locationButton
            if locationManager.permissionDenied {
                PermissionDeniedView()
            }
        }
        .sheet(isPresented: $showingBikeDetail) {
            if let bike = selectedBike {
                BikeDetailView(bike: bike)
            }
        }
        .onAppear {
            locationManager.requestLocation()
            if let location = locationManager.location {
                region.center = location.coordinate
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                region.center = location.coordinate
            }
        }
    }
}

// MARK: - Location Button View
private struct LocationButtonView: View {
    @Binding var region: MKCoordinateRegion
    let locationManager: LocationManager
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    if let location = locationManager.location {
                        region.center = location.coordinate
                    }
                }) {
                    Image(systemName: "location.fill")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
}

// MARK: - Permission Denied View
private struct PermissionDeniedView: View {
    var body: some View {
        VStack {
            Text("Location Access Required")
                .font(.title)
                .padding()
            Text("Please enable location services in Settings to use all features of this app.")
                .multilineTextAlignment(.center)
                .padding()
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .padding()
    }
}

// MARK: - Preview Provider
#if DEBUG
struct BikeMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BikeMapView(bikes: sampleBikes)
                .navigationTitle("Campus Bikes")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
#endif