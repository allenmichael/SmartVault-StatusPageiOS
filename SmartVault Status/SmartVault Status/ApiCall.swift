//
//  ApiCall.swift
//  SmartVault Status
//
//  Created by Allen-Michael Grobelny on 6/12/15.
//  Copyright (c) 2015 Allen-Michael Grobelny. All rights reserved.
//

import Foundation

class ApiCall : ComponentApiProtocol, CreateIncidentApiProtocol {
    
    let pageID = "p05k52wrb15t"
    let statusURL = "https://api.statuspage.io/v1/pages/"
    let jsonAuth = ".json?api_key="
    let componentExtensionUrl = "/components"
    let incidentExtensionUrl = "/incidents"
    
    var apiKey: String?
    var updateComponentUrl: String?
    var baseComponentsUrl: NSURL?
    var createIncidentsUrl: NSURL?
    
    init(var key: String) {
        apiKey = key
        constructBaseComponentsUrl()
        constructIncidentCreationUrl()
    }
    
    init(var key: String, var component: String) {
        apiKey = key
        constructComponentUrl(component)
    }
    
    func constructBaseComponentsUrl() {
        baseComponentsUrl = NSURL(string: statusURL + pageID + componentExtensionUrl + jsonAuth + apiKey!)
    }
    
    func constructComponentUrl(var component: String) {
        
        var constructedUrl:String = statusURL + pageID + componentExtensionUrl + "/" + component + jsonAuth + apiKey!
        updateComponentUrl = constructedUrl
        
    }
    
    func constructIncidentCreationUrl() {
        createIncidentsUrl = NSURL(string: statusURL + pageID + incidentExtensionUrl + jsonAuth + apiKey!)
    }
    
    func makeComponentApiCall (var params: NSDictionary, var httpVerb: String) -> NSMutableURLRequest {
        
        var request = NSMutableURLRequest(URL: NSURL(string: updateComponentUrl!)!)
        request.HTTPMethod = httpVerb
        var err: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        
        return request
        
    }
    
    func makeIncidentCreationApiCall(params: NSDictionary, httpVerb: String) -> NSMutableURLRequest {
        var request = NSMutableURLRequest(URL: createIncidentsUrl!)
        var err: NSError?
        request.HTTPMethod = httpVerb
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        return request
    }
    
}