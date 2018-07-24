//
//  main.swift
//  OperatorGenerator
//
//  Created by NobodyNada on 10/12/17.
//  Copyright © 2017 NobodyNada. All rights reserved.
//
//  A quick & dirty program to generate operator declarations.

import Foundation

struct Operator {
    var swiftOperator: String
    var sqlOperator: String
    var resultType: String
    var expressionResultRequirement: String?
    
    init(
        swiftOperator: String,
        sqlOperator: String? = nil,
        resultType: String,
        expressionResultRequirement: String? = "L.ExpressionResult: DatabaseType"
        ) {
        
        self.swiftOperator = swiftOperator
        self.sqlOperator = sqlOperator ?? swiftOperator
        self.resultType = resultType
        
    }
}

let numeric = "L.ExpressionResult: DatabaseType & Numeric"
let boolean = "L.ExpressionResult == Bool"
let binaryOperators: [Operator] = [
    .init(swiftOperator: "==", sqlOperator: "=", resultType: "Bool"),
    .init(swiftOperator: "!=", sqlOperator: "<>", resultType: "Bool"),
    .init(swiftOperator: "<", resultType: "Bool", expressionResultRequirement: numeric),
    .init(swiftOperator: ">", resultType: "Bool", expressionResultRequirement: numeric),
    .init(swiftOperator: "<=", resultType: "Bool", expressionResultRequirement: numeric),
    .init(swiftOperator: ">=", resultType: "Bool", expressionResultRequirement: numeric),
    .init(swiftOperator: "||", sqlOperator: "OR", resultType: "Bool", expressionResultRequirement: boolean),
    .init(swiftOperator: "&&", sqlOperator: "AND", resultType: "Bool", expressionResultRequirement: boolean),
    
    .init(swiftOperator: "+", resultType: "%lValue%", expressionResultRequirement: numeric),
    .init(swiftOperator: "-", resultType: "%lValue%", expressionResultRequirement: numeric),
    .init(swiftOperator: "*", resultType: "%lValue%", expressionResultRequirement: numeric),
    .init(swiftOperator: "/", resultType: "%lValue%", expressionResultRequirement: numeric),
]

let prefixOperators: [Operator] = [
    .init(swiftOperator: "!", sqlOperator: "NOT", resultType: "Never", expressionResultRequirement: "T.ExpressionResult == Bool"),
    .init(swiftOperator: "-", resultType: "Never", expressionResultRequirement: "T.ExpressionResult: DatabaseType & Numeric"),
    .init(swiftOperator: "+", resultType: "Never", expressionResultRequirement: "T.ExpressionResult: DatabaseType & Numeric"),
]

enum ExpressionType {
    case typed
    case untyped
    case keyPath
    
    var name: String {
        switch self {
        case .typed: return "TypedExpressionConvertible"
        case .untyped: return "UntypedExpressionConvertible"
        case .keyPath: return "KeyPath"
        }
    }
}

