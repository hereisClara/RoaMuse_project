//
//  Extension+String.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation

extension String {
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
