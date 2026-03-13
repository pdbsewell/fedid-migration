({
    /**
     * On init, load listings
     * 
     * @param component     The Listing Career component
     */
    onInit : function (component, event, helper) {
        helper.loadListingList(component, event);
    }
})