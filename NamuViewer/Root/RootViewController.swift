//
//  RootViewController.swift
//  NamuViewer
//

import UIKit
import WebKit
import SafariServices
import SwiftUI
import SPIndicator
import Combine
import COMIKit

final class RootViewController: UIViewController {
	weak var coordinator: RootCoordinator?

	var initialURL: URL = Constants.NamuWiki.mainURL
	var searchNamuWikiAfterLoading: (Bool, String?) = (false, nil)
	var showDismissButton: Bool = false
	var bookmarksRepository: BookmarksRepository?
	var historiesRepository: HistoriesRepository?

	@Published var adBlock: Bool = false
	@Published var isLoading: Bool = false
	@Published var documentTitle: String?
	@Published var isBackButtonEnabled: Bool = false
	@Published var isForwardButtonEnabled: Bool = false
	@Published var isStarButtonHighlighted: Bool = false
	@Published var isSearchButtonEnabled: Bool = false
	@Published var isTableOfContentsButtonEnabled: Bool = false

	lazy var webView: WKWebView = {
		let userContentController = WKUserContentController()
		userContentController.add(self, name: "pushStateChanged")
		userContentController.add(self, name: "locationHrefChanged")
		userContentController.add(self, name: "openYoutube")

		let userScript = WKUserScript(source: Constants.JavaScript.findInPage + Constants.JavaScript.pushStateChanged + Constants.JavaScript.locationHrefChanged + (AppSettings.shared.useOpenYoutubeApp ? Constants.JavaScript.youtubeFix : "") + Constants.JavaScript.adBlock, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
		userContentController.addUserScript(userScript)

		let preferences = WKPreferences()
		preferences.javaScriptCanOpenWindowsAutomatically = false

		let configuration = WKWebViewConfiguration()
		configuration.preferences = preferences
		configuration.userContentController = userContentController
		configuration.allowsInlineMediaPlayback = true
		configuration.allowsAirPlayForMediaPlayback = true
		configuration.allowsPictureInPictureMediaPlayback = true

		let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
		webView.navigationDelegate = self
		webView.uiDelegate = self
		webView.allowsBackForwardNavigationGestures = true
		webView.scrollView.isScrollEnabled = true
		webView.setKeyboardRequiresUserInteraction(false)

		return webView
	}()

	lazy var toolbarItemsProvider: RootViewToolbarItemsProvider = {
		let toolbarItemsProvider = RootViewToolbarItemsProvider()

		toolbarItemsProvider.starActionHandler = { [weak self] in
			guard let `self` = self, let documentTitle = self.documentTitle else { return }

			if self.isStarButtonHighlighted {
				self.removeFromBookmark(documentTitle: documentTitle)
			} else {
				self.addToBookmark(documentTitle: documentTitle)
			}
		}

		toolbarItemsProvider.bookmarksActionHandler = { [weak self] in
			self?.coordinator?.presentBookmarkHistoryTabView()
		}

		toolbarItemsProvider.searchActionHandler = { [weak self] in
			self?.coordinator?.searchNamuWiki()
		}
		toolbarItemsProvider.search.isEnabled = false

		toolbarItemsProvider.tableOfContentsActionHandler = { [weak self] in
			self?.webView.evaluateJavaScript(Constants.NamuWiki.Selector.tableOfContents) { (result, error) in
				if let error = error {
					SPIndicator.present(title: "오류가 발생하였습니다.", message: error.localizedDescription, preset: .error, haptic: .error)
					return
				}
				guard let html = result as? String else { return }

				self?.coordinator?.presentTableOfContentsForm(html: html)
			}
		}
		toolbarItemsProvider.tableOfContents.isEnabled = false

		toolbarItemsProvider.moreActionHandler = { [weak self] in
			guard let `self` = self else { return }
			self.present(contextMenuItems: self.moreContextMenuItems, animated: true) { vc in
				vc.barButtonItem = self.toolbarItems?.last
			}
		}

		if #available(iOS 14.0, *) {
			let menu = UIMenu(contextMenuItems: self.moreContextMenuItems.reversed())
			toolbarItemsProvider.more = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: menu)
		}

