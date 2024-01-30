//
//  HistoryList.swift
//  NamuViewer
//

import SwiftUI
import Combine
import SPIndicator
import COMIKit

struct HistoryList: View {
	typealias RowItem = BookmarkHistoryTabView.RowItem

	private let repository = RealHistoriesRepository()
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
						title: "방문 기록이 비어있습니다.",
						description: "위키를 탐험해보세요! (´･ω･`)"
					)
				}
			} else {
				List {
					Section(header: headerText) {
						ForEach(rowItems, content: rowContent)
							.onDelete(perform: remove)
					}
				}.modifier(CompatibleInsetGroupedListStyle())
			}
		}
		.navigationBarTitle("방문 기록", displayMode: .large)
		.navigationBarItems(leading: leadingButton, trailing: trailingButtons)
		.environment(\.editMode, $editMode)
		.onReceive(Just(editMode)) { editMode in
			self.tabBarControler?.tabBar.isHidden = editMode == .active
		}
		.introspectTabBarController { tabBarControler in
			self.tabBarControler = tabBarControler
		}
	}

	@ViewBuilder var headerText: some View {
		if !AppSettings.shared.enabledHistory {
			Text("방문 기록 남기기 설정이 비활성화되어 있습니다.")
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
				Image(systemName: "clock")
					.imageScale(.large)
					.foregroundColor(.accentColor)
			}
		}.modifier(CopyContextMenuModifier(text: rowItem.text))
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

	private func store(rowItems: [RowItem], completion: () -> Void) {
		let histories = rowItems.map { $0.text }

		switch repository.store(histories: histories) {
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

	// TODO: - iOS13 Fix
	var trailingButtons: some View {
		HStack(spacing: 24) {
			if editMode == .active {
				removeAllButton
					.disabled(rowItems.isEmpty)
					.actionSheet(isPresented: $isActionSheetPresented) {
						ActionSheet(
							title: Text("방문 기록을 모두 지우시겠습니까?"),
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
			let filePath = cachesDirectory.appendingPathComponent("나무위키_뷰어_방문_기록.csv")

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
