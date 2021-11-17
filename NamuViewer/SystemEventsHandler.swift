//
//  SystemEventsHandler.swift
//  NamuViewer
//

import Foundation
import UIKit

protocol SystemEventsHandler {
	func sceneOpenURLContexts(_ urlContexts: Set<UIOpenURLContext>)
	func windowScenePerformActionFor(_ shortcutItem: UIApplicationShortcutItem)
}

struct RealSystemEventsHandler: SystemEventsHandler {
	let coordinator: RootCoordinator
	let deepLinksHandler: DeepLinksHandler

	init(coordinator: RootCoordinator, deepLinksHandler: DeepLinksHandler) {
		self.coordinator = coordinator
		self.deepLinksHandler = deepLinksHandler
	}

	func sceneOpenURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
		guard let url = urlContexts.first?.url else { return }
		handle(url: url)
	}

	private func handle(url: URL) {
		guard let deepLink = DeepLink(url: url) else { return }
		deepLinksHandler.open(deepLink: deepLink)
	}

	func windowScenePerformActionFor(_ shortcutItem: UIApplicationShortcutItem) {
		switch shortcutItem.type {
		case "com.wincomi.ios.namuViewer.search":
			coordinator.searchNamuWiki()
		case "com.wincomi.ios.namuViewer.bookmark":
			coordinator.presentBookmarkHistoryTabView()
		case "com.wincomi.ios.namuViewer.random":
			coordinator.goNamuWikiRandomDocument()
		default:
			break
		}
	}
}
