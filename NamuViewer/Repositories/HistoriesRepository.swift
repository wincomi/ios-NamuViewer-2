//
//  HistoriesRepository.swift
//  NamuViewer
//

import Foundation

protocol HistoriesRepository {
	typealias Histories = [String]

	func histories() -> Result<Histories, Error>
	func store(histories: Histories) -> Result<Void, Error>
	func insertFirst(history: String) -> Result<Void, Error>
	func removeAll() -> Result<Void, Error>
	func makeFileIfDoesNotexist()

	func convertToCSV() -> String?
}

struct RealHistoriesRepository: HistoriesRepository {
	private let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(Constants.historiesFileName)

	func histories() -> Result<Histories, Error> {
		do {
//			let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
			let historiesFileArray = try NSArray(contentsOf: fileURL, error: ())
			let histories = historiesFileArray as? [String]
			return .success(histories ?? [])
		} catch {
			return .failure(error)
		}
	}
	
	func store(histories: Histories) -> Result<Void, Error> {
		do {
			try NSArray(array: histories).write(to: fileURL)
			return .success(())
		} catch {
			return .failure(error)
		}
	}

	func insertFirst(history: String) -> Result<Void, Error> {
		if history == Constants.NamuWiki.homeDocumentTitle {
			return .success(())
		}

		switch histories() {
		case .success(let histories):
			guard histories.first != history else { return .success(()) }

			var historiesCopy = histories
			historiesCopy.insert(history, at: 0)

			return store(histories: historiesCopy)
		case .failure(let error):
			return .failure(error)
		}
	}

	func removeAll() -> Result<Void, Error> {
		do {
			try NSArray().write(to: fileURL)
			return .success(())
		} catch {
			return .failure(error)
		}
	}

	func makeFileIfDoesNotexist() {
		switch histories() {
		case .success(_):
			break
		case .failure(_):
			_ = store(histories: [])
		}
	}

	func convertToCSV() -> String? {
		switch histories() {
		case .success(let histories):
			return histories.joined(separator: "\n")
		case .failure(_):
			return nil
		}
	}
}
