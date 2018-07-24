# SwORM

[SQLite Adapter](https://github.com/NobodyNada/SQLiteSwORM) | [MySQL Adapter](https://github.com/NobodyNada/MySQLSwORM)

SwORM is an experimental object-relational mapper written in Swift.  It is type-safe at compile-type using key paths, operator overloading, and lots of generics abuse. 

To create a model, create a struct or class which conforms to the `DatabaseObject` protocol.  Here's an example implementation:

    struct TestObject: DatabaseObject, Equatable {
        // Required by DatabaseObject; the name of the database table backing this model.
        static let tableName: String = "test_object"

        var id: Int64?
        var bool: Bool
        var double: Double
        var int: Int
        var string: String
        var data: Data
        var otherObject: ForeignKey<OtherObject>
        
        // Required by DatabaseObject; the property which contains the model's primary key
        static let primaryKey: KeyPath<TestObject, Int64?> = \.id
        
        // Required by DatabaseObject; an array containing the key path and coding key of each of this model's columns.
        static let allColumns: [(PartialKeyPath<TestObject>, CodingKey)]
            (\TestObject.id, CodingKeys.id),
            (\TestObject.bool, CodingKeys.bool),
            (\TestObject.double, CodingKeys.double),
            (\TestObject.int, CodingKeys.int),
            (\TestObject.string, CodingKeys.string),
            (\TestObject.data, CodingKeys.data),
            (\TestObject.optionalString, CodingKeys.optionalString)
            (\TestObject.otherObject, CodingKeys.otherObject)
        ]
    }

Create the table using a migration:

    try migrator.migrate(to: 1) { connection in
        connection.create(table: TestObject.self) { t in
            t.int(\.id)
            t.bool(\.bool)
            t.double(\.double)
            t.int(\.int)
            t.string(\.string, .unique) // columns can have constraints!
            t.data(\.data)
            t.string(\.optionalString, .check(\.optionalString == (nil as String?) || \.int > 5))
            t.foreignKey(\.otherObject)
        }
    }

Insert a row by creating it and calling the `save` function:

    let object = TestObject(...)
    object.save(connection) // returns Future<Int64> (the inserted row ID)

Select rows matching an expression:

    TestObject.select(where: \.int < 100 || \.bool).all(connection) // returns Future<[TestObject]>
    
You can even use joins:

    let results = TestObject.join(\.otherObject).select().first(connection)
    //results is a Future<JoinResult<TestObject, OtherObject>>
    
    results.then {
        print($0.first)  //TestObject
        print($0.second) //OtherObject
    }
    
You can update a database object by re-saving an object returned by a select:

    let object = TestObject.find(1, connection: connection) //find looks up an object by primary key
    //object is a Future<TestObject?>
    
    object.then {
        guard let o = $0 else { return }
        o.string = "Hello, world!"
        return o.save(connection)
    }
    
You can run more general update queries:

    TestObject.update(\.optionalString, to: "Hello, world!", where: \.optionalString == (nil as String?), connection: connection)   // returns Future<Void>

Deletions work in a similar way:
    
    let object = TestObject.find(1, connection: connection)
    object.then {
        $0?.destroy(connection)
    }
    
    TestObject.delete(where: \.int < 5)