		return toolbarItemsProvider
	}()

	lazy var moreContextMenuItems: [ContextMenuItem] = {
		let random = ContextMenuItem(title: "랜덤 문서", image: UIImage(systemName: "shuffle")) { [weak self] in
			self?.coordinator?.goNamuWikiRandomDocument()
		}

		let share = ContextMenuItem(title: "공유...", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] in
			guard let `self` = self, let url = self.webView.url else { return }

			let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			vc.popoverPresentationController?.sourceView = self.view
			vc.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
			vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
			self.present(vc, animated: true, completion: nil)
		}

		let findInPage = ContextMenuItem(title: "페이지에서 찾기...", image: UIImage(systemName: "doc.text.magnifyingglass")) { [weak self] in
			self?.findInPage()
		}

		let openInSafari = ContextMenuItem(title: "Safari에서 열기", image: UIImage(systemName: "safari")) { [weak self] in
			if let url = self?.webView.url {
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
			}
		}

		var hideNavigationBar = ContextMenuItem(title: "상단바 숨기기", image: UIImage(systemName: "arrow.up.left.and.arrow.down.right")) { [weak self] in
			guard let `self` = self else { return }
			self.navigationController?.setNavigationBarHidden(!(self.navigationController?.isNavigationBarHidden ?? true), animated: true)
		}

		let namuWikiSettings = ContextMenuItem(title: "나무위키 설정...", image: UIImage(systemName: "textformat.alt")) { [weak self] in
			self?.webView.evaluateJavaScript("\(Constants.NamuWiki.Selector.theseedSetting).click()", completionHandler: nil)
		}

		let settings = ContextMenuItem(title: "앱 설정...", image: UIImage(systemName: "gear")) { [weak self] in
			self?.coordinator?.presentSettingsForm()
		}

		return [random, share, findInPage, openInSafari, hideNavigationBar, namuWikiSettings, settings]
	}()

	private var cancellables = Set<AnyCancellable>()

	private func addToBookmark(documentTitle: String) {
		guard let bookmarksRepository = self.bookmarksRepository else { return }

		switch bookmarksRepository.insertFirst(bookmark: documentTitle) {
		case .success():
			let icon = UIImage(systemName: "star.fill")!.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
			SPIndicator.present(title: "즐겨찾기에 추가됨", message: documentTitle, preset: .custom(icon))
			self.isStarButtonHighlighted = true
		case .failure(let error):
			SPIndicator.present(title: "오류가 발생했습니다.", message: error.localizedDescription, preset: .error, haptic: .error)
		}
	}

	private func removeFromBookmark(documentTitle: String) {
		guard let bookmarksRepository = self.bookmarksRepository else { return }
		switch bookmarksRepository.remove(bookmark: documentTitle) {
		case .success():
			let icon = UIImage(systemName: "star.slash.fill")!.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
			SPIndicator.present(title: "즐겨찾기에 제거됨", message: documentTitle, preset: .custom(icon), haptic: .warning)
			self.isStarButtonHighlighted = false
		case .failure(let error):
			SPIndicator.present(title: "오류가 발생했습니다.", message: error.localizedDescription, preset: .error, haptic: .error)
		}
	}

	@objc func refreshControlValueChanged(_ sender: UIRefreshControl) {
		webView.reload()
		sender.endRefreshing()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		setupUI()

		setupHandOff()

		$documentTitle
			.receive(on: DispatchQueue.main)
			.sink { [weak self] documentTitle in
				if AppSettings.shared.enabledHistory, let documentTitle = documentTitle {
					_ = self?.historiesRepository?.insertFirst(history: documentTitle)
				}
			}.store(in: &cancellables)

		adBlock = AppSettings.shared.adBlock

		if adBlock {
			enableAdBlock()
		}

		AppSettings.shared.objectWillChange
			.receive(on: DispatchQueue.main)
			.sink { [weak self] in
				if self?.adBlock != AppSettings.shared.adBlock {
					self?.adBlock = AppSettings.shared.adBlock
				}
			}.store(in: &cancellables)

		$adBlock
			.receive(on: DispatchQueue.main)
			.sink { [weak self] adBlock in
				if adBlock {
					self?.enableAdBlock()
				} else {
					self?.disableAdBlock()
				}
				self?.webView.reload()
			}.store(in: &cancellables)
	}

	func load(url: URL) {
		print("load: \(url)")
		let request = URLRequest(url: url)
		webView.load(request)
	}

	private func setupUI() {
		navigationController?.view.backgroundColor = .systemBackground
		navigationController?.isToolbarHidden = false
		navigationController?.isNavigationBarHidden = false

		self.view = webView

		// 다크모드시 배경 조정
		webView.isOpaque = false
		webView.backgroundColor = .systemBackground
		webView.scrollView.backgroundColor = .systemBackground

		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refreshControlValueChanged(_:)), for: .valueChanged)
		webView.scrollView.refreshControl = refreshControl

		self.navigationItem.leftBarButtonItems = [backButton, forwardButton]
		self.navigationItem.rightBarButtonItem = showDismissButton ? dismissButton : refreshButton
		self.toolbarItems = toolbarItemsProvider.toolbarItems(withFlexibleSpace: true)

		$documentTitle
			.receive(on: DispatchQueue.main)
			.assign(to: \.title, on: self)
			.store(in: &cancellables)

		$documentTitle
			.receive(on: DispatchQueue.main)
			.sink { [weak self] documentTitle in
				guard let documentTitle = documentTitle else { return }
				switch self?.bookmarksRepository?.contains(bookmark: documentTitle) {
				case .success(let isContained):
					self?.isStarButtonHighlighted = isContained
				default:
					break
				}
			}.store(in: &cancellables)

