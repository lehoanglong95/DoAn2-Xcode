//
//  ViewController.swift
//  LocationInfo
//
//  Created by lehoanglong on 11/26/16.
//  Copyright © 2016 LeHoangLong. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager:CLLocationManager!
    var geoCoder: CLGeocoder!
    var placeMark:CLPlacemark!
    
    //serverside
    let IP_API = "http://172.16.12.131:1791/api/locations"
    
    //local variable
    var latitude = "0.0"
    var longitude = "0.0"
    var subThoroughfare = "unknow"
    var thoroughfare = "unknow"
    var postalCode = "unknow"
    var locality = "unknow"
    var administrative = "unknow"
    var country = "unknow"
    var username = "unknow"
    var timestamp = "unknow"
    
    @IBAction func getLocationClick(sender: UIButton) {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    @IBAction func sendLocationClick(sender: UIButton) {
        //Lấy thời gian hiện tại của hệ thống
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        let dateString = dateFormatter.stringFromDate(date)
        
        //lưu thông tin vào CSDL offline với status = 0
        let queryString = "INSERT INTO main.LocationInfo VALUES (NULL,\(self.latitude),\(self.longitude),'\(self.subThoroughfare)','\(self.thoroughfare)','\(self.postalCode)','\(self.locality)','\(administrative)','\(self.country)','\(textUsername.text)','\(dateString)','0')"
        let dbInsert: COpaquePointer = connectdb("LocationInfo", type: "sqlite")
        self.db_query(queryString, database: dbInsert)
        sqlite3_close(dbInsert)
        
        //Gửi dữ liệu lên máy chủ, lấy dữ liệu từ CSDL offline, chỉ gửi những row có status = 0, gửi thành công update status = 1
        var alertString = ""
        let dbSelect: COpaquePointer = connectdb("LocationInfo", type: "sqlite")
        let statement: COpaquePointer = self.db_select("SELECT * FROM LocationInfo", database: dbSelect)
        while sqlite3_step(statement) == SQLITE_ROW {
            let rowData11 = sqlite3_column_text(statement, 11)
            let status = String.fromCString(UnsafePointer<CChar>(rowData11))
            if(status != "1"){
                let rowData0 = sqlite3_column_text(statement, 0)
                let tmpID = String.fromCString(UnsafePointer<CChar>(rowData0))
                
                let rowData1 = sqlite3_column_text(statement, 1)
                let tmpLatitude = String.fromCString(UnsafePointer<CChar>(rowData1))
                
                let rowData2 = sqlite3_column_text(statement, 2)
                let tmpLongitude = String.fromCString(UnsafePointer<CChar>(rowData2))
                
                let rowData3 = sqlite3_column_text(statement, 3)
                let tmpSubThroughfare = String.fromCString(UnsafePointer<CChar>(rowData3))
                
                let rowData4 = sqlite3_column_text(statement, 4)
                let tmpThroughfare = String.fromCString(UnsafePointer<CChar>(rowData4))
                
                let rowData5 = sqlite3_column_text(statement, 5)
                let tmpPostalCode = String.fromCString(UnsafePointer<CChar>(rowData5))
                
                let rowData6 = sqlite3_column_text(statement, 6)
                let tmpLocality = String.fromCString(UnsafePointer<CChar>(rowData6))
                
                let rowData7 = sqlite3_column_text(statement, 7)
                let tmpAdministrative = String.fromCString(UnsafePointer<CChar>(rowData7))
                
                let rowData8 = sqlite3_column_text(statement, 8)
                let tmpCountry = String.fromCString(UnsafePointer<CChar>(rowData8))
                
                let rowData9 = sqlite3_column_text(statement, 9)
                let tmpUsername = String.fromCString(UnsafePointer<CChar>(rowData9))
                
                let rowData10 = sqlite3_column_text(statement, 10)
                let tmpDateString = String.fromCString(UnsafePointer<CChar>(rowData10))
                
                let headers = [
                    "content-type": "application/x-www-form-urlencoded",
                    "cache-control": "no-cache"
                ]
                
                let postString = "latitude=\(tmpLatitude!)&longitude=\(tmpLongitude!)&subThoroughfare=\(tmpSubThroughfare!)&thoroughfare=\(tmpThroughfare!)&postalCode=\(tmpPostalCode!)&locality=\(tmpLocality!)&administrativeArea=\(tmpAdministrative!)&country=\(tmpCountry!)&userName=\(tmpUsername!)&timeStamp=\(tmpDateString!)"
                let postStringEnc = postString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
                
                let request = NSMutableURLRequest(URL: NSURL(string: "\(self.IP_API)?\(postStringEnc!)")!)
                request.HTTPMethod = "POST"
                request.allHTTPHeaderFields = headers
                
                var response:NSURLResponse?
                
                do{
                    let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
                    let responseString = NSString(data: data, encoding: NSISOLatin1StringEncoding)
                    alertString += "\(responseString!)\n"
                    self.db_query("UPDATE LocationInfo SET status = '1' WHERE  ID = \(tmpID)", database: dbSelect)
                } catch{
                    print(error)
                    alertString += "\(error)"
                }
            }
        }
        sqlite3_finalize(statement)
        sqlite3_close(dbSelect)
        
        let alert = UIAlertView(title: "Result", message: "\(alertString)", delegate: nil, cancelButtonTitle: "OK")
        alert.show()

    }
    @IBAction func viewAllClick(sender: UIButton) {
        let headers = [
            "content-type": "application/x-www-form-urlencoded",
            "cache-control": "no-cache"
        ]
        
        
        let request = NSMutableURLRequest(URL: NSURL(string: "\(self.IP_API)")!)
        request.HTTPMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        var response:NSURLResponse?
        
        do{
            let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            let allView = self.storyboard?.instantiateViewControllerWithIdentifier("AllView") as! AllLocationViewController
            allView.jsonData = json
            self.presentViewController(allView, animated: true, completion: nil)
        } catch{
            print(error)
            let alert = UIAlertView(title: "Result", message: "\(error)", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    @IBAction func viewAllLocalClick(sender: UIButton) {
        let allViewLocal = self.storyboard?.instantiateViewControllerWithIdentifier("AllViewLocal")
        self.presentViewController(allViewLocal!, animated: true, completion: nil)
    }
    @IBOutlet weak var textUsername: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var textAddress: UITextView!
    @IBOutlet weak var labelLongitude: UILabel!
    @IBOutlet weak var labelLatitude: UILabel!
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("[Error]: \(error)")
        let errorAlert = UIAlertView(title: "Error!", message: "Failed to get current Location!", delegate: nil, cancelButtonTitle: "OK")
        errorAlert.show()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations[0]
        self.latitude = String.init(format: "%.4f", currentLocation.coordinate.latitude)
        self.longitude = String.init(format: "%.4f", currentLocation.coordinate.latitude)
        
        labelLatitude.text = String.init(format: "%.4f", currentLocation.coordinate.latitude)
        labelLongitude.text = String.init(format: "%.4f", currentLocation.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: {
            (placeMarks, error) -> Void in
            if(error == nil && (placeMarks?.count)! > 0){
                self.placeMark = placeMarks?.last
                if(self.placeMark.subThoroughfare != nil &&
                    self.placeMark.thoroughfare != nil &&
                    self.placeMark.postalCode != nil &&
                    self.placeMark.locality != nil &&
                    self.placeMark.administrativeArea != nil &&
                    self.placeMark.country != nil){
                    
                    self.subThoroughfare = self.placeMark.subThoroughfare!
                    self.thoroughfare = self.placeMark.thoroughfare!
                    self.postalCode = self.placeMark.postalCode!
                    self.locality = self.placeMark.locality!
                    self.administrative = self.placeMark.administrativeArea!
                    self.country = self.placeMark.country!
                } else {
                    self.subThoroughfare = "unknow"
                    self.thoroughfare = "unknow"
                    self.postalCode = "unknow"
                    self.locality = "unknow"
                    self.administrative = "unknow"
                    self.country = "unknow"
                }
                
                self.textAddress.text = String.init(format: "%@ %@\n%@ %@\n%@\n%@",
                    self.subThoroughfare, self.thoroughfare,
                    self.postalCode, self.locality,
                    self.administrative,self.country)
            } else {
                print("[Error]: \(error)")
            }
        })
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let myCurrentLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myCurrentLocation, span)
        mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        geoCoder = CLGeocoder()
        self.textUsername.text = "defaultUser"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func connectdb(dbname: String, type: String) -> COpaquePointer{
        var database: COpaquePointer = nil
        let path: NSArray = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentpath: NSString = path.objectAtIndex(0) as! NSString
        let dbpath: NSString = documentpath.stringByAppendingPathComponent("\(dbname).\(type)")
        let dbAlreadyExits = NSFileManager.defaultManager().fileExistsAtPath(dbpath as String)
        print(dbpath)
        if(!dbAlreadyExits){
            let dbFromBundle: NSString = NSBundle.mainBundle().pathForResource(dbname, ofType: type)!
            try! NSFileManager.defaultManager().copyItemAtPath(dbFromBundle as String, toPath: dbpath as String)
            print("DB Create")
        }
        if(sqlite3_open(dbpath.UTF8String, &database) != SQLITE_OK){
            sqlite3_close(database)
            print("Open Error")
        }
        return database
    }
    
    func db_select(query:String, database:COpaquePointer)->COpaquePointer{
        var statement:COpaquePointer = nil
        sqlite3_prepare_v2(database, query, -1, &statement, nil)
        return statement
    }
    
    func db_query(sql:String, database: COpaquePointer){
        var errmsg:UnsafeMutablePointer<Int8> = nil
        let result = sqlite3_exec(database, sql, nil, nil, &errmsg)
        if (result != SQLITE_OK){
            sqlite3_close(database)
            print("Query Error \(errmsg)")
            return
        }
    }}