
//
//  MasterTableViewController.swift
//  OdataFioriDemoApp
//
//  Created by Riya Ganguly on 09/06/17.
//  Copyright © 2017 SAP. All rights reserved.
//

import UIKit
import MessageUI
import SAPFoundation
import SAPFiori
import SAPCommon
import SAPOData

class MasterTableViewController: UITableViewController , Notifier, MFMailComposeViewControllerDelegate, ActivityIndicator, UISearchBarDelegate,MasterDetailCustomerDelegate {

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var collectionType: CollectionType = .none {
        didSet {
            
        }
    }
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var activityIndicator: FUIProcessingIndicatorView!
    var entities: [EntityValue]? = nil;
    var filteresEntities: [EntityValue]? = nil;
    var customers: Customer?
    var fuiNavigationbar: FUINavigationBar!
    var searchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = self.collectionType.rawValue
//        FUIToastMessage.show(message: "Loading Data...", icon: UIImage(named: "default_person.png")!, inView: self.view, withDuration: 1.0, maxNumberOfLines: 1)
        
//        self.addtableHeaderView()
        tableView.estimatedRowHeight = 300
        tableView.rowHeight = UITableViewAutomaticDimension
        self.activityIndicator = self.initWithActivityIndicator()
        self.activityIndicator.center = self.tableView.center
        self.tableView.addSubview(self.activityIndicator)
        self.getDetailCollectionData()
        searchBar.delegate=self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//    func searchBar(searchBar: UISearchBar, textDidChange searchText: String){
//        print(searchText)
//    }
    
    
    
    //MARK: - Entity fetches
    
