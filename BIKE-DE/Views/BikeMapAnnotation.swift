import SwiftUI

struct BikeMapAnnotation: View {
    let bike: Bike
    let isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: "bicycle")
                .font(.title)
                .foregroundColor(bike.isAvailable ? .green : .red)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                )
                .scaleEffect(isSelected ? 1.2 : 1.0)
            if isSelected {
                Text(bike.id)
                    .font(.caption)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
        }
        .contentShape(Rectangle()) // Makes the entire VStack tappable
        .onTapGesture {
            onTap()
        }
    }
} 