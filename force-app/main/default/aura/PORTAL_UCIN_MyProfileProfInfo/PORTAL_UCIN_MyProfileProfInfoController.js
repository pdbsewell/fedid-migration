({
    /**
     * Toggle the ability to edit fields on the component
     * 
     * @param component The  Professional Info component
     */
    toggleEdit : function(component, event) {
        component.set("v.isEditing", !component.get("v.isEditing"));
        //console.log(JSON.stringify(component.get("v.positionDetails")));
        //console.log(component.get("v.positionDetails"));
    },

    /**
     * Update the text for the position of the user
     * 
     * @param component The  Professional Info component
     */
    updateText : function(component, event) {
        let idToChange = event.getSource().get("v.name");
        switch(idToChange) {
            case 'position':
                component.set("v.positionDetails.position", event.getSource().get("v.value"));
                break;
            case 'orgName':
                component.set("v.positionDetails.orgName", event.getSource().get("v.value"));
                break;
            case 'country':
                component.set("v.businessAddress.Country2__c", event.getSource().get("v.value"));
                break;
            case 'street':
                component.set("v.businessAddress.Street_Name__c", event.getSource().get("v.value"));
                break;
            case 'city':
                component.set("v.businessAddress.City__c", event.getSource().get("v.value"));
                break;
            case 'state':
                component.set("v.businessAddress.State__c", event.getSource().get("v.value"));
                break;
            case 'postcode':
                component.set("v.businessAddress.Post_Code__c", event.getSource().get("v.value"));
                break;
            default:
                console.log('nothing happened');   
        }
    },

    /**
     * Update the country picklist value
     * 
     * @param component The  Professional Info component
     */
    updateCountry : function(component, event) {
        component.set("v.businessAddress.Country2__c", component.find("businessAddress_country").get("v.value"));
    },

    /**
     * Update the industry picklist value
     * 
     * @param component The  Professional Info component
     */
    updateIndustry : function(component, event) {
        component.set("v.positionDetails.orgIndustry", component.find("orgIndustry").get("v.value"));
    }
})