//		if !showDismissButton {
//			let indicatorView = UIActivityIndicatorView(style: .medium)
//			indicatorView.startAnimating()
//			indicatorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedIndicatorView)))
//
//			let indicatorBarButtonItem = UIBarButtonItem(customView: indicatorView)
//
//			$isLoading
//				.receive(on: DispatchQueue.main)
//				.sink { [weak self] isLoading in
//					self?.navigationItem.rightBarButtonItem = isLoading ? indicatorBarButtonItem : self?.refreshButton
//				}.store(in: &cancellables)
//		} else {
			$isLoading
				.receive(on: DispatchQueue.main)
				.map { !$0 }
				.assign(to: \.refreshButton.isEnabled, on: self)
				.store(in: &cancellables)
//		}

		$isBackButtonEnabled
			.receive(on: DispatchQueue.main)
			.assign(to: \.backButton.isEnabled, on: self)
			.store(in: &cancellables)

		$isForwardButtonEnabled
			.receive(on: DispatchQueue.main)
			.assign(to: \.forwardButton.isEnabled, on: self)
			.store(in: &cancellables)

		$isStarButtonHighlighted
			.receive(on: DispatchQueue.main)
			.map { $0 ? UIImage(systemName: "star.fill") : UIImage(systemName: "star") }
			.assign(to: \.star.image, on: toolbarItemsProvider)
			.store(in: &cancellables)

		$isSearchButtonEnabled
			.receive(on: DispatchQueue.main)
			.assign(to: \.search.isEnabled, on: toolbarItemsProvider)
			.store(in: &cancellables)

		$isTableOfContentsButtonEnabled
			.receive(on: DispatchQueue.main)
			.assign(to: \.tableOfContents.isEnabled, on: toolbarItemsProvider)
			.store(in: &cancellables)

		load(url: initialURL)

		// Fixed for App Store Connect Review at 2021-12-16
		if let data = try? Data(contentsOf: initialURL) {
			webView.load(data, mimeType: "text/html", characterEncodingName: "UTF-8", baseURL: initialURL)
		} else {
			webView.loadHTMLString("에러가 발생하였습니다.<br>\(initialURL.absoluteString)", baseURL: initialURL)
		}

//		updateNavigationBar()
	}

