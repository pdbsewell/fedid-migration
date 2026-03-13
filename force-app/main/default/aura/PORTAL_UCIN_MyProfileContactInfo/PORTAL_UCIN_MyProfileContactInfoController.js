({
    /**
     * Toggle the ability to edit fields on the component
     * 
     * @param component The  Contact Info component
     */
    toggleEdit : function(component, event) {
        component.set("v.isEditing", !component.get("v.isEditing"));
    },

    /**
     * Update the text associated with the field that is changed
     * 
     * @param component     The Contact Info component
     * @param event         The text change which caused the function to run
     */
    updateText : function(component, event) {
        let idToChange = event.getSource().get("v.name");
        switch(idToChange) {
            case 'personalEmail':
                component.set("v.emailMap.Personal.Name", event.getSource().get("v.value"));
                component.set("v.isPersonalEmailValid", event.getSource().get("v.validity").valid);
                break;
            case 'businessEmail':
                component.set("v.emailMap.Business.Name", event.getSource().get("v.value"));
                component.set("v.isBusinessEmailValid", event.getSource().get("v.validity").valid);
                break;
            case 'mobile':
                component.set("v.phoneMap.Mobile.Name", event.getSource().get("v.value"));
                component.set("v.isMobileValid", event.getSource().get("v.validity").valid);
                break;
            case 'homePhone':
                component.set("v.phoneMap.Home.Name", event.getSource().get("v.value"));
                component.set("v.isHomePhoneValid", event.getSource().get("v.validity").valid);
                break;
            case 'workPhone':
                component.set("v.phoneMap.Work.Name", event.getSource().get("v.value"));
                component.set("v.isWorkPhoneValid", event.getSource().get("v.validity").valid);
                break;
            case 'linkedIn':
                component.set("v.socialMap.LinkedIn.Name", event.getSource().get("v.value"));
                break;
            case 'twitter':
                component.set("v.socialMap.Twitter.Name", event.getSource().get("v.value"));
                break;
            case 'weChat':
                component.set("v.socialMap.WeChat.Name", event.getSource().get("v.value"));
                break;
            case 'address1':
                component.set("v.prefAddress.Street_Name__c", event.getSource().get("v.value"));
                break;
            case 'address2':
                break;
            case 'suburb':
                component.set("v.prefAddress.City__c", event.getSource().get("v.value"));
                break;
            case 'state':
                component.set("v.prefAddress.State__c", event.getSource().get("v.value"));
                break;
            case 'postcode':
                component.set("v.prefAddress.Post_Code__c", event.getSource().get("v.value"));
                break;
            default:
                console.log('nothing happened');   
        }
        if(component.get("v.isPersonalEmailValid") && component.get("v.isBusinessEmailValid") &&
           component.get("v.isMobileValid") && component.get("v.isHomePhoneValid") &&component.get("v.isWorkPhoneValid")) {

            component.set("v.isAllValid", true);
        } else {
            component.set("v.isAllValid", false);
        }

    },

    /**
     * Update the country picklist value
     * 
     * @param component The  Contact Info component
     */
    updateCountry : function(component, event) {
        component.set("v.prefAddress.Country2__c", component.find("country").get("v.value"));        
    },

    /**
     * Update the address picklist value
     * 
     * @param component The  Contact Info component
     */
    updateAddressType : function(component, event) {
        component.set("v.prefAddress.Classification__c", component.find("addressType").get("v.value"));
    },

    handleEmailRadio : function(component, event) {
        let value = event.getSource().get("v.id");
        if(value === "personalEmail") {
            component.set("v.preferredMap.email", "personal");
            component.set("v.emailMap.Personal.Is_Primary__c", true);
            component.set("v.emailMap.Business.Is_Primary__c", false);
        } else {
            component.set("v.preferredMap.email", "business");
            component.set("v.emailMap.Personal.Is_Primary__c", false);
            component.set("v.emailMap.Business.Is_Primary__c", true);
        }
    },

    handlePhoneRadio : function(component, event) {
        let value = event.getSource().get("v.id");
        console.log('Phone value:' + value);
        if(value === "mobilePhone") {
            component.set("v.preferredMap.phone", "mobile");
        } else if(value === "homePhone") {
            component.set("v.preferredMap.phone", "home");
        } else {
            component.set("v.preferredMap.phone", "work");
        }
        console.log('preferredMap.phone: ' + component.get("v.preferredMap.phone"));
    }
})