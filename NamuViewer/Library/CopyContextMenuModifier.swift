//
//  CopyContextMenuModifier.swift
//  NamuViewer
//

import SwiftUI

struct CopyContextMenuModifier: ViewModifier {
	var text: String

	func body(content: Content) -> some View {
		content
			.contextMenu {
				Button {
					UIPasteboard.general.string = text
				} label: {
					Image(systemName: "doc.on.doc")
					Text("복사")
				}
			}
	}
}
