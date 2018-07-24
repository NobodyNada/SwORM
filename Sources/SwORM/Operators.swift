//
//  Operators.swift
//  SwORM
//
//  Created by NobodyNada on 7/24/17.
//

import Foundation

//MARK: - Binary operators
public func == <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "=", rhs.asTypedExpression)
}

public func == <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "=", rhs.asUntypedExpression)
}

public func == <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "=", rhs.asTypedExpression)
}

public func == <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "=", rhs.asTypedExpression)
}

public func == <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<Bool>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "=", rhs.asUntypedExpression)
}

public func == <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "=", rhs.asTypedExpression)
}

public func == <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "=", rhs.asTypedExpression)
}

public func == <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "=", rhs.asUntypedExpression)
}

public func == <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<Bool, R> {
    return .binaryOperator(lhs.asTypedExpression, "=", rhs.asTypedExpression)
}

public func == <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<Bool> {
    return .binaryOperator(lhs.asUntypedExpression, "=", rhs.asUntypedExpression)
}

public func != <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "<>", rhs.asTypedExpression)
}

public func != <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "<>", rhs.asUntypedExpression)
}

public func != <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "<>", rhs.asTypedExpression)
}

public func != <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "<>", rhs.asTypedExpression)
}

public func != <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<Bool>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "<>", rhs.asUntypedExpression)
}

public func != <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "<>", rhs.asTypedExpression)
}

public func != <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "<>", rhs.asTypedExpression)
}

public func != <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "<>", rhs.asUntypedExpression)
}

public func != <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<Bool, R> {
    return .binaryOperator(lhs.asTypedExpression, "<>", rhs.asTypedExpression)
}

public func != <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<Bool> {
    return .binaryOperator(lhs.asUntypedExpression, "<>", rhs.asUntypedExpression)
}

public func < <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "<", rhs.asTypedExpression)
}

public func < <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "<", rhs.asUntypedExpression)
}

public func < <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "<", rhs.asTypedExpression)
}

public func < <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "<", rhs.asTypedExpression)
}

public func < <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<Bool>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "<", rhs.asUntypedExpression)
}

public func < <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "<", rhs.asTypedExpression)
}

public func < <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "<", rhs.asTypedExpression)
}

public func < <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "<", rhs.asUntypedExpression)
}

public func < <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<Bool, R> {
    return .binaryOperator(lhs.asTypedExpression, "<", rhs.asTypedExpression)
}

public func < <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<Bool> {
    return .binaryOperator(lhs.asUntypedExpression, "<", rhs.asUntypedExpression)
}

public func > <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, ">", rhs.asTypedExpression)
}

public func > <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, ">", rhs.asUntypedExpression)
}

public func > <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, ">", rhs.asTypedExpression)
}

public func > <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, ">", rhs.asTypedExpression)
}

public func > <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<Bool>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, ">", rhs.asUntypedExpression)
}

public func > <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, ">", rhs.asTypedExpression)
}

public func > <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, ">", rhs.asTypedExpression)
}

public func > <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, ">", rhs.asUntypedExpression)
}

public func > <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<Bool, R> {
    return .binaryOperator(lhs.asTypedExpression, ">", rhs.asTypedExpression)
}

public func > <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<Bool> {
    return .binaryOperator(lhs.asUntypedExpression, ">", rhs.asUntypedExpression)
}

public func <= <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "<=", rhs.asTypedExpression)
}

public func <= <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "<=", rhs.asUntypedExpression)
}

public func <= <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "<=", rhs.asTypedExpression)
}

public func <= <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "<=", rhs.asTypedExpression)
}

public func <= <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<Bool>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "<=", rhs.asUntypedExpression)
}

public func <= <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "<=", rhs.asTypedExpression)
}

public func <= <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "<=", rhs.asTypedExpression)
}

public func <= <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "<=", rhs.asUntypedExpression)
}

public func <= <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<Bool, R> {
    return .binaryOperator(lhs.asTypedExpression, "<=", rhs.asTypedExpression)
}

public func <= <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<Bool> {
    return .binaryOperator(lhs.asUntypedExpression, "<=", rhs.asUntypedExpression)
}

public func >= <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, ">=", rhs.asTypedExpression)
}

public func >= <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, ">=", rhs.asUntypedExpression)
}

public func >= <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, ">=", rhs.asTypedExpression)
}

public func >= <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, ">=", rhs.asTypedExpression)
}

public func >= <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<Bool>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, ">=", rhs.asUntypedExpression)
}

