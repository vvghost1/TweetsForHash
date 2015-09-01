//
//  DataModel.swift
//  TweetsForHasgTag
//
//  Created by Yura Vorontsov on 13.08.15.
//  Copyright (c) 2015 Yura Vorontsov. All rights reserved.
//

import Foundation
import UIKit

struct Tweet
{
    var text = ""
    var name = ""
    var profileImg: UIImage?
    var profileImgUrl: String?
    var image: [UIImage]?
    var imageUrl: [String]?
}

struct Data
{
    var tweet: Tweet
    var id: String
    var cellHeight: [CGFloat!] = [nil,nil]
    var cellType: String
    init(tweet theTweet: Tweet, id ids: String, cellType ctype: String)
    {
        id=ids
        cellType = ctype
        tweet = theTweet
    }
    init(tweet theTweet: Tweet, id ids: String)
    {
        self.init(tweet: theTweet, id: ids, cellType: "defaultCell")
    }
    init(id ids: String, cellType ctype: String)
    {
        self.init(tweet: Tweet(), id: ids, cellType: ctype)
    }
    init(id ids: String)
    {
        self.init(tweet: Tweet(), id: ids, cellType: "defaultCell")
    }
}

protocol DataModelDelegate: class
{
    func didRecieveTextDataForEndOfTable(newData: [Data], forSearchString str: String)
    func didRecieveTextDataForStartOfTable(newData: [Data], forSearchString str: String)
    func didRecieveMedia(newMedia: [UIImage], forSearchString str: String, forId id: String, isFirstAvatar avatar: Bool)
    func requestForCleanRangeFromMedia(range: Range<Int>, forSearchString str: String)
    func askForTotallyNewSearch()
}


class DataModel
{
    
    init(bearerToken token: String)
    {
        bearerToken = token
        semafor = dispatch_semaphore_create(1)
    }

    init()
    {
        semafor = dispatch_semaphore_create(1)
    }

    let maxDataArraySize = 200
    let countOfTweets = 15
    
    var data = [Data]()
    weak var delegate: DataModelDelegate?
    var semafor: dispatch_semaphore_t!
    var bearerToken: String!
    var offset = 0
    var uppset = 0
    var storedTweetsCount: Int{get{return data.count - offset - uppset}}
    var lastStoredTweetIndex: Int{get{return data.count - uppset - 1}}
    
    var maxId: String? //id твита снизу, который не был загружен (если не был совсем последним, и тогда поиск закончен)
    var searchText = ""
    var searchEnded = true
    
// MARK: url composer
    let urlPrefix = "https://api.twitter.com/1.1/search/tweets.json?q=%23"
    var urlSuffix = "&result_type=recent"
    
    func getUrlForSearchHash(str: String, maxId: String?, sinceId: String?, counterOfTweets: Int)->String
    {
        var ids = ""
        if let mid = maxId
        {
            ids = "&max_id=" + mid
        }
        if let sid = sinceId
        {
            ids += "&since_id=" + sid
        }
        if counterOfTweets != 15
        {
            urlSuffix += "&count=\(counterOfTweets)"
        }
        return urlPrefix + str + urlSuffix + ids
    }
    
    func getUrlForSearchHash(str: String, maxId: String?, sinceId: String?)->String
    {
        return getUrlForSearchHash(str, maxId: maxId, sinceId: sinceId, counterOfTweets: countOfTweets)
    }

// MARK: Media download section
    struct MediaForBackgroundDownload
    {
        var id: String
        var status: String
        var imgUrl: [String]
    }
    var mediaForBackgroundDownload = [MediaForBackgroundDownload]()
    
    func downloadMedia()
    {
        let localMediaArr = mediaForBackgroundDownload
        mediaForBackgroundDownload.removeRange(0..<localMediaArr.count)
        for mediaEnt in localMediaArr
        {
            let id = mediaEnt.id
            for imgUrl in mediaEnt.imgUrl
            {
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: imgUrl)!, completionHandler: {(data1: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
                    if let thePict = UIImage(data: data1)
                    {
                        var isAvatar = false
                        if mediaEnt.status == "avatar"
                        {
                            isAvatar = true
                        }
                        dispatch_semaphore_wait(self.semafor, DISPATCH_TIME_FOREVER)
                        self.delegate?.didRecieveMedia([thePict], forSearchString: self.searchText, forId: mediaEnt.id, isFirstAvatar: isAvatar)
                        dispatch_semaphore_signal(self.semafor)
                    }
                }).resume()
            }
        }
    }

    
