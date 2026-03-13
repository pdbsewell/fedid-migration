({
	doBrowserCheck : function(component, event, helper) {
		var isChrome = false;
		var ua = navigator.userAgent;
		var browser = /Edge\/\d+/.test(ua) ? 'ed' : /MSIE 9/.test(ua) ? 'ie9' : /MSIE 10/.test(ua) ? 'ie10' : /MSIE 11/.test(ua) ? 'ie11' : /MSIE\s\d/.test(ua) ? 'ie?' : /rv\:11/.test(ua) ? 'ie11' : /Firefox\W\d/.test(ua) ? 'ff' : /Chrome\W\d/.test(ua) ? 'gc' : /Chromium\W\d/.test(ua) ? 'oc' : /\bSafari\W\d/.test(ua) ? 'sa' : /\bOpera\W\d/.test(ua) ? 'op' : /\bOPR\W\d/i.test(ua) ? 'op' : typeof MSPointerEvent !== 'undefined' ? 'ie?' : '';
		if(browser == 'gc' || navigator.userAgent.match('CriOS')) {
			isChrome = true;
		}
		component.set("v.isChrome", isChrome);
	},

	closeMessage: function(component, event, helper) {
		console.log('closing message...');
		var cmpTarget = component.find('message-container');
        $A.util.addClass(cmpTarget, 'slds-hide');

	}
})