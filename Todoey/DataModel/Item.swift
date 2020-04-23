//
//  Item.swift
//  Todoey
//
//  Created by Anh Dinh on 4/21/20.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation
import RealmSwift

// Object is for RealmSwift
class Item: Object{
    @objc dynamic var title: String = ""
    @objc dynamic var done: Bool = false
    @objc dynamic var dateCreated: Date?
    
    // INVERSE relationship
    // this code means parentCategory is all items that belong to Category, through "items" - the variable of the forward relationship.
    var parentCategory = LinkingObjects(fromType: Category.self, property: "items")
}