// MARK: downloading top of table
    func performNewTweets(str: String)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
        dispatch_semaphore_wait(self.semafor, DISPATCH_TIME_FOREVER)
        
        if self.data.count < 2
        {
            self.delegate?.askForTotallyNewSearch()
            dispatch_semaphore_signal(self.semafor)
            return
        }
    
        let sinceId = self.data[1].id
        let targetId = self.data[0].id
        var currentMinId: String? = nil
        var localData = [Data]()
        
        do
        {
            let hostUrl = self.getUrlForSearchHash(str, maxId: currentMinId, sinceId: sinceId,counterOfTweets: self.countOfTweets+1)
            let newData = self.requestPerform(hostUrl)
            if newData.count < 2
            {
                NSNotificationCenter.defaultCenter().postNotificationName("dataReady", object: nil)
                dispatch_semaphore_signal(self.semafor)
                return
            }
            currentMinId = newData[newData.endIndex-1].id
            localData += newData
            localData.removeLast()
            if self.data.count + localData.count - self.offset - self.uppset > self.maxDataArraySize
            {
                if self.data.count - self.uppset - self.countOfTweets >= 0
                {
                    self.delegate?.requestForCleanRangeFromMedia(self.data.count - self.uppset - self.countOfTweets..<self.data.count - self.uppset, forSearchString: self.searchText)
                    self.uppset+=self.countOfTweets
                }
                else
                {
                    self.delegate?.askForTotallyNewSearch()
                    dispatch_semaphore_signal(self.semafor)
                    return
                }
            }
        }
        while currentMinId != targetId
            
        self.delegate?.didRecieveTextDataForStartOfTable(localData, forSearchString: self.searchText)
        dispatch_semaphore_signal(self.semafor)
        self.downloadMedia()
        }
    }
    
    
// MARK: downloading bottom of table
    
    func performNext(str: String)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
        dispatch_semaphore_wait(self.semafor, DISPATCH_TIME_FOREVER)
        
        if self.searchEnded && str == self.searchText
        {
            NSNotificationCenter.defaultCenter().postNotificationName("dataReady", object: nil)
            dispatch_semaphore_signal(self.semafor)
            return
        }
        self.searchText = str
        self.searchEnded = false
        let hostUrl = self.getUrlForSearchHash(str, maxId: self.maxId, sinceId: nil,counterOfTweets: self.countOfTweets+1)
        var newData = self.requestPerform(hostUrl)
        if newData.count != self.countOfTweets+1
        {
            self.searchEnded = true
        }
        if newData.count == 0
        {
            NSNotificationCenter.defaultCenter().postNotificationName("dataReady", object: nil)
            dispatch_semaphore_signal(self.semafor)
            return
        }
        self.maxId = newData[newData.endIndex-1].id
        if !self.searchEnded
        {
            newData.removeLast()
        }
        if self.data.count + newData.count - self.offset - self.uppset > self.maxDataArraySize
        {
            self.delegate?.requestForCleanRangeFromMedia(self.offset..<self.offset+self.countOfTweets, forSearchString: self.searchText)
            self.offset+=self.countOfTweets
        }
        self.delegate?.didRecieveTextDataForEndOfTable(newData, forSearchString: self.searchText)
        dispatch_semaphore_signal(self.semafor)
        self.downloadMedia()
        }
    }

