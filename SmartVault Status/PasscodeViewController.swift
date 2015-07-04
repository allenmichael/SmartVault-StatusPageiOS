//
//  PasscodeViewController.swift
//  SmartVault Status
//
//  Created by Allen-Michael Grobelny on 6/12/15.
//  Copyright (c) 2015 Allen-Michael Grobelny. All rights reserved.
//

import UIKit
import Security

class PasscodeViewController: UIViewController {
    
    @IBOutlet weak var PasscodeValue: UITextField!

    @IBOutlet weak var PasscodeCheck: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let (dictionary, error) = Locksmith.loadDataForUserAccount("svStatusPasscode")
        println(error)
        println(dictionary)
        println(dictionary?.classForCoder)
        println(dictionary?.allKeys)
        var key = dictionary?.allKeys
        var resultingString = dictionary?.objectForKey("passcode") as! String
        println(resultingString)
        if(error != nil ){
            PasscodeCheck.setTitle("Create a Passcode", forState: .Normal)
        } else {
            PasscodeCheck.setTitle("Enter Your Passcode", forState: .Normal)
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func EnterPasscode(sender: AnyObject) {
        let(dictionary, error) = Locksmith.loadDataForUserAccount("svStatusPasscode")
        
        if(error != nil) {
            if(PasscodeValue.text != "") {
                let error = Locksmith.saveData(["passcode": PasscodeValue.text], forUserAccount: "svStatusPasscode")
                print("Added the passcode!")
                print(error)
            } else {
                var alert = UIAlertView()
                alert.title = "No passcode set"
                alert.message = "You must enter a passcode"
                alert.addButtonWithTitle("OK")
                alert.show()
            }
        } else {
            var passcode = dictionary?.objectForKey("passcode") as! String
            if(passcode == PasscodeValue.text) {
                println("A match!")
            } else {
                println("No match!")
            }
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
