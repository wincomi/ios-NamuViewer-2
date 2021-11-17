//
//  SceneDelegate.swift
//  NamuViewer
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var coordinator: RootCoordinator?
	var deepLinksHandler: DeepLinksHandler?
	var systemEventsHandler: SystemEventsHandler?

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = (scene as? UIWindowScene) else { return }
		window = UIWindow(windowScene: windowScene)

		self.window?.tintColor = AppSettings.shared.globalTintColor


		let vc = RootViewController()
		vc.edgesForExtendedLayout = [.left, .right]

		coordinator = RootCoordinator(viewController: vc)
		coordinator?.start()

		vc.coordinator = coordinator

		if let coordinator = coordinator {
			let deepLinksHandler = RealDeepLinksHandler(coordinator: coordinator)
			self.deepLinksHandler = deepLinksHandler
			self.systemEventsHandler = RealSystemEventsHandler(coordinator: coordinator, deepLinksHandler: deepLinksHandler)
		}

		let bookmarksRepository = RealBookmarksRepository()
		bookmarksRepository.makeFileIfDoesNotexist()

		let historiesRepository = RealHistoriesRepository()
		historiesRepository.makeFileIfDoesNotexist()

		vc.bookmarksRepository = bookmarksRepository
		vc.historiesRepository = historiesRepository
		
		let nc = UINavigationController(rootViewController: vc)
		
		window?.rootViewController = nc
		window?.makeKeyAndVisible()

		window?.overrideUserInterfaceStyle = AppSettings.shared.ignoreDarkmode ? .light : .unspecified

		if let shortcutItem = connectionOptions.shortcutItem {
			systemEventsHandler?.windowScenePerformActionFor(shortcutItem)
		}

		systemEventsHandler?.sceneOpenURLContexts(connectionOptions.urlContexts)
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		systemEventsHandler?.sceneOpenURLContexts(URLContexts)
	}

	func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		systemEventsHandler?.windowScenePerformActionFor(shortcutItem)
		completionHandler(true)
	}

	func presentActivityController(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
		guard let topVC = window?.rootViewController?.top else { return }

		let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
		vc.popoverPresentationController?.sourceView = topVC.view
		vc.popoverPresentationController?.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
		vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)

		topVC.present(vc, animated: true)
	}
}

extension UIViewController {
	var top: UIViewController? {
		if let controller = self as? UINavigationController {
			return controller.topViewController?.top
		}
		if let controller = self as? UISplitViewController {
			return controller.viewControllers.last?.top
		}
		if let controller = self as? UITabBarController {
			return controller.selectedViewController?.top
		}
		if let controller = presentedViewController {
			return controller.top
		}
		return self
	}
}
