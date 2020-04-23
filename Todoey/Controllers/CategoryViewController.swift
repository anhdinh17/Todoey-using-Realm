//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Anh Dinh on 4/16/20.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

class CategoryViewController: UITableViewController {
    
    // initialize Realm
    // don't worry about try! in this situation,
    // it's a valid way to initialize Realm
    let realm = try! Realm()
    
    // Results is an auto-updating container
    // container means it's like List, Array, etc.
    // atuo-updating: when adding new Category with add button, we don't have to append it to "categories", Results will take care of it.
    // make Results<Category> optional in case we forget to loadCategories() in ViewDidLoad
    // hieu don gian la nhieu khi co hoac ko co cai Category nao lol
    var categories: Results<Category>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCategories()
        
        tableView.rowHeight = 90.00 // change the height of the row
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if categories?.count is not nil, return it otherwise return 1
        return categories?.count ?? 1
    }
    
    //    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! SwipeTableViewCell
    //        cell.delegate = self
    //        return cell
    //    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // as! SwipeTableViewCell is from SwipeCellKit library to work with the swipe
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! SwipeTableViewCell
        
        cell.textLabel?.text = categories?[indexPath.row].name ?? "No Category Added"
        
        cell.delegate = self // from SwipeCellKit library
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Segueway to go from CategoryViewController to TodoListViewController when we click on 1 row/1 Category
        performSegue(withIdentifier: "goToItems", sender: self)
    }
    
    // prepare for SegueWay
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // create an instance of ToDoListViewController
        let destinationVC = segue.destination as! TodoListViewController
        
        // grab the Category correspond to selected cell
        // 1. create indexPath, just like the one in tableView func, but bc we
        // can't tap into that local variable, we create a new one here
        // 2. Set the selectedCategory = the Category of the row that we click
        if let indexPath = tableView.indexPathForSelectedRow{ // optional binding bc this is optional
            destinationVC.selectedCategory = categories?[indexPath.row]
        }
    }
    
    //MARK: - Data Manipulation Methods:
    // Save to Realm:
    func save(category: Category){
        do{
            try realm.write{ // commit changes to Realm
                realm.add(category) // add data of Category to Realm
            }
        }catch{
            print("Error saving Category: \(error)")
        }
        tableView.reloadData()
    }
    
    // Load data from Realm
    func loadCategories(){
        
        // this pulls out all Categories objects in Realm and store into categories
        // realm.objects(Category.self) returns Results<Category> matching categories type decalred at top
        categories = realm.objects(Category.self)
        
        tableView.reloadData()
    }
    
    //MARK: - Add button pressed
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        // create alert with a note of "Add new Category"
        let alert = UIAlertController(title: "Add new Category", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Category", style: .default) { (action) in
            
            let newCategory = Category()
            newCategory.name = textField.text!
            /* No need to append newCategory to "categories"
             because Results<> is auto-updating, it will automatically add new Category to it that will
             update "categories".
             */
            
            //print(self.categories)
            
            self.save(category: newCategory) // save data to Realm
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "type in a category"
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        present(alert,animated: true, completion: nil)
    }
}

//MARK: - Swipe Cell Delegate Methods from SwipeCellKit library
extension CategoryViewController: SwipeTableViewCellDelegate {
    
    // delegate method from library cocoapod SwipeCellKit
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        // swipe from right
        guard orientation == .right else { return nil }
        
        // delete action when we swipe and click on Delelte
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // when clicking on "Delete"
            // unwrap categories because it's optional
            if let categoryForDeletion = self.categories?[indexPath.row]{
                do{
                    try self.realm.write{
                        self.realm.delete(categoryForDeletion) // delete this Category from Realm
                    }
                }catch{
                    print("Error deleting this cell: \(error)")
                }
                 tableView.reloadData()
            }
            
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: "delete-icon")
        
        return [deleteAction]
    }
    
//    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
//        var options = SwipeOptions()
//        options.expansionStyle = .destructive
//        return options
//    }
    
}
