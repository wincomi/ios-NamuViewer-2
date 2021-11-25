//
//  DeepLinksHandler.swift
//  NamuViewer
//

import Foundation

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
			coordinator.searchNamuWiki(searchText: searchText)
		case .openBookmarks:
			coordinator.presentBookmarkHistoryTabView()
		}
	}
}
