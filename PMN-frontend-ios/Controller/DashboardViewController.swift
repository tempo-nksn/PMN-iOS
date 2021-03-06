//
//  DashboardViewController.swift
//  PMN-frontend-ios
//
//  Created by bharath on 2019/02/16.
//  Copyright © 2019 bharath. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import MapKit
import CoreLocation

class DashboardViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate {
    
    
    //MARK- Local Variables
    
    var vehicles = ["cycle","car"]
    var selected = 1
    var userId = 3
    var name = "Hello User"
    
    //MARK:- Map options
    var locationManager = CLLocationManager()
    var location = CLLocation(latitude: 37.3321, longitude: -122.0318)
    

    
    //MARK:- IBOutlets
    
    @IBOutlet weak var MainLabel: UILabel!
    @IBOutlet weak var VehicleTypePicker: UIPickerView!
    @IBOutlet weak var startDate: UITextField!
    @IBOutlet weak var endDate: UITextField!
    @IBOutlet weak var startHr: UITextField!
    @IBOutlet weak var endHr: UITextField!
    @IBOutlet weak var startMin: UITextField!
    @IBOutlet weak var endMin: UITextField!
    @IBOutlet weak var locationButton: UIButton!
    
    //MARK:- PickerView Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
         return vehicles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selected = row
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return vehicles[row]
    }
    
    //MARK:- Button presses
    @IBAction func listingButtonPressed(_ sender: UIButton) {
        getAlamoListing()
    }
    
    @IBAction func ParkMeButtonPressed(_ sender: Any) {
        
        let vehicleType = selected+1 //1 index
        let lat = location.coordinate.latitude as Double
        let lon = location.coordinate.longitude as Double
        let srttime = self.startDate.text!+"T"+self.startHr.text!+"00:00.000Z"
        let endtime = self.endDate.text!+"T"+self.endHr.text!+"00:00.000Z"

        let parameters : [String: Any] = [
            "Type" : vehicleType,
            "Lat": lat,
            "Long": lon,
            "StartTime" : srttime,
            "EndTime" : endtime
        ]
        AlamoPostParkMeNow(with: parameters)
      
        
    }
    
    func AlamoPostParkMeNow(with parameters: [String : Any]){
        let bearer = "Bearer "+globalData.accessToken
        print(bearer)
        
        let headers: HTTPHeaders = [
            "Authorization": bearer,
            "Accept": "application/json"
        ]
        
        //TODO Add authentication headers later
        Alamofire.request( globalData.parkMeURL , method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                if let data = response.data {
                    do{
                       let properties = self.parse(json: data)
                        self.instantiateParkingview(with: properties)
                    }
                }
        }
    }
    
    func instantiateParkingview(with properties: [property]){
        let vc = ShowParkingViewController(nibName: "ShowParkingViewController", bundle: nil)
        vc.properties = properties
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MainLabel.text = name
        VehicleTypePicker.delegate = self
        VehicleTypePicker.dataSource = self
        
        self.startMin.text = "00"
        self.startMin.allowsEditingTextAttributes = false
        
        self.endMin.text = "00"
        self.endMin.allowsEditingTextAttributes = false
        
  
        
        //Location fetch
        if CLLocationManager.locationServicesEnabled() == true {
            
            if CLLocationManager.authorizationStatus() == .restricted || CLLocationManager.authorizationStatus() == .denied ||  CLLocationManager.authorizationStatus() == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        } else {
            print("PLease turn on location services or GPS")
        }
    }

        
    
    
    func getAlamoListing(){
        
        let bearer = "Bearer "+globalData.accessToken
        print(bearer)
        
        let headers: HTTPHeaders = [
            "Authorization": bearer,
            "Accept": "application/json"
        ]
  
        Alamofire.request( globalData.listingURL , method: .get, headers: headers)
            .responseJSON { response in
                if let data = response.data {
                    do{
                        let properties = self.parse(json: data)
                        print("In dashboard")
                        print(properties)
                        self.callListings(with: properties)
                    }
                }
        }
    }
    
    func parse(json: Data) ->[property] {
        
        let decoder = JSONDecoder()
        do {
            let properties = try decoder.decode([property].self, from: json)
            return properties
            
        } catch {
            print("error trying to convert data to JSON")
            print(error)
            return []
        }
        
    }
    
    func callListings(with properties: [property]){
        let vc = ListingsViewController(nibName: "ListingsViewController", bundle: nil)
        vc.myProperties = properties
        self.navigationController?.pushViewController(vc, animated: true)
    }

// Print out the location to the console
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationnow = locations.first {
            self.location = locationnow
   
            getReversedLocation(with: locationnow)
        }
    }
    
    func getReversedLocation(with location: CLLocation){
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            
            guard let placemark = placemarks?.first else {
                let errorString = error?.localizedDescription ?? "Unexpected Error"
                print("Unable to reverse geocode the given location. Error: \(errorString)")
                return
            }
            
            let reversedGeoLocation = ReversedGeoLocation(with: placemark)
            print(reversedGeoLocation.cityName)
            self.locationButton.setTitle(reversedGeoLocation.cityName, for: .normal)
        }
    }
 
    
}
