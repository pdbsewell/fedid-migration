/*******************************************************************************
* @author       Russell Cadapan
* @date         11/11/2019
* @description  Service class for preferenceCenter LWC
* @revision     1.0
*******************************************************************************/
public with sharing class PreferenceCentreServices {

    // String literal for Undefined
    public static final String Undefined  = 'undefined';

    /*
    * Method Name: fetchData
    * Description: method to query and generate the data object for the LWC
    */
    @AuraEnabled(cacheable=true)
    public static PreferenceCentreData fetchData(String myAffiliation){

        PreferenceCentreData thisData;

        try{
            Id portalUserContactId = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1].ContactId;
            thisData = new  PreferenceCentreData(portalUserContactId, myAffiliation);
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, String.valueOf(PreferenceCentreServices.class)+' - Unexpected error occured: '+ e);
            ExLog.add('Preference Centre','PreferenceCentreData','fetchData', e);
        }

        return thisData;
    }


    /*
    * Method Name: saveContact
    * Description: method to save the contact object
    */
    @AuraEnabled
    public static void saveContact(Contact con, String reason, String source){
        con.Last_Consent_Updated_Source__c = source;
        con.Last_Consent_Updated_Date__c = System.now();
        if(String.isNotBlank(reason)){
            con.Last_Consent_Updated_Reason__c = reason;
        }
		
		// perform dml via non-sharing class to run in System context
		PreferenceCentreData.saveContact(con);
    }

    /*
    * Method Name: saveContact
    * Description: method to save the campaign member object
    */
    @AuraEnabled
    public static void saveCampaignMember(List<Object> subs, String reason, String source){

        // list of campaign member to be saved
        List<CampaignMember> membershipToUpdate = new List<CampaignMember>();

        // for each generic object passed by the LWC
        for(Object ob: subs){
            // serialise each object into a generic object
            String json_instance = JSON.serialize(ob);
            // de-serialise and cast each object into a CampaignMember object
            CampaignMember member = (CampaignMember) JSON.deserialize(json_instance, CampaignMember.class);

            // if the campaign membership has been deactivated/activated, capture the following fields
            if(!member.Active__c){
                member.Last_Unsubscribed_Date__c = System.now();
                member.Last_Unsubscribed_Reason__c = reason;
                member.Last_Unsubscribed_Source__c = String.isNotBlank(source)? source : Undefined ;
            }
            else{
                member.Last_Subscribed_Date__c = System.now();
                member.Last_Subscribed_Source__c = String.isNotBlank(source)? source : Undefined;
            }

            // add the campaign membership to the list
            membershipToUpdate.add(member);
        }

        // perform dml via non-sharing class to run in System context
        if(!membershipToUpdate.isEmpty()) PreferenceCentreData.saveMemberships(membershipToUpdate);
    }
}