//
//  ViewController.swift
//  kogepan-q
//
//  Created by 堅固潤也 on 2018/05/20.
//  Copyright © 2018年 堅固潤也. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {
    var titleArray: [String] = [NSLocalizedString("appVersion", comment: "appVersion"),NSLocalizedString("yourOpinion", comment: "yourOpinion")]
    var textArray: [String] = [ Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, "Twitter(@spoon_kogepan)"]
    var sentLabel:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.red
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titleArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = self.titleArray[indexPath.row] + " : "  + self.textArray[indexPath.row]
        return cell
    }
    
    override func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {

        
    }
    
}
