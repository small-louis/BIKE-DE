import SwiftUI

struct BikeListView: View {
    @State private var bikes = sampleBikes
    
    var body: some View {
        NavigationView {
            List {
                // Section for Campus A
                Section(header: Text("Battersea").font(.headline)) {
                    ForEach(bikes.filter { $0.location == "Campus A" }) { bike in
                        NavigationLink(destination: BikeDetailView(bike: bike)) {
                            HStack {
                                Text(bike.id)
                                    .font(.headline)
                                Spacer()
                                Text(bike.isAvailable ? "Available" : "In Use")
                                    .foregroundColor(bike.isAvailable ? .green : .red)
                            }
                        }
                    }
                }
                
                // Section for Campus B
                Section(header: Text("Kensington").font(.headline)) {
                    ForEach(bikes.filter { $0.location == "Campus B" }) { bike in
                        NavigationLink(destination: BikeDetailView(bike: bike)) {
                            HStack {
                                Text(bike.id)
                                    .font(.headline)
                                Spacer()
                                Text(bike.isAvailable ? "Available" : "In Use")
                                    .foregroundColor(bike.isAvailable ? .green : .red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Campus Bikes")
            .listStyle(InsetGroupedListStyle()) // Optional: Gives a nicer appearance
        }
    }
}

struct BikeListView_Previews: PreviewProvider {
    static var previews: some View {
        BikeListView()
    }
}


