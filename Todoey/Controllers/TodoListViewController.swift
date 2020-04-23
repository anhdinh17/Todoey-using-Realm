//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift

class TodoListViewController: UITableViewController{
    
    let realm = try! Realm()
    
    var todoItems: Results<Item>?
    
    var selectedCategory: Category? { //optional bc it's going to be nill until we give it value from the prepare Seuge way code.
        // didSet = as soon as selectedCategory has a value, it triggers the codes inside it
        // so when the users click on 1 category, it will go to second ViewController and loadItems() to show items
        // we don't need to leave the loadItems() in ViewDidLoad anymore
        didSet{
            loadItems()
        }
    }
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    //MARK: - TableView DataSource methods
    // return number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    // display each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        
        // optional binding because todoItems is optional
        if let item = todoItems?[indexPath.row]{
            // set the textLabel of this cell
            cell.textLabel?.text = item.title
            
            //Ternary Operator
            // to check "done" and give checkmark depending on todoItems[indexPath.row].done value
            cell.accessoryType = item.done ? .checkmark : .none
        }else{
            cell.textLabel?.text = "No Item Added"
        }
        
        return cell
    }
    
    //MARK: - Delegate Methods to select each row
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // UPDATE using Realm
        // optional binding because todoItems is optional
        if let item = todoItems?[indexPath.row]{
            do{
                try realm.write{
                    item.done = !item.done
                    
                    // realm.delete(item) ------> if you want to DELETE using Realm
                }
            }catch{
                print("Error updating cell: \(error)")
            }
        }
        
        tableView.reloadData()
        
        // fash grey when clicking on the row
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add Button pressed
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        // we create a UITextField variable to store the text of the
        // UITextField of the Alert
        var textField = UITextField()
        
        // create an alert
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        // the button we click to add new item
        let action = UIAlertAction(title: "Add item", style: .default) { (action) in
            // What will happen when we click "Add item" button on the UIAlert
            
            // optional binding selectedCategory
            if let currentCategory = self.selectedCategory{
                // what happens here is that we add new Item,
                // append it to current Category "items" ===> this is the key line
                // save it without save() method ( we delete save() already)
                do{
                    try self.realm.write{
                        let newItem = Item()
                        newItem.title = textField.text! // use the text from alertTextField/UITextField
                        newItem.dateCreated = Date()
                        
                        // I think we use the relationship we created in Category.swift
                        // to add the new Item to the List<> belong to the Category
                        // by using this line, we add new Item to Realm and make it appearn to the current Category in Realm
                        // and it can be printed in tableView.
                        currentCategory.items.append(newItem) // ===> IMPORTANT LINE
                        
                        /*
                         self.realm.add(newItem)
                         if we use realm.add(), it just the newItem to Realm, it doesn't add that to the current Category, and we can't print it to tableView
                         the KEY LINE is currentCategory.items.append()
                        */
                        print(self.todoItems)
                    }
                }catch{
                    print("Error writing to Realm: \(error)")
                }
            }
            
            self.tableView.reloadData()
        }
        
        // add a text field to the alert
        // the parameter "alertTextField" is an UITextField
        // we store alertTextField to textField so that it can be used
        // inside the closure of the "Add item" button,
        // which means alertTexField.text = textField.text
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        // combine action to alert
        alert.addAction(action)
        // present the alert
        present(alert,animated: true, completion: nil)
    }
    
    //MARK: - loadItems
    
    func loadItems(){
        // look at Category.swift, selectedCategory.items is a List of Items objects
        // so we put a List of Items objects sorted by "title" into todoItems
        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        
        tableView.reloadData()
    }
    
}

//https://codewithchris.com/swift-try-catch/

//MARK: - UISearchBarDelegate
extension TodoListViewController: UISearchBarDelegate{
    // SearchBarDelegate func when users press search button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // make a new todoItems with the filter and sort by "title"
        // we can sort by time if you want, watch video 284
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()
      
    }

    // when the text inside the searchBar change
    // for example if we type some texts, it will trigger this func
    // OR when we have some text and we remove all the text to 0, this func also runs
    // RMB: when we first starts the app, this func doesn't run because there's no change
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 { // when we remove all the text(cross button)
            loadItems()

            DispatchQueue.main.async {
                // this one is to disappear keyboard, cursor in searchBar after we stop using it
                // it means that searchBar is not in editing mode, everything back to before we use searchBar
                // and it has to be in DispatchQueue.main.async
                searchBar.resignFirstResponder()
            }

        }
    }
}

/*
 04/15/2020:
 About request.predicate:
 - in loaditems(), if you print the request (call loadItems() when app first load), you will see that request has "predicate", "sortDescriptors" properties.
 - when we use SearchBar and tap into the request.predicate, it will change the "predicate" of the request, which makes the request now have only the query that we want, so when you fetch the request again in the SearchBar, it will give you the new request with the query.
 
 04/18/2020:
 - So now we have to understand this: when we click on 1 Category and go to Items screen, the tableView shows only the items that belong to corresponding Category.
 - in loadItems(), we have to modify it so that the default request is Item entity, and the default query is the items belong to the same Category.
 - when using the searchbar, we combine the query of the search bar and the default query by using NSCompoundPredicate()
 
 04/22/2020:
 -Start using Realm, pay attention to add button pressed, it's kind of complicated.
 -Inside real.write{}, work just like working with OOP stuff.
 */
