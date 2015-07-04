//
//  CreateIncidentController.swift
//  SmartVault Status
//
//  Created by Allen-Michael Grobelny on 3/27/15.
//  Copyright (c) 2015 Allen-Michael Grobelny. All rights reserved.
//

import UIKit

class CreateIncidentViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var incidentBody: UITextView!
    
    @IBOutlet weak var incidentTitle: UITextField!
    
    @IBOutlet weak var CriticalTempSelector: UISegmentedControl!
    
    @IBOutlet weak var InterTempSelector: UISegmentedControl!
    
    @IBOutlet weak var FillTitleCompBtn: UIButton!
    
    @IBOutlet weak var OverrideTempSwitch: UISwitch!
    
    @IBOutlet weak var SubmittedLabel: UILabel!
    
    @IBOutlet weak var segmentedControlOneLabel: UILabel!
    
    @IBOutlet weak var segmentedControlTwoLabel: UILabel!
    
    let attributes = [NSFontAttributeName: UIFont.fontAwesomeOfSize(20)] as Dictionary!
    let normalFont = UIFont.systemFontOfSize(14.0)
    let filepath = NSBundle.mainBundle().pathForResource("templateList", ofType: "plist") as String!
    let apiKey = ""
    
    let statusStringArr: [String] = ["Investigating", "Identified", "Monitoring", "Resolved"]
    let tempTitles: [String] = ["Initial", "15 Min", "1 Hour", "ETA", "Restore"]
    let impactStringArr: [String] = ["None", "Minor", "Major", "Critical"]
    
    let criticalTempTitle: String = "Critical Templates"
    let interTempTitle: String = "Intermittent Templates"
    let statusTitle: String = "Status"
    let impactTitle: String = "Impact Override"
    
    var updatedComponentsArray: [ComponentModel] = []
    var showFillTitle = true
    var incidentStatus: String?
    var incidentImpact: String?
    var labelArr = [UILabel()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.incidentBody.delegate = self
        self.incidentTitle.delegate = self
        self.FillTitleCompBtn.hidden = showFillTitle
        self.CriticalTempSelector.selectedSegmentIndex = UISegmentedControlNoSegment
        self.InterTempSelector.selectedSegmentIndex = UISegmentedControlNoSegment
        if(updatedComponentsArray.count == 0) {
            FillTitleCompBtn.removeFromSuperview()
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func prefillTitle(sender: AnyObject) {
        incidentTitle.text = viewComponentList()
    }
    
    
    @IBAction func closeKeyboard(sender: AnyObject) {
        self.incidentBody.resignFirstResponder()
        self.incidentTitle.resignFirstResponder()
    }
    
    @IBAction func selectCriticalTemp(sender: AnyObject) {
        SubmittedLabel.text = ""
        if(OverrideTempSwitch.on == false) {
            InterTempSelector.selectedSegmentIndex = UISegmentedControlNoSegment
            let templates = NSDictionary(contentsOfFile: filepath) as? Dictionary <String, String>
            switch CriticalTempSelector.selectedSegmentIndex {
            case 0:
                incidentBody.text = templates!["InitialCritical"]
                createTitle("offline")
                incidentImpact = "critical"
                incidentStatus = "investigating"
            case 1:
                incidentBody.text = templates!["15MinCritical"]
                createTitle("offline")
                incidentImpact = "critical"
                incidentStatus = "investigating"
            case 2:
                incidentBody.text = templates!["1HrCritical"]
                createTitle("offline")
                incidentImpact = "critical"
                incidentStatus = "investigating"
            case 3:
                incidentBody.text = templates!["ETACritical"]
                createTitle("diagnosed")
                incidentImpact = "critical"
                incidentStatus = "identified"
            case 4:
                incidentBody.text = templates!["RestoredCritical"]
                createTitle("operational")
                incidentImpact = "critical"
                incidentStatus = "resolved"
            default:
                incidentBody.text = ""
                incidentTitle.text = ""
            }
        } else {
            segmentedControlOneLabel.text = "Status"
        }
    }
    
    @IBAction func selectInterTemp(sender: AnyObject) {
        SubmittedLabel.text = ""
        if(InterTempSelector.numberOfSegments == tempTitles.count && segmentedControlTwoLabel.text == interTempTitle) {
            CriticalTempSelector.selectedSegmentIndex = UISegmentedControlNoSegment
            let templates = NSDictionary(contentsOfFile: filepath) as? Dictionary <String, String>
            switch InterTempSelector.selectedSegmentIndex {
            case 0:
                incidentBody.text = templates!["InitialInter"]
                createTitle("inter")
                incidentImpact = "minor"
                incidentStatus = "investigating"
            case 1:
                incidentBody.text = templates!["15MinInter"]
                createTitle("inter")
                incidentImpact = "minor"
                incidentStatus = "investigating"
            case 2:
                incidentBody.text = templates!["1HrInter"]
                createTitle("inter")
                incidentImpact = "minor"
                incidentStatus = "investigating"
            case 3:
                incidentBody.text = templates!["ETAInter"]
                createTitle("interDiag")
                incidentImpact = "minor"
                incidentStatus = "identified"
            case 4:
                incidentBody.text = templates!["RestoredInter"]
                createTitle("operational")
                incidentImpact = "minor"
                incidentStatus = "resolved"
            default:
                incidentBody.text = ""
                incidentTitle.text = ""
            }
        } else if(OverrideTempSwitch.on && segmentedControlTwoLabel.text == impactTitle && InterTempSelector.numberOfSegments == impactStringArr.count){
            switch InterTempSelector.selectedSegmentIndex {
            case 0:
                println(impactStringArr[0].lowercaseString)
            default:
                println("Seeing if this is called")
            }
            
        }
        
    }
    

    @IBAction func submittedIncident(sender: AnyObject) {
        if(InterTempSelector.selectedSegmentIndex == UISegmentedControlNoSegment && CriticalTempSelector.selectedSegmentIndex == UISegmentedControlNoSegment && OverrideTempSwitch.on == false) {
            SubmittedLabel.text = "Select a template or override."
        } else if(OverrideTempSwitch.on == true) {
            createIncidentAPICall()
        } else {
            createIncidentAPICall()
        }
    }
    
    @IBAction func overrideTempOn(sender: AnyObject) {
        SubmittedLabel.text = ""
        if(OverrideTempSwitch.on) {
            segmentedControlOneLabel.text = statusTitle
            segmentedControlTwoLabel.text = impactTitle
            var critIndex = CriticalTempSelector.numberOfSegments
            var interIndex = InterTempSelector.numberOfSegments
            var statusNum = statusStringArr.count
            var impactNum = impactStringArr.count
            
            while(critIndex >= statusNum && interIndex >= impactNum){
                CriticalTempSelector.removeSegmentAtIndex(critIndex, animated: true)
                critIndex--
                InterTempSelector.removeSegmentAtIndex(interIndex, animated: true)
                interIndex--
            }
            
            CriticalTempSelector.setTitleTextAttributes(attributes, forState: .Normal)
            CriticalTempSelector.setTitle(String.fontAwesomeIconWithName(.Question), forSegmentAtIndex: 0)
            CriticalTempSelector.setTitle(String.fontAwesomeIconWithName(.Search), forSegmentAtIndex: 1)
            CriticalTempSelector.setTitle(String.fontAwesomeIconWithName(.Eye), forSegmentAtIndex: 2)
            CriticalTempSelector.setTitle(String.fontAwesomeIconWithName(.Check), forSegmentAtIndex: 3)
            generateLabels(CriticalTempSelector, text: statusStringArr)
            generateLabels(InterTempSelector, text: impactStringArr)
        } else {
            removeLabels()
            segmentedControlOneLabel.text = criticalTempTitle
            segmentedControlTwoLabel.text = interTempTitle
            CriticalTempSelector.removeAllSegments()
            InterTempSelector.removeAllSegments()
            let fontAttr = NSDictionary(object: normalFont, forKey: NSFontAttributeName)
            CriticalTempSelector.setTitleTextAttributes(fontAttr as [NSObject : AnyObject], forState: UIControlState.Normal)
            InterTempSelector.setTitleTextAttributes(fontAttr as [NSObject : AnyObject], forState: UIControlState.Normal)
            var tempNum = tempTitles.count
            for(var index = 0; index < tempNum; index++){
                CriticalTempSelector.insertSegmentWithTitle(tempTitles[index], atIndex: index, animated: true)
                InterTempSelector.insertSegmentWithTitle(tempTitles[index], atIndex: index, animated: true)
            }
        }
    }
    
    func createTitle(caseTxt: String) {
        var titleText = viewComponentList()
        switch caseTxt {
        case "offline":
            if(updatedComponentsArray.count <= 1) {
                incidentTitle.text = titleText + "Service is Offline"
            } else {
                incidentTitle.text = titleText + "Services are Offline"
            }
        case "diagnosed":
            if(updatedComponentsArray.count <= 1) {
                incidentTitle.text = titleText + "Service Disruption Diagnosed"
            } else {
                incidentTitle.text = titleText + "Services Disruption Diagnosed"
            }
        case "operational":
            if(updatedComponentsArray.count <= 1) {
                incidentTitle.text = titleText + "Service is Fully Operational"
            } else {
                incidentTitle.text = titleText + "Services are Fully Operational"
            }
        case "inter":
            if(updatedComponentsArray.count <= 1) {
                incidentTitle.text = "Intermittent Disruption on " + titleText + "Service"
            } else {
                incidentTitle.text = "Intermittent Disruption on " + titleText + "Services"
            }
        case "interDiag":
            if(updatedComponentsArray.count <= 1) {
                incidentTitle.text = "Intermittent Disruption on " + titleText + "Service Diagnosed"
            } else {
                incidentTitle.text = "Intermittent Disruption on " + titleText + "Services Diagnosed"
            }
        default:
            incidentTitle.text = "The SmartVault Service is Offline"
        }
    }
    
    func viewComponentList() -> String {
        var titleText = "[Insert SmartVault Component]"
        if (updatedComponentsArray.count < 1) {
            titleText = "SmartVault "
            return titleText
        } else {
            titleText = ""
            if(updatedComponentsArray.count == 1) {
                titleText += updatedComponentsArray[0].name
            } else if(updatedComponentsArray.count == 2){
                titleText += updatedComponentsArray[0].name + " and " + updatedComponentsArray[1].name
            } else {
                for(var i = 0; i < updatedComponentsArray.count; i++) {
                    if(i == updatedComponentsArray.count - 1) {
                        titleText += "and " + updatedComponentsArray[i].name
                    } else {
                        titleText += updatedComponentsArray[i].name + ", "
                    }
                }
            }
            titleText += " "
            return titleText
        }
    }
    
    func createIncidentAPICall() {
        var assembly = ApiCall(key: apiKey)
        
        var params = ["incident":["name":incidentTitle.text, "status":incidentStatus!, "message":incidentBody.text, "impact_override":incidentImpact!]] as NSDictionary
        
        var request = assembly.makeIncidentCreationApiCall(params, httpVerb: "POST")

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            let httpResponse = response as! NSHTTPURLResponse
            dispatch_async(dispatch_get_main_queue()) {
                if(httpResponse.statusCode != 201) {
                    println(response)
                    println("Error! \(error)")
                    self.SubmittedLabel.text = "Error! Couldn't submit your incident! \(httpResponse.statusCode)"
                } else {
                    self.SubmittedLabel.text = "Submitted!"
                    if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                        println("response = \(httpResponse.statusCode)")
                        println("responseString = \(responseString)")
                    }
                    let timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: ("timedResponse:"), userInfo: nil, repeats: false)
                }
            }
        }
        task.resume()
    }
    
    func generateLabels(segControl: UISegmentedControl, text: [String]) {
        var index = segControl.numberOfSegments
        var segFrame = segControl.frame
        var centerCon = segControl.center
        
        var totalSegments = CGFloat(segControl.numberOfSegments)
        var segmentSize = (segFrame.width / totalSegments)
        
        for(var i = 0; i < segControl.numberOfSegments; i++) {
            var label = UILabel()
            label.text = text[i]
            label.font = UIFont.systemFontOfSize(10.0)
            label.textColor = UIColor(white: 1, alpha: 1)
            label.textAlignment = NSTextAlignment.Center
            
            var setX = segFrame.minX + (segmentSize * CGFloat(i))
            var setY = segFrame.maxY + 3
            var setWidth = segmentSize
            var setHeight = CGFloat(10)
            
            label.frame = CGRect(x: setX, y: setY, width: setWidth, height: setHeight)
            labelArr.append(label)
            self.view.addSubview(label)
        }
        
    }
    
    func removeLabels() {
        if(labelArr.count != 0) {
            for label in labelArr {
                label.removeFromSuperview()
            }
        }
    }
    
    func timedResponse(time: NSTimer) {
        navigationController!.popViewControllerAnimated(true)
    }

}

