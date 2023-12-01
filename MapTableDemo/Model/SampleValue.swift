//
//  SampleValue.swift
//  MapTableDemo
//
//  Created by Robert Ryan on 11/30/23.
//

import Foundation

class SampleValue {
    let foo: String

    init(foo: String) {
        self.foo = foo
    }
}

extension SampleValue: CustomStringConvertible {
    var description: String { "<SampleValue foo=\(foo)>"}
}
