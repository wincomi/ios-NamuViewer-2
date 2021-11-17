//
//  BookmarksRepository.swift
//  NamuViewer
//

import Foundation

protocol BookmarksRepository {
	typealias Bookmarks = [String]

	func bookmarks() -> Result<Bookmarks, Error>
	func contains(bookmark: String) -> Result<Bool, Error>
	func insertFirst(bookmark: String) -> Result<Void, Error>
	func remove(bookmark: String) -> Result<Void, Error>
	func store(bookmarks: Bookmarks) -> Result<Void, Error>
	func removeAll() -> Result<Void, Error>
	func makeFileIfDoesNotexist()

	func convertToCSV() -> String?
}

struct RealBookmarksRepository: BookmarksRepository {
	static let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(Constants.bookmarksFileName)
	static let cloudStore = NSUbiquitousKeyValueStore.default

	func bookmarks() -> Result<Bookmarks, Error> {
		if AppSettings.shared.useIcloudBookmarks {
			let bookmarksFileArray = RealBookmarksRepository.cloudStore.array(forKey: Constants.bookmarksFileName)
			let bookmarks = bookmarksFileArray as? [String]
			return .success(bookmarks ?? [])
		} else {
			do {
				let bookmarksFileArray = try NSArray(contentsOf: RealBookmarksRepository.fileURL, error: ())
				let bookmarks = bookmarksFileArray as? [String]
				return .success(bookmarks ?? [])
			} catch {
				return .failure(error)
			}
		}
	}

	func contains(bookmark: String) -> Result<Bool, Error> {
		switch bookmarks() {
		case .success(let bookmarks):
			return .success(bookmarks.contains(bookmark))
		case .failure(let error):
			return .failure(error)
		}
	}

	func insertFirst(bookmark: String) -> Result<Void, Error> {
		switch bookmarks() {
		case .success(let bookmarks):
			if bookmarks.contains(bookmark) { return .success(()) }
			var bookmarksCopy = bookmarks
			bookmarksCopy.insert(bookmark, at: 0)
			return store(bookmarks: bookmarksCopy)
		case .failure(let error):
			return .failure(error)
		}
	}

	func remove(bookmark: String) -> Result<Void, Error> {
		switch bookmarks() {
		case .success(let bookmarks):
			var bookmarksCopy = bookmarks
			bookmarksCopy.removeAll { $0 == bookmark}
			return store(bookmarks: bookmarksCopy)
		case .failure(let error):
			return .failure(error)
		}
	}

	func store(bookmarks: Bookmarks) -> Result<Void, Error> {
		if AppSettings.shared.useIcloudBookmarks {
			RealBookmarksRepository.cloudStore.set(bookmarks, forKey: Constants.bookmarksFileName)
			return .success(())
		} else {
			do {
				try NSArray(array: bookmarks).write(to: RealBookmarksRepository.fileURL)
				return .success(())
			} catch {
				return .failure(error)
			}
		}
	}

	func removeAll() -> Result<Void, Error> {
		store(bookmarks: [])
	}

	func makeFileIfDoesNotexist() {
		switch bookmarks() {
		case .success(_):
			break
		case .failure(_):
			_ = store(bookmarks: [])
		}
	}

	func convertToCSV() -> String? {
		switch bookmarks() {
		case .success(let bookmarks):
			return bookmarks.joined(separator: "\n")
		case .failure(_):
			return nil
		}
	}
}
