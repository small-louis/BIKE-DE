import Foundation
import MapKit

enum MapAnnotationItem: Identifiable {
    case bike(Bike)
    case parkingIcon(name: String, coordinate: CLLocationCoordinate2D)
    
    var id: String {
        switch self {
        case .bike(let bike):
            return bike.id
        case .parkingIcon(let name, _):
            return "parkingIcon_\(name)"
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .bike(let bike):
            return bike.coordinates
        case .parkingIcon(_, let coordinate):
            return coordinate
        }
    }
} 