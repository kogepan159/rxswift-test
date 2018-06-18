//
//  ViewController.swift
//  kogepan-q
//
//  Created by 堅固潤也 on 2018/05/20.
//  Copyright © 2018年 堅固潤也. All rights reserved.
//

import UIKit

class SelectTableViewController: UITableViewController {
    var fileNameArray: [String] = []
    var sentLabel:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fileArraySet()
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fileNameArray.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            print("削除処理")
            self.deleteMusic(deleteFilename:  self.fileNameArray[indexPath.row])
            self.fileArraySet()
            tableView.reloadData()
        }
    }
    
    func fileArraySet() {
        if let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            
            do {
                self.fileNameArray = try FileManager.default.contentsOfDirectory(atPath: documentDirectory)
                
            } catch let error {
                print(error)
            }
        }
    }
    
    func deleteMusic(deleteFilename: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let url = docsDirect.appendingPathComponent(deleteFilename)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            //エラー処理
            print("error")

        }
    
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = self.fileNameArray[indexPath.row]
        return cell
    }
    
    override func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        // [indexPath.row] から画像名を探し、UImage を設定
        self.sentLabel = self.fileNameArray[indexPath.row]
        if self.sentLabel !=  "" {
            // SubViewController へ遷移するために Segue を呼び出す
           goToNextPage()
        }
    }
    
    func goToNextPage(){
        
        let next = self.storyboard?.instantiateViewController(withIdentifier:"EditingViewController") as? EditingViewController
        next!.fileName = self.sentLabel
        self.navigationController?.pushViewController(next!, animated: true)
    }
}
