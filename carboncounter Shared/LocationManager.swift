import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager
    var delegate: CLLocationManagerDelegate?
    var lastLocation: CLLocation?
    var totalDistance: CLLocationDistance = 0.0
    var totalDuration: TimeInterval = 0.0
    var isDriving = false
    var startDrivingDate: Date?
    var carYear: String = ""
    var carMake: String = ""
    var carModel: String = ""
    var emissionsPerMile = 0.0
    
    // Add a property to store car emissions data
    var userCar = [String]()
    var carData = [[String]]()
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func startTrackingDriving() {
        isDriving = true
        startDrivingDate = Date()
        lastLocation = nil
        totalDistance = 0.0
        totalDuration = 0.0
        
        // Start real-time location updates
        startLocationUpdates()
    }
    
    func stopTrackingDriving() {
        isDriving = false
        startDrivingDate = nil
        
        // Calculate and print emissions
        let emissions = calculateEmissions(distance: totalDistance, duration: totalDuration, carYear: carYear, carMake: carMake, carModel: carModel, carData: carData)
        print("Total emissions for the drive: \(String(format: "%.2f", emissions)) grams of CO2")
        
        // Stop location updates
        stopLocationUpdates()
    }
    
    func setCarDetails(year: String, make: String, model: String, list: [[String]]) {
        carYear = year
        carMake = make
        carModel = model
        userCar.append(carYear)
        userCar.append(carMake)
        userCar.append(carModel)
        carData = list
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isDriving else { return }
        guard let newLocation = locations.last else { return }
        
        processLocation(newLocation)
    }
    
    func processLocation(_ location: CLLocation) {
        guard isDriving else { return }
        
        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)
            totalDistance += distance
            if let startDrivingDate = startDrivingDate {
                let duration = Date().timeIntervalSince(startDrivingDate)
                totalDuration += duration
            }
        }
        
        lastLocation = location
        delegate?.locationManager?(locationManager, didUpdateLocations: [location])
        
        // Check if the user is likely in a car (speed > 25 mph)
        if location.speed > 11.176 { // 25 mph in meters per second
            print("User is likely in a car.")
        }
    }
    
    func calculateEmissions(distance: Double, duration: TimeInterval, carYear: String, carMake: String, carModel: String, carData: [[String]]) -> Double {
        // Find car emissions data
        for row in carData {
            if row.count >= 4 && row[0] == carYear && row[1] == carMake && row[2] == carModel {
                emissionsPerMile = (row[3] as NSString).doubleValue
                break
            }
        }
        
        // Convert distance to miles and calculate total emissions
        let distanceInMiles = totalDistance / 1609.34
        let totalEmissions = emissionsPerMile * distanceInMiles
        
        return totalEmissions
    }
}
