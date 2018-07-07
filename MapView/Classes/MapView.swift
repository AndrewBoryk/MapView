//
//  MapView.swift
//  MapView
//
//  Created by Andrew Boryk on 6/28/18.
//  Copyright © 2018 Rocket n Mouse. All rights reserved.
//

import GoogleMaps

open class MapView: GMSMapView {
    
    public private(set) var markers = [Marker]()
    public private(set) var polylines = [GMSPolyline]()
    public fileprivate(set) var userLocationMarker: Marker?
    
    private lazy var locationService = UserLocation(delegate: self)
    
    open var isUserLocationVisible: Bool = false {
        didSet {
            isUserLocationVisible ? showUserLocationMarker() : hideUserLocation()
        }
    }
    
    public var userLocationIcon: UIImage? {
        didSet {
            userLocationMarker?.icon = userLocationIcon
        }
    }
    
    // MARK: - Style
    open func styleMapUsing(jsonString: String, completion: @escaping (Error?) -> Void) {
        do {
            mapStyle = try GMSMapStyle(jsonString: jsonString)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    open func styleMapUsing(fileAt url: URL, completion: @escaping (Error?) -> Void) {
        do {
            mapStyle = try GMSMapStyle(contentsOfFileURL: url)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    // MARK: - Marker
    open func addMarker(position: CLLocationCoordinate2D, icon: UIImage? = nil, animated: Bool = false) -> Marker {
        let marker = Marker(position: position, map: self, indicator: icon)
        marker.appearAnimation = animated ? .pop : .none
        markers.append(marker)
        return marker
    }
    
    // MARK: - Polyline
    public func fetchAndDraw(polyline: Polyline) {
        polyline.fetchPath { path in
            polyline.path = path
            self.addPolyline(polyline)
        }
    }
    
    public func drawPolyline(using path: GMSPath?) {
        DispatchQueue.main.async {
            self.addPolyline(GMSPolyline(path: path))
        }
    }
    
    public func addPolyline(_ polyline: GMSPolyline) {
        polyline.map = self
        polylines.append(polyline)
    }
    
    // MARK: - Camera
    public func updateCamera(to marker: Marker, zoom: Float = 15.0, animated: Bool = false) {
        updateCamera(position: marker.position, zoom: zoom, animated: animated)
    }
    
    public func updateCamera(position: CLLocationCoordinate2D, zoom: Float = 15.0, animated: Bool = false) {
        if animated {
            let update = GMSCameraUpdate.setTarget(position, zoom: zoom)
            animate(with: update)
        } else {
            camera = GMSCameraPosition.camera(withLatitude: position.latitude,
                                              longitude: position.longitude,
                                              zoom: zoom)
        }
    }
    
    public func updateCameraToShowAllMarkers(padding: CGFloat, animated: Bool = false) {
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        updateCameraToShowAllMarkers(insets: insets, animated: animated)
    }
    
    public func updateCameraToShowAllMarkers(insets: UIEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: Bool = false) {
        var bounds = GMSCoordinateBounds()
        markers.forEach { bounds = bounds.includingCoordinate($0.position) }
        
        updateCamera(to: bounds, insets: insets, animated: animated)
    }
    
    public func updateCamera(to polyline: GMSPolyline, padding: CGFloat, animated: Bool = false) {
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        updateCamera(to: polyline, insets: insets, animated: animated)
    }
    
    public func updateCamera(to polyline: GMSPolyline, insets: UIEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: Bool = false) {
        updateCameraToShow(polylines: [polyline], insets: insets, animated: animated)
    }
    
    public func updateCameraToShowAllPolylines(padding: CGFloat, animated: Bool = false) {
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        updateCameraToShowAllPolylines(insets: insets, animated: animated)
    }
    
    public func updateCameraToShowAllPolylines(insets: UIEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: Bool = false) {
        updateCameraToShow(polylines: polylines, insets: insets, animated: animated)
    }
    
    public func updateCameraToShow(polylines: [GMSPolyline], insets: UIEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: Bool = false) {
        var bounds = GMSCoordinateBounds()
        
        for polyline in polylines {
            guard let path = polyline.path else {
                continue
            }
            
            for index in 0..<path.count() {
                bounds = bounds.includingCoordinate(path.coordinate(at: index))
            }
        }
        
        updateCamera(to: bounds, insets: insets, animated: animated)
    }
    
    public func updateCamera(to bounds: GMSCoordinateBounds, insets: UIEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: Bool = false) {
        if animated {
            let update = GMSCameraUpdate.fit(bounds, with: insets)
            animate(with: update)
        } else if let updatedCamera = camera(for: bounds, insets: insets) {
            camera = updatedCamera
        }
    }
    
    // MARK: - User Location
    open func showUserLocationMarker() {
        locationService.startUpdatingLocation()
    }
    
    open func hideUserLocation() {
        locationService.stopUpdatingLocation()
        userLocationMarker?.removeFromMap()
        userLocationMarker = nil
    }
    
    // MARK: - Clear
    open func clearMarkers() {
        for marker in markers {
            if let id = marker.id, let userLocationId = userLocationMarker?.id {
                guard id != userLocationId,
                    !isUserLocationVisible else {
                        continue
                }
            }
            
            marker.removeFromMap()
        }
        
        markers.removeAll()
    }
    
    open func clearPolylines() {
        polylines.forEach { $0.map = nil }
        polylines.removeAll()
    }
    
    open func clearMap() {
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
