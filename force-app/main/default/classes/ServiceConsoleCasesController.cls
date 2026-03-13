/*
 * @author			ayush.agrawal@monash.edu
 * @description		SA-290 Service Console Cases - Mark As Spam implementation.
 * @group			Student Administration
 */

public with sharing class ServiceConsoleCasesController {

    @AuraEnabled
    public static void markAsSpam(Id recordId) {
        try {
            List<Group> spamQueues = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN ('Spam', 'Spam_Private') AND Type = 'Queue'];
            
            Id spamQueue;
            Id spamPrivateQueue;
            
            for(Group g : spamQueues) {
                if(g.DeveloperName == 'Spam') {
                    spamQueue = g.Id;
                } else if(g.DeveloperName == 'Spam_Private') {
                    spamPrivateQueue = g.Id;
                }
            }
            
            Case c = [SELECT Id, ContactId, Is_Sensitive__c, OwnerId FROM Case WHERE Id = :recordId LIMIT 1];

            c.ContactId = null;
            if(c.Is_Sensitive__c) {
                c.OwnerId = spamPrivateQueue;
            } else {
                c.OwnerId = spamQueue;
            }
            
            update c;
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }

}