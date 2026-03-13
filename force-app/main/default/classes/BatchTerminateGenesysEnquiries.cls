/**
 * @author Inderpal Dhanoa
 * @date 20.Nov.2023
 * @description Batch class for Monash Connect to terminate Bulk GeneSys Enquiries.
 * @group Monash Connect
 * @Modifications Log
 *  NOV.20.2023     Inderpal D   - Initial Version MCT-323
 */
public class BatchTerminateGenesysEnquiries implements Database.Batchable<sObject> {
    List<Id> l_linkedEnqIds;
    Id i_newOwnerId;
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         20/11/2023
    * @description  Constructor for Batch Class
    * @revision     20/11/2023 - Created
    *******************************************************************************/ 
    public BatchTerminateGenesysEnquiries(List<Id> l_linkedEnq, Id i_ownerId) {
        l_linkedEnqIds = l_linkedEnq;
        i_newOwnerId = i_ownerId;
    }
    
    /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, OwnerId, Bypass_Case_Assignment__c, Terminate_Genesys_Routing__c FROM CASE WHERE Id IN : l_linkedEnqIds]); 
    }
    
    /**
    * Implement execute method (from interface) to run the business logic
    */
    public void execute(Database.BatchableContext bc, List<Case> terminateEnquiries) {
        for(Case terminateEnq : terminateEnquiries){
            terminateEnq.OwnerId = i_newOwnerId;
            terminateEnq.Bypass_Case_Assignment__c = true;
            terminateEnq.Terminate_Genesys_Routing__c = true;
        }
        try {
            update terminateEnquiries;
        } catch (Exception e) {
            LogUtilityException.addLogEvent('BatchTerminateGenesysEnquiries','BatchTerminateGenesysEnquiries', e, 'BatchTerminateGenesysEnquiries update Enquiry ');
        }
    }
    
    /**
    * Implement finsh method (from interface) to wrap up processing.
    */
    public void finish(Database.BatchableContext bc) {
    }
}