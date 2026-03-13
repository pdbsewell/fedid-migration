/**
 * @description Service class for Agent Portal specific applications
 * @author      Nick Guia
 * @date        FEB.20.2024       
 */
public virtual with sharing class AgentPortalApplicationService extends ApplicationService {
    
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public AgentPortalApplicationService() {}

    /**
     * @description @description populate fields that track the potential recursion of 
     *  Agent send to Applicant > Applicant reverts back to Agent > and so on...
     *  (moved from AgentPortalPayload to centralise the logic)
     * @param app   
     * @return `Application__c`
     */
    public Application__c populateRevisionFields(Application__c app) {
        if(app.Sent_to_student_for_review_Timestamp__c != null) {
            app.Agent_Edits_After_Applicant_Acceptance__c = true;
        }
        app.Sent_to_student_for_review_Timestamp__c = Datetime.now();
        return app;
    }

    /**
     * @description overload; additionally collects Delegator Org Unit Codes within the Applications
     * @param appList 
     * @return `List<Application__c>`
     */
    public List<Application__c> delegateApplication(List<Application__c> appList) {
        Set<String> delegatorExternalIds = new Set<String>();

        for(Application__c iApp : appList) {
            delegatorExternalIds.add(iApp.Delegator_Org_Unit_Code__c);
        }

        return delegateApplication(appList, delegatorExternalIds);
    }

    /**
     * @description Reassigns an Application to the Agency indicated in the Delegator_Org_Unit_Code__c field.
     *  This method is typically used in trigger handlers where delegatorExternalIds collection can also be done
     *  within the Trigger context in order to reduce iteration. Otherwise, use the overload.
     * @param appList : List of Application records
     * @param delegatorExternalIds : Collection of Delegator_Org_Unit_Code__c, within the application list
     * @return `List<Application__c>`
     */
    public List<Application__c> delegateApplication(List<Application__c> appList, Set<String> delegatorExternalIds) {

        if(appList != null && !appList.isEmpty() && delegatorExternalIds != null && !delegatorExternalIds.isEmpty()) {

            Map<String, Account> agencyByExternalId = new Map<String, Account>();
            Map<Id, Id> userIdByContactId = new Map<Id, Id>();
            // Set<Id> branchManagerContactIds = new Set<Id>();
            
            Id agencyRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                    .get('Agency')
                                    .getRecordTypeId();

            // get accounts based on Org Unit Code
            for(Account iAcc : [SELECT Id, Callista_Org_Unit_Code__c,
                                    (SELECT Id FROM Contacts WHERE Agency_Contact_Roles__c INCLUDES ('Branch Manager'))
                                FROM Account
                                WHERE RecordTypeId = :agencyRecTypeId
                                AND Callista_Org_Unit_Code__c IN :delegatorExternalIds])
            {
                agencyByExternalId.put(iAcc.Callista_Org_Unit_Code__c, iAcc);
                if(!iAcc.Contacts.isEmpty()) {
                    userIdByContactId.put(iAcc.Contacts[0].Id, null);
                }
            }

            // query users associated to the branch manager so we can transfer the Application ownership to them
            for(User iUser : [SELECT Id, ContactId, AccountId FROM User WHERE ContactId IN :userIdByContactId.keySet()]) {
                userIdByContactId.put(iUser.contactId, iUser.Id);
            }

            // change the Agency of the application to the Account of the Delegator Org Unit code
            for(Application__c iApp : appList) {

                Account newAgency = agencyByExternalId.get(iApp.Delegator_Org_Unit_Code__c);
                
                if(newAgency != null) {

                    iApp.Agent__c = newAgency.Id;
                    /**
                     * unfortunately, this is required because there are some legacy processes 
                     * that treats this field as source of truth rather than the Agency lookup
                     */
                    iApp.Agent_Org_Unit_Code__c = iApp.Delegator_Org_Unit_Code__c; 

                    /**
                     * if the Delegator Agency has a branch manager (which they should), transfer the ownership
                     * of the application to the branch manager to revoke Delegate agency access on the Application 
                     */
                    if(!newAgency.Contacts.isEmpty() && userIdByContactId.get(newAgency.Contacts[0].Id) != null) {
                        iApp.ownerId = userIdByContactId.get(newAgency.Contacts[0].Id);
                    } else {
                        Nebula.Logger.error('Unable to transfer record ownership. Delegator Account does not have a Branch Manager', iApp)
                                .addTag('Agency Delegation');
                    }
                } else {
                    Nebula.Logger.error('Agency transfer failed. Agency with this Delegator Org Unit does not exist.', iApp)
                                .addTag('Agency Delegation');
                }
            }
        }
        return appList;
    }
}