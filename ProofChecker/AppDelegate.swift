//
//  AppDelegate.swift
//  ProofChecker
//
//  Created by 龚杰洪 on 16/4/26.
//  Copyright © 2016年 龚杰洪. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    @IBOutlet weak var testCheckBox: NSButton!
    @IBOutlet weak var productCheckBox: NSButton!
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet var proofTextView: NSTextView!
    
    var storeURL = "https://sandbox.itunes.apple.com/verifyReceipt"
    
    let shareSecret = "ba249dbf458348b5a41d81153754e90b"

    var kvoContext = 10000
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        addObserver(self, forKeyPath: "window.visible", options: NSKeyValueObservingOptions.New, context: &kvoContext)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    
    @IBAction func checkBoxDicChecked(sender: NSButton) {
        if (sender == productCheckBox) {
            storeURL = "https://buy.itunes.apple.com/verifyReceipt"
        }
        else {
            storeURL = "https://sandbox.itunes.apple.com/verifyReceipt"
        }
    }

    @IBAction func startCheck(sender: NSButton) {
        if (proofTextView.string != nil && proofTextView.string?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 10) {
            
        }
        else {
            let alert = NSAlert()
            alert.messageText = "Please enter a valid proof"
            alert.beginSheetModalForWindow(self.window, completionHandler: { (response) in
                
            })
            return
        }
        
        MBProgressHUD.showHUDAddedTo(self.window.contentView, animated: true)
        
        let proofString = proofTextView.string
        var proofDic : [String: AnyObject]
        do {
            proofDic = try NSJSONSerialization.JSONObjectWithData((proofString?.dataUsingEncoding(NSUTF8StringEncoding))!, options: NSJSONReadingOptions.AllowFragments) as! [String : AnyObject]
            let proof = proofDic["proof_of_purchase"] as! String
            self.checkWithParams(proof)
        }
        catch let error as NSError {
            print("\(error)")
            let proof = proofString?.stringByReplacingOccurrencesOfString("\\/", withString: "/")
            self.checkWithParams(proof!)
        }
        catch {
            MBProgressHUD.hideHUDForView(self.window.contentView, animated: true)
        }
    
    }
    
    func checkWithParams(proof: String) {
        let appleRequestParam = ["password": shareSecret, "receipt-data": proof]
        
        
        do {
            let requestData = try NSJSONSerialization.dataWithJSONObject(appleRequestParam,
                                                                         options: NSJSONWritingOptions.PrettyPrinted)
            
            let storeRequest = NSMutableURLRequest(URL: NSURL(string: storeURL)!)
            storeRequest.HTTPMethod = "POST"
            storeRequest.HTTPBody = requestData
            
            let queue = NSOperationQueue()
            

            NSURLConnection.sendAsynchronousRequest(storeRequest, queue: queue, completionHandler: { (response, data, error) in
                
                MBProgressHUD.hideHUDForView(self.window.contentView, animated: true)
                if (error != nil) {
                    let alert = NSAlert()
                    alert.messageText = "Request error"
                    alert.beginSheetModalForWindow(self.window, completionHandler: { (response) in
                        
                    })
                    return
                }
                do {
                    let jsonDic = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                    guard let statCode = jsonDic.objectForKey("status") as? NSNumber else {
                        return
                    }
                    print("\(jsonDic)")
                    
                    if (statCode == 0) {
                        var payedGoods = "Purchased goods:\n\n"
                        
                        let tempArray = jsonDic.objectForKey("receipt")?.objectForKey("in_app") as? [AnyObject]
                        
                        if (tempArray?.count > 0) {
                            for object in tempArray! {
                                payedGoods = payedGoods + "product_id = \(object.objectForKey("product_id")!) \n"
                                payedGoods = payedGoods + "purchase_date = \(object.objectForKey("purchase_date")!) \n\n"
                            }
                        }
                        
                        let alert = NSAlert()
                        alert.messageText = "Valid proof"
                        alert.informativeText = payedGoods
                        alert.beginSheetModalForWindow(self.window, completionHandler: { (response) in
                            
                        })
                    }
                    else {
                        let alert = NSAlert()
                        alert.messageText = "Error Code \(statCode)"
                        alert.beginSheetModalForWindow(self.window, completionHandler: { (response) in
                            
                        })
                    }
                }
                catch {
                    let alert = NSAlert()
                    alert.messageText = "Exception"
                    alert.beginSheetModalForWindow(self.window, completionHandler: { (response) in
                        
                    })
                    return
                }
                
            })
        }
        catch let error as NSError {
            print(error)
            MBProgressHUD.hideHUDForView(self.window.contentView, animated: true)
        }
        catch {
            MBProgressHUD.hideHUDForView(self.window.contentView, animated: true)
        }

    }
    
    func performClose(sender: AnyObject) {
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if  context == &kvoContext {
            if (self.window.visible == false) {
                exit(0)
            }
            else {
                
            }
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}

