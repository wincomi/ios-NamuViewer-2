//
//  CircleColorView.swift
//

import SwiftUI

struct CircleColorView: View {
	@Binding var showBorder: Bool
	let buttonColor: Color
	let backgroundColor: Color
	let borderColor: Color

	var body: some View {
		ZStack {
			if showBorder {
				Circle()
					.fill(borderColor)
			}
			Circle()
				.fill(backgroundColor)
				.padding(2)
			Circle()
				.fill(buttonColor)
				.padding(4)
		}
	}
}

extension CircleColorView {
	init(showBorder: Binding<Bool>, uiColor: UIColor) {
		self._showBorder = showBorder
		self.buttonColor = Color(uiColor)
		self.backgroundColor = Color(UIColor.tertiarySystemBackground)
		self.borderColor = Color(UIColor.separator)
	}
}

struct CircleColorView_Previews: PreviewProvider {
	static var previews: some View {
		CircleColorView(showBorder: .constant(true), buttonColor: .blue, backgroundColor: .white, borderColor: .secondary)
			.previewLayout(.fixed(width: 64, height: 64))
	}
}
