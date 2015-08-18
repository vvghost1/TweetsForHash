//
//  MainViewController.swift
//  TweetsForHasgTag
//
//  Created by Yura Vorontsov on 12.08.15.
//  Copyright (c) 2015 Yura Vorontsov. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, DataModelDelegate {

    var cellWidth: [CGFloat!] = [nil,nil]
    @IBOutlet weak var tableView: UITableView!
    var bearerToken: String!
    var dataModel = DataModel()
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataModel.bearerToken = bearerToken
        dataModel.delegate=self
        
        tableView.estimatedRowHeight = 275.0
        spinner.color = UIColor.blackColor()
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        hashtagField.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataModelPerformReturn", name: "dataReady", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadSomeCells", name: "reloadSomeCells", object: nil)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
// MARK: - data model protocol
    func didRecieveTextDataForStartOfTable(newData: [Data], forSearchString str: String)
    {
        if str != searchText
        {
            return
        }
        dataModel.data = newData + dataModel.data
        dataModelPerformReturn()
        if autoUpdate
        {
            tableView.setContentOffset(CGPointZero, animated: true)
        }
    }
    func didRecieveTextDataForEndOfTable(newData: [Data], forSearchString str: String)
    {
        if str != searchText
        {
            return
        }
        dataModel.data += newData
        dataModelPerformReturn()
    }
    func didRecieveMedia(newMedia: [UIImage], forSearchString str: String, forId id: String, isFirstAvatar avatar: Bool)
    {
        if str != searchText
        {
            return
        }
        if let indexInData = find(dataModel.data.map{$0.id}, id)
        {
            var media = newMedia
            if avatar
            {
                dataModel.data[indexInData].tweet.profileImg = media.removeAtIndex(media.startIndex)
            }
            if dataModel.data[indexInData].tweet.image != nil
            {
            dataModel.data[indexInData].tweet.image! += media
            }
            else
            {
            dataModel.data[indexInData].tweet.image = media
            }
            reloadSomeCells()
            
        }

    }
    func requestForCleanRangeFromMedia(range: Range<Int>, forSearchString str: String)
    {
        if str != searchText
        {
            return
        }
        for index in range
        {
            dataModel.data[index].tweet.profileImg = nil
            dataModel.data[index].tweet.image = nil
        }
    }
    func askForTotallyNewSearch()
    {
        reCreateDataModel()
        dataModel.performNext(searchText)
    }
    func reCreateDataModel()
    {
        dataModel = DataModel(bearerToken: bearerToken)
        dataModel.delegate = self
        dataModelPerformReturn()
    }
    
// MARK: autoupdate
    var autoUpdate = false
        {didSet
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)){
                while self.autoUpdate
                {
                    sleep(10)
                    if self.autoUpdate
                    {
                        if let text = self.searchText
                        {
                            
                            if text != ""
                            {
                                self.dataModel.performNewTweets(text)
                            }
                        }
                    }}
            }
        }}
    
    @IBOutlet weak var autoButton: UIButton!
    
    @IBAction func autoTweetUpdate(sender: UIButton) {
        if !autoUpdate
        {
            dispatch_async(dispatch_get_main_queue()){
                self.autoUpdate = true
                self.autoButton.highlighted = true}
        }
        else
        {
            dispatch_async(dispatch_get_main_queue()){
                self.autoUpdate = false
                self.autoButton.highlighted = false}
        }
        
    }

    
    
    
    
// MARK: textField protocol
    
    
    @IBOutlet weak var hashtagField: UITextField!
    var searchText: String! = nil
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(textField: UITextField) {
        var arr = (split(textField.text){$0 == " "})
        if arr.count == 0
        {
            if searchText != nil
            {
                if searchText != ""
                {
                    textField.text = "#" + searchText}}
            return
        }
        var text = arr[0]
        if !text.hasPrefix("#")
        {
            text.insert("#", atIndex: text.startIndex)
        }
        if text == ""
        {
            textField.text = "#" + searchText
            return
        }
        textField.text = text
        text.removeAtIndex(text.startIndex)
        if searchText != text
        {
            searchText = text
            askForTotallyNewSearch()
            //tableView.reloadData()
            
        }
    }

    
// MARK: TableView protocol
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataModel.data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(dataModel.data[indexPath.row].cellType, forIndexPath: indexPath) as! TableViewCell
        
        self.dataModel.initThisCell(cell, row: indexPath.row)
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row < dataModel.offset
        {
            dataModel.refillSpase(areWeRefillingStart: true, row: indexPath.row)
        }
        if indexPath.row >= dataModel.data.count - dataModel.uppset
        {
            dataModel.refillSpase(areWeRefillingStart: false, row: indexPath.row)
        }
        if indexPath.row >= self.dataModel.data.count - 2 && self.searchText != nil && !self.dataModel.searchEnded
        {
            self.footView(true)
            self.dataModel.performNext(self.searchText)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return calculateCellHeight(indexPath.row)
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return calculateCellHeight(indexPath.row)
    }
    
    func calculateCellHeight(row: Int) -> CGFloat
    {
        var orient = 1
        if UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)
        {
            orient = 0
        }
        if dataModel.data[row].cellHeight[orient] != nil
        {
            return dataModel.data[row].cellHeight[orient]
        }
        if cellWidth[orient] == nil
        {
            cellWidth[orient] = tableView.frame.width
        }
        let contLabelWidth = cellWidth[orient] - 30 - 58
        var myLabel = UILabel(frame: CGRectMake(0, 0, contLabelWidth, CGFloat.max))
        myLabel.numberOfLines = 0
        myLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        myLabel.font = UIFont.systemFontOfSize(17.0)
        myLabel.text = dataModel.data[row].tweet.text
        myLabel.sizeToFit()
        if dataModel.data[row].cellType == "defaultCell"
        {
            dataModel.data[row].cellHeight[orient] = myLabel.frame.height + 47
        }
        else
        {
            dataModel.data[row].cellHeight[orient] = myLabel.frame.height + 47 + 208
        }
        return dataModel.data[row].cellHeight[orient]

    }
    
    

    
    
    
    
    
// MARK: some refresh stuff
    
    func refresh()
    {
        if searchText != nil
        {
            self.dataModel.performNewTweets(self.searchText)
        }
        else
        {
            refreshControl.endRefreshing()
        }
    }
    func dataModelPerformReturn()
    {
        dispatch_async(dispatch_get_main_queue()){
        if self.refreshControl.refreshing
        {
            self.refreshControl.endRefreshing()
        }
        if self.tableView.tableFooterView != nil
        {
        self.footView(false)
        }
        
        self.tableView.reloadData()
        
        }
    }
    func reloadSomeCells()
    {
        dispatch_async(dispatch_get_main_queue()){
        self.tableView.reloadData() //?
        }
    }
    func footView(status: Bool)
    {
        if status
        {
            spinner.startAnimating()
            tableView.tableFooterView = spinner
        }
        else
        {
            spinner.stopAnimating()
            tableView.tableFooterView = nil
        }
    }

}
