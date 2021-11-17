//
//  RootViewToolbarItemsProvider.swift
//  NamuViewer
//

import COMIKit
import Foundation
import UIKit

final class RootViewToolbarItemsProvider {
	enum ToolbarItemType: String, CaseIterable {
		case star
		case bookmarks
		case search
		case tableOfContents
		case more
	}

	var starActionHandler: (() -> Void)?
	var bookmarksActionHandler: (() -> Void)?
	var searchActionHandler: (() -> Void)?
	var tableOfContentsActionHandler: (() -> Void)?
	var moreActionHandler: (() -> Void)?

	lazy var star: UIBarButtonItem = {
		UIBarButtonItem(image: UIImage(systemName: "star"), style: .plain, target: self, action: #selector(starAction))
	}()

	lazy var bookmarks: UIBarButtonItem = {
		UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(bookmarksAction))
	}()

	lazy var search: UIBarButtonItem = {
		UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(RootViewToolbarItemsProvider.searchAction))
	}()

	lazy var tableOfContents: UIBarButtonItem = {
		UIBarButtonItem(image: UIImage(systemName: "list.number"), style: .plain, target: self, action: #selector(tableOfContentsAction))
	}()

	lazy var more: UIBarButtonItem = {
		UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(moreAction))
	}()

	@objc private func starAction() {
		starActionHandler?()
	}

	@objc private func bookmarksAction() {
		bookmarksActionHandler?()
	}

	@objc private func searchAction() {
		searchActionHandler?()
	}

	@objc private func tableOfContentsAction() {
		tableOfContentsActionHandler?()
	}

	@objc private func moreAction() {
		moreActionHandler?()
	}
}

extension RootViewToolbarItemsProvider: ToolbarItemsProvider {
	func toolbarItem(for type: ToolbarItemType) -> UIBarButtonItem? {
		switch type {
		case .star:
			return star
		case .bookmarks:
			return bookmarks
		case .search:
			return search
		case .tableOfContents:
			return tableOfContents
		case .more:
			return more
		}
	}
}
