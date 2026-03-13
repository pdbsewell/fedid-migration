({

    /**
     * Checks current page and sets appropriate navigation tab as selected
     * 
     * @param component     The NavigationMenu component 
     * @param helper        This helper class
     *  
     */
    
    setCurrentPageActive : function(component, helper) {
        let pageName = window.location.href;
		let compToChange = component.find("showHome");
		helper.clearNavTabs(component, helper);

		if(pageName.includes("events")) {
			compToChange = component.find("showEvents");
		} else if(pageName.includes("get-involved")) {
			compToChange = component.find("showGetInvolved");
        } else if(pageName.includes("benefits")) {
			compToChange = component.find("showBenefits");
		} else if(pageName.includes("directory")) {
			compToChange = component.find("showDirectory");
		} else if(pageName.includes("careers")) {
			compToChange = component.find("showCareers");
		} else if(pageName.includes("donations") || pageName.includes("give")) {
			compToChange = component.find("showDonations");
		} else if(pageName.includes("library")) {
			compToChange = component.find("showLibrary");
		}else if (pageName.includes("myprofile") || pageName.includes("messages")) {
			compToChange = null;
		}
		helper.activateNavTab(compToChange, true);
    },
    
    /**
     * Resets the apppearance of all navigation tabs
     * 
     * @param component     The NavigationMenu component 
     * @param helper        This helper class
     */
	clearNavTabs : function(component, helper) {
		let showMonashHome = component.find("showHome");
		helper.activateNavTab(showMonashHome, false);
		
		let showEvents = component.find("showEvents");
		helper.activateNavTab(showEvents, false);
		
		let showGetInvolved = component.find("showGetInvolved");
		helper.activateNavTab(showGetInvolved, false);
		
		let showDirectory = component.find("showDirectory");
		helper.activateNavTab(showDirectory, false);
		
		let showCareers = component.find("showCareers");
		helper.activateNavTab(showCareers, false);
		
		let showDonations = component.find("showDonations");
		helper.activateNavTab(showDonations, false); 

		let showLibrary = component.find("showLibrary");
		helper.activateNavTab(showLibrary, false);
	}, 

    /**
     * Updates the appearance of the selected tab
     * 
     * @param thisComponent              The tab which is being updated
     * @param {Boolean} isCurrentPage    Determines how the tab should appear 
     */
	activateNavTab : function(thisComponent, isCurrentPage) {
		if(isCurrentPage) {
			$A.util.addClass(thisComponent, 'bg-bg-grey selected-tab-black');
		} else {
			$A.util.removeClass(thisComponent, 'bg-bg-grey selected-tab-black');
		}
	}
})