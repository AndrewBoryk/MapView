//
//  UserLocation.swift
//  MapView
//
//  Created by Andrew Boryk on 7/2/18.
//  Copyright © 2018 Rocket n Mouse. All rights reserved.
//

import CoreLocation

protocol UserLocationDelegate: class {
    
    func didUpdate(_ location: UserLocation)
    func didFailUpdate(_ location: UserLocation, error: Error)
}

class UserLocation: NSObject {
    
    weak var delegate: UserLocationDelegate?
    var latitude: Double?
    var longitude: Double?
    var isLocationRequesting = false
    var updateLocationContinuously = false
    
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private let locationManager = CLLocationManager()
    
    // MARK: - Initialize
    init(delegate: UserLocationDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - Shared
    func startUpdatingLocation() {
        guard !isLocationRequesting else {
            return
        }
        
        isLocationRequesting = true
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        updateLocationContinuously = false
        isLocationRequesting = false
        locationManager.stopUpdatingLocation()
    }
}

extension UserLocation: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if !updateLocationContinuously {
            stopUpdatingLocation()
        }
        
        delegate?.didFailUpdate(self, error: error)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, location.horizontalAccuracy > 0 {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
        }
        
        if !updateLocationContinuously {
            stopUpdatingLocation()
        }
        
        delegate?.didUpdate(self)
    }
}
