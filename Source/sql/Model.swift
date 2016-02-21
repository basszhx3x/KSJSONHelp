import Foundation
/**
	Base model for all Fluent entities.
 
	Override the `table()`, `serialize()`, and `init(serialized:)`
	methods on your subclass.
 */
 /** Implement this protocol to use primary keys */
public protocol PrimaryKeys {
    /**
     Method used to define a set of primary keys for the types table
     
     - returns:  set of property names
     */
    static func primaryKeys() -> Set<String>
}

/** Implement this protocol to ignore arbitrary properties */
public protocol IgnoredProperties {
    /**
     Method used to define a set of ignored properties
     
     - returns:  set of property names
     */
    static func ignoredProperties() -> Set<String>
}
///支持对象保存到数据库，转为字典
public protocol Model: Serialization {
    
    ///The database table in which entities are stored.
    static var table: String { get }
    /**
     This method will be called when the entity is saved.
     The keys of the dictionary are the column names
     in the database.
     */
    var serialize: [String: Binding?] { get }
}
extension Model {
    public static var table: String {
        return String(self)
    }
    public func save() {
        Query().save(self)
    }
    
    public func delete() {
        Query().delete(self)
    }
    
    //	public static func find(id: Int) -> Self? {
    //		return Query().find(id)
    //	}
    internal var serialize: [String: Binding?] {
        var data: [String: Binding?] = [:]
        PropertyData.validPropertyDataForObject(self).forEach { (var propertyData) -> () in
            data[propertyData.name!] = propertyData.bindingValue
        }
        return data
    }
    
    public var dictionary: [String: AnyObject] {
        var data: [String: AnyObject] = [:]
        PropertyData.validPropertyDataForObject(self).forEach { propertyData -> () in
            let value = propertyData.value
            if !(value is NSNull || "\(value)" == "nil"){
                if value is Serialization {
                    data[propertyData.name!] = (value as! Serialization).serialization
                }else if let anyObject = value as? AnyObject {
                    data[propertyData.name!] = anyObject
                }
            }
        }
        return data
    }
    
    public static func setObjectArray(objectArray: [Model], forKey defaultName: String) {
        
        NSUserDefaults.standardUserDefaults().setValue(objectArray.map{$0.dictionary}, forKey: defaultName)
        
    }
    public var serialization: AnyObject {
        return self.dictionary
    }
}
///从数据库的表取出对象。从字典转为对象
public protocol Storable {
    /** Used to initialize an object to get information about its properties */
    init()
    func setValue(value: AnyObject?, forKey key: String)
}
extension Storable {
    public typealias ValueType1 = Self
    
    public func setValuesForKeysWithDictionary(keyedValues: [String : AnyObject]) {
        keyedValues.forEach { (key, value) -> () in
            self.setValue(value, forKey: key)
        }
    }
    
    internal init(serialized: [String: Binding?]) {
        self.init()
        let propertyDatas = PropertyData.validPropertyDataForObject(self)
        for propertyData in propertyDatas {
            if let name = propertyData.name, let type = propertyData.bindingType, let optionalValue = serialized[name], let binding = optionalValue {
                setValue(type.toAnyObject(binding), forKey: name)
            }
        }
    }
    public static func fromDictionary(dic: [String: AnyObject]) -> Self {
        let model = self.init()
        PropertyData.validPropertyDataForObject(model).forEach{ (propertyData) -> () in
            if let name = propertyData.name, var value = dic[name] {
                if !(value is NSNull || "\(value)" == "nil"){
                    if value is Deserialization {
                        value = (value as! Deserialization).deserialization(propertyData.type)
                    }
                    model.setValue(value, forKey: name)
                    
                }
            }
        }
        return model
    }
    
    public static func objectArrayForKey(defaultName: String) -> [ValueType1]? {
        if let objectArray = NSUserDefaults.standardUserDefaults().arrayForKey(defaultName) {
            return objectArray.map {
                fromDictionary($0 as! [String : AnyObject])
            }
        }else{
            return nil
        }
    }
    
}
extension Storable where Self: Model {
    public typealias ValueType = Self
    
    public static func fetchOne(filter: Filter?) -> ValueType? {
        if let serialized = Database.driver.fetchOne(table: self.table, filter: filter) {
            return self.init(serialized: serialized)
        } else {
            return nil
        }
    }
    
    public static func fetch(filter: Filter?) -> [ValueType]? {
        if let serializeds = Database.driver.fetch(table: self.table, filter: filter) {
            return serializeds.map({ (serialized) -> ValueType in
                self.init(serialized: serialized)
            })
        } else {
            return nil
        }
    }
}
