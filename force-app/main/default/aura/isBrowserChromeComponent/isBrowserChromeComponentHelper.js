({
	/**
	* @author 	Nick Guia
	* @date 	22/09/2017
	* @description 	function for checkick mobile devices
	* @param 	mobile : Android / BlackBerry / iOS / Opera / Windows
	* 					 if not provided, checks all devices
	**/
	isMobile : function(mobile) {
		if(mobile) {
			//specific mobile provided
			if(mobile === 'Android') {
				return this.isAndroid();
			} else if(mobile === 'BlackBerry') {
				return this.isBlackBerry();
			} else if(mobile === 'iOS') {
				return this.isIOS();
			} else if(mobile === 'Opera') {
				return this.isOpera();
			} else if(mobile === 'Windows') {
				return this.isWindows();
			}
		} else {
			//check any devices
			return(this.any());
		}
	},

	isAndroid: function() {
        return navigator.userAgent.match(/Android/i);
    },
    isBlackBerry: function() {
        return navigator.userAgent.match(/BlackBerry/i);
    },
    isIOS: function() {
        return navigator.userAgent.match(/iPhone|iPad|iPod/i);
    },
    isOpera: function() {
        return navigator.userAgent.match(/Opera Mini/i);
    },
    isWindows: function() {
        return navigator.userAgent.match(/IEMobile/i);
    },
    any: function() {
        return (this.isAndroid() || this.isBlackBerry() || this.isIOS() || this.isOpera() || this.isWindows());
    },

    /**
	* @author 	Nick Guia
	* @date 	22/09/2017
	* @description 	a robust method of detecting current user's browser, version, or OS
	* @param  	check 'dataBrowser' and 'dataOS' for available comparisons
	**/
    isBrowser : function(browserName, versionName, osName) {
    	//storage of currently known browsers
		var dataBrowser = [{
			string: navigator.userAgent,
			subString: "Chrome",
			identity: "Chrome"
		}, {
			string: navigator.userAgent,
			subString: "OmniWeb",
			versionSearch: "OmniWeb/",
			identity: "OmniWeb"
		}, {
			string: navigator.vendor,
			subString: "Apple",
			identity: "Safari",
			versionSearch: "Version"
		}, {
			prop: window.opera,
			identity: "Opera",
			versionSearch: "Version"
		}, {
			string: navigator.vendor,
			subString: "iCab",
			identity: "iCab"
		}, {
			string: navigator.vendor,
			subString: "KDE",
			identity: "Konqueror"
		}, {
			string: navigator.userAgent,
			subString: "Firefox",
			identity: "Firefox"
		}, {
			string: navigator.vendor,
			subString: "Camino",
			identity: "Camino"
		}, { // for newer Netscapes (6+)
			string: navigator.userAgent,
			subString: "Netscape",
			identity: "Netscape"
		}, {
			string: navigator.userAgent,
			subString: "MSIE",
			identity: "Explorer",
			versionSearch: "MSIE"
		}, {
			string: navigator.userAgent,
			subString: "Gecko",
			identity: "Mozilla",
			versionSearch: "rv"
		}, { // for older Netscapes (4-)
			string: navigator.userAgent,
			subString: "Mozilla",
			identity: "Netscape",
			versionSearch: "Mozilla"
		}];

		var dataOS = [{
			string: navigator.platform,
			subString: "Win",
			identity: "Windows"
		}, {
			string: navigator.platform,
			subString: "Mac",
			identity: "Mac"
		}, {
			string: navigator.userAgent,
			subString: "iPhone",
			identity: "iPhone/iPod"
		}, {
			string: navigator.platform,
			subString: "Linux",
			identity: "Linux"
		}];

		// , versionName, osName
		var browserMatched = true;
		var versionMatched = true;
		var osMatched = true;
		// check browser
		if(browserName) { //check if browserName provided
			var detectedBrowser = this.searchString(dataBrowser) || "An unknown browser";
			console.log('detectedBrowser', detectedBrowser);
			if(browserName != detectedBrowser) {
				browserMatched = false;
			}
		}

		// check version
		// if(versionName) { //check if versionName provided
		// 	var detectedVersion = this.searchVersion(navigator.userAgent) || this.searchVersion(navigator.appVersion) || "an unknown version";
		// 	if(versionName != detectedVersion) {
		// 		console.log('detectedVersion', detectedVersion);
		// 		versionMatched = false;
		// 	}
		// }
		
		// check OS
		if(osName) { //check if osName provided
			var detectedOS = this.searchString(dataOS) || "an unknown OS";
			console.log('detectedOS', detectedOS);
			if(osName != detectedOS) {
				osMatched = false;
			}
		}
		return (browserMatched && versionMatched && osMatched);
    },

    // function for checking browsername or OS 
    searchString: function(data) {
		for (var i = 0; i < data.length; i++) {
			var dataString = data[i].string;
			var dataProp = data[i].prop;
			// var versionSearchString = data[i].versionSearch || data[i].identity;
			if (dataString) {
				if (dataString.indexOf(data[i].subString) != -1) return data[i].identity;
			} else if (dataProp) return data[i].identity;
		}
	},
	// function for checking browser version
	// searchVersion: function(dataString) {
	// 	var index = dataString.indexOf(this.versionSearchString);
	// 	if (index == -1) return;
	// 	return parseFloat(dataString.substring(index + this.versionSearchString.length + 1));
	// },
})