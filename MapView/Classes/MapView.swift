//
//  MapView.swift
//  RottenApples
//
//  Created by Andrew Boryk on 6/28/18.
//  Copyright © 2018 Rocket n Mouse. All rights reserved.
//

import GoogleMaps

class MapView: GMSMapView {
    
    private(set) var markers = [Marker]()
    private(set) var polylines = [GMSPolyline]()
    fileprivate(set) var userLocationMarker: Marker?
    private lazy var locationService = UserLocation(delegate: self)
    
    var isUserLocationVisible: Bool = false {
        didSet {
            isUserLocationVisible ? showUserLocationMarker() : hideUserLocation()
        }
    }
    
    var userLocationIcon: UIImage? {
        didSet {
            userLocationMarker?.icon = userLocationIcon
        }
    }
    
    // MARK: - Style
    func styleMapUsing(jsonString: String, completion: @escaping (Error?) -> Void) {
        do {
            mapStyle = try GMSMapStyle(jsonString: jsonString)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func styleMapUsing(fileAt url: URL, completion: @escaping (Error?) -> Void) {
        do {
            mapStyle = try GMSMapStyle(contentsOfFileURL: url)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    // MARK: - Marker
    func addMarker(position: CLLocationCoordinate2D, icon: UIImage? = nil, animated: Bool = false) -> Marker {
        let marker = Marker(position: position, map: self, indicator: icon)
        marker.appearAnimation = animated ? .pop : .none
        markers.append(marker)
        return marker
    }
    
    // MARK: - Polyline
    func fetchAndDraw(polyline: Polyline) {
        polyline.fetchPath { path in
            polyline.path = path
            self.addPolyline(polyline)
        }
    }
    
    func drawPolyline(using path: GMSPath?) {
        DispatchQueue.main.async {
            self.addPolyline(GMSPolyline(path: path))
        }
    }
    
    func addPolyline(_ polyline: GMSPolyline) {
        polyline.map = self
        polylines.append(polyline)
    }
    
    // MARK: - Camera
    func updateCamera(to marker: Marker, zoom: Float = 15.0, animated: Bool = false) {
        updateCamera(position: marker.position, zoom: zoom, animated: animated)
    }
    
    func updateCamera(position: CLLocationCoordinate2D, zoom: Float = 15.0, animated: Bool = false) {
        if animated {
            let update = GMSCameraUpdate.setTarget(position, zoom: zoom)
            animate(with: update)
        } else {
            camera = GMSCameraPosition.camera(withLatitude: position.latitude,
                                              longitude: position.longitude,
                                              zoom: zoom)
        }
    }
    
    func updateCameraToShowAllMarkers(padding: CGFloat, animated: Bool = false) {
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        updateCameraToShowAllMarkers(insets: insets, animated: animated)
    }
    
    func updateCameraToShowAllMarkers(insets: UIEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: Bool = false) {
        var bounds = GMSCoordinateBounds()
        markers.forEach { bounds = bounds.includingCoordinate($0.position) }
        
        if animated {
            let update = GMSCameraUpdate.fit(bounds, with: insets)
            animate(with: update)
        } else if let updatedCamera = camera(for: bounds, insets: insets) {
            camera = updatedCamera
        }
    }
    
    // MARK: - User Location
    func showUserLocationMarker() {
        locationService.startUpdatingLocation()
    }
    
    func hideUserLocation() {
        locationService.stopUpdatingLocation()
        userLocationMarker?.removeFromMap()
        userLocationMarker = nil
    }
    
    // MARK: - Clear
    func clearMarkers() {
        markers.forEach {
            guard $0.id != userLocationMarker?.id, !isUserLocationVisible else {
                return
            }
            
            $0.removeFromMap()
        }
        
        markers.removeAll()
    }
    
    func clearPolylines() {
        polylines.forEach { $0.map = nil }
        polylines.removeAll()
    }
    
    func clearMap() {
        clearMarkers()
        clearPolylines()
    }
}

extension MapView: UserLocationDelegate {
    func didUpdate(_ location: UserLocation) {
        guard let coordinate = location.coordinate else {
            return
        }
        
        if let marker = userLocationMarker {
            marker.position = coordinate
        } else {
            userLocationMarker = addMarker(position: coordinate, icon: userLocationIcon)
        }
    }
    
    func didFailUpdate(_ location: UserLocation, error: Error) {
        // Failed to load user location
    }
}
