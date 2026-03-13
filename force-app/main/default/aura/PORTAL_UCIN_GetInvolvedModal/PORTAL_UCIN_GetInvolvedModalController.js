({
    /**
     * Closes the GetInvolved Modal
     * 
     * @param  component  The GetInvolvedModal component
     */
	closeSignupModal : function(component) {
		component.find("overlayModal").notifyClose();
	}
})