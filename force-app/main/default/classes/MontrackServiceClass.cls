/**
 * @description         Custom Controller Extension for use in Montrack Lightning Console.
 * @author 				APRivera
 * @revisionHistory 	Created		-	02.AUG.2018
 */
public class MontrackServiceClass {

    @auraEnabled
    public static List<Task> retrieveCallAttemptHistory(Id recordId){
        System.debug('Record Id; ' + recordId);
        List<Task> lstTasks = new List<Task>();
        Id contactId = [SELECT Id, WhoId FROM Task WHERE Id =: recordId].WhoId;
        if(contactId != null){
            lstTasks = [SELECT Id, Subject, Description, Owner.Name, Call_Attempt__c, Offer_Status__c,
                                CompletedDateTime, FORMAT(CompletedDateTime) CompletedDate, What.Name, Who.Name,
                                LastModifiedBy.Name, LastModifiedDate,  FORMAT(LastModifiedDate) LastModifiedDateTime
                        FROM Task
                        WHERE WhoId =: contactId AND Status = 'Completed'
                        AND Call_Attempt__c != NULL
                        ORDER BY CompletedDateTime DESC LIMIT 20];
        }
        return lstTasks;
    }

}