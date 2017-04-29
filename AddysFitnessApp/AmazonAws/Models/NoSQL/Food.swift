//
//  Food.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.14
//

import Foundation
import UIKit
import AWSDynamoDB

class Food: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _foodName: String?
    var _type: String?
    var _category: String?
    var _createdBy: String?
    var _createdDate: String?
    var _description: String?
    var _ingredients: [String: String]?
    var _steps: Set<String>?
    
    class func dynamoDBTableName() -> String {

        return "addysfitnessapp-mobilehub-805122985-Food"
    }
    
    class func hashKeyAttribute() -> String {

        return "_foodName"
    }
    
    class func rangeKeyAttribute() -> String {

        return "_type"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
               "_foodName" : "foodName",
               "_type" : "type",
               "_category" : "category",
               "_createdBy" : "createdBy",
               "_createdDate" : "createdDate",
               "_description" : "description",
               "_ingredients" : "ingredients",
               "_steps" : "steps",
        ]
    }
}
