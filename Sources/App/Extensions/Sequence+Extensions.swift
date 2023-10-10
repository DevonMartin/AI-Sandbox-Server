//
//  File.swift
//  
//
//  Created by Devon Martin on 10/9/23.
//

import Foundation

extension Sequence where Element: Hashable {
	func unique() -> [Element] {
		uniqued().map{$0}
	}
}
