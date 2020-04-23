//
//  Category.swift
//  Todoey
//
//  Created by Anh Dinh on 4/21/20.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation
import RealmSwift
import SwipeCellKit

// Object is usef for saving into Realm
class Category: Object {
    // whatever saved in Realm, we have to use @obj dynamic
    @objc dynamic var name: String = ""
    
    // relationship between Category and Item like we did in Core Data Graph
    // List is something from Realm
    // List<Item>() is a list of objects of Item
    // this is the FORWARD relationship, items points to a lists of Item.
    // maybe because this is a relationship link, that's why we don't use @objc dynamic
    let items = List<Item>()
}
