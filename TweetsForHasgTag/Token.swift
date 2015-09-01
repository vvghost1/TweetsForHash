//
//  Token.swift
//  TweetsForHasgTag
//
//  Created by Yura Vorontsov on 11.08.15.
//  Copyright (c) 2015 Yura Vorontsov. All rights reserved.
//

import Foundation

class Token
{
    var bearerToken: String!
    {
        didSet
        {
            if (bearerToken != nil)
            {
                NSNotificationCenter.defaultCenter().postNotificationName("tokenReady", object: nil)
            }
        }
    }

    let bearerTokenDefaultsKey = "bearerToken"
    let hostUrl = "https://api.twitter.com/oauth2/token"
    let headerStr = "application/x-www-form-urlencoded;charset=UTF-8"
    let bodyStr = "grant_type=client_credentials"
    
    let consumerKey = "u5aOPiL8xU7As8WGxI5vH916X"
    let consumerSecret = "FHPXgnaxCIRENLcvMLRPCNQuvrMrYV0JXdQGNT4C8MIeiJDKPo"
    
    func base64EncodeFormat(key: String, secret: String) -> String?
    {
        let consumerKeyRFC = consumerKey.stringByAddingPercentEscapesUsingEncoding(NSASCIIStringEncoding)!
        let consumerSecretRFC = consumerSecret.stringByAddingPercentEscapesUsingEncoding(NSASCIIStringEncoding)!
        let unionKey = consumerKeyRFC + ":" + consumerSecretRFC
        let utf8str = unionKey.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
        return utf8str?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
    
    init()
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let token = defaults.stringForKey(bearerTokenDefaultsKey)
        {
            bearerToken = token
            print("use saved token\n")
        }
        else
        {
            print("loading token...\n")
            getToken(base64EncodeFormat(consumerKey,secret: consumerSecret)!)
        }
    }
    
    func getToken(unionKey: String)
    {
        var request = NSMutableURLRequest(URL: NSURL(string: hostUrl)!)
        request.addValue("Basic " + unionKey, forHTTPHeaderField: "Authorization")
        request.addValue(headerStr, forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        request.HTTPBody = bodyStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            var theError: NSErrorPointer = nil
            if let result = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: theError) as? NSDictionary
            {
                if let bearer = result["access_token"] as? String
                {
                    print("Token downloaded\n")
                    let str = "Bearer " + bearer
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setObject(str, forKey: self.bearerTokenDefaultsKey)
                    defaults.synchronize()
                    self.bearerToken = str
                }
                else
                {
                    print(result["errors"])
                }
            }
            else
            {
                print(theError)
                print(error)
            }
        }).resume()
    }
}