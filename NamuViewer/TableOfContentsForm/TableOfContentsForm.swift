//
//  TableOfContentsForm.swift
//  NamuViewer
//

import SwiftUI
import Kanna

struct TableOfContentsForm: View {
	let html: String
	let documentTitle: String?
	let currentHash: String?
	@State var items: [TocItem] = []
	var onSelectItem: (TocItem?) -> Void

	var body: some View {
		NavigationView {
			Form {
				ForEach(items) { item in
					Button {
						onSelectItem(item)
					} label: {
						Text(item.title)
							.foregroundColor(item.id == currentHash ? Color.white : Color(UIColor.label))
					}
					.listRowBackground(item.id == currentHash ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
				}
			}
			.navigationBarTitle("목차")
			.navigationBarItems(trailing: dismissButton)
			.onAppear(perform: parse)
		}.navigationViewStyle(StackNavigationViewStyle())
	}

	func parse() {
		guard let doc = try? HTML(html: html, encoding: .utf8) else { return }
		
		items = doc.css(".toc-item").compactMap {
			guard let href = $0.css("a[href]").first?["href"],
				  let title = $0.content else { return nil }
			return TocItem(id: href, indent: 0, title: title)
		}
	}

	var dismissButton: some View {
		Button {
			onSelectItem(nil)
		} label: {
			Image(systemName: "xmark")
		}
	}

	struct TocItem: Identifiable {
		var id: String
		var indent: Int
		var title: String
	}
}
