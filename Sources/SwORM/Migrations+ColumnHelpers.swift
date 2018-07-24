//
//  Migrations+ColumnHelpers.swift
//  SwORM
//
//  Created by NobodyNada on 3/22/18.
//

import Foundation

public extension TableDef {
    
    
    public mutating func add(column name: String, type: Column.ColumnType, constraints: [Column.Constraint]) {
        add(column: Column(name: name, type: type, constraints: constraints))
    }
    public mutating func add<V: DatabaseType>(column: KeyPath<T, V>, type: Column.ColumnType, constraints: [Column.Constraint]) {
        var constraints = constraints
        
        //Add a non-null constraint unless one already exists
        if !constraints.contains(where: { if case .notNull = $0 { return true } else { return false } }) {
            constraints.append(.notNull)
        }
        
        //Add a primary key constraint if neccessary
        if T.primaryKey == column && !constraints.contains(where: { if case .primaryKey = $0 { return true } else { return false } }) {
            constraints.append(.primaryKey)
        }
        add(column: T.name(of: column)!, type: type, constraints: constraints)
    }
    public mutating func add<V: DatabaseType>(column: KeyPath<T, V?>, type: Column.ColumnType, constraints: [Column.Constraint]) {
        var constraints = constraints
        //Add a primary key constraint if neccessary
        if T.primaryKey == column && !constraints.contains(where: { if case .primaryKey = $0 { return true } else { return false } }) {
            constraints.append(.primaryKey)
            //Add a non-null constraint unless one already exists
            if !constraints.contains(where: { if case .notNull = $0 { return true } else { return false } }) {
                constraints.append(.notNull)
            }
        }
        add(column: T.name(of: column)!, type: type, constraints: constraints)
    }
    
