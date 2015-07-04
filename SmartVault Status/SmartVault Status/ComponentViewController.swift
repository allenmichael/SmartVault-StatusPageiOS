//
//  ComponentViewController.swift
//  SmartVault Status
//
//  Created by Allen-Michael Grobelny on 3/27/15.
//  Copyright (c) 2015 Allen-Michael Grobelny. All rights reserved.
//

import UIKit

class ComponentViewController: UIViewController, UIPickerViewDelegate {
    
    @IBOutlet weak var svServicesComponentPicker: UIPickerView!
    
    @IBOutlet weak var svServiceComponent: UILabel!
    
    @IBOutlet weak var updateConfirmLabel: UILabel!
    
    @IBOutlet weak var contentPreviewControl: UISegmentedControl!
    
    @IBOutlet weak var listOfCompForIncident: UITextView!
    
    @IBOutlet weak var goToIncidentReport: UIButton!
    
    @IBOutlet weak var componentWarning: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var fullActivityView: UIActivityIndicatorView!
    
    let attributes = [NSFontAttributeName: UIFont.fontAwesomeOfSize(20)] as Dictionary!
    let apiKey = ""
    let statusType = ["operational", "degraded_performance", "partial_outage", "major_outage"]
    
    var svServicesComponents: [ComponentModel] = []
    var svServicesNames = ["Select a SmartVault Component"]
    var selectedCompStatus = ""
    var updatedComponents: [ComponentModel] = []
    var selectedRow = 0
    var startRow = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        contentPreviewControl.setTitleTextAttributes(attributes, forState: .Normal)
        contentPreviewControl.setTitle(String.fontAwesomeIconWithName(.Check), forSegmentAtIndex: 0)
        contentPreviewControl.setTitle(String.fontAwesomeIconWithName(.MinusSquare), forSegmentAtIndex: 1)
        contentPreviewControl.setTitle(String.fontAwesomeIconWithName(.ExclamationTriangle), forSegmentAtIndex: 2)
        contentPreviewControl.setTitle(String.fontAwesomeIconWithName(.Times), forSegmentAtIndex: 3)
    }
    
    override func viewDidAppear(animated: Bool) {
        fullActivityView.center = svServicesComponentPicker.center
        svServicesComponentPicker.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        svServicesComponentPicker.addSubview(fullActivityView)
        startSpinning(fullActivityView)
        getCompArray()
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: ("timedResponseLoad:"), userInfo: nil, repeats: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func selectOutage(sender: AnyObject) {
        updateConfirmLabel.text = ""
        pickStatus()
    }
    
    @IBAction func addComponent(sender: AnyObject) {
        addCompToList()
        viewComponentList()
    }
    
    
    @IBAction func removeComponent(sender: AnyObject) {
        updatedComponents.removeAll(keepCapacity: false)
        componentWarning.text = "Components Removed!"
        viewComponentList()
        goToIncidentReport.setTitle("Create an Incident Report", forState: UIControlState.Normal)
        let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: ("timedResponseComp:"), userInfo: nil, repeats: false)
    }
    
    @IBAction func updateStatus(sender: UIButton) {
        if (svServiceComponent.text == "Select a Component") {
            updateConfirmLabel.text = "No component selected!"
            
        } else if(svServicesComponents[selectedRow].status == selectedCompStatus) {
            updateConfirmLabel.text = "Component already set to this status"
            let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: ("timedResponseUpdate:"), userInfo: nil, repeats: false)
        }
        else {
            startSpinning(activityIndicator)
            archive()

            var params = ["component": ["status":selectedCompStatus]] as NSDictionary
            var assembly = ApiCall(key: apiKey, component: svServicesComponents[selectedRow].id)
            
            var request: NSMutableURLRequest = assembly.makeComponentApiCall(params, httpVerb: "PATCH")

            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                (data, response, error) in
                let httpResponse = response as! NSHTTPURLResponse
                dispatch_async(dispatch_get_main_queue()) {
                    if(httpResponse.statusCode != 200) {
                        println("Error! \(error)")
                        self.updateConfirmLabel.text = "Error! Couldn't update component! \(httpResponse.statusCode)"
                    } else {
                        self.updateConfirmLabel.text = "Updated!"
                        let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: ("timedResponseUpdate:"), userInfo: nil, repeats: false)
                        if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding){
                            println("response = \(httpResponse.statusCode)")
                            println("responseString = \(responseString)")
                        }
                        self.getCompArray()
                        self.addCompToList()
                        self.viewComponentList()
                    }
                }
            }
            task.resume()
            
        }
    
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView!) -> Int{
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return svServicesNames.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateConfirmLabel.text = ""
        svServiceComponent.text = "\(svServicesNames[row])"
        matchStatus(row)
        selectedRow = row
    }
    
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
        var pickerLabel = UILabel()
        pickerLabel.textAlignment = .Center
        pickerLabel.textColor = UIColor.whiteColor()
        pickerLabel.text = svServicesNames[row] as String
        return pickerLabel
    }
    
    func pickStatus() {
        println(contentPreviewControl.selectedSegmentIndex)
        switch contentPreviewControl.selectedSegmentIndex {
            case 0:
                selectedCompStatus = statusType[0]
            case 1:
                selectedCompStatus = statusType[1]
            case 2:
                selectedCompStatus = statusType[2]
            case 3:
                selectedCompStatus = statusType[3]
            default:
                selectedCompStatus = statusType[0]
        }
    }
    
    func matchStatus(row :Int) {
        switch svServicesComponents[row].status as String {
            case statusType[0]:
                contentPreviewControl.selectedSegmentIndex = 0
            case statusType[1]:
                contentPreviewControl.selectedSegmentIndex = 1
            case statusType[2]:
                contentPreviewControl.selectedSegmentIndex = 2
            case statusType[3]:
                contentPreviewControl.selectedSegmentIndex = 3
            default:
                contentPreviewControl.selectedSegmentIndex = 0
        }

    }
    
    func archive() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(selectedRow, forKey: "row")
    }
    
    func unarchive() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let savedRow = defaults.stringForKey("row")
        {
            startRow = savedRow.toInt()!
        }
    }
    
    func startSpinning(sender: UIActivityIndicatorView) {
        sender.startAnimating()
    }
    
    func stopSpinning(sender: UIActivityIndicatorView) {
        sender.stopAnimating()
    }
    
    func getCompArray() {
        var assembly = ApiCall(key: apiKey)
        let baseURL = assembly.baseComponentsUrl
        
        println("Starting")
        let sharedSession = NSURLSession.sharedSession()
        
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(baseURL!, completionHandler: {
            (location: NSURL!, response: NSURLResponse!, error: NSError!)-> Void in
            if(error == nil) {
                let statusDataObject = NSData(contentsOfURL: location)
                let statusArray: NSArray = (NSJSONSerialization.JSONObjectWithData(statusDataObject!, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSArray)!
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.svServicesComponents.removeAll(keepCapacity: false)
                    for eachComponent in statusArray {
                        var component = ComponentModel()
                        component.createdAt = eachComponent["created_at"] as! String
                        component.id = eachComponent["id"] as! String
                        component.name = eachComponent["name"] as! String
                        component.position = eachComponent["position"] as! Int
                        component.status = eachComponent["status"] as! String
                        component.updatedAt = eachComponent["updated_at"] as! String
                        self.svServicesComponents.append(component)
                    }
                    self.reloadComponents()
                })
                
                println("Finishing!")
                println(response)
            } else {
                println(error)
                println(error.localizedDescription)
                self.updateConfirmLabel.text = "Error! Couldn't load components!"
                let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: ("timedResponseUpdate:"), userInfo: nil, repeats: false)
            }
        })
        downloadTask.resume()
    }
    
    func reloadComponents() {
        svServicesComponents.sort({$0.name < $1.name})
        svServicesNames.removeAll(keepCapacity: false)
        for component in svServicesComponents{
            svServicesNames.append(component.name)
        }
        svServicesComponentPicker.reloadAllComponents()
    }
    
    func viewComponentList() {
        var titleText = "No components in your list."
        if (updatedComponents.count < 1) {
            listOfCompForIncident.text = titleText
        } else {
            titleText = ""
            if(updatedComponents.count == 1) {
                titleText = updatedComponents[0].name
            } else if(updatedComponents.count == 2){
                titleText = updatedComponents[0].name + " and " + updatedComponents[1].name
            } else {
                for(var i = 0; i < updatedComponents.count; i++) {
                    if(i == updatedComponents.count - 1) {
                        titleText += "and " + updatedComponents[i].name
                    } else {
                        titleText += updatedComponents[i].name + ", "
                    }
                }
            }
            titleText += " "
            listOfCompForIncident.text = titleText
        }
    }
    
    func addCompToList() {
        var onList = false
        if (svServiceComponent.text == "Select a Component") {
            updateConfirmLabel.text = "No component selected!"
        } else {
            if(updatedComponents.count > 0) {
                for comp in updatedComponents {
                    if(svServicesComponents[selectedRow].id == comp.id) {
                        onList = true
                        componentWarning.text = "Component already on list!"
                    }
                }
            }
            for component in svServicesComponents {
                if(svServicesComponents[selectedRow].id == component.id && onList == false) {
                    updatedComponents.append(component)
                    componentWarning.text = "Component Added!"
                }
            }
            goToIncidentReport.setTitle("Use component list to\ncreate an Incident Report", forState: UIControlState.Normal)
        }
        let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: ("timedResponseComp:"), userInfo: nil, repeats: false)
    }
    
    func timedResponseUpdate(time: NSTimer) {
        updateConfirmLabel.text = ""
        stopSpinning(activityIndicator)
    }
    
    func timedResponseComp(time: NSTimer) {
        componentWarning.text = ""
    }
    
    func timedResponseLoad(time: NSTimer) {
        unarchive()
        println("Timer up!")
        svServicesComponentPicker.selectRow(startRow, inComponent: 0, animated: true)
        if(startRow < svServicesNames.count){
          svServiceComponent.text = "\(svServicesNames[startRow])"
          matchStatus(startRow)
          selectedRow = startRow
          selectedCompStatus = svServicesComponents[startRow].status
          stopSpinning(fullActivityView)
          svServicesComponentPicker.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        } else {
            updateConfirmLabel.text = "Error! Cannot load components."
            let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: ("timedResponseGetComp:"), userInfo: nil, repeats: false)
        }
    }
    
    func timedResponseGetComp(time: NSTimer) {
        getCompArray()
        let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: ("timedResponseLoad:"), userInfo: nil, repeats: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "UpdatedComponentsSegue") {
            let svc = segue.destinationViewController as! CreateIncidentViewController
            svc.updatedComponentsArray = updatedComponents
            svc.showFillTitle = false
            
        }
    }
}

