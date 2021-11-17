//
//  AppSettings.swift
//

import Combine
import UIKit

final class AppSettings: ObservableObject {
	static let shared = AppSettings()

	static let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""

	static let feedbackMailAddress = "admin@wincomi.com"
	static let developerId = "849003301"
	static let appStoreId = "993035669"

	static var shortVersionString: String {
		Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
	}

	@UserDefault("adblock")
	var adBlock: Bool = false { willSet { objectWillChange.send() } }

	@UserDefault("ignoreDarkmode")
	var ignoreDarkmode: Bool = false {
		willSet { objectWillChange.send() }
		didSet {
			let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
			sceneDelegate?.window?.overrideUserInterfaceStyle = ignoreDarkmode ? .light : .unspecified
		}
	}

	@UserDefault("enabled_history")
	var enabledHistory: Bool = true { willSet { objectWillChange.send() } }

	@UserDefault("use_icloud")
	var useIcloudBookmarks: Bool = false { willSet { objectWillChange.send() } }

	@UserDefault("globalTintColor")
	var globalTintColor = Constants.mainColor {
		willSet { objectWillChange.send() }
		didSet {
			let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
			sceneDelegate?.window?.tintColor = globalTintColor
		}
	}
}
