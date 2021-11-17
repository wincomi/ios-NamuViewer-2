//
//  SettingsFormLabel.swift
//  NamuViewer
//

import SwiftUI

struct SettingsFormLabel: View {
	var title: String
	var systemImageName: String

	init(_ title: String, systemImage systemImageName: String) {
		self.title = title
		self.systemImageName = systemImageName
	}

	var body: some View {
		CompatibleLabel {
			Text(title)
				.foregroundColor(Color(UIColor.label))
		} icon: {
			Image(systemName: systemImageName)
				.imageScale(.large)
		}
	}
}
