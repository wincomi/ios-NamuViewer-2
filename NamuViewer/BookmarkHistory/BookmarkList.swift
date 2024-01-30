//
//  BookmarkList.swift
//  NamuViewer
//

import SwiftUI
import Combine
import COMIKit
import SPIndicator

struct BookmarkList: View {
	typealias RowItem = BookmarkHistoryTabView.RowItem

	private let repository = RealBookmarksRepository()

	@Binding var rowItems: [RowItem]
	@State private var editMode: EditMode = .inactive
	@State private var tabBarControler: UITabBarController?
	@State private var isActionSheetPresented = false

	var onSelectItem: (String) -> Void
	var dismissAction: () -> Void

	var body: some View {
		Group {
			if rowItems.isEmpty {
				ZStack {
					Color(UIColor.systemGroupedBackground)
						.edgesIgnoringSafeArea(.all)
					EmptyDataView(
						title: "즐겨찾기가 비어있습니다.",
						description: "하단의 별 버튼을 이용하여 자주 찾는 문서를 즐겨찾기에 추가해보세요."
					)
				}
			} else {
				List {
					Section(footer: sectionFooter) {
						ForEach(rowItems, content: rowContent)
							.onDelete(perform: remove)
							.onMove(perform: move)
					}
				}.modifier(CompatibleInsetGroupedListStyle())
			}
		}
		.navigationBarTitle("즐겨찾기", displayMode: .large)
		.navigationBarItems(leading: leadingButton, trailing: trailingButtons)
		.environment(\.editMode, $editMode)
		.onReceive(Just(editMode)) { editMode in
			self.tabBarControler?.tabBar.isHidden = editMode == .active
		}
		.introspectTabBarController { tabBarControler in
			self.tabBarControler = tabBarControler
		}
	}

	func rowContent(_ rowItem: RowItem) -> some View {
		Button {
			onSelectItem(rowItem.text)
			dismissAction()
		} label: {
			CompatibleLabel {
				Text(rowItem.text)
					.lineLimit(1)
					.foregroundColor(Color(UIColor.label))
			} icon: {
				Image(systemName: "doc.text")
					.imageScale(.large)
					.foregroundColor(.accentColor)
			}
		}
		.modifier(CopyContextMenuModifier(text: rowItem.text))
	}

	@ViewBuilder var sectionFooter: some View {
		if AppSettings.shared.useIcloudBookmarks {
			CompatibleLabel("iCloud 동기화를 사용하고 있습니다.", systemImage: "checkmark.icloud")
		} else {
			CompatibleLabel("iCloud 동기화가 비활성화되어 있습니다.", systemImage: "xmark.icloud")
		}
	}

	func remove(at offsets: IndexSet) {
		var rowItemsCopy = self.rowItems
		rowItemsCopy.remove(atOffsets: offsets)

		store(rowItems: rowItemsCopy) {
			self.rowItems.remove(atOffsets: offsets)
		}
	}

	func removeAll() {
		switch repository.removeAll() {
		case .success():
			self.rowItems = []
			editMode = .inactive
		case .failure(let error):
			SPIndicator.present(title: Constants.L10n.errorOccured, message: error.localizedDescription, haptic: .error)
		}
	}

	func move(from source: IndexSet, to destination: Int) {
		var rowItemsCopy = self.rowItems
		rowItemsCopy.move(fromOffsets: source, toOffset: destination)

		store(rowItems: rowItemsCopy) {
			self.rowItems.move(fromOffsets: source, toOffset: destination)
		}
	}

	private func store(rowItems: [RowItem], completion: () -> Void) {
		let bookmarks = rowItems.map { $0.text }

		switch repository.store(bookmarks: bookmarks) {
		case .success():
			completion()
		case .failure(let error):
			SPIndicator.present(title: Constants.L10n.errorOccured, message: error.localizedDescription, haptic: .error)
		}
	}

	@ViewBuilder var leadingButton: some View {
		if !rowItems.isEmpty {
			EditButton()
		}
	}

	// TODO: - iOS 13 Fix
	var trailingButtons: some View {
		HStack(spacing: 24) {
			if editMode == .active {
				removeAllButton
					.disabled(rowItems.isEmpty)
					.actionSheet(isPresented: $isActionSheetPresented) {
						ActionSheet(
							title: Text("북마크를 모두 지우시겠습니까?"),
							message: Text("지운 후 복구할 수 없습니다."),
							buttons: [
								.destructive(Text("모두 지우기"), action: removeAll),
								.cancel()
							]
						)
					}
			} else {
                backupButton
                    .disabled(rowItems.isEmpty)
				dismissButton
			}
		}.animation(nil)
	}

	var backupButton: some View {
		Button {
			let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
			let filePath = cachesDirectory.appendingPathComponent("나무위키_뷰어_즐겨찾기.csv")

			guard let csv = repository.convertToCSV() else { return }

			do {
				try csv.write(to: filePath, atomically: false, encoding: .utf8)
				let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
				sceneDelegate?.presentActivityController(activityItems: [filePath])
			} catch {
				print(error.localizedDescription)
			}
		} label: {
			Image(systemName: "square.and.arrow.up")
				.imageScale(.large)
		}
	}

	var removeAllButton: some View {
		Button {
			isActionSheetPresented = true
		} label: {
			Image(systemName: "trash")
				.foregroundColor(Color(UIColor.red))
				.imageScale(.large)
		}
	}

	var dismissButton: some View {
		Button(action: dismissAction) {
			Image(systemName: "xmark")
				.imageScale(.large)
		}
	}
}