print("//MARK: - Binary operators")
for op in binaryOperators {
    for lType in [ExpressionType.typed, .untyped, .keyPath] {
        for rType in [ExpressionType.typed, .untyped, .keyPath] {
            let template = """
            public func %swiftOperator% <%genericParams%>(lhs: %lParamType%, rhs: %rParamType%) -> %resultAndWhereClause% {
                return .binaryOperator(lhs.as%lTyped%Expression, "%sqlOperator%", rhs.as%rTyped%Expression)
            }
            
            """
            var resultAndWhereClause: String
            
            if lType != .untyped || rType != .untyped {
                resultAndWhereClause = "TypedExpression<%result%, %\(lType != .untyped ? "lObject" : "rObject")%>"
                
            } else { resultAndWhereClause = "UntypedExpression<%result%>" }
            
            if lType != .keyPath || rType != .keyPath { resultAndWhereClause += "\nwhere %lValue% == %rValue%" }
            if let requirement = op.expressionResultRequirement { resultAndWhereClause += ", " + requirement }
            if lType != .untyped && rType != .untyped && (lType != .keyPath || rType != .keyPath) { resultAndWhereClause += ", %lObject% == %rObject%" }
            
            let lTypeName: String
            let rTypeName: String
            
            if lType != .untyped || rType != .untyped {
                lTypeName = (lType == .untyped ? "ParameterExpressionConvertible" : lType.name)
                rTypeName = (rType == .untyped ? "ParameterExpressionConvertible" : rType.name)
            } else {
                lTypeName = lType.name
                rTypeName = rType.name
            }
            
            let parameters = [
                ("resultAndWhereClause", resultAndWhereClause),
                ("swiftOperator", op.swiftOperator),
                ("sqlOperator", op.sqlOperator),
                ("genericParams", lType == .keyPath && rType == .keyPath ? "R: DatabaseObject, V: DatabaseType" : "%lGenericParams%, %rGenericParams%"),
                ("lGenericParams", lType == .keyPath ? "LR: DatabaseObject, LV" : "L: %lType%"),
                ("rGenericParams", rType == .keyPath ? "RR: DatabaseObject, RV" : "R: %rType%"),
                ("lParamType", lType == .keyPath ? (rType == .keyPath ? "KeyPath<R, V>" : "KeyPath<LR, LV>") : "L"),
                ("rParamType", rType == .keyPath ? (lType == .keyPath ? "KeyPath<R, V>" : "KeyPath<RR, RV>") : "R"),
                ("lType", lTypeName),
                ("rType", rTypeName),
                ("lTyped", lType == .untyped ? "Untyped" : "Typed"),
                ("rTyped", rType == .untyped ? "Untyped" : "Typed"),
                ("result", op.resultType),
                ("lValue", (lType == .keyPath ? (rType == .keyPath ? "V" : "LV") : "L.ExpressionResult")),
                ("rValue", (rType == .keyPath ? (lType == .keyPath ? "V" : "RV") : "R.ExpressionResult")),
                ("lObject", (lType == .keyPath ? (rType == .keyPath ? "R" : "LR") : "L.ExpressionObject")),
                ("rObject", (rType == .keyPath ? (lType == .keyPath ? "R" : "RR") : "R.ExpressionObject")),
            ]
            print(parameters.reduce(template) {
                $0.replacingOccurrences(of: "%\($1.0)%", with: $1.1)
            })
        }
    }
    
    let template = """
            public func %swiftOperator% <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
                lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
                ) -> UntypedExpression<%resultType%> {
                    return .binaryOperator(lhs.asUntypedExpression, "%sqlOperator%", rhs.asUntypedExpression)
            }

            """
    let parameters = [
        ("swiftOperator", op.swiftOperator),
        ("resultType", op.resultType),
        ("lValue", "V"),
        ("sqlOperator", op.sqlOperator),
    ]
    print(parameters.reduce(template) {
        $0.replacingOccurrences(of: "%\($1.0)%", with: $1.1)
    })
}

print()
print("//MARK: - Prefix operators")


for op in prefixOperators {
    for type in [ExpressionType.typed, .untyped, .keyPath] {
        let template = """
        public prefix func %swiftOperator% <%genericParameters%>(expr: %paramType%) -> %resultAndWhereClause% {
            return .prefixOperator("%sqlOperator%", expr.as%typed%Expression)
        }

        """
        
        var resultAndWhereClause: String
        if type == .untyped { resultAndWhereClause = "UntypedExpression<T.ExpressionResult>" }
        else { resultAndWhereClause = "TypedExpression<%result%, %object%>" }
        
        resultAndWhereClause += op.expressionResultRequirement.map { "\nwhere \($0)" } ?? ""
        let parameters = [
            ("resultAndWhereClause", resultAndWhereClause),
            ("swiftOperator", op.swiftOperator),
            ("sqlOperator", op.sqlOperator),
            ("genericParameters", (type == .keyPath ? "R: DatabaseObject, V" : "T: %type%")),
            ("paramType", (type == .keyPath ? "KeyPath<R, V>" : "T")),
            ("object", (type == .keyPath ? "R" : "T.ExpressionObject")),
            ("result", (type == .keyPath ? "V" : "T.ExpressionResult")),
            ("type", type.name),
            ("typed", (type == .untyped ? "Untyped" : "Typed"))
            ]
        print(parameters.reduce(template) {
            $0.replacingOccurrences(of: "%\($1.0)%", with: $1.1)
        })
    }
}