// MARK: Request NW and parse section
    func requestPerform(url: String) -> [Data]
    {
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.addValue(bearerToken, forHTTPHeaderField: "Authorization")
        request.HTTPMethod = "GET"
        var theError: NSErrorPointer = nil
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: theError)
        {
            if let result = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: theError) as? NSDictionary
            {
                if let statuses = result["statuses"] as? NSArray
                {
                    return self.parseTwitArrays(statuses)
                }
            }
            else
            {
                print(theError)
                print(" Some error in Network\n")
            }
        }
        else
        {
            print(theError)
            print(" Some error in Network\n")
        }
        return [Data]()
    }
    
    func parseTwitArrays(arr: NSArray)->[Data]
    {
        var localData = [Data]()
        var currTweet: Data?
        var parsedArr = [Tweet]()
        var idArr = [String]()
        
        for var i = 0; i < arr.count; i++
        {
            if let statusesD = arr[i] as? NSDictionary
            {
                if let id = statusesD["id_str"] as? String
                {
                    currTweet = Data(tweet: Tweet(), id: id)
                }
                if currTweet == nil
                {
                    break
                }
                if let text = statusesD["text"] as? String
                {
                    currTweet?.tweet.text = text
                }

                if let enteties = statusesD["entities"] as? NSDictionary
                {
                    if let media = enteties["media"] as? NSArray
                    {
                        var pictUrls = [String]()
                        for element in media
                        {
                            if let elemD = element as? NSDictionary
                            {
                                if let picture = elemD["media_url"] as? String
                                {
                                    pictUrls.append(picture)
                                }
                            }
                        }
                        if (pictUrls.count>0)
                        {
                            currTweet?.tweet.imageUrl = pictUrls
                            currTweet?.cellType = "imageCell1" //+ String(pictUrls.count)
                            mediaForBackgroundDownload.append(MediaForBackgroundDownload(id: currTweet!.id,status: "media", imgUrl: pictUrls))
                        }
                    }
                }
                if let user = statusesD["user"] as? NSDictionary
                {
                    if let name = user["name"] as? String
                    {
                        currTweet?.tweet.name = name
                    }
                    if let profImg = user["profile_image_url"] as? String
                    {
                        currTweet?.tweet.profileImgUrl = profImg
                        mediaForBackgroundDownload.append(MediaForBackgroundDownload(id: currTweet!.id,status: "avatar", imgUrl: [profImg]))
                    }
                }
            }
            localData.append(currTweet!)
            currTweet = nil
        }
        return localData
    }
    
    
// MARK: Cell initialization section
    
    
    func refillSpase(areWeRefillingStart start: Bool, row: Int)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
        dispatch_semaphore_wait(self.semafor, DISPATCH_TIME_FOREVER)
        if start
        {
            let r = (self.lastStoredTweetIndex - self.countOfTweets + 1)...self.lastStoredTweetIndex
            self.delegate?.requestForCleanRangeFromMedia(r, forSearchString: self.searchText)
    
            self.uppset += self.countOfTweets
            let oldOffset = self.offset
            self.offset = self.offset - self.countOfTweets
            if self.offset < 0
            {
                self.offset = 0
            }

            for var i = self.offset; i < oldOffset; i++
            {
                if let profImUrl = self.data[i].tweet.profileImgUrl
                {
                    self.mediaForBackgroundDownload.append(MediaForBackgroundDownload(id: self.data[i].id, status: "avatar", imgUrl: [profImUrl]))
                }
                if self.data[i].cellType != "defaultCell"
                {
                    self.mediaForBackgroundDownload.append(MediaForBackgroundDownload(id: self.data[i].id, status: "media", imgUrl: self.data[i].tweet.imageUrl!))
                }
            }
            dispatch_semaphore_signal(self.semafor)
            self.downloadMedia()
            return
        }
        else
        {
            let r = self.offset...(self.offset + self.countOfTweets - 1)
            self.delegate?.requestForCleanRangeFromMedia(r, forSearchString: self.searchText)
            self.offset += self.countOfTweets
            
            let oldLastStored = self.lastStoredTweetIndex
            self.uppset -= self.countOfTweets
            if self.uppset < 0
            {
                self.uppset = 0
            }
    
            for var i = oldLastStored + 1; i < self.data.count - self.uppset; i++
            {
                if let profImUrl = self.data[i].tweet.profileImgUrl
                {
                    self.mediaForBackgroundDownload.append(MediaForBackgroundDownload(id: self.data[i].id, status: "avatar", imgUrl: [profImUrl]))
                }
                if self.data[i].cellType != "defaultCell"
                {
                    self.mediaForBackgroundDownload.append(MediaForBackgroundDownload(id: self.data[i].id, status: "media", imgUrl: self.data[i].tweet.imageUrl!))
                }
            }
            dispatch_semaphore_signal(self.semafor)
            self.downloadMedia()
            return
            }
        }
    }
    
    func cleanCell(cell: TableViewCell)
    {
        cell.name = "...loadig..."
        cell.content = ""
        cell.imageArr = nil
        cell.profileImg = nil
    }
    
    func initThisCell(cell: TableViewCell, row: Int)
    {
        cleanCell(cell)
        initCellWithTweet(cell, tweet: data[row].tweet)
        if row >= offset && row < data.count - uppset
        {
            return
        }
    }
    
    func initCellWithTweet(cell: TableViewCell, tweet: Tweet)
    {
        cell.name = tweet.name
        cell.imageArr = tweet.image
        cell.content = tweet.text
        cell.profileImg = tweet.profileImg
    }
}