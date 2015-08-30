//
//  NSObject+KeyValues.swift
//  CFRuntime
//
//  Created by 成林 on 15/7/10.
//  Copyright (c) 2015年 冯成林. All rights reserved.
//

import Foundation

extension NSObject {
    /**  一键字典转模型  */
    public class func toModel(dict: NSDictionary) -> Self{
        let model = self.init()
        let mirror = KSMirror(model)
        model.toModel(mirror,dict: dict)
        return model
    }
    private func toModel(mirror: KSMirror,dict: NSDictionary){
        let mappingDict = self.mappingDict()
        for item in mirror {
            if item.name == "super" {
                if let superMirror = item.superMirror {
                    self.toModel(superMirror, dict: dict)
                }
                continue
            }
            var key = item.name
            key = mappingDict?[key] ?? key
            if let value = dict[key] {
                if value is NSArray {
                    let genericType = NSObject.genericType(item)
                    let arrM = NSMutableArray()
                    for  genericValue in value as! NSArray {
                        arrM.addObject(NSObject.transformValue(genericType, value: genericValue))
                    }
                    self.setValue(arrM, forKeyPath: key)
                }else{
                    self.setValue(NSObject.transformValue(item.type, value: value), forKeyPath: key)
                }
            }
        }
    }
    
    
    public class func toModels(array: NSArray) -> [NSObject]{
        var models: [NSObject] = []
        
        for value in array {
            models.append(self.toModel(value as! NSDictionary))
        }
        return models
    }
    
    /**  一键模型转字典  */
    public func toDictionary() -> NSDictionary{
        return toDictionary(KSMirror(self))
    }
    private func toDictionary(mirror: KSMirror) -> NSDictionary{
        
        let dict = NSMutableDictionary()
        for item in mirror {
            if item.name == "super" {
                if let superMirror = item.superMirror {
                    dict.addEntriesFromDictionary(toDictionary(superMirror) as [NSObject : AnyObject])
                }
                continue
            }
            var value = item.value
            if item.isOptional {
                //狂吐槽apple的Optional。用item.value不行，要用valueForKeyPath这个方法才行
                //                let a = (item.value as! Any?) as? AnyObject?
                let valueOptional = self.valueForKeyPath(item.name)
                if valueOptional == nil {
                    continue
                }else{
                    value = valueOptional!
                }
            }
            dict[item.name] = NSObject.transformValue(value)
        }
        return dict
    }
    
    /**  字段映射  */
    public func mappingDict() -> [String: String]? {
        return nil
    }
    /**  数组Element类型截取：截取字符串并返回一个类型  */
    public class func genericType(item: KSMirrorItem) -> Any.Type {
        let clsString = "\(item.type)".replacingOccurrencesOfString("Array<", withString: "").replacingOccurrencesOfString("Optional<", withString: "").replacingOccurrencesOfString(">", withString: "")
        return NSClassFromString(clsString)!
    }
   
    
    private class func transformValue(type: Any.Type,value: Any) -> AnyObject{
        if type is Int.Type || type is Optional<Int>.Type {
            if value is String {
                return Int(value as! String)!
            }
            return value as! Int
        }else if type is Float.Type || type is Optional<Float>.Type {
            if value is String {
                return Float(value as! String)!
            }
            return value as! Float
        }else if type is Double.Type || type is Optional<Double>.Type {
            if value is String {
                return Double(value as! String)!
            }
            return value as! Double
        }else if type is String.Type || type is Optional<String>.Type || type is NSString.Type || type is Optional<NSString>.Type  {
            return value as! String
        }else if value is NSDictionary {
            return (type as! NSObject.Type).toModel(value as! NSDictionary)
        }
        return value as! AnyObject
    }
    private class func transformValue(value: Any) -> AnyObject {
        if value is NSArray {
            var dictM: [AnyObject] = []
            let valueArray = value as! NSArray
            for item in valueArray {
                dictM.append(NSObject.transformValue(item))
            }
            return dictM
        }else if value is NSNumber {
            return value as! NSNumber
        }else if value is NSString {
            return value as! NSString
        }else if value is NSObject {
            return (value as! NSObject).toDictionary()
        }else if value is Int8 {
            return NSNumber(char: value as! Int8)
        }else if value is UInt8 {
            return NSNumber(unsignedChar: value as! UInt8)
        }else if value is Int16 {
            return NSNumber(short: value as! Int16)
        }else if value is UInt16 {
            return NSNumber(unsignedShort: value as! UInt16)
        }else if value is Int32 {
            return NSNumber(int: value as! Int32)
        }else if value is UInt32 {
            return NSNumber(unsignedInt: value as! UInt32)
        }else if value is Int64 {
            return NSNumber(longLong: value as! Int64)
        }else if value is UInt64 {
            return NSNumber(unsignedLongLong: value as! UInt64)
        }
        return value as! AnyObject
    }
}
