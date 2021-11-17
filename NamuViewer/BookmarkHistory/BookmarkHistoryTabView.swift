//
//  BookmarkHistoryTabView.swift
//  NamuViewer
//

import SwiftUI
import SPIndicator
import Combine

struct BookmarkHistoryTabView: View {
	struct RowItem: Identifiable {
		let id: UUID
		let text: String

		init(_ text: String) {
			self.id = UUID()
			self.text = text
		}
	}

	private let bookmarksRepository = RealBookmarksRepository()
	private let historiesRepository = RealHistoriesRepository()

	var onSelectItem: (String) -> Void
	var dismissAction: () -> Void

	@State private var bookmarkRowItems: [RowItem] = []
	@State private var historyRowItems: [RowItem] = []

	var body: some View {
		TabView {
			NavigationView {
				BookmarkList(
					rowItems: $bookmarkRowItems,
					onSelectItem: onSelectItem,
					dismissAction: dismissAction
				)
			}.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Image(systemName: "star.fill")
				Text("즐겨찾기")
			}

			NavigationView {
				HistoryList(
					rowItems: $historyRowItems,
					onSelectItem: onSelectItem,
					dismissAction: dismissAction
				)
			}.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Image(systemName: "clock")
				Text("방문 기록")
			}
		}
		.onAppear(perform: onAppear)
		.onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: RealBookmarksRepository.cloudStore)) { _ in
			print("NSUbiquitousKeyValueStore.didChangeExternallyNotification")
			switch bookmarksRepository.bookmarks() {
			case .success(let bookmarks):
				self.bookmarkRowItems = bookmarks.map(RowItem.init)
			case .failure(let error):
				self.bookmarkRowItems = []
				SPIndicator.present(title: Constants.L10n.errorOccured, message: error.localizedDescription, haptic: .error)
			}
		}
	}

	func onAppear() {
		switch bookmarksRepository.bookmarks() {
		case .success(let bookmarks):
			self.bookmarkRowItems = bookmarks.map(RowItem.init)
		case .failure(let error):
			self.bookmarkRowItems = []
			SPIndicator.present(title: Constants.L10n.errorOccured, message: error.localizedDescription, haptic: .error)
		}

		switch historiesRepository.histories() {
		case .success(let histories):
			self.historyRowItems = histories.map(RowItem.init)
		case .failure(let error):
			self.historyRowItems = []
			SPIndicator.present(title: Constants.L10n.errorOccured, message: error.localizedDescription, haptic: .error)
		}
	}
}
