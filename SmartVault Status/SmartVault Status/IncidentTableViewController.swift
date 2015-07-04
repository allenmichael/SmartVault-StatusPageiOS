//
//  IncidentTableViewController.swift
//  SmartVault Status
//
//  Created by Allen-Michael Grobelny on 4/3/15.
//  Copyright (c) 2015 Allen-Michael Grobelny. All rights reserved.
//

import UIKit

class IncidentTableViewController: UITableViewController {
    
    let pageID = ""
    let statusURL = "https://api.statuspage.io/v1/pages/"
    let apiKey = ""
    let jsonAuth = ".json?api_key="
    
    var prevIncidentArray = Array<String>()
    var unresolvedIncidents: [UnresolvedModel] = []
    var incidentToUpdate = UnresolvedModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return prevIncidentArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("IncidentCell", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        cell.textLabel!.text = prevIncidentArray[indexPath.row]
        return cell
    }

    
    func getUnresolvedList() {
        let baseURL = NSURL(string: statusURL + pageID + "/incidents/unresolved" + jsonAuth + apiKey)
        println("Starting")
        let sharedSession = NSURLSession.sharedSession()
        
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(baseURL!, completionHandler: {
            (location: NSURL!, response: NSURLResponse!, error: NSError!)-> Void in
            if(error == nil) {
                let statusDataObject = NSData(contentsOfURL: location)
                let statusArray: NSArray = NSJSONSerialization.JSONObjectWithData(statusDataObject!, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSArray
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    for unresolvedIncident in statusArray {
                        var incident = UnresolvedModel()
                        var incidentUpdates = unresolvedIncident["incident_updates"] as! NSArray
                        incident.backfilled = unresolvedIncident["backfilled"] as! Bool
                        incident.created_at = unresolvedIncident["created_at"] as! String
                        incident.id = unresolvedIncident["id"] as! String
                        incident.impact = unresolvedIncident["impact"] as! String
                        incident.impact_override = unresolvedIncident["impact_override"] as? String
                        incident.name = unresolvedIncident["name"] as! String
                        
                        for incidentUpdate in incidentUpdates {
                            var update = IncidentUpdateModel()
                            update.body = incidentUpdate["body"] as! String
                            update.created_at = incidentUpdate["created_at"] as! String
                            update.display_at = incidentUpdate["display_at"] as! String
                            update.id = incidentUpdate["id"] as! String
                            update.incident_id = incidentUpdate["incident_id"] as! String
                            update.status = incidentUpdate["status"] as! String
                            incident.incident_updates.append(update)
                        }
                        
                        self.unresolvedIncidents.append(incident)
                    }
                    if(self.unresolvedIncidents.count == 0) {
                        self.prevIncidentArray.removeAll(keepCapacity: false)
                        self.prevIncidentArray.append("No incidents are available to update.")
                    } else {
                        self.prevIncidentArray.removeAll(keepCapacity: false)
                        for incident in self.unresolvedIncidents {
                            self.prevIncidentArray.append(incident.name)
                        }
                    }
                    self.tableView.reloadData()
                })
                
                println("Finishing!")
                println(response)
                } else {
                println(error)
            }
        })

        downloadTask.resume()
    
    }
    
    override func viewWillAppear(animated: Bool) {
        prevIncidentArray.removeAll(keepCapacity: false)
        unresolvedIncidents.removeAll(keepCapacity: false)
        prevIncidentArray.append("Loading...")
        getUnresolvedList()
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if(identifier == "UpdateAnIncident") {
            let indexPath: NSIndexPath = self.tableView.indexPathForSelectedRow()!
            let currentCell = tableView.cellForRowAtIndexPath(indexPath);
            let checkName = currentCell!.textLabel!.text!
            if(checkName == "No incidents are available to update.") {
                let alert = UIAlertView()
                alert.title = "No Incidents Exist"
                alert.message = "There are no open incidents to update. Check status.smartvault.com for open incidents if you think you've received this message in error."
                alert.addButtonWithTitle("OK")
                alert.show()
                
                return false
            } else {
                return true
            }
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "UpdateAnIncident") {
            let indexPath: NSIndexPath = self.tableView.indexPathForSelectedRow()!
            let currentCell = tableView.cellForRowAtIndexPath(indexPath);
            let checkName = currentCell!.textLabel!.text!
            for incident in unresolvedIncidents {
                if(incident.name == checkName) {
                    incidentToUpdate = incident
                    break;
                }
            }
            let svc = segue.destinationViewController as! UpdateThisIncidentViewController
            svc.incident = incidentToUpdate
        }

    }
}
