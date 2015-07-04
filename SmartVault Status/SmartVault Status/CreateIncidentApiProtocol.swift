//
//  CreateIncidentApiProtocol.swift
//  SmartVault Status
//
//  Created by Allen-Michael Grobelny on 6/12/15.
//  Copyright (c) 2015 Allen-Michael Grobelny. All rights reserved.
//

import Foundation

protocol CreateIncidentApiProtocol {
    
    func constructIncidentCreationUrl()
    
    func makeIncidentCreationApiCall(var params: NSDictionary, var httpVerb: String) -> NSMutableURLRequest
    
}