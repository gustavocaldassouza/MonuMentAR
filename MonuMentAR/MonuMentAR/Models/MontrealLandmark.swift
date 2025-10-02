import Foundation
import CoreLocation

struct MontrealLandmark: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let coordinates: CLLocationCoordinate2D
    let historicalInfo: String
    let architecturalStyle: String
    let yearBuilt: String
    
    // GPS-based detection properties
    let height: Double // Height above ground level in meters
    let footprintRadius: Double // Approximate radius of the landmark in meters
    let elevationAboveSeaLevel: Double // Elevation in meters above sea level
    
    // Core ML model identifier for recognition (legacy)
    let modelIdentifier: String
    
    static let landmarks: [MontrealLandmark] = [
        MontrealLandmark(
            name: "Notre-Dame Basilica",
            description: "A stunning Gothic Revival basilica in Old Montreal",
            coordinates: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5563),
            historicalInfo: "Built between 1824-1829, this basilica is a masterpiece of Gothic Revival architecture and one of Montreal's most iconic landmarks.",
            architecturalStyle: "Gothic Revival",
            yearBuilt: "1829",
            height: 69.0, // Twin towers height
            footprintRadius: 50.0, // Approximate building footprint
            elevationAboveSeaLevel: 20.0, // Old Montreal elevation
            modelIdentifier: "notre_dame_basilica"
        ),
        MontrealLandmark(
            name: "Olympic Stadium & Tower",
            description: "The iconic Olympic Stadium with its distinctive inclined tower",
            coordinates: CLLocationCoordinate2D(latitude: 45.5580, longitude: -73.5516),
            historicalInfo: "Built for the 1976 Summer Olympics, the stadium features the world's tallest inclined tower at 165 meters.",
            architecturalStyle: "Modernist",
            yearBuilt: "1976",
            height: 165.0, // Tower height
            footprintRadius: 200.0, // Large stadium complex
            elevationAboveSeaLevel: 35.0, // East Montreal elevation
            modelIdentifier: "olympic_stadium_tower"
        ),
        MontrealLandmark(
            name: "Mount Royal Cross",
            description: "The illuminated cross atop Mount Royal overlooking the city",
            coordinates: CLLocationCoordinate2D(latitude: 45.5048, longitude: -73.5881),
            historicalInfo: "The current cross was erected in 1924 and is illuminated at night, serving as a symbol of Montreal's Catholic heritage.",
            architecturalStyle: "Neo-Gothic",
            yearBuilt: "1924",
            height: 31.4, // Cross height
            footprintRadius: 10.0, // Small footprint
            elevationAboveSeaLevel: 233.0, // Mount Royal summit elevation
            modelIdentifier: "mount_royal_cross"
        ),
        MontrealLandmark(
            name: "Old Port Clock Tower",
            description: "The historic clock tower at the Old Port of Montreal",
            coordinates: CLLocationCoordinate2D(latitude: 45.5019, longitude: -73.5508),
            historicalInfo: "Built in 1922, this clock tower is part of the Old Port's heritage and offers panoramic views of the St. Lawrence River.",
            architecturalStyle: "Beaux-Arts",
            yearBuilt: "1922",
            height: 45.0, // Tower height
            footprintRadius: 15.0, // Tower base
            elevationAboveSeaLevel: 15.0, // Port level elevation
            modelIdentifier: "old_port_clock_tower"
        ),
        MontrealLandmark(
            name: "Saint Joseph's Oratory",
            description: "The largest church in Canada and a major pilgrimage site",
            coordinates: CLLocationCoordinate2D(latitude: 45.4914, longitude: -73.6170),
            historicalInfo: "Construction began in 1904 and was completed in 1967. It's the largest church in Canada and a major Catholic pilgrimage site.",
            architecturalStyle: "Italian Renaissance",
            yearBuilt: "1967",
            height: 97.0, // Dome height
            footprintRadius: 80.0, // Large basilica complex
            elevationAboveSeaLevel: 165.0, // Westmount elevation
            modelIdentifier: "saint_josephs_oratory"
        ),
        MontrealLandmark(
            name: "Collège de La Salle",
            description: "Historic educational institution founded by the Christian Brothers",
            coordinates: CLLocationCoordinate2D(latitude: 45.4267, longitude: -73.6567), // Lachine area
            historicalInfo: "Founded by the Christian Brothers (Frères des Écoles chrétiennes), this institution has been providing education in Montreal for over a century, continuing the educational mission of Saint John Baptist de La Salle.",
            architecturalStyle: "Institutional Modern",
            yearBuilt: "1888",
            height: 25.0, // Typical institutional building height
            footprintRadius: 100.0, // Large educational complex
            elevationAboveSeaLevel: 30.0, // Lachine area elevation
            modelIdentifier: "college_la_salle"
        )
    ]
}

// Extension to make CLLocationCoordinate2D codable
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

