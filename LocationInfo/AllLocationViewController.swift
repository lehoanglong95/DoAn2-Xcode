//
//  AllLocationViewController.swift
//  LocationInfo
//
//  Created by lehoanglong on 11/26/16.
//  Copyright © 2016 LeHoangLong. All rights reserved.
//

import UIKit

class AllLocationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var jsonData:AnyObject?
    var timeStamps:[String]!
    var longitudes:[Double]!
    var latitudes:[Double]!
    
    @IBAction func closeClick(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        timeStamps = []
        longitudes = []
        latitudes = []
        if let datas = jsonData as? [[String: AnyObject!]] {
            print(datas)
            for data in datas {
                if let timpStamp = data["Timestamp"] as? String {
                    self.timeStamps.append(timpStamp)
                }
                if let latitude = data["Latitude"] as? Double {
                    self.latitudes.append(latitude)
                }
                if let longitude = data["Longitude"] as? Double {
                    self.longitudes.append(longitude)
                }
            }
        }
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
        cell.textLabel?.text = timeStamps[row]
        cell.detailTextLabel?.text = "\(latitudes[row]) : \(longitudes[row])"
        return cell
    }
}