public func >= <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, ">=", rhs.asTypedExpression)
}

public func >= <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, ">=", rhs.asTypedExpression)
}

public func >= <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, ">=", rhs.asUntypedExpression)
}

public func >= <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<Bool, R> {
    return .binaryOperator(lhs.asTypedExpression, ">=", rhs.asTypedExpression)
}

public func >= <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<Bool> {
    return .binaryOperator(lhs.asUntypedExpression, ">=", rhs.asUntypedExpression)
}

public func || <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "OR", rhs.asTypedExpression)
}

public func || <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "OR", rhs.asUntypedExpression)
}

public func || <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "OR", rhs.asTypedExpression)
}

public func || <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "OR", rhs.asTypedExpression)
}

public func || <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<Bool>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "OR", rhs.asUntypedExpression)
}

public func || <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "OR", rhs.asTypedExpression)
}

public func || <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "OR", rhs.asTypedExpression)
}

public func || <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "OR", rhs.asUntypedExpression)
}

public func || <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<Bool, R> {
    return .binaryOperator(lhs.asTypedExpression, "OR", rhs.asTypedExpression)
}

public func || <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<Bool> {
    return .binaryOperator(lhs.asUntypedExpression, "OR", rhs.asUntypedExpression)
}

public func && <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "AND", rhs.asTypedExpression)
}

public func && <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "AND", rhs.asUntypedExpression)
}

public func && <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "AND", rhs.asTypedExpression)
}

public func && <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<Bool, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "AND", rhs.asTypedExpression)
}

public func && <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<Bool>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "AND", rhs.asUntypedExpression)
}

public func && <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<Bool, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "AND", rhs.asTypedExpression)
}

public func && <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "AND", rhs.asTypedExpression)
}

public func && <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<Bool, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "AND", rhs.asUntypedExpression)
}

public func && <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<Bool, R> {
    return .binaryOperator(lhs.asTypedExpression, "AND", rhs.asTypedExpression)
}

public func && <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<Bool> {
    return .binaryOperator(lhs.asUntypedExpression, "AND", rhs.asUntypedExpression)
}

public func + <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "+", rhs.asTypedExpression)
}

public func + <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "+", rhs.asUntypedExpression)
}

public func + <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "+", rhs.asTypedExpression)
}

public func + <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "+", rhs.asTypedExpression)
}

public func + <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<L.ExpressionResult>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "+", rhs.asUntypedExpression)
}

public func + <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<L.ExpressionResult, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "+", rhs.asTypedExpression)
}

public func + <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<LV, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "+", rhs.asTypedExpression)
}

public func + <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<LV, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "+", rhs.asUntypedExpression)
}

public func + <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<V, R> {
    return .binaryOperator(lhs.asTypedExpression, "+", rhs.asTypedExpression)
}

public func + <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<V> {
    return .binaryOperator(lhs.asUntypedExpression, "+", rhs.asUntypedExpression)
}

public func - <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "-", rhs.asTypedExpression)
}

public func - <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "-", rhs.asUntypedExpression)
}

public func - <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "-", rhs.asTypedExpression)
}

public func - <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "-", rhs.asTypedExpression)
}

public func - <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<L.ExpressionResult>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "-", rhs.asUntypedExpression)
}

public func - <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<L.ExpressionResult, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "-", rhs.asTypedExpression)
}

public func - <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<LV, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "-", rhs.asTypedExpression)
}

public func - <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<LV, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "-", rhs.asUntypedExpression)
}

public func - <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<V, R> {
    return .binaryOperator(lhs.asTypedExpression, "-", rhs.asTypedExpression)
}

public func - <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<V> {
    return .binaryOperator(lhs.asUntypedExpression, "-", rhs.asUntypedExpression)
}

public func * <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "*", rhs.asTypedExpression)
}

public func * <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "*", rhs.asUntypedExpression)
}

public func * <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "*", rhs.asTypedExpression)
}

public func * <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "*", rhs.asTypedExpression)
}

public func * <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<L.ExpressionResult>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "*", rhs.asUntypedExpression)
}

public func * <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<L.ExpressionResult, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "*", rhs.asTypedExpression)
}

public func * <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<LV, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "*", rhs.asTypedExpression)
}

public func * <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<LV, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "*", rhs.asUntypedExpression)
}

public func * <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<V, R> {
    return .binaryOperator(lhs.asTypedExpression, "*", rhs.asTypedExpression)
}

public func * <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<V> {
    return .binaryOperator(lhs.asUntypedExpression, "*", rhs.asUntypedExpression)
}

