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
        self.navigationController?.navigationBar.tintColor = UIColor.red
        self.tableView.tableFooterView = UIView()
        self.title = "音源選択"
        
    }
    override func viewWillAppear(_ animated: Bool) {
        self.fileArraySet()
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
            
        }
    }
    
    func fileArraySet() {
        self.fileNameArray = []
        if let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            do {
                self.fileNameArray = try FileManager.default.contentsOfDirectory(atPath: documentDirectory)
                if fileNameArray.index(of: "Inbox") != nil {
                    self.fileNameArray.remove(at: fileNameArray.index(of: "Inbox")!)//[fileNameArray.index(of: "Inbox")!]
                }
                do {
                    let otherFileNameArray = try FileManager.default.contentsOfDirectory(atPath: documentDirectory + "/Inbox")
                    for oFile in  otherFileNameArray {
                        self.fileNameArray += ["Inbox/" + oFile]
                    }
                } catch let error {
                    print(error)
                }
            } catch let error {
                print(error)
            }
            
            
        }
        tableView.reloadData()
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
    
    func returnfileSize(path: String) -> String {
        do {
            let manager = FileManager.default
            let attributes = try manager.attributesOfItem(atPath: path) as NSDictionary
            let fileSize: Double = Double(attributes.fileSize())
            return String(format: "%.2f",(fileSize/1024.0/1024.0))
        }
        catch _ as NSError {
            return ""
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        let file = getURL(fileName: self.fileNameArray[indexPath.row],m4aAddFlag: false)
        cell.textLabel?.text = self.fileNameArray[indexPath.row] + " : " + returnfileSize(path: file.path) + "MB"
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
