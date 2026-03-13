({
	/**
     * On init, initiate year 
     * 
     * @param component     The Footer component
     */
    onInit : function (component, event, helper) {
        const d = new Date();
        let year = d.getFullYear();
        component.set('v.currentYear',year);
    },
    
    onClickDataConsentSettings:function (component, event, helper) {
        event.preventDefault();
        // Fire the GTM method to collect Data Consent settings
        window.initConsent();
        return false;
    }
})