//	private func updateNavigationBar() {
//		let appearance = UINavigationBarAppearance()
//		appearance.configureWithTransparentBackground()
//		appearance.backgroundColor = AppSettings.shared.globalTintColor
//		appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//
//		let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
//		buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
//		appearance.buttonAppearance = buttonAppearance
//
//		navigationController?.navigationBar.standardAppearance = appearance
//		navigationController?.navigationBar.scrollEdgeAppearance = appearance
//		navigationController?.navigationBar.compactAppearance = appearance
//		if #available(iOS 15.0, *) {
//			navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
//		}
//
//		navigationController?.toolbar.barTintColor = AppSettings.shared.globalTintColor
//		navigationController?.toolbar.tintColor = .white
//	}

	private func setupHandOff() {
		let handOffActivity = NSUserActivity(activityType: "com.wincomi.ios.namuViewer.url")
		handOffActivity.isEligibleForHandoff = true
		handOffActivity.webpageURL = Constants.NamuWiki.mainURL

		self.userActivity = handOffActivity
		self.userActivity?.becomeCurrent()
	}

	func update() {
		isBackButtonEnabled = webView.canGoBack
		isForwardButtonEnabled = webView.canGoForward

		userActivity?.webpageURL = webView.url

		webView.evaluateJavaScript(Constants.NamuWiki.Selector.documentTitle) { [weak self] result, error in
			if let documentTitle = result as? String {
				self?.documentTitle = documentTitle
			}
		}

		webView.evaluateJavaScript("\(Constants.NamuWiki.Selector.searchInput) != null") { [weak self] (result, error) in
			if let isSearchInputAvailable = result as? Bool, isSearchInputAvailable {
				self?.isSearchButtonEnabled = true
			} else {
				self?.isSearchButtonEnabled = false
			}
		}

		webView.evaluateJavaScript("\(Constants.NamuWiki.Selector.tableOfContents) != null") { [weak self] (result, error) in
			if let isTableOfContentsAvailable = result as? Bool, isTableOfContentsAvailable {
				self?.isTableOfContentsButtonEnabled = true
			} else {
				self?.isTableOfContentsButtonEnabled = false
			}
		}

		if AppSettings.shared.useOpenYoutubeApp {
			webView.evaluateJavaScript(Constants.JavaScript.youtubeFix, completionHandler: nil)
		}
	}

//	@objc func tappedIndicatorView() {
//		isLoading = false
//		webView.stopLoading()
//	}

	lazy var backButton: UIBarButtonItem = {
		UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(touchBackButton))
	}()

	lazy var forwardButton: UIBarButtonItem = {
		UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(touchForwardButton))
	}()

	lazy var refreshButton: UIBarButtonItem = {
		UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(touchRefreshButton))
	}()

	lazy var dismissButton: UIBarButtonItem = {
		UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(touchDismissButton))
	}()

	@objc func touchDismissButton() {
		dismiss(animated: true, completion: nil)
	}

	@objc func touchBackButton() {
		webView.goBack()
	}

	@objc func touchForwardButton() {
		webView.goForward()
	}

	@objc private func touchRefreshButton() {
		webView.reload()
	}

	private func findInPage() {
		let alert = UIAlertController(title: "페이지에서 찾기", message: nil, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "검색", style: .default) { _ in
			let js = "_namuviewer_find_in_page('\(alert.textFields?.first?.text ?? "")');"
			self.webView.evaluateJavaScript(js, completionHandler: nil)
		})
		alert.addAction(.cancelAction())
		alert.addTextField(configurationHandler: nil)
		self.present(alert, animated: true, completion: nil)
	}

	private func enableAdBlock() {
		guard let path = Bundle.main.path(forResource: "ContentRuleList", ofType: "json") else { return }

		do {
			let jsonString = try String(contentsOfFile: path, encoding: .utf8)
			WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "com.wincomi.ios.namuViewer.rule01", encodedContentRuleList: jsonString) { [weak self] contentRuleList, error in
				if let error = error {
					SPIndicator.present(title: "광고 차단에 실패하였습니다.", message: error.localizedDescription, preset: .error, haptic: .error)
					return
				}

				if let contentRuleList = contentRuleList {
					self?.webView.configuration.userContentController.add(contentRuleList)
				}
			}
		} catch {
			SPIndicator.present(title: "광고 차단에 실패하였습니다.", message: error.localizedDescription, preset: .error, haptic: .error)
		}
	}

	private func disableAdBlock() {
		WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: "com.wincomi.ios.namuViewer.rule01") { contentRuleList, _ in
			if let contentRuleList = contentRuleList {
				self.webView.configuration.userContentController.remove(contentRuleList)
			}
		}
	}

	// TODO: - v2.1
