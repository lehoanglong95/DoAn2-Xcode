//
//  ViewAllLocalViewController.swift
//  LocationInfo
//
//  Created by lehoanglong on 11/27/16.
//  Copyright © 2016 LeHoangLong. All rights reserved.
//

import UIKit

class ViewAllLocalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBAction func closeClick(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBOutlet weak var tableView: UITableView!
    var timeStamps:[String]!
    var longitudes:[String]!
    var latitudes:[String]!
    var status:[String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeStamps = []
        longitudes = []
        latitudes = []
        status = []
        tableView.delegate = self
        tableView.dataSource = self
        let dbSelect: COpaquePointer = connectdb("LocationInfo", type: "sqlite")
        let statement: COpaquePointer = self.db_select("SELECT * FROM LocationInfo", database: dbSelect)
        while sqlite3_step(statement) == SQLITE_ROW {
            let rowData11 = sqlite3_column_text(statement, 11)
            let status = String.fromCString(UnsafePointer<CChar>(rowData11))
            self.status.append(status!)
                
                let rowData1 = sqlite3_column_text(statement, 1)
                let tmpLatitude = String.fromCString(UnsafePointer<CChar>(rowData1))
            self.latitudes.append(tmpLatitude!)
                
                let rowData2 = sqlite3_column_text(statement, 2)
                let tmpLongitude = String.fromCString(UnsafePointer<CChar>(rowData2))
            self.longitudes.append(tmpLongitude!)
                
                let rowData10 = sqlite3_column_text(statement, 10)
                let tmpDateString = String.fromCString(UnsafePointer<CChar>(rowData10))
            self.timeStamps.append(tmpDateString!)
        }
        sqlite3_finalize(statement)
        sqlite3_close(dbSelect)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeStamps.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        let row = indexPath.row
        var upload = ""
        if status[row] == "1" {
            upload = "uploaded"
        }
        cell.textLabel?.text = timeStamps[row]
        cell.detailTextLabel?.text = "\(latitudes[row]) : \(longitudes[row]) : \(upload)"
        return cell
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
    }
}
