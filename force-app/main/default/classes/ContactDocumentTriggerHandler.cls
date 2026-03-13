/*
 * @File Name          : ContactDocumentTriggerHandler.cls
 * @Description        : Service layer containing most business logic for Contact Document object 
 * @Author             : Vishal Gupta
 * @Last Modified By   : 
 * @Last Modified On   : 27/05/2025
 * @Modification Log   : 
 * Date         Author      		    Modification
 * 10/15/2019   Vishal Gupta            Initial Version
**/
public class ContactDocumentTriggerHandler {
	public class RetryGRDocumentSyncToCallista extends TriggerAbstract {
        Map<Id, List<Id>> applicationAndConDocIds = new Map<Id, List<Id>>();//application and con doc map for filtering the grad res applications only
        public override void process(SObject record, SObject oldRec) {            
            // before and or after update logic here
            Contact_Document__c newConDoc = (Contact_Document__c)record;
            Contact_Document__c oldConDoc = (Contact_Document__c)oldRec;
            if(Trigger.isAfter && Trigger.isUpdate && newConDoc.Sync_In_Progress__c == true && oldConDoc.Sync_In_Progress__c == false && newConDoc.Callista_Document_Id__c == null && newConDoc.Application__c != null){
                if(applicationAndConDocIds.containsKey(newConDoc.Application__c)) {
                    applicationAndConDocIds.get(newConDoc.Application__c).add(newConDoc.Id);
                } else {
                    applicationAndConDocIds.put(newConDoc.Application__c, new List<Id>{newConDoc.Id});
                }
            }
        }
        public override void execute() {
            List<Id> conDocIds = new List<Id>();
            try{
                if(!applicationAndConDocIds.isEmpty()) {
                    for(Application__c app : new ApplicationsSelector().selectById(applicationAndConDocIds.keySet())) {
                        //retry is only for Graduate Research applications
                        if(app.Type_of_Study__c == 'Graduate Research') {
                            conDocIds.addAll(applicationAndConDocIds.get(app.Id));
                        }
                    }
                }
                if(!conDocIds.isEmpty()) {
                    GRInvocablePostDocumentService.queueFileToSend(conDocIds);
                }    
            }  
            catch(Exception ex) {
                Nebula.Logger.error('ContactDocumentTriggerHandler.RetryGRDocumentSyncToCallista '+ex.getMessage(), ex);
                Nebula.Logger.saveLog();
            }      
        }
    }
}