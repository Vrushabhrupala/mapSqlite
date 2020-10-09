//
//  ViewController.swift
//  mapSqlite
//
//  Created by Vrushabh Rupala on 08/10/20.
//
// https://medium.com/macoclock/adding-a-guided-tour-to-your-ios-app-995f5618bf68
import UIKit
import GoogleMaps
import CoreLocation
import SQLite3

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var mapView: GMSMapView!
    
    let marker = GMSMarker()
    let path = GMSMutablePath()
    let locationManager = CLLocationManager()
    
    var db: OpaquePointer?
    //var heroList = [Hero]()
    
    var longitude = "14.11"
    var latitude = "15.14"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Map
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        //SQLite
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("LocationDatabase.sqlite")
 
 
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
 
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Locations (id INTEGER PRIMARY KEY AUTOINCREMENT, latitude TEXT, longitude TEXT)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
 
    }


}

extension ViewController{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        guard status == .authorizedWhenInUse else {
          return
        }
        
        locationManager.startUpdatingLocation()
          
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
        
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        path.add(CLLocationCoordinate2D(latitude: locValue.latitude, longitude: locValue.longitude))
        let line = GMSPolyline(path: path)
        line.map = mapView
        
        latitude = String(locValue.latitude)
        longitude = String(locValue.longitude)
        
        sqlitework(funcLat: latitude, funcLog: longitude)
        print(latitude, longitude)
        
    }
    
    
    
    func sqlitework(funcLat: String, funcLog: String){
        
        let func1Lat = funcLat as NSString
        let func1Log = funcLog as NSString
        
        var stmt:OpaquePointer?
        
        let queryString = "INSERT INTO Locations (latitude, longitude) VALUES (?,?)"
        //print(funcLat, funcLog)
 
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }

        if sqlite3_bind_text(stmt, 1, func1Lat.utf8String, -1, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name1: \(errmsg)")
            return
        }

        if sqlite3_bind_text(stmt, 2, func1Log.utf8String, -1, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name2: \(errmsg)")
            return
        }

        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure inserting hero: \(errmsg)")
            return
        }
        
        uploadToPHP(upLat: func1Lat, upLog: func1Log)
    }
    
    // if you need to read sqlite files
    func readValues(){
 
        let queryString = "SELECT * FROM Locations"
 
        var stmt:OpaquePointer?
 
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }
 
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let id = sqlite3_column_int(stmt, 0)
            let lat = String(cString: sqlite3_column_text(stmt, 1))
            let log = String(cString: sqlite3_column_text(stmt, 2))
            
            print(id, lat, log)
        }
    }
    
    func uploadToPHP(upLat: NSString, upLog: NSString){
        let myUrl = URL(string: "http://192.168.0.117/sdb/sdb2.php");
        var request = URLRequest(url:myUrl!);
        request.httpMethod = "POST";

        let postString = "latitude=\(upLat)&longitude=\(upLog)";
        request.httpBody = postString.data(using: String.Encoding.utf8);

        URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) -> Void in
                if error != nil {
                    print("fail")
                    return
                }
            
            let outputStr = String(data: data!, encoding: String.Encoding.utf8) as String?
            
            print(outputStr as Any)
            
        }).resume()
    }
    
}

