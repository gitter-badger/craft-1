//
//  Craft.swift
//  craft
//
//  Created by Tommy Leung on 6/28/14.
//  Copyright (c) 2014 Tommy Leung. All rights reserved.
//

import Foundation

typealias Action = (resolve: (value: AnyObject?) -> (), reject: (value: AnyObject)? -> ()) -> ()

class Craft
{
    class func promise() -> Promise
    {
        return promise(nil)
    }
    
    class func promise(action: Action?) -> Promise
    {
        let d = Deferred.create()
        
        let q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(q, {
            
            dispatch_sync(dispatch_get_main_queue(), {
                if let a = action
                {
                    a(resolve: d.resolve, reject: d.reject)
                }
            })
        })
        
        return d.promise;
    }
    
    class func all(promises: Array<Promise>) -> Promise
    {
        let d = Deferred.create()
        
        var results: Array<AnyObject?> = Array()
        let count = promises.count
        var fulfilled = 0
        
        func attach(promise: Promise, index: Int) -> ()
        {
            promise.then({
                (value: AnyObject?) -> AnyObject? in
                
                results[index] = value
                ++fulfilled
                
                if (fulfilled >= count)
                {
                    //seems to be issues passing an Array<AnyObject?> as AnyObject?
                    //that's why this is wrapped in a BulkResult
                    d.resolve(BulkResult(data: results))
                }
                
                return nil
            }, reject: {
                (value: AnyObject?) -> AnyObject? in
                
                d.reject(value)
                
                return nil
            })
        }
        
        for var i = 0; i < count; ++i
        {
            results.append(nil)
            let promise = promises[i]
            
            attach(promise, i)
        }
        
        return d.promise
    }
}