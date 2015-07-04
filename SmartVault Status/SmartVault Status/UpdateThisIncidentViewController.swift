//
//  UpdateThisIncidentViewController.swift
//  SmartVault Status
//
//  Created by Allen-Michael Grobelny on 4/3/15.
//  Copyright (c) 2015 Allen-Michael Grobelny. All rights reserved.
//

import UIKit

class UpdateThisIncidentViewController: UIViewController {
    
    @IBOutlet weak var updateName: UITextField!
    
    @IBOutlet weak var updateBody: UITextView!
    
    @IBOutlet weak var updateBodiesList: UITableView!
    
    @IBOutlet weak var previousUpdatesLabel: UILabel!
    
    @IBOutlet weak var updateBodySegments: UISegmentedControl!
    
    @IBOutlet weak var updateIncidentStatus: UISegmentedControl!
    
    @IBOutlet weak var submittedLabel: UILabel!
    
    let attributes = [NSFontAttributeName: UIFont.fontAwesomeOfSize(20)] as Dictionary!
    let pageID = ""
    let statusURL = "https://api.statuspage.io/v1/pages/"
    let apiKey =  ""
    let jsonAuth = ".json?api_key="
    
    var incident = UnresolvedModel()
    var incidentStatus: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        incidentStatus = incident.incident_updates[0].status
        
        updateIncidentStatus.setTitleTextAttributes(attributes,forState: .Normal)
        updateIncidentStatus.setTitle(String.fontAwesomeIconWithName(.Question), forSegmentAtIndex: 0)
        updateIncidentStatus.setTitle(String.fontAwesomeIconWithName(.Search), forSegmentAtIndex: 1)
        updateIncidentStatus.setTitle(String.fontAwesomeIconWithName(.Eye), forSegmentAtIndex: 2)
        updateIncidentStatus.setTitle(String.fontAwesomeIconWithName(.Check), forSegmentAtIndex: 3)
        
        updateName.text = incident.name
        updateBody.text = incident.incident_updates[0].body
        
        generateSegments()
        
        if(updateBodySegments.numberOfSegments > 1) {
            updateBodySegments.selectedSegmentIndex = 0
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func closeKeyboard(sender: AnyObject) {
        self.updateName.resignFirstResponder()
        self.updateBody.resignFirstResponder()
    }

    @IBAction func selectedUpdate(sender: AnyObject) {
        var index = updateBodySegments.selectedSegmentIndex
        updateBody.text = incident.incident_updates[index].body
        println(incident.incident_updates[index].body)
        switch incident.incident_updates[index].status {
            case "investigating":
                updateIncidentStatus.selectedSegmentIndex = 0
            case "identified":
                updateIncidentStatus.selectedSegmentIndex = 1
            case "monitoring":
                updateIncidentStatus.selectedSegmentIndex = 2
            case "resolved":
                updateIncidentStatus.selectedSegmentIndex = 3
            default:
                updateIncidentStatus.selectedSegmentIndex = UISegmentedControlNoSegment
            
        }
    }
    
    @IBAction func submitUpdate(sender: AnyObject) {
        createIncidentUpdate()
    }
    
    @IBAction func selectIncidentStatus(sender: AnyObject) {
        submittedLabel.text = ""
        switch updateIncidentStatus.selectedSegmentIndex {
        case 0:
            incidentStatus = "investigating"
        case 1:
            incidentStatus = "identified"
        case 2:
            incidentStatus = "monitoring"
        case 3:
            incidentStatus = "resolved"
        default:
            incidentStatus = incident.incident_updates[0].status
            
        }
    }
    
    func generateSegments() {
        while(updateBodySegments.numberOfSegments != incident.incident_updates.count) {
            if(incident.incident_updates.count == 1){
                updateBodySegments.removeAllSegments()
                previousUpdatesLabel.removeFromSuperview()
                break
            }
            else if(updateBodySegments.numberOfSegments > incident.incident_updates.count) {
                var index = updateBodySegments.numberOfSegments
                updateBodySegments.removeSegmentAtIndex(index, animated: false)
            } else {
                var index = updateBodySegments.numberOfSegments
                updateBodySegments.insertSegmentWithTitle("\(index + 1)", atIndex: index, animated: false)
            }
        }

    }
    
    func createIncidentUpdate() {
        println(updateBody.text)
        let baseURL = NSURL(string: statusURL + pageID + "/incidents/" + incident.id + jsonAuth + apiKey)
        var params = ["incident":["name":updateName.text, "status":incidentStatus, "message":updateBody.text]] as NSDictionary
        var request = NSMutableURLRequest(URL: baseURL!)
        var session = NSURLSession.sharedSession()
        var err: NSError?
        println(params)
        request.HTTPMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            let httpResponse = response as! NSHTTPURLResponse
            dispatch_async(dispatch_get_main_queue()) {
                if(httpResponse.statusCode != 200) {
                    println(response)
                    println("Error! \(error)")
                } else {
                    let responseString = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                    if (responseString.count > 0) {
                        println("response = \(httpResponse.statusCode)")
                        println("responseString = \(responseString)")
                        println(responseString.objectForKey("name"))
                        self.updateIncidentModel(responseString)
                        self.submittedLabel.text = "Submitted!"
                        let timer : NSTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("timedResponse:"), userInfo: nil, repeats: false)
                    }
                }
            }
        }
        task.resume()
    }
    
    func updateIncidentModel(responseData: NSDictionary) {
        incident.deleteIncidentUpdates()
        var incidentUpdates = responseData.objectForKey("incident_updates") as! NSArray
        incident.backfilled = responseData.objectForKey("backfilled") as! Bool
        incident.created_at = responseData.objectForKey("created_at") as! String
        incident.id = responseData.objectForKey("id") as! String
        incident.impact = responseData.objectForKey("impact") as! String
        incident.impact_override = responseData.objectForKey("impact_override") as? String
        incident.name = responseData.objectForKey("name") as! String
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
    }
    
    func timedResponse(time: NSTimer) {
        if(incident.incident_updates[0].status == "resolved"){
            navigationController!.popViewControllerAnimated(true)
        } else {
            generateSegments()
            submittedLabel.text = ""
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
