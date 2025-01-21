//
//  BikeDetailView.swift
//  BIKE-DE
//
//  Created by Louis Brouwer on 21/01/2025.
//

import SwiftUI

struct BikeDetailView: View {
    @State var bike: Bike
    @State private var rideStarted = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Bike ID: \(bike.id)")
                .font(.largeTitle)
            Text("Location: \(bike.location)")
                .font(.title2)
            Text("Lock Code: \(bike.lockCode)")
                .font(.title)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            Button(action: {
                rideStarted.toggle()
                bike.isAvailable.toggle()
            }) {
                Text(rideStarted ? "End Ride" : "Start Ride")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(rideStarted ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Bike Details")
    }
}

struct BikeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BikeDetailView(bike: sampleBikes[0])
    }
}

