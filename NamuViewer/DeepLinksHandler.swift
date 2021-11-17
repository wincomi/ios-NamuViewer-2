//
//  DeepLinksHandler.swift
//  NamuViewer
//

import Foundation

//Section(header: Text("앱 실행")) {
//	Text("namuviewer://")
//		.modifier(CopyContextMenuModifier(text: "namuviewer://"))
//}
//
//Section(header: Text("URL 열기")) {
//	Text("namuviewer://?url=https://namu.wiki/...")
//		.modifier(CopyContextMenuModifier(text: "namuviewer://?url="))
//}
//
//Section(header: Text("검색"), footer: Text("[XXX]에는 검색을 원하는 항목을 입력하세요.")) {
//	Text("namuviewer://?search=[XXX]")
//		.modifier(CopyContextMenuModifier(text: "namuviewer://?search="))
//}
//
//Section(header: Text("즐겨찾기 열기")) {
//	Text("namuviewer://bookmark")
//		.modifier(CopyContextMenuModifier(text: "namuviewer://bookmark"))
//}

enum DeepLink: Equatable {
	case openURL(String)
	case search(String)
	case openBookmarks

	init?(url: URL) {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }

		if let item = components.queryItems?.first(where: { $0.name == "openURL" }), let urlString = item.value {
			self = .openURL(urlString)
			return
		} else if let item = components.queryItems?.first(where: { $0.name == "search" }) {
			self = .search(item.value ?? "")
			return
		} else if components.host == "bookmark" {
			self = .openBookmarks
			return
		}

		return nil
	}
}

// MARK: - DeepLinksHandler

protocol DeepLinksHandler {
	func open(deepLink: DeepLink)
}

struct RealDeepLinksHandler: DeepLinksHandler {
	var coordinator: RootCoordinator

	init(coordinator: RootCoordinator) {
		self.coordinator = coordinator
	}

	func open(deepLink: DeepLink) {
		switch deepLink {
		case .openURL(let urlString):
			if let url = URL(string: urlString) {
				coordinator.open(url: url)
			}
		case .search(let searchText):
			// TODO: -
			print("search")
			coordinator.searchNamuWiki()
		case .openBookmarks:
			coordinator.presentBookmarkHistoryTabView()
		}
	}
}
