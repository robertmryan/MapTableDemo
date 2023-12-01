//
//  SampleKey.swift
//  MapTableDemo
//
//  Created by Robert Ryan on 11/30/23.
//

import Foundation

class SampleKey: Identifiable {
    let id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}

extension SampleKey: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension SampleKey: Equatable {
    static func == (lhs: SampleKey, rhs: SampleKey) -> Bool {
        lhs.id == rhs.id
    }
}

extension SampleKey: CustomStringConvertible {
    var description: String { "<SampleKey id=\(id)>"}
}