//	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//		if traitCollection.horizontalSizeClass == .regular {
//			navigationController?.isToolbarHidden = true
//			self.navigationItem.rightBarButtonItems = toolbarItemsProvider.toolbarItems().reversed()
//		} else {
//			self.navigationItem.rightBarButtonItems = [refreshButton]
//			navigationController?.isToolbarHidden = false
//		}
//	}
}

// MARK: - WKUIDelegate
extension RootViewController: WKUIDelegate {
	func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
		print("ALERT: \(message)")
		completionHandler()
	}

	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
		if let url = navigationAction.request.url {
			if url.isNamuWiki {
				webView.load(navigationAction.request)
			} else {
				if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
					coordinator?.presentSafariViewController(url: url)
				} else {
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				}
			}
		}

		return nil
	}

	func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
		guard let url = elementInfo.linkURL else {
			completionHandler(nil)
			return
		}

		let copy = UIAction(title: "URL 복사", image: UIImage(systemName: "doc.on.doc")) { _ in
			if let urlString = elementInfo.linkURL?.absoluteString {
				UIPasteboard.general.string = urlString
			}
		}

		let share = UIAction(title: "공유...", image: UIImage(systemName: "square.and.arrow.up")) { _ in
			let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			vc.popoverPresentationController?.sourceView = self.view
			vc.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
			vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
			self.present(vc, animated: true, completion: nil)
		}

		if url.isNamuWiki {
			let configuration = UIContextMenuConfiguration(identifier: nil) {
				return self.makeWebViewController(url: url)
			} actionProvider: { _ in
				let openInNewWindow = UIAction(title: "새 창에서 열기", image: UIImage(systemName: "macwindow")) { _ in
					self.coordinator?.presentNewWindow(url: url)
				}

				let openInBrowser = UIAction(title: "Safari에서 열기", image: UIImage(systemName: "safari")) { _ in
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				}

				return UIMenu(children: [openInNewWindow, openInBrowser, copy, share])
			}

			completionHandler(configuration)
			return
		}

		let configuration = UIContextMenuConfiguration(identifier: nil) {
			return self.makeWebViewController(url: url)
		} actionProvider: { _ in
			return UIMenu(children: [copy, share])
		}

		completionHandler(configuration)
	}

	private func makeWebViewController(url: URL) -> UIViewController {
		let vc = UIViewController()

		let webView = WKWebView()
		let request = URLRequest(url: url)
		webView.load(request)

		vc.view = webView

		return vc
	}
}

// MARK: - WKNavigationDelegate
extension RootViewController: WKNavigationDelegate {
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		update()

		guard let url = navigationAction.request.url else {
			decisionHandler(.cancel)
			return
		}

		print("decidePolicyFor url = \(url.absoluteString), navigationType = \(navigationAction.navigationType.rawValue)")

		if navigationAction.navigationType == .linkActivated {
			// 유저가 링크를 클릭할 경우
			if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
				if url.host == "namu.wiki" {
					decisionHandler(.allow)
				} else {
					coordinator?.presentSafariViewController(url: url)
					decisionHandler(.cancel)
				}
			} else {
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
				decisionHandler(.cancel)
			}
		} else {
			decisionHandler(.allow)
		}
	}

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		isLoading = true
		print("didStartProvisionalNavigation isLoading = true")
	}

	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		isLoading = true
		print("didCommit isLoading = true")
	}

	func webView(_ webview: WKWebView, didFinish: WKNavigation!) {
		update()
		isLoading = false
		print("didFinish isLoading = false")
		
		if searchNamuWikiAfterLoading.0 {
			coordinator?.searchNamuWiki(searchText: searchNamuWikiAfterLoading.1)
			searchNamuWikiAfterLoading = (false, nil)
		}
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		SPIndicator.present(title: "페이지를 불러올 수 없습니다.", message: error.localizedDescription, preset: .error, haptic: .none)
		isLoading = false
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		SPIndicator.present(title: "페이지를 불러올 수 없습니다.", message: error.localizedDescription, preset: .error, haptic: .none)
		isLoading = false
	}
}

