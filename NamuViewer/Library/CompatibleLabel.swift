//
//  CompatibleLabel.swift
//

import SwiftUI

struct CompatibleLabel<Title: View, Icon: View>: View {
	private let title: (() -> Title)
	private let icon: (() -> Icon)
	
	init<S>(_ title: S, systemImage name: String) where S: StringProtocol, Title == Text, Icon == Image {
		self.init {
			Text(title)
		} icon: {
			Image(systemName: name)
		}
	}
	
	init(_ titleKey: LocalizedStringKey, systemImage name: String) where Title == Text, Icon == Image {
		self.init {
			Text(titleKey)
		} icon: {
			Image(systemName: name)
		}
	}
	
	init(@ViewBuilder title: @escaping () -> Title, @ViewBuilder icon: @escaping () -> Icon) {
		self.title = title
		self.icon = icon
	}
	
	var body: some View {
		if #available(iOS 14.0, *) {
			Label(title: title, icon: icon)
		} else {
			HStack(alignment: .firstTextBaseline, spacing: 16) {
				icon()
					.padding(.horizontal, 4)
					.foregroundColor(.accentColor)
					.frame(width: 28)
				title()
			}
		}
	}

//	func labelStyle<S: CompatibleLabelStyle>(_ style: S) -> some View {
//		CompatibleLabel {
//			self.title()
//		} icon: {
//			self.icon()
//		}
//	}
}

//public protocol CompatibleLabelStyle {
//	associatedtype Body : View
//
//	@ViewBuilder func makeBody(configuration: CompatibleLabelStyleConfiguration) -> Self.Body
//
//	typealias Configuration = CompatibleLabelStyleConfiguration
//}
//
//public struct CompatibleLabelStyleConfiguration {
//	public struct Title {
//		public typealias Body = Never
//	}
//
//	public struct Icon {
//		public typealias Body = Never
//	}
//
//	public private(set) var title: CompatibleLabelStyleConfiguration.Title
//	public private(set) var icon: CompatibleLabelStyleConfiguration.Icon
//}
//
//extension CompatibleLabelStyleConfiguration.Title: View {
//	public var body: Never { fatalError() }
//}
//
//extension CompatibleLabelStyleConfiguration.Icon: View {
//	public var body: Never { fatalError() }
//}
