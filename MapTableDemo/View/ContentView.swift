//
//  ContentView.swift
//  MapTableDemo
//
//  Created by Robert Ryan on 11/30/23.
//

import SwiftUI
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContentView")

struct ContentView: View {
    @State var mapTable = MapTable<SampleKey, SampleValue>()
    @State var keys: [SampleKey] = []

    var body: some View {
        VStack {
            Button("Add") {
                let key = SampleKey(id: UUID())
                keys.append(key)
                let value = SampleValue(foo: "\(Date.now)")
                mapTable.setValue(value, forKey: key)
            }
            Button("Examine") {
                print("Examine:")
                print(mapTable)
                print(keys)
            }
            Button("Remove first key") {
                guard !keys.isEmpty else { return }
                keys.removeFirst()
            }
            Button("Replace first key with new value") {
                guard !keys.isEmpty else { return }

                // remove strong reference to a key
                let firstKey = keys.removeFirst()

                // create a new key
                let newKey = SampleKey(id: firstKey.id)
                let value = SampleValue(foo: "\(Date.now)")

                // add it to the weak-to-strong map table
                mapTable.setValue(value, forKey: newKey)

                // make sure to save a strong reference to this new key
                keys.append(newKey)

                // report results
                print("Removed ", firstKey)
                print("Adding ", newKey, value)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