// MARK: - WKScriptMessageHandler
extension RootViewController: WKScriptMessageHandler {
	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		switch message.name {
		case "pushStateChanged":
			update()
			isLoading = false
			print("pushStateChanged isLoading = false")
		case "locationHrefChanged":
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				self.update()
				self.isLoading = false
				print("locationHrefChanged isLoading = false")
			}
		case "openYoutube":
			guard let youtubeId = message.body as? String else { return }
			if UIApplication.shared.canOpenURL(URL(string: "youtube://")!) {
				let youtubeAppURL = URL(string: "youtube://\(youtubeId)")!
				UIApplication.shared.open(youtubeAppURL, options: [:], completionHandler: nil)
			} else {
				coordinator?.presentSafariViewController(url: URL(string: "http://www.youtube.com/watch?v=\(youtubeId)")!)
			}
		default:
			break
		}
	}

	// MARK: - KeyCommands
	override var keyCommands: [UIKeyCommand]? {
		let commandR = UIKeyCommand(title: "새로고침", image: UIImage(systemName: "arrow.clockwise"), action: #selector(handleKeyCommand(_:)), input: "r", modifierFlags: .command)
		let controlR = UIKeyCommand(title: "랜덤 문서", image: UIImage(systemName: "shuffle"), action: #selector(handleKeyCommand(_:)), input: "r", modifierFlags: .control)
		let commandL = UIKeyCommand(title: "검색", image: UIImage(systemName: "magnifyingglass"), action: #selector(handleKeyCommand(_:)), input: "l", modifierFlags: .command)
		let commandF = UIKeyCommand(title: "페이지 내 검색", image: UIImage(systemName: "doc.text.magnifyingglass"), action: #selector(handleKeyCommand(_:)), input: "f", modifierFlags: .command)
		let commandD = UIKeyCommand(title: "즐겨찾기 추가", image: UIImage(systemName: "star"), action: #selector(handleKeyCommand(_:)), input: "d", modifierFlags: .command)
		let commandY = UIKeyCommand(title: "즐겨찾기 보기", image: UIImage(systemName: "book"), action: #selector(handleKeyCommand(_:)), input: "y", modifierFlags: .command)
		let commandBack = UIKeyCommand(title: "뒤로", image: UIImage(systemName: "arrow.left"), action: #selector(handleKeyCommand(_:)), input: "[", modifierFlags: .command)
		let commandForward = UIKeyCommand(title: "앞으로", image: UIImage(systemName: "arrow.right"), action: #selector(handleKeyCommand(_:)), input: "]", modifierFlags: .command)
		let commandComma = UIKeyCommand(title: "설정", image: UIImage(systemName: "gear"), action: #selector(handleKeyCommand(_:)), input: ",", modifierFlags: .command)

		return [commandR, controlR, commandL, commandF, commandD, commandY, commandBack, commandForward, commandComma]
	}

	@objc func handleKeyCommand(_ keyCommand: UIKeyCommand) {
		switch keyCommand.input {
		case "r" where keyCommand.modifierFlags == .command:
			touchRefreshButton()
		case "r" where keyCommand.modifierFlags == .control:
			let request = URLRequest(url: Constants.NamuWiki.randomURL)
			webView.load(request)
		case "l":
			toolbarItemsProvider.searchActionHandler?()
		case "f":
			findInPage()
		case "y":
			toolbarItemsProvider.bookmarksActionHandler?()
		case "d":
			toolbarItemsProvider.starActionHandler?()
		case "[":
			touchBackButton()
		case "]":
			touchForwardButton()
		case ",":
			coordinator?.presentSettingsForm()
		default:
			break
		}
	}
}

// MARK: - SFSafariViewControllerDelegate
extension RootViewController: SFSafariViewControllerDelegate {

}

extension URL {
	var isNamuWiki: Bool {
		host == "namu.wiki"
	}
}
