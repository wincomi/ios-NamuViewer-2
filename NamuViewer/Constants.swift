//
//  Constants.swift
//  NamuViewer
//

import Foundation
import UIKit

enum Constants {
	static let mainColor = UIColor(red: 0.00, green: 0.51, blue: 0.46, alpha: 1.00)
	static let bookmarksFileName = "bookmarksFile"
	static let historiesFileName = "historiesFile"

	enum L10n {
		static let errorOccured = "에러가 발생하였습니다."
	}
	
	enum NamuWiki {
		static let mainURL = URL(string: "https://namu.wiki/")!
		static let randomURL = URL(string: "https://namu.wiki/random")!
		static func documentURL(name: String) -> URL {
			URL(string: "https://namu.wiki/go/\(name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")")!
		}

		static func searchURL(searchText: String) -> URL {
			URL(string: "https://namu.wiki/Search?q=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")")!
		}

		static let homeDocumentTitle = "나무위키:대문"

		enum Selector {
			static let searchInput = "document.querySelector('nav>form input[type=search]')"
			static let documentTitle = "document.querySelectorAll('article > div + h1 > a[href]')[0].innerText.trim()"
			static let tableOfContents = "document.querySelector('#toc > div').innerHTML"
			static let theseedSetting = "document.getElementsByClassName('ion-ios-cog')[0]"
			static let theseedSettingModal = "document.querySelector(\"div[data-modal='theseed-setting']\")"
			static let theseedSettingModalDismissButton = "document.querySelector(\"div[data-modal='theseed-setting'] > div > .theseed-fix-dialog > .s > button\")"
		}
	}

	enum JavaScript {
		static let findInPage = "function _namuviewer_find_in_page(text){/*var text=prompt(\"검색할 항목을 입력하세요:\",\"\");*/if(text==null||text.length==0){alert(\"검색 결과가 없습니다.\")}var spans=document.getElementsByClassName(\"labnol\");if(spans){for(var i=0;i<spans.length;i++){spans[i].style.backgroundColor=\"transparent\"}}function searchWithinNode(node,te,len){var pos,skip,spannode,middlebit,endbit,middleclone;skip=0;if(node.nodeType==3){pos=node.data.indexOf(te);if(pos>=0){spannode=document.createElement(\"span\");spannode.setAttribute(\"class\",\"labnol\");spannode.style.backgroundColor=\"yellow\";middlebit=node.splitText(pos);endbit=middlebit.splitText(len);middleclone=middlebit.cloneNode(true);spannode.appendChild(middleclone);middlebit.parentNode.replaceChild(spannode,middlebit);skip=1}}else if(node.nodeType==1&&node.childNodes&&node.tagName.toUpperCase()!=\"SCRIPT\"&&node.tagName.toUpperCase!=\"STYLE\"){for(var child=0;child<node.childNodes.length;++child){child=child+searchWithinNode(node.childNodes[child],te,len)}}return skip}searchWithinNode(document.body,text,text.length)}"

		static let pushStateChanged = "function track(t,s){return function(){return s.apply(this,arguments),t.apply(this,arguments)}}history.pushState=track(history.pushState,function(t,s,e){webkit.messageHandlers.pushStateChanged.postMessage(e)});"

		/// https://stackoverflow.com/questions/3522090/event-when-window-location-href-changes
		static let locationHrefChanged = """
var oldHref = document.location.href;
window.onload = function() {
 var bodyList = document.querySelector("body");
 var observer = new MutationObserver(function(mutations) {
  mutations.forEach(function(mutation) {
   if (oldHref != document.location.href) {
 oldHref = document.location.href;
 webkit.messageHandlers.locationHrefChanged.postMessage(oldHref);
   }
  });
 });

 var config = {
  childList: true,
  subtree: true
 };

 observer.observe(bodyList, config);
};
"""
		static let youtubeFix = """
Array.from(document.getElementsByClassName('wiki-youtube')).forEach( (element) => {
	var youtubeId = element.src.substring(element.src.lastIndexOf('/') + 1);
	element.outerHTML = '<button type="button" class="_namuViewer-youtube-link" style="background: black;display: block;padding: 5px 5px 10px 5px;font-size: 1.1em;color: red;font-weight: bold;text-decoration: none;text-align: center;border: 0;width: 100%" onclick="webkit.messageHandlers.openYoutube.postMessage(\\'' + youtubeId + '\\');"><img src="https://img.youtube.com/vi/' + youtubeId + '/hqdefault.jpg" style="max-width:100%" /><br>▶ Youtube 앱에서 보기</a>';
});
"""

		static let adBlock = "var style = document.createElement('style');style.innerHTML = '#search-ad { display: none; }';document.head.appendChild(style);"

		static let disableMemberMenu = """
document.querySelector('a[title="Member menu"]').remove();
"""
	}
}
