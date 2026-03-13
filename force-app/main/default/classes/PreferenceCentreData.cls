/*******************************************************************************
* @author       Russell Cadapan
* @date         11/11/2019
* @description  Service class DTO for preferenceCenter LWC
* @revision     1.0
*******************************************************************************/

public without sharing class PreferenceCentreData {
    // Subscription List Campaign record type
    public static final Id CampaignSubscriptionRecTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Subscription List').getRecordTypeId();

    // Global String Affiliation
    public static final String GlobalAffiliation = 'Global';

    @AuraEnabled
    public Contact myCurrentContact; // contact object
    @AuraEnabled
    public List<CampaignMember> myCurrentSubscriptions; // contact's campaign membership(s)
    @AuraEnabled
    public Map<String, Boolean> myApplicableConsent; // applicable consent map
    @AuraEnabled
    public Map<String, Consent_Display_Mapping__mdt> fieldToDisplayMap; // consent field and its labels
    @AuraEnabled
    public List<String> optOutReasons; //opt out reasons

    // constructor
    public PreferenceCentreData(Id contactId, String affiliation){
        String myAffiliation = String.isBlank(affiliation) ? 'Global' : affiliation;

        // get the Contact record and with the relevant fields
        Contact myContact = [SELECT Id,
                Commercial_Opt_Out__c,
                HasOptedOutOfEmail,
                SMS_Opt_Out__c,
                DoNotCall,
                Direct_Mail_Opt_Out__c,
                Study_at_Monash__c,
                Volunteer_at_Monash__c,
                Partner_with_Monash__c,
                Giving_to_Monash__c,
                Work_at_Monash__c,
                Monash_Corporate__c,
                Monash_Community__c,
                Research_with_Monash__c,
                Last_Consent_Updated_Date__c,
                Last_Consent_Updated_Source__c,
                Last_Consent_Updated_Reason__c,
                (SELECT Id,
                        Active__c,
                        Last_Subscribed_Date__c,
                        Last_Subscribed_Source__c,
                        Last_Unsubscribed_Date__c,
                        Last_Unsubscribed_Reason__c,
                        Last_Unsubscribed_Source__c,
                        Campaign.External_Label__c,
                        Campaign.External_Description__c,
                        Campaign.Applicable_Affiliations__c
                FROM CampaignMembers
                WHERE Campaign.RecordTypeId =: CampaignSubscriptionRecTypeId
                AND Campaign.Externally_Visible__c = TRUE
                AND Campaign.IsActive = TRUE
                AND ContactId =: contactId
                ORDER BY Active__c DESC, Campaign.Name ASC)
        FROM Contact WHERE Id =: contactId];

        // assign the contact record to the data
        this.myCurrentContact = myContact;

        if(!myContact.CampaignMembers.isEmpty()){
            this.myCurrentSubscriptions = new List<CampaignMember>();

            // retrieve only the memberships that are applicable to the affiliation
            for(CampaignMember cm: myContact.CampaignMembers){
                if(cm.Campaign.Applicable_Affiliations__c != null &&
                        (String.isNotBlank(myAffiliation) &&
                                String.valueOf(cm.Campaign.Applicable_Affiliations__c).contains(myAffiliation))
                        || (myAffiliation == GlobalAffiliation || String.isBlank(myAffiliation))){
                    this.myCurrentSubscriptions.add(cm);
                }
            }
        }

        if(this.myCurrentSubscriptions != null && this.myCurrentSubscriptions.isEmpty()) this.myCurrentSubscriptions = null;

        this.myApplicableConsent = getConsentsMap(myAffiliation);
        this.fieldToDisplayMap = getFieldToLabelMapping();
        this.optOutReasons = getOptOutReasons();
    }

    /*
    * Method Name: getConsentsMap
    * Description: method to query the consent mapping for each affiliation stored in the custom metadata (Affiliation_to_Consent_Mapping__mdt)
    */
    public static Map<String, Boolean> getConsentsMap(String myAffiliation){
        // initialise map container
        Map<String, Boolean> consentMap = new Map<String, Boolean>();

        // get the custom metadata schema
        Schema.DescribeSObjectResult afSchema = Affiliation_to_Consent_Mapping__mdt.sObjectType.getDescribe();

        // list of schema field names
        List<String> apiNames = new List<String>();

        // get all the boolean fields
        for(string apiName : afSchema.fields.getMap().keySet()){
            Schema.SObjectField field = afSchema.fields.getMap().get(apiName);
            String fieldType = String.valueOf(field.getDescribe().getType());
            if(fieldType == 'Boolean'){
                apiNames.add(apiName);
            }
        }

        // generate the query String
        String queryString = 'SELECT Id';

        for(String fieldName: apiNames){
            queryString += ',';
            queryString += fieldName;
        }

        queryString += ' FROM Affiliation_to_Consent_Mapping__mdt';
        queryString += ' WHERE MasterLabel =: myAffiliation';

        // query the data
        List<Affiliation_to_Consent_Mapping__mdt> mappingConfig = Database.query(queryString);

        // generate the consent map
        for(String fieldName: apiNames){
            consentMap.put(fieldName, (Boolean) mappingConfig[0].get(fieldName));
        }

        return consentMap;
    }

    /*
    * Method Name: getFieldToLabelMapping
    * Description: a constant map of contact consent fields and their respective page label
    */
    public static Map<String, Consent_Display_Mapping__mdt> getFieldToLabelMapping(){

        Map<String, Consent_Display_Mapping__mdt> fieldToDisplayMap = new Map<String, Consent_Display_Mapping__mdt>();

        for(Consent_Display_Mapping__mdt mdt: [SELECT Source_Field__r.QualifiedApiName, Display_Label__c, Display_Description__c FROM Consent_Display_Mapping__mdt]){
            fieldToDisplayMap.put(mdt.Source_Field__r.QualifiedApiName, mdt);
        }
        return fieldToDisplayMap;
    }

    /*
    * Method Name: getOptOutReasons
    * Description: list of opt out reasons stored in a custom metadata
    */
    public static List<String> getOptOutReasons(){
        List<String> reasons = new List<String>();

        for(Consent_Opt_Out_Reasons__mdt setting: [SELECT MasterLabel, Value__c, Order__c FROM Consent_Opt_Out_Reasons__mdt ORDER BY Order__c ASC]){
            reasons.add(setting.Value__c);
        }
        return reasons;
    }
	
	/*
    * Method Name: saveMembership
    * Description: save list of Campaign Member records
    */
    public static void saveMemberships(List<CampaignMember> listMemberships){
        try{
            update listMemberships;
        }
        catch(Exception e){
            ExLog.add('Preference Centre','CampaignMember','saveMemberships', e);
            throw e;
        }
    }
	
	/*
    * Method Name: saveContact
    * Description: save contact record
    */
    public static void saveContact(Contact contactRecord){
        try{
            update contactRecord;
        }
        catch(Exception e){
            ExLog.add('Preference Centre','Contact','saveContact', e);
            throw e;
        }
    }
	
}