public func / <L: TypedExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult, L.ExpressionObject == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "/", rhs.asTypedExpression)
}

public func / <L: TypedExpressionConvertible, R: ParameterExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "/", rhs.asUntypedExpression)
}

public func / <L: TypedExpressionConvertible, RR, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<L.ExpressionResult, L.ExpressionObject>
    where L.ExpressionResult == RV, L.ExpressionObject == RR {
        return .binaryOperator(lhs.asTypedExpression, "/", rhs.asTypedExpression)
}

public func / <L: ParameterExpressionConvertible, R: TypedExpressionConvertible>(lhs: L, rhs: R) -> TypedExpression<L.ExpressionResult, R.ExpressionObject>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "/", rhs.asTypedExpression)
}

public func / <L: UntypedExpressionConvertible, R: UntypedExpressionConvertible>(lhs: L, rhs: R) -> UntypedExpression<L.ExpressionResult>
    where L.ExpressionResult == R.ExpressionResult {
        return .binaryOperator(lhs.asUntypedExpression, "/", rhs.asUntypedExpression)
}

public func / <L: ParameterExpressionConvertible, RR: DatabaseObject, RV>(lhs: L, rhs: KeyPath<RR, RV>) -> TypedExpression<L.ExpressionResult, RR>
    where L.ExpressionResult == RV {
        return .binaryOperator(lhs.asUntypedExpression, "/", rhs.asTypedExpression)
}

public func / <LR, LV, R: TypedExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<LV, LR>
    where LV == R.ExpressionResult, LR == R.ExpressionObject {
        return .binaryOperator(lhs.asTypedExpression, "/", rhs.asTypedExpression)
}

public func / <LR: DatabaseObject, LV, R: ParameterExpressionConvertible>(lhs: KeyPath<LR, LV>, rhs: R) -> TypedExpression<LV, LR>
    where LV == R.ExpressionResult {
        return .binaryOperator(lhs.asTypedExpression, "/", rhs.asUntypedExpression)
}

public func / <R: DatabaseObject, V: DatabaseType>(lhs: KeyPath<R, V>, rhs: KeyPath<R, V>) -> TypedExpression<V, R> {
    return .binaryOperator(lhs.asTypedExpression, "/", rhs.asTypedExpression)
}

public func / <LR: DatabaseObject, RR: DatabaseObject, V: DatabaseType>(
    lhs: KeyPath<LR, V>, rhs: KeyPath<RR, V>
    ) -> UntypedExpression<V> {
    return .binaryOperator(lhs.asUntypedExpression, "/", rhs.asUntypedExpression)
}


//MARK: - Prefix operators
public prefix func ! <T: TypedExpressionConvertible>(expr: T) -> TypedExpression<T.ExpressionResult, T.ExpressionObject> {
    return .prefixOperator("NOT", expr.asTypedExpression)
}

public prefix func ! <T: UntypedExpressionConvertible>(expr: T) -> UntypedExpression<T.ExpressionResult> {
    return .prefixOperator("NOT", expr.asUntypedExpression)
}

public prefix func ! <R: DatabaseObject, V>(expr: KeyPath<R, V>) -> TypedExpression<V, R> {
    return .prefixOperator("NOT", expr.asTypedExpression)
}

public prefix func - <T: TypedExpressionConvertible>(expr: T) -> TypedExpression<T.ExpressionResult, T.ExpressionObject> {
    return .prefixOperator("-", expr.asTypedExpression)
}

public prefix func - <T: UntypedExpressionConvertible>(expr: T) -> UntypedExpression<T.ExpressionResult> {
    return .prefixOperator("-", expr.asUntypedExpression)
}

public prefix func - <R: DatabaseObject, V>(expr: KeyPath<R, V>) -> TypedExpression<V, R> {
    return .prefixOperator("-", expr.asTypedExpression)
}

public prefix func + <T: TypedExpressionConvertible>(expr: T) -> TypedExpression<T.ExpressionResult, T.ExpressionObject> {
    return .prefixOperator("+", expr.asTypedExpression)
}

public prefix func + <T: UntypedExpressionConvertible>(expr: T) -> UntypedExpression<T.ExpressionResult> {
    return .prefixOperator("+", expr.asUntypedExpression)
}

public prefix func + <R: DatabaseObject, V>(expr: KeyPath<R, V>) -> TypedExpression<V, R> {
    return .prefixOperator("+", expr.asTypedExpression)
}
