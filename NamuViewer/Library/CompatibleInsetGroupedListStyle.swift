//
//  CompatibleInsetGroupedListStyle.swift
//

import SwiftUI

public struct CompatibleInsetGroupedListStyle: ViewModifier {
	@ViewBuilder public func body(content: Content) -> some View {
		if #available(iOS 14.0, *) {
			content
				.listStyle(InsetGroupedListStyle())
		} else {
			content
				.listStyle(GroupedListStyle())
				.environment(\.horizontalSizeClass, .regular)
		}
	}
}
