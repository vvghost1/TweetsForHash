//
//  ViewController.swift
//  TweetsForHasgTag
//
//  Created by Yura Vorontsov on 11.08.15.
//  Copyright (c) 2015 Yura Vorontsov. All rights reserved.
//

import UIKit

//СПРОСИТЬ ПРО ПОДДЕРЖКУ АЙПАДА


class ViewController: UIViewController {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    var z: Token! = Token()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let mvc = segue.destinationViewController as? MainViewController
        {
            mvc.bearerToken = z.bearerToken
            z = nil
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if(z.bearerToken != nil)
        {
            zTdone()
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "zTdone", name: "tokenReady", object: nil)
    }
    
    
    func zTdone()
    {
        performSegueWithIdentifier("loadIsFinished", sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

