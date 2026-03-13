/**
* @description  : Batch Class to run daily and check if there is any enquiry in awaiting feedback(Monash Connect BAU)
* @author       : Seeva
* @group        : Batch Class
* @date         : 22-02-2023
* @revision     : 2022-11-10 - Seeva Singh - MCT-4 - Initial version
* @revision     : 2023-02-06 - Inderpal Singh - MCT-87 - Revised version
* Ver   Date         Author         Modification
* 
**/
public without sharing class AutoClosureOfAwaitingCasesBatch implements Database.Batchable<SObject>,Schedulable{
    public String query;
    List <String> roleNameList =  Label.Monash_Connect_Roles_Subordinates.split(','); // TO STORE MONASH CONNECT ROLE NAMES
    List <String> recordTypeNameList =  Label.monashConnectRecordTypes.split(','); // TO STORE MONASH CONNECT ROLE NAMES
    public AutoClosureOfAwaitingCasesBatch() {
        this.query = 'SELECT Id,casenumber,status,Enquiry_Type__c, Category_Level_1__c, Monash_Connect_Awaiting_Feedback_Time__c,sendReminderEmailForAwaitingFeedback__c, Days_In_Awaiting_Feedback__c,contact.email FROM Case WHERE status = \'Awaiting Customer Feedback\' AND recordtype.developername IN: recordTypeNameList AND owner.userrole.name IN: roleNameList and Monash_Connect_Awaiting_Feedback_Time__c !=null';
    }
    
    public AutoClosureOfAwaitingCasesBatch(String query) {
        this.query = query;
    }
    //COLLECT CASES WITH STATUS AWAITING CUSTOMER FEEDBACK AND ARE OF MONCON_SUPPORT OR STANDARD ENQUIRY AND WHOSE OOWNER'S ROLE IS UNDER MONASH CONNECT
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator q = Database.getQueryLocator(query);
        return q;
    }
    
    public void execute(Database.BatchableContext BC,List<SObject> scope) {
        List<Case> casesToUpdate = new List<Case>();
        Case enquiryObj;
        for(Case ENQUIRY : (List<Case>) scope) {
            //CHECK IF ENQUIRY IS IN AWAITING CUSTOMER FEEDBACK FOR 2 DAYS THEN SET THE sendReminderEmailForAwaitingFeedback__c TO TRUE TO SEND THE EMAIL ALERT USING FLOW
            if (ENQUIRY.Days_In_Awaiting_Feedback__c != null && ENQUIRY.Days_In_Awaiting_Feedback__c== 2) {
                enquiryObj = new Case();
                enquiryObj.Id = ENQUIRY.Id;
                enquiryObj.sendReminderEmailForAwaitingFeedback__c  = true;
                casesToUpdate.add(enquiryObj);
            }
            //CHECK IF ENQUIRY IS IN AWAITING CUSTOMER FEEDBACK FOR 5 DAYS THEN CLOSE THE ENQUIRY.
            else if(ENQUIRY.Days_In_Awaiting_Feedback__c != null && ENQUIRY.Days_In_Awaiting_Feedback__c >= 5)
            {

                if(!(ENQUIRY.Enquiry_Type__c == 'Current Course' && ENQUIRY.Category_Level_1__c == 'Enrolment - Current Course')){
                     enquiryObj = new Case();
                     enquiryObj.Id = ENQUIRY.Id;
                     enquiryObj.status='Closed';
                     casesToUpdate.add(enquiryObj);   
                }
            }            
        }
        if(!casesToUpdate.isEmpty()) {
            try {
                Database.SaveResult [] srList = Database.update(casesToUpdate, false);
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        LogUtilityException.debug('Error from AutoClosureOfAwaitingCasesBatch :: ' + sr.getId());
                    }
                }
            } catch(Exception ex) {
                LogUtilityException.logException(ex);
            }     
        }
    }
    public void finish(Database.BatchableContext BC){
        LogUtilityException.getLimits();
    }
/**
* Schedulable execute - executes the batch job
*/
    public void execute(SchedulableContext sc) {
        // 300 CASES per batch
        Database.executeBatch(new AutoClosureOfAwaitingCasesBatch(),300);
    }  
}