    public mutating func add(column: String, type: Column.ColumnType, constraints: Column.Constraint...) {
        add(column: column, type: type, constraints: constraints)
    }
    public mutating func add<V: DatabaseType>(column: KeyPath<T, V>, type: Column.ColumnType, constraints: Column.Constraint...) {
        add(column: column, type: type, constraints: constraints)
    }
    public mutating func add<V: DatabaseType>(column: KeyPath<T, V?>, type: Column.ColumnType, constraints: Column.Constraint...) {
        add(column: column, type: type, constraints: constraints)
    }
    
    
    public mutating func int(_ name: String, _ constraints: [Column.Constraint]) {
        add(column: name, type: .integer, constraints: constraints)
    }
    public mutating func int<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .integer, constraints: constraints)
    }
    public mutating func int<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .integer, constraints: constraints)
    }
    
    public mutating func int(_ name: String, _ constraints: Column.Constraint...) {
        add(column: name, type: .integer, constraints: constraints)
    }
    public mutating func int<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) {
        add(column: column, type: .integer, constraints: constraints)
    }
    public mutating func int<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) {
        add(column: column, type: .integer, constraints: constraints)
    }
    
    
    public mutating func bool(_ name: String, _ constraints: [Column.Constraint]) {
        add(column: name, type: .integer, constraints: constraints)
    }
    public mutating func bool<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .integer, constraints: constraints)
    }
    public mutating func bool<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .integer, constraints: constraints)
    }
    
    public mutating func bool(_ name: String, _ constraints: Column.Constraint...) {
        add(column: name, type: .integer, constraints: constraints)
    }
    public mutating func bool<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) {
        add(column: column, type: .integer, constraints: constraints)
    }
    public mutating func bool<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) {
        add(column: column, type: .integer, constraints: constraints)
    }
    
    
    public mutating func numeric(_ name: String, _ constraints: [Column.Constraint]) {
        add(column: name, type: .numeric, constraints: constraints)
    }
    public mutating func real(_ name: String, _ constraints: [Column.Constraint]) { numeric(name, constraints) }
    public mutating func float(_ name: String, _ constraints: [Column.Constraint]) { numeric(name, constraints) }
    public mutating func double(_ name: String, _ constraints: [Column.Constraint]) { numeric(name, constraints) }
    
    
    public mutating func numeric<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .numeric, constraints: constraints)
    }
    public mutating func real<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) { numeric(column, constraints) }
    public mutating func float<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) { numeric(column, constraints) }
    public mutating func double<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) { numeric(column, constraints) }
    
    
    public mutating func numeric<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .numeric, constraints: constraints)
    }
    public mutating func real<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) { numeric(column, constraints) }
    public mutating func float<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) { numeric(column, constraints) }
    public mutating func double<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) { numeric(column, constraints) }
    
    
    public mutating func numeric(_ name: String, _ constraints: Column.Constraint...) {
        add(column: name, type: .numeric, constraints: constraints)
    }
    public mutating func real(_ name: String, _ constraints: Column.Constraint...) { numeric(name, constraints) }
    public mutating func float(_ name: String, _ constraints: Column.Constraint...) { numeric(name, constraints) }
    public mutating func double(_ name: String, _ constraints: Column.Constraint...) { numeric(name, constraints) }
    
    
    public mutating func numeric<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) {
        add(column: column, type: .numeric, constraints: constraints)
    }
    public mutating func real<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) { numeric(column, constraints) }
    public mutating func float<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) { numeric(column, constraints) }
    public mutating func double<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) { numeric(column, constraints) }
    
    
    public mutating func numeric<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) {
        add(column: column, type: .numeric, constraints: constraints)
    }
    public mutating func real<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) { numeric(column, constraints) }
    public mutating func float<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) { numeric(column, constraints) }
    public mutating func double<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) { numeric(column, constraints) }
    
    
    
    public mutating func string(_ name: String, maxLength: Int? = nil, _ constraints: [Column.Constraint]) {
        if let length = maxLength { add(column: name, type: .varchar(length), constraints: constraints) }
        else { add(column: name, type: .text, constraints: constraints) }
    }
    public mutating func text(_ name: String, _ constraints: [Column.Constraint]) { string(name, constraints) }
    public mutating func varchar(_ name: String, maxLength: Int, _ constraints: [Column.Constraint]) { string(name, maxLength: maxLength, constraints) }
    
    
    public mutating func string<V: DatabaseType>(_ column: KeyPath<T, V>, maxLength: Int? = nil, _ constraints: [Column.Constraint]) {
        if let length = maxLength { add(column: column, type: .varchar(length), constraints: constraints) }
        else { add(column: column, type: .text, constraints: constraints) }
    }
    public mutating func text<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) { string(column, constraints) }
    public mutating func varchar<V: DatabaseType>(_ column: KeyPath<T, V>, maxLength: Int, _ constraints: [Column.Constraint]) { string(column, maxLength: maxLength, constraints) }
    
    
    public mutating func string<V: DatabaseType>(_ column: KeyPath<T, V?>, maxLength: Int? = nil, _ constraints: [Column.Constraint]) {
        if let length = maxLength { add(column: column, type: .varchar(length), constraints: constraints) }
        else { add(column: column, type: .text, constraints: constraints) }
    }
    public mutating func text<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) { string(column, constraints) }
    public mutating func varchar<V: DatabaseType>(_ column: KeyPath<T, V?>, maxLength: Int, _ constraints: [Column.Constraint]) { string(column, maxLength: maxLength, constraints) }
    
    
    public mutating func string(_ name: String, maxLength: Int? = nil, _ constraints: Column.Constraint...) {
        if let length = maxLength { add(column: name, type: .varchar(length), constraints: constraints) }
        else { add(column: name, type: .text, constraints: constraints) }
    }
    public mutating func text(_ name: String, _ constraints: Column.Constraint...) { string(name, constraints) }
    public mutating func varchar(_ name: String, maxLength: Int, _ constraints: Column.Constraint...) { string(name, maxLength: maxLength, constraints) }
    
    
    public mutating func string<V: DatabaseType>(_ column: KeyPath<T, V>, maxLength: Int? = nil, _ constraints: Column.Constraint...) {
        if let length = maxLength { add(column: column, type: .varchar(length), constraints: constraints) }
        else { add(column: column, type: .text, constraints: constraints) }
    }
    public mutating func text<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) { string(column, constraints) }
    public mutating func varchar<V: DatabaseType>(_ column: KeyPath<T, V>, maxLength: Int, _ constraints: Column.Constraint...) { string(column, maxLength: maxLength, constraints) }
    
    
    public mutating func string<V: DatabaseType>(_ column: KeyPath<T, V?>, maxLength: Int? = nil, _ constraints: Column.Constraint...) {
        if let length = maxLength { add(column: column, type: .varchar(length), constraints: constraints) }
        else { add(column: column, type: .text, constraints: constraints) }
    }
    public mutating func text<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) { string(column, constraints) }
    public mutating func varchar<V: DatabaseType>(_ column: KeyPath<T, V?>, maxLength: Int, _ constraints: Column.Constraint...) { string(column, maxLength: maxLength, constraints) }
    
    
    
    public mutating func data(_ name: String, _ constraints: [Column.Constraint]) {
        add(column: name, type: .blob, constraints: constraints)
    }
    public mutating func blob(_ name: String, _ constraints: [Column.Constraint]) { data(name, constraints) }
    
    
    public mutating func data<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .blob, constraints: constraints)
    }
    public mutating func blob<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) { data(column, constraints) }
    
    
    public mutating func data<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .blob, constraints: constraints)
    }
    public mutating func blob<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) { data(column, constraints) }
    
    
    public mutating func data(_ name: String, _ constraints: Column.Constraint...) {
        add(column: name, type: .blob, constraints: constraints)
    }
    public mutating func blob(_ name: String, _ constraints: Column.Constraint...) { numeric(name, constraints) }
    
    
    public mutating func data<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) {
        add(column: column, type: .blob, constraints: constraints)
    }
    public mutating func blob<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) { data(column, constraints) }
    
    
    public mutating func data<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) {
        add(column: column, type: .blob, constraints: constraints)
    }
    public mutating func blob<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) { data(column, constraints) }
    
    
    public mutating func date(_ name: String, _ constraints: [Column.Constraint]) {
        add(column: name, type: .datetime, constraints: constraints)
    }
    public mutating func date<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .datetime, constraints: constraints)
    }
    public mutating func date<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: [Column.Constraint]) {
        add(column: column, type: .datetime, constraints: constraints)
    }
    
    public mutating func date(_ name: String, _ constraints: Column.Constraint...) {
        add(column: name, type: .datetime, constraints: constraints)
    }
    public mutating func date<V: DatabaseType>(_ column: KeyPath<T, V>, _ constraints: Column.Constraint...) {
        add(column: column, type: .datetime, constraints: constraints)
    }
    public mutating func date<V: DatabaseType>(_ column: KeyPath<T, V?>, _ constraints: Column.Constraint...) {
        add(column: column, type: .datetime, constraints: constraints)
    }
    
    
    public mutating func foreignKey<O: DatabaseObject>(_ key: KeyPath<T, ForeignKey<O>>, _ constraints: [Column.Constraint]) {
        add(column: key, type: .integer, constraints: constraints + [.foreignKey(key)])
    }
    
    public mutating func foreignKey<O: DatabaseObject>(_ key: KeyPath<T, ForeignKey<O>?>, _ constraints: [Column.Constraint]) {
        add(column: key, type: .integer, constraints: constraints + [.foreignKey(key)])
    }
    
    
    public mutating func foreignKey<O: DatabaseObject>(_ key: KeyPath<T, ForeignKey<O>>, _ constraints: Column.Constraint...) {
        foreignKey(key, constraints)
    }
    
    public mutating func foreignKey<O: DatabaseObject>(_ key: KeyPath<T, ForeignKey<O>?>, _ constraints: Column.Constraint...) {
        foreignKey(key, constraints)
    }
}
