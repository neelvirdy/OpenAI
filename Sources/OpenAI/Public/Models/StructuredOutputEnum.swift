//
//  StructuredOutputEnum.swift
//
//
//  Created by Andriy Gordiyenko on 8/29/24.
//

import Foundation

public protocol StructuredOutputEnum: Codable, CaseIterable {
    var caseNames: [String] { get }
}
