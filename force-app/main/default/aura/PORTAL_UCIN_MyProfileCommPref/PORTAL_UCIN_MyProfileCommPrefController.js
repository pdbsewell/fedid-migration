({
    /**
     * Toggle the Email Opt checkbox
     * 
     * @param component The Comm preferences component
     */
    checkEmail : function(component, event, helper) {
        component.set("v.contactCommPref.HasOptedOutOfEmail", !(component.get("v.contactCommPref.HasOptedOutOfEmail")));
    },
    
    /**
     * Toggle the Phone Opt checkbox
     * 
     * @param component The Comm preferences component
     */
    checkDNC : function(component, event, helper) {
        component.set("v.contactCommPref.DoNotCall", !(component.get("v.contactCommPref.DoNotCall")));
    },

    /**
     * Toggle the SMS Opt checkbox
     * 
     * @param component The Comm preferences component
     */
    checkSMS : function(component, event, helper) {
        component.set("v.contactCommPref.SMS_Opt_Out__c", !(component.get("v.contactCommPref.SMS_Opt_Out__c")));
    },

    /**
     * Toggle the Direct Mail Opt checkbox
     * 
     * @param component The Comm preferences component
     */
    checkMail : function(component, event, helper) {
        component.set("v.contactCommPref.Direct_Mail_Opt_Out__c", !(component.get("v.contactCommPref.Direct_Mail_Opt_Out__c")));
    },

    /**
     * Toggle the Volunteer at Monash checkbox
     * 
     * @param component The Comm preferences component
     */
    checkVolunteer : function(component, event, helper) {
        component.set("v.contactCommPref.Volunteer_at_Monash__c", !(component.get("v.contactCommPref.Volunteer_at_Monash__c")));
    },

    /**
     * Toggle the Monash Community checkbox
     * 
     * @param component The Comm preferences component
     */
    checkCommunity : function(component, event, helper) {
        component.set("v.contactCommPref.Monash_Community__c", !(component.get("v.contactCommPref.Monash_Community__c")));
    },

    /**
     * Toggle the Monash Corporate checkbox
     * 
     * @param component The Comm preferences component
     */
    checkCorporate : function(component, event, helper) {
        component.set("v.contactCommPref.Monash_Corporate__c", !(component.get("v.contactCommPref.Monash_Corporate__c")));
    },

    /**
     * Toggle the Research with Monash checkbox
     * 
     * @param component The Comm preferences component
     */
    checkResearch : function(component, event, helper) {
        component.set("v.contactCommPref.Research_with_Monash__c", !(component.get("v.contactCommPref.Research_with_Monash__c")));
    },

    /**
     * Toggle the Partner with Monash checkbox
     * 
     * @param component The Comm preferences component
     */
    checkPartner : function(component, event, helper) {
        component.set("v.contactCommPref.Partner_with_Monash__c", !(component.get("v.contactCommPref.Partner_with_Monash__c")));
    },

    /**
     * Toggle the Giving to Monash checkbox
     * 
     * @param component The Comm preferences component
     */
    checkGiving : function(component, event, helper) {
        component.set("v.contactCommPref.Giving_to_Monash__c", !(component.get("v.contactCommPref.Giving_to_Monash__c")));
    },

    /**
     * Toggle the Study at Monash checkbox
     * 
     * @param component The Comm preferences component
     */
    checkStudy : function(component, event, helper) {
        component.set("v.contactCommPref.Study_at_Monash__c", !(component.get("v.contactCommPref.Study_at_Monash__c")));
    }
})