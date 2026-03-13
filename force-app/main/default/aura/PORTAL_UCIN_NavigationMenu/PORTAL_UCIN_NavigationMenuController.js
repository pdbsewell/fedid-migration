({
    /**
     * Determine which page has been loaded and set the appropriate tab as selected
     * 
     * @param component     The NavigationMenu component
     * @param helper        The NavigationMenu helper class
     */
	doInit : function(component, event, helper) {
        component.set("v.loaded", false);

        let action = component.get("c.SERVER_getUserType");
        action.setCallback(this, function(response) {
            component.set("v.loggedIn", response.getReturnValue());
            helper.setCurrentPageActive(component, helper);
            component.set("v.loaded", true);
        });

        $A.enqueueAction(action);

        let getBaseURL = component.get("c.SERVER_getDomainName");
        getBaseURL.setCallback(this, function(response) {
            component.set("v.baseURL", response.getReturnValue());
        });

        $A.enqueueAction(getBaseURL);

        let getContactID = component.get("c.SERVER_getContactId");
        getContactID.setCallback(this, function(response) {
            component.set("v.contactId", response.getReturnValue());
        });

        $A.enqueueAction(getContactID);
    },
    
    /**
     * Perform actions on url change
     */
    handleRouteChange : function(component, event, helper) {
        helper.setCurrentPageActive(component, helper);
    },
    
    /**
     * Perform logout actions on button press
     */
    doLogout : function(component, event, helper) {
		var baseURL = component.get("v.baseURL");
		window.location.replace(baseURL + '/secur/logout.jsp?retUrl=' + baseURL + '/s/login');
	},
	
	doLogIn: function(component, event, helper) {
		var baseURL = component.get("v.baseURL");
		window.location.replace(baseURL + '/s/login/');
	},
    
    onNavHBMenuIconClick : function(component, event, helper) {
        var navMobile = component.find("navMobile");
        var hbmenuCtn = component.find("hbmenuCtn");
        if ($A.util.hasClass(hbmenuCtn, "ucin-hm-on")) {
            $A.util.removeClass(hbmenuCtn, "ucin-hm-on");
            $A.util.addClass(navMobile, "hidden");
        } else {
            $A.util.addClass(hbmenuCtn, "ucin-hm-on");
            $A.util.removeClass(navMobile, "hidden");
        }
    },

    /**
     * Toggle My Details mobile submenus
     * 
     * @param component              The NavigationMenu component 
     */
	onToggleMyDetailsMobileTab : function(component, event, helper) {
        var showMydetails_m = component.find("showMydetails_m");
        var showProfile_m = component.find("showProfile_m");
        var showPreferenceCentre_m = component.find("showPreferenceCentre_m");
        var showVolunteerPreferences_m = component.find("showVolunteerPreferences_m");
        var showMessages_m = component.find("showMessages_m");
        var showMydetailsToggleIco_m = component.find("showMydetailsToggleIco_m");
        
        if ($A.util.hasClass(showMydetails_m, "submenu-collapsed")) {
            $A.util.removeClass(showMydetails_m, "submenu-collapsed");
            $A.util.removeClass(showProfile_m, "hidden");
            $A.util.removeClass(showPreferenceCentre_m, "hidden");
            $A.util.removeClass(showVolunteerPreferences_m, "hidden");
            $A.util.removeClass(showMessages_m, "hidden");
            $A.util.removeClass(showLibrary_m, "hidden");
            $A.util.removeClass(showMydetailsToggleIco_m, "toggle-collapsed");
			$A.util.addClass(showMydetailsToggleIco_m, "toggle-expanded");            
        } else {
            $A.util.addClass(showMydetails_m, "submenu-collapsed");
            $A.util.addClass(showProfile_m, "hidden");
            $A.util.addClass(showPreferenceCentre_m, "hidden");
            $A.util.addClass(showVolunteerPreferences_m, "hidden");
            $A.util.addClass(showMessages_m, "hidden");
            $A.util.removeClass(showLibrary_m, "hidden");
			$A.util.addClass(showMydetailsToggleIco_m, "toggle-collapsed");
            $A.util.removeClass(showMydetailsToggleIco_m, "toggle-expanded");
        }
	},

    /**
     * Toggle My Details desktop submenus
     * 
     * @param component              The NavigationMenu component 
     */
	onToggleMyDetailsDektopTab : function(component, event, helper) {
        var showMydetails_d = component.find("showMydetails_d");
        var navMyDetailsDesktopNav = component.find("navMyDetailsDesktopNav");
        
        if ($A.util.hasClass(showMydetails_d, "submenu-collapsed")) {
            $A.util.removeClass(showMydetails_d, "submenu-collapsed");
            $A.util.removeClass(navMyDetailsDesktopNav, "hidden");           
        } else {
            $A.util.addClass(showMydetails_d, "submenu-collapsed");
            $A.util.addClass(navMyDetailsDesktopNav, "hidden");
        }
	}
})