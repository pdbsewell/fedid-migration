/**
 * @author       P.Victoriano
 * @date         05/Nov/2021
 * @description  Deactivates the User Record - Use UserDeactivateSchd to schedule CRON
 * @revision
 *               05.Nov.21 P.Victoriano - Create Class
 *               09.Nov.21 P.Victoriano - Added checking on Contact.IT_account_disabled__c 
 **/
public without sharing class UserDeactivateBatch implements Database.Batchable<SObject>,
               Database.RaisesPlatformEvents {
    @TestVisible
    private Id testUserId;
    @TestVisible
    private Boolean forceError = false;
    public UserDeactivateBatch() {}

    public Database.QueryLocator start(Database.BatchableContext BC) {
        if (Test.isRunningTest() && testUserId != null) {
            return Database.getQueryLocator([
                                                SELECT Id,Scheduled_Deactivation__c,Pending_Deactivation__c,Deactivated_DateTime__c,
                                                    IsActive,FederationIdentifier, ProfileId
                                                FROM User WHERE IsActive = true
                                                                           AND UserType != 'CspLitePortal'
                                                                           AND FederationIdentifier != null
                                                                           AND Pending_Deactivation__c = true
                                                                                                         AND Scheduled_Deactivation__c != null
                                                                                                         AND Scheduled_Deactivation__c <= TODAY
                                                                                                         AND Id =: testUserId
                                            ]);
        }
        return Database.getQueryLocator([
                                            SELECT Id,Scheduled_Deactivation__c,Pending_Deactivation__c,Deactivated_DateTime__c,
                                                IsActive,FederationIdentifier, ProfileId
                                            FROM User WHERE IsActive = true
                                                                       AND UserType != 'CspLitePortal'
                                                                       AND FederationIdentifier != null
                                                                       AND Pending_Deactivation__c = true
                                                                                                     AND Scheduled_Deactivation__c != null
                                                                                                     AND Scheduled_Deactivation__c <= TODAY
                                        ]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        //
        Map<String, Contact> m_contacts = new Map<String,Contact>();
        Set<String> fedIs = new Set<String>();
        List<User> users = (List<User>) scope;
        //Retrieve FederationIdentifier for Contact Match
        for (User usr:users) {
            if (String.isNotBlank(usr.FederationIdentifier)) {
                fedIs.add(usr.FederationIdentifier);
            }
        }
        //Build Map to verify It Account Disabled is true
        if (fedIs.isEmpty() == false) {
            List<Contact> contacts = [SELECT Id, Authcate__c, IT_account_disabled__c FROM Contact WHERE Authcate__c IN:fedIs];
            if (contacts != null) {
                for (Contact con:contacts) {
                    m_contacts.put(con.Authcate__c,con);
                }
            }
        }
        for (User usr:users) {
            //Reset Values
            usr.Pending_Deactivation__c = false;
            usr.Scheduled_Deactivation__c = null;
            usr.Deactivated_DateTime__c = null;
            //Disable by default
            Boolean isItAccountDisabled = true;
            if(m_contacts.containsKey(usr.FederationIdentifier)){
                isItAccountDisabled = m_contacts.get(usr.FederationIdentifier).IT_account_disabled__c;
            }
            //Determine based on Contact.IT_account_disabled__c 
            if(isItAccountDisabled){
                usr.IsActive = false;
                usr.Deactivated_DateTime__c = System.now();
            }
            //Forced Exception
            if (Test.isRunningTest() && forceError == true) {
                //Force Exception
                usr.ProfileId = null;
            }
        }
        Database.SaveResult[] srList = Database.update(users, false);
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess() == false) {
                for (Database.Error err: sr.getErrors()) {
                    LogUtilityException.addLogEvent('UserDeactivateBatch Error', sr, err, UserDeactivateBatch.class.getName());
                }
            }
        }
        LogUtilityException.publishAll();
    }

    public void finish(Database.BatchableContext BC) {
        System.debug(
            String.format('{0} Finished', new List<String> {
            UserDeactivateBatch.class.getName()
        })
            );
    }
}