//
//  RootCoordinator.swift
//  NamuViewer
//

import UIKit
import SwiftUI
import SafariServices
import SPIndicator

final class RootCoordinator: NSObject, Coordinator {
	var viewController: RootViewController

	init(viewController: RootViewController) {
		self.viewController = viewController
	}

	func start() {
	}
}

extension RootCoordinator {
	func presentSettingsForm() {
		let view = SettingsForm(onSelectURL: onSelect) {
			self.viewController.dismiss(animated: true)
		}.environmentObject(AppSettings.shared)

		let vc = UIHostingController(rootView: view)
		let nc = UINavigationController(rootViewController: vc)
		nc.navigationBar.prefersLargeTitles = true
		nc.modalPresentationStyle = .pageSheet
		viewController.present(nc, animated: true, completion: nil)
	}

	private func onSelect(_ url: URL) {
		if url.isNamuWiki {
			viewController.load(url: url)
		} else {
			if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
				presentSafariViewController(url: url)
			} else {
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
			}
		}
	}

	func presentTableOfContentsForm(html: String) {
		viewController.webView.evaluateJavaScript("window.location.hash") { result, _ in
			let view = TableOfContentsForm(html: html, documentTitle: self.viewController.documentTitle, currentHash: result as? String) { item in
				self.viewController.dismiss(animated: true, completion: nil)
				if let item = item {
					self.viewController.webView.evaluateJavaScript("window.location.hash='\(item.id)'", completionHandler: nil)
				}
			}
			let vc = UIHostingController(rootView: view)
			vc.modalPresentationStyle = .formSheet
			self.viewController.present(vc, animated: true, completion: nil)
		}
	}

	private func onSelect(_ tocItem: TableOfContentsForm.TocItem) {
		viewController.webView.evaluateJavaScript("window.location.hash='\(tocItem.id)'", completionHandler: nil)
	}

	func presentBookmarkHistoryTabView() {
		let bookmarkHistoryTabView = BookmarkHistoryTabView(onSelectItem: goNamuWikiDocument) {
			self.viewController.dismiss(animated: true, completion: nil)
		}
		let vc = UIHostingController(rootView: bookmarkHistoryTabView)
		viewController.present(vc, animated: true, completion: nil)
	}

	func presentSafariViewController(url: URL) {
		let configuration = SFSafariViewController.Configuration()
		configuration.barCollapsingEnabled = true
		let vc = SFSafariViewController(url: url, configuration: configuration)
		vc.delegate = viewController
		viewController.navigationController?.present(vc, animated: true)
	}

	func presentNewWindow(url: URL) {
		let vc = RootViewController()
		vc.showDismissButton = true
		vc.initialURL = url

		let nc = UINavigationController(rootViewController: vc)
		nc.modalPresentationStyle = .fullScreen

		viewController.present(nc, animated: true)
	}

	func open(url: URL) {
		if url.isNamuWiki {
			viewController.load(url: url)
		} else {
			presentSafariViewController(url: url)
		}
	}

	func goNamuWikiDocument(name: String) {
		viewController.load(url: Constants.NamuWiki.documentURL(name: name))
	}

	func goNamuWikiRandomDocument() {
		SPIndicator.present(title: "랜덤 문서", message: "랜덤한 문서로 이동합니다.", preset: .custom(UIImage(systemName: "shuffle")!), haptic: .none)

		viewController.load(url: Constants.NamuWiki.randomURL)
	}

	func searchNamuWiki(searchText: String? = nil) {
		if let searchText = searchText {
			goNamuWikiSearch(searchText: searchText)
			return
		}

		let indicatorView = SPIndicatorView(title: "검색", message: "검색창으로 이동합니다.", preset: .custom(UIImage(systemName: "magnifyingglass")!))
		indicatorView.present(duration: 0.3, haptic: .none)

		// 설정 모달 감추기
		let scriptSource = "\(Constants.NamuWiki.Selector.theseedSettingModal) != null"
		viewController.webView.evaluateJavaScript(scriptSource) { isModalActived, _ in
			if isModalActived as? Bool ?? false {
				self.viewController.webView.evaluateJavaScript("\(Constants.NamuWiki.Selector.theseedSettingModalDismissButton).click()", completionHandler: nil)
			}
		}

		UIApplication.shared.sendAction(#selector(UIView.resignFirstResponder), to: nil, from: nil, for: nil)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			self.viewController.webView.becomeFirstResponder()
			let scriptSource = "\(Constants.NamuWiki.Selector.searchInput).focus()"
			self.viewController.webView.evaluateJavaScript(scriptSource) { (result, error) in
				if let error = error {
					SPIndicator.present(title: "오류가 발생하였습니다.", message: error.localizedDescription, preset: .error, haptic: .error)
					return
				}
			}

//			guard let searchText = searchText else { return }
//
//			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//				let scriptSource = "\(Constants.NamuWiki.Selector.searchInput).value = '\(searchText)'"
//
//				self.viewController.webView.evaluateJavaScript(scriptSource) { (result, error) in
//					if let error = error {
//						SPIndicator.present(title: "오류가 발생하였습니다.", message: error.localizedDescription, preset: .error, haptic: .error)
//						return
//					}
//				}
//			}
		}
	}

	func goNamuWikiSearch(searchText: String) {
		viewController.load(url: Constants.NamuWiki.searchURL(searchText: searchText))
	}
}
