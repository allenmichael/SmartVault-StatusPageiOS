//
//  UnresolvedModel.swift
//  SmartVault Status
//
//  Created by Allen-Michael Grobelny on 5/15/15.
//  Copyright (c) 2015 Allen-Michael Grobelny. All rights reserved.
//

import UIKit

class UnresolvedModel: NSObject {
    
    var backfilled: Bool = Bool()
    var created_at: String = String()
    var id: String = String()
    var impact: String = String()
    var impact_override: String! = String()
    var incident_updates: Array<IncidentUpdateModel> = []
    var name: String = String()
    
    func deleteIncidentUpdates() {
        incident_updates.removeAll()
    }
    
}
