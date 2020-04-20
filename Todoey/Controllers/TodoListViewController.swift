//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController{
    
    var itemArray = [Item]()
    
    var selectedCategory: Category? { //optional bc it's going to be nill until we give it value from the prepare Seuge way code.
        // didSet = as soon as selectedCategory has a value, it triggers the codes inside it
        // so when the users click on 1 category, it will go to second ViewController and loadItems() to show items
        // we don't need to leave the loadItems() in ViewDidLoad anymore
        didSet{
            loadItems()
        }
    }
    
    let defaults = UserDefaults.standard
    
    // still need the dataFilePath to see where the SQLite is saved
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    
    // Create the context of Core Data
    // UIApplication.shared is a Singleton
    // UIApplication.shared.delegate as! AppDelegate is to tap into an object
    // of AppDelegate file so that we can get to the persistentContainer
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(dataFilePath)

    }
    
    //MARK: - TableView DataSource methods
    // return number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    // display each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        
        let item = itemArray[indexPath.row]
        
        // set the textLabel of this cell
        cell.textLabel?.text = item.title
        
        //Ternary Operator
        // to check "done" and give checkmark depending on itemArray[indexPath.row].done value
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    //MARK: - Delegate Methods to select each row
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        /* If you want to delete one row:
         the order is very important, we delete data from Core Data first,
         then we delete it from the itemArray
         
         context.delete(itemArray[indexPath.row])
         itemArray.remove(at: indexPath.row)
         
         */
        
        // togle the "done" of Item()
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        
        saveItems()
        
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
            
            // create new Object of Item inside context of Core Data
            // give both title and done values because when we create the attributes
            // within the Core Data, we uncheck the "optional" so they can't be nil
            let newItem = Item(context: self.context)
            newItem.title = textField.text! // use the text from alertTextField/UITextField
            newItem.done = false
            newItem.parentCategory = self.selectedCategory
            /* We create a relationship graph in Core Data,
             newItem.parenCategory is to set this newItem belong to the Category
             of selectedCategory.
             */
            
            self.itemArray.append(newItem)
            
            self.saveItems()
            
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
    
    func saveItems(){
        do{
            try context.save() // save whatever inside context to Core Data SQLite.
        }catch{
            print("Error saving context: \(error)")
        }
        
        tableView.reloadData() // trigger DataSource methods
    }
    
    //MARK: - loadItems
    // this func has internal and external parameter
    // it also has default value of request: NSFetchRequest<Item> = Item.fetchRequest()
    // which means that by default, request is now fetched with data from Item entity.
    // we can just call "loadItems()" without giving any para. just like in ViewDidLoad
    // and this process below still runs to load data.
    // 04-18-20: we add another parameter, predicate: NSPredicate? = nil
    // which means by default, predicate is nil
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(),predicate: NSPredicate? = nil){
       // create a predicate that has the items with parentCategory.name MATCHES selectedCategory.name
        // which means items belong to the same Category entity
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory?.name as! CVarArg)
        
        // because predicate has default of nil, optional binding it.
        // if it's not nil, we have a compound predicate.
        // if it's nil, then we only have 1 categoryPredicate.
        if let additionalPredicate = predicate {
            /* NSCompoundPredicate:
             - it is an array of 2 or more predicates
             - pay attention to the "and" (there's one with "or" too) at the beggining of the parameter, this means
             that the predicate is "parentCategory.name MATCHES %@" AND "title CONTAINS[cd] %@",
             this is used when we click on the search bar and start search process, it means all items
             in this Category AND they contain the context of your search.
             */
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate,additionalPredicate])
        }else{
            request.predicate = categoryPredicate
        }
        
        print(request)
        
        do{
            // store result of fetch into itemArray so that DataSource can use it
            itemArray = try context.fetch(request)
            print(request)
        }catch{
            print("Error fetching data from Core Data: \(error)")
        }
        
        tableView.reloadData()
    }
    
}

//https://codewithchris.com/swift-try-catch/

//MARK: - UISearchBarDelegate
extension TodoListViewController: UISearchBarDelegate{
    // SearchBarDelegate func when users press search button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        //the query that we want
        // in this case, we want to have all the items whose "title" contains the text in search bar.
        // I know it's weird to use String but watch the video
        // %@ is replaced by the searchBar.text! in background
        // [cd] is for case sensitive and diacritic
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        
        // sort the title of the items ascendingly
        // because request.sortDescriptors is an array of NSSortDescriptor
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        loadItems(with: request, predicate: predicate)// this request now is predicate with query.
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
 */
