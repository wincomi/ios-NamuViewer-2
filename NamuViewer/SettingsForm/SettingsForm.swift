//
//  SettingsForm.swift
//  NamuViewer
//

import SwiftUI
import WebKit
import SPIndicator

struct SettingsForm: View {
	@EnvironmentObject var appSettings: AppSettings
	let globalTintColorDefaultCases: [UIColor] = [Constants.mainColor, .systemBlue, .systemGreen, .systemIndigo, .systemOrange, .systemPurple, .systemRed, .systemTeal, .systemYellow]
	var onSelectURL: (URL) -> Void
	var dismissAction: () -> Void

	var body: some View {
		Form {
			Section(header: Text("광고 차단"), footer: Text("나무위키 사이트 내 광고를 차단합니다. 활성화 후에도 광고가 나타날 경우 피드백을 보내주세요.")) {
				Toggle(isOn: $appSettings.adBlock) {
					SettingsFormLabel("나무위키 광고 차단", systemImage: "hand.raised.slash")
				}
			}
			Section(header: Text("일반")) {
				Toggle(isOn: $appSettings.enabledHistory) {
					SettingsFormLabel("방문 기록 남기기", systemImage: "clock")
				}
			}

			themeSection

			Section(header: Text("고급"), footer: Text("iCloud 동기화 기능을 사용할 경우 저장된 로컬 즐겨찾기 대신 iCloud에 저장된 즐겨찾기로 대체됩니다. 활성화하기 전에 즐겨찾기를 백업하세요. ")) {
				NavigationLink {
					SchemeList()
				} label: {
					SettingsFormLabel("URL Scheme", systemImage: "link")
				}
				Button {
					WKWebsiteDataStore.default()
						.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0)) {
							SPIndicator.present(title: "캐시를 비웠습니다.", preset: .done, haptic: .success)
						}
				} label: {
					SettingsFormLabel("캐시 비우기", systemImage: "trash")
				}
				Toggle(isOn: $appSettings.useIcloudBookmarks) {
					SettingsFormLabel("즐겨찾기 iCloud 동기화", systemImage: "icloud")
				}
			}

//			Section(header: Text("실험실"), footer: Text("문서에 있는 모든 Youtube 영상을 Youtube 앱에서 볼 수 있도록 변경합니다. 이 방식으로 스크롤시 영상 재생을 막을 수 있습니다.\n앱 재시작 후 적용됩니다.")) {
//				Toggle(isOn: $appSettings.useOpenYoutubeApp) {
//					SettingsFormLabel("Yotubue 앱에서 보기", systemImage: "play.rectangle")
//				}
//			}

			Section(header: Text("나무위키"), footer: Text("나무위키는 백과사전이 아니며 검증되지 않았거나, 편향적이거나, 잘못된 서술이 있을 수 있습니다.\n나무위키는 위키위키입니다. 여러분이 직접 문서를 고칠 수 있으며, 다른 사람의 의견을 원할 경우 직접 토론을 발제할 수 있습니다.")) {
				Button {
					dismissAction()
					onSelectURL(URL(string: "https://board.namu.wiki")!)
				} label: {
					SettingsFormLabel("나무위키 게시판", systemImage: "list.dash")
				}
				Button {
					onSelectURL(URL(string: "mailto:support@namu.wiki")!)
				} label: {
					SettingsFormLabel("나무위키 관리자에게 문의", systemImage: "envelope")
				}
				Button {
					dismissAction()
					onSelectURL(URL(string: "https://namu.wiki/Policy")!)
				} label: {
					SettingsFormLabel("이용약관", systemImage: "exclamationmark.shield")
				}
			}

			Section(header: Text("나무위키 뷰어"), footer: Text("이 앱은 나무위키의 공식 앱이 아니므로 나무위키 사이트의 문의사항은 나무위키로 문의하시기 바랍니다.\n나무위키 내의 컨텐츠는 앱 개발자가 보증하지 않습니다.")) {
				Button {
					let url = URL(string: "https://itunes.apple.com/app/id\(AppSettings.appStoreId)?action=write-review")!
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				} label: {
					SettingsFormLabel("앱 리뷰하기", systemImage: "heart")
				}
				Button {
					let subject = "나무뷰어 v\(AppSettings.shortVersionString) 피드백".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
					let url = URL(string: "mailto:\(AppSettings.feedbackMailAddress)?subject=\(subject)")!
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				} label: {
					SettingsFormLabel("앱 피드백 보내기", systemImage: "paperplane")
				}
				Button {
					let url = URL(string: "https://apps.apple.com/developer/id\(AppSettings.developerId)")!
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				} label: {
					SettingsFormLabel("개발자의 모든 앱 보기", systemImage: "square.and.arrow.down")
				}
			}

			Section(header: Text("앱 아이콘 디자이너")) {
				Button {
					let url = URL(string: "https://twitter.com/krevony")!
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				} label: {
					SettingsFormLabel("Kyle(chanu)", systemImage: "paintbrush")
				}
			}
		}
		.modifier(CompatibleInsetGroupedListStyle())
		.navigationBarTitle("설정", displayMode: .large)
		.navigationBarItems(trailing: dismissButton)
	}

	var themeSection: some View {
		Section(header: Text("테마")) {
			HStack(spacing: 4) {
				ForEach(globalTintColorDefaultCases, id: \.self) { globalTintColor in
					Button {
						appSettings.globalTintColor = globalTintColor
					} label: {
						CircleColorView(showBorder: .constant(appSettings.globalTintColor == globalTintColor), uiColor: globalTintColor)
					}
				}
			}
			.buttonStyle(PlainButtonStyle())
			Toggle(isOn: $appSettings.ignoreDarkmode) {
				SettingsFormLabel("다크모드 무시하기", systemImage: "moon")
			}
		}
	}

	var dismissButton: some View {
		Button(action: dismissAction) {
			Image(systemName: "xmark")
				.imageScale(.large)
		}
	}
}
