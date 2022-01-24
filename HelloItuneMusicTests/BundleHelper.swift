//
//  BundleHelper.swift
//  HelloItuneMusicTests
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/24.
//

import Foundation
import XCTest
@testable import HelloItuneMusic

extension XCTestCase {
    func decode(from filename: String, with extensionName: String) -> ItemSearchModel {
       
        let testBundle = Bundle(for: type(of: self))
        
        guard let url = testBundle.url(forResource: filename, withExtension: extensionName) else {
            fatalError("Missing file: \(filename).\(extensionName)")
        }
   
        guard let jsonData = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(filename) from app bundle.")
        }

        let decoder = JSONDecoder()

        guard let result = try? decoder.decode(ItemSearchModel.self, from: jsonData) else {
            fatalError("Failed to decode \(filename) from app bundle.")
        }

        return result
    }
    
    func decodeToData(from filename: String, with extensionName: String) -> Data? {
       
        let testBundle = Bundle(for: type(of: self))
        
        guard let url = testBundle.url(forResource: filename, withExtension: extensionName) else {
            fatalError("Missing file: \(filename).\(extensionName)")
        }
   
        guard let jsonData = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(filename) from app bundle.")
        }

        return jsonData
    }
}
