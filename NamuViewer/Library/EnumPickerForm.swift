//
//  EnumPickerForm.swift
//

import SwiftUI

struct EnumPickerForm<T: Hashable, Content: View>: View {
	@Environment(\.presentationMode) var presentationMode

	let title: Text
	let items: [T]
	@Binding var selection: T
	let rowContent: ((T, Bool) -> Content)

	var body: some View {
		Form {
			ForEach(items, id: \.hashValue) { item in
				Button {
					selection = item
					presentationMode.wrappedValue.dismiss()
				} label: {
					rowContent(item, selection == item)
				}
			}
		}
		.navigationBarTitle(title, displayMode: .inline)
		.modifier(CompatibleInsetGroupedListStyle())
	}
}
