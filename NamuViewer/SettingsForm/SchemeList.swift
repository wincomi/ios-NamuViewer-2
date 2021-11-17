//
//  SchemeList.swift
//  NamuViewer
//

import SwiftUI

struct SchemeList: View {
	var body: some View {
		Form {
			Section(header: Text("앱 실행")) {
				Text("namuviewer://")
					.modifier(CopyContextMenuModifier(text: "namuviewer://"))
			}

			Section(header: Text("URL 열기")) {
				Text("namuviewer://?url=https://namu.wiki/...")
					.modifier(CopyContextMenuModifier(text: "namuviewer://?url="))
			}

			Section(header: Text("검색"), footer: Text("[XXX]에는 검색을 원하는 항목을 입력하세요.")) {
				Text("namuviewer://?search=[XXX]")
					.modifier(CopyContextMenuModifier(text: "namuviewer://?search="))
			}

			Section(header: Text("즐겨찾기 열기")) {
				Text("namuviewer://bookmark")
					.modifier(CopyContextMenuModifier(text: "namuviewer://bookmark"))
			}
		}
		.modifier(CompatibleInsetGroupedListStyle())
		.navigationBarTitle("URL Scheme")
	}
}

struct SchemeList_Previews: PreviewProvider {
	static var previews: some View {
		SchemeList()
	}
}

