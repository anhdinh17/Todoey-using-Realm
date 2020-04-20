//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Anh Dinh on 4/16/20.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import UIKit
import CoreData

class CategoryViewController: UITableViewController {
    
    // create array for category from Category from Core Data
    var categories = [Category]()
    
    // create context of Core Data
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCategories()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        
        cell.textLabel?.text = categories[indexPath.row].name
        
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
            destinationVC.selectedCategory = categories[indexPath.row]
        }
    }
    
    //MARK: - Data Manipulation Methods:
    // Save to Core Data:
    func saveCategories(){
        do{
            try context.save()
        }catch{
            print("Error saving Category: \(error)")
        }
        tableView.reloadData()
    }
    
    // Load Category from Core Data
    // default value for request is the entity of Catgory
    func loadCategories(with request: NSFetchRequest<Category> = Category.fetchRequest()){
        do{
            categories = try context.fetch(request)
        }catch{
            print("Error loading: \(error)")
        }
        
        tableView.reloadData()
        
    }
    
    //MARK: - Add button pressed
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        // create alert with a note of "Add new Category"
        let alert = UIAlertController(title: "Add new Category", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Category", style: .default) { (action) in
            
            let newCategory = Category(context: self.context)
            newCategory.name = textField.text
            self.categories.append(newCategory)
            
            self.saveCategories()
            
            print("Add Category working")
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "type in a category"
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        present(alert,animated: true, completion: nil)
    }
}