    fileprivate func getProductsData(){
        ProductDA().requestEntities(completionHandler: { (product, error) in
            guard let products = product else {
                print("error")
                return
            }
            print(products)
            print(products.count)
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.hideActivityIndicator(self.activityIndicator)
            }
            self.entities = products
            self.filteresEntities = products
        })
    }
    
    func getSalesOrderData(){
        SalesOrderHeaderDA().requestEntities { (entities,error) in
            guard let error = error else {
                DispatchQueue.main.async {
                    
                    self.entities=entities!;
                    self.filteresEntities = entities!
                    let salesorderheader = self.entities?[0] as! SalesOrderHeader
                    print("\(salesorderheader.salesOrderID ?? "")")
                    self.tableView.reloadData()
                    print("Table updated successfully!")
                    self.hideActivityIndicator(self.activityIndicator)
                }
                return
            }
            self.hideActivityIndicator(self.activityIndicator)
            self.displayAlert(
                title: NSLocalizedString("keyErrorLoadingData", value: "Loading data failed!",
                                         comment: "XTIT: Title of loading data error pop up."),
                message: "\(error.localizedDescription)",
                buttonText: NSLocalizedString("keyOkButtonLoadingDataError", value: "OK", comment: "XBUT: Title of OK button."))
        }
    }
    
    func getCustomerData(){
        CustomerDA().requestEntities { (entities,error) in
            guard error != nil else {
                DispatchQueue.main.async {
                    
                    self.entities=entities!;
                    self.filteresEntities = entities!
                    let customers = self.entities?[0] as! Customer
                    print("\(customers.customerID ?? "")")
                    self.tableView.reloadData()
                    print("Table updated successfully!")
                    self.hideActivityIndicator(self.activityIndicator)
                }
                return
            }
            self.hideActivityIndicator(self.activityIndicator)
            self.displayAlert(
                title: "Loading data failed!",
                message: "Error loading data",//"\(error.localizedDescription)",
                buttonText:"OK")
        }
    }

    // MARK: - Class Methods
    
    func getDetailCollectionData()  {
        
        switch collectionType {
        case .salesOrderHeaders:
            self.showActivityIndicator(self.activityIndicator)
            self.tableView.register(FUIObjectTableViewCell.self, forCellReuseIdentifier: "FUICell")
            self.getSalesOrderData()
        case .customers:
            DispatchQueue.main.async {
                self.showActivityIndicator(self.activityIndicator)
            }
            self.tableView.register(FUIContactCell.self, forCellReuseIdentifier: "FUICell")
            self.getCustomerData()
            
        case .products:
            self.showActivityIndicator(self.activityIndicator)
            self.navigationItem.title = "Products"
            tableView.register(FUIObjectTableViewCell.self, forCellReuseIdentifier: "FUIObjectCell")
            getProductsData()
            
        default:
            self.dismissIndicator(self.activityIndicator)
            self.displayAlert(title: "Warning", message: "Something goes wrong!!", buttonText: "OK")
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        filterContentForSearchText(searchText: searchText)
    }

    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteresEntities?.removeAll()
//        let filteredEntities = self.entities.map({$0 as? [Customer]})
        
        
//        filteresEntities = filteredEntities??.filter{ entity  in
//            (entity.firstName!.contains(searchText.lowercased()))
//        }
        filteresEntities = self.entities!.filter{ entity  in
            (entity.entityID?.contains(searchText.lowercased()))!
        }
    
        if(searchText == ""){
            filteresEntities = self.entities
        }
        print(filteresEntities ?? "")
        self.tableView.reloadData()
    }

    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([(customers?.emailAddress)!])
            mail.setSubject("Test")
            mail.setMessageBody("<p>This is a Test Message</p>", isHTML: true)
            
            present(mail, animated: true)
        } else {
            self.displayAlert(title: "Warning", message: "Mail Service not supported in this device", buttonText: "OK")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func callNumber(phoneNumber:String) {
        
        if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {
            
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            }else {
                self.displayAlert(title: "Warning", message: "Phones Service not supported in this device", buttonText: "OK")
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if(self.filteresEntities == nil){
            return 0
        }
        else{
            return self.filteresEntities!.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch collectionType {
            case .salesOrderHeaders:
                let cell = tableView.dequeueReusableCell(withIdentifier: "FUICell",for: indexPath as IndexPath)as! FUIObjectTableViewCell
                cell.accessoryType = .detailDisclosureButton
//                let salesorderheader = self.entities?[indexPath.row] as! SalesOrderHeader
                let salesorderheader = self.filteresEntities?[indexPath.row] as! SalesOrderHeader
                cell.headlineText = "\(salesorderheader.salesOrderID ?? "")"
                cell.footnoteText = "\(String(describing: salesorderheader.createdAt))"
                return cell
            case .customers:
                let cell = tableView.dequeueReusableCell(withIdentifier: "FUICell") as! FUIContactCell
//                customers = self.entities?[indexPath.row] as? Customer
                customers = self.filteresEntities?[indexPath.row] as? Customer
                let customerName = (customers?.firstName!)! + " " + (customers?.lastName!)!
                let address = "\(customers?.street ?? "")" + ", " + "\(customers?.city ?? "")" + " - " + "\(customers?.postalCode ?? "")"
                
                let activities = [FUIActivityItem.phone, FUIActivityItem.email]
                cell.detailImage = UIImage(named: "icon.jpg")
                cell.headlineText = customerName
                cell.subheadlineText = customers?.customerID//address
                cell.descriptionText = address + ",\(customers?.country ?? "")"
                cell.activityControl.addActivities(activities)
                
                cell.onActivitySelectedHandler = { activities in
                    
                    switch activities {
                    case FUIActivityItem.phone:
                        self.callNumber(phoneNumber:(self.customers?.phoneNumber!)!);
                    case FUIActivityItem.email:
                        self.sendEmail()
                    default:
                        self.displayAlert(title: "Warning", message: "Something goes wrong!!", buttonText: "OK")
                    }
                }
                
                
                return cell
            
            case .products:
                
                let cell = (tableView.dequeueReusableCell(withIdentifier: "FUIObjectCell", for: indexPath) as? FUIObjectTableViewCell)!
//                let product = entities?[indexPath.row] as? Product
                let product = filteresEntities?[indexPath.row] as? Product
                cell.headlineText = "\(product?.category! ?? "")"
                cell.subheadlineText = product?.categoryName ?? ""
                cell.descriptionText = product?.longDescription ?? ""
                return cell
            
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                self.displayAlert(title: "Warning", message: "Something goes wrong!!", buttonText: "OK")
                return cell
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let controller = segue.destination as! DetailTableViewController//(segue.destination as! UINavigationController).topViewController as! DetailTableViewController
//                controller.selectedEntity = self.entities?[indexPath.row]
                controller.selectedEntity = self.filteresEntities?[indexPath.row]
                controller.collectionType = self.collectionType
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
        if segue.identifier == "addEntity" {
            let controller = (segue.destination as! UINavigationController).viewControllers[0] as! DetailTableViewController
            controller.title = "Add Entity"
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: controller, action: #selector(controller.createSelectedEntity))
            controller.navigationItem.rightBarButtonItem = doneButton
            let cancelButton = UIBarButtonItem(title: NSLocalizedString("keyCancelButtonToGoPreviousScreen", value: "Cancel", comment: "XBUT: Title of Cancel button."),
                                               style: .plain, target: controller, action: #selector(controller.cancel))
            controller.navigationItem.leftBarButtonItem = cancelButton
            controller.collectionType = self.collectionType
            controller.showDetailViewController(controller, sender: sender)
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowDetail", sender: tableView)
    }
    
    //MARK: - MasterDetailCustomerDelegate
    func showDetail(type: CollectionType) {
        print(type)
        collectionType = type
        self.showActivityIndicator(self.activityIndicator)
        self.navigationItem.title = collectionType.rawValue
        getDetailCollectionData()
    }

}

//extension MasterTableViewController: UISearchResultsUpdating {
//    func updateSearchResults(for searchController: UISearchController) {
//        filterContentForSearchText(searchText: searchController.searchBar.text!)
//    }
//}

