try {
  document.execCommand("BackgroundImageCache", false, true);
} catch(err) {}

function addDOMLoadEvent(f){if(!window.__ADLE){var n=function(){if(arguments.callee.d)return;arguments.callee.d=true;if(window.__ADLET){clearInterval(window.__ADLET);window.__ADLET=null}for(var i=0;i<window.__ADLE.length;i++){window.__ADLE[i]()}window.__ADLE=null};if(document.addEventListener)document.addEventListener("DOMContentLoaded",n,false);/*@cc_on @*//*@if (@_win32)document.write("<scr"+"ipt id=__ie_onload defer src=//0><\/scr"+"ipt>");var s=document.getElementById("__ie_onload");s.onreadystatechange=function(){if(this.readyState=="complete")n()};/*@end @*/if(/WebKit/i.test(navigator.userAgent)){window.__ADLET=setInterval(function(){if(/loaded|complete/.test(document.readyState)){n()}},10)}window.onload=n;window.__ADLE=[]}window.__ADLE.push(f)}


function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node == null )
		node = document;
	if ( tag == null )
		tag = '*';
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
	for (i = 0, j = 0; i < elsLen; i++) {
		if ( pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}


function fixlayout_ff () {
	var title_wrapper_right =  getElementsByClass('title_wrapper_right',null,null);
	if(!title_wrapper_right.length) {return false}
	for(i=0; i<title_wrapper_right.length; i++) {
		var this_element = title_wrapper_right[i];
		var this_element_parent = title_wrapper_right[i].parentNode;
		this_element.style.display = 'none';
		title_wrapper_right[i].parentNode.removeChild(title_wrapper_right[i]);
		this_element_parent.appendChild(this_element);
		
		this_element.style.display = 'block';
		
	}
}


window.onresize = function () {
	fixlayout_ff ();
}





 