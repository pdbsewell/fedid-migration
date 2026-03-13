global class DocumentShareFix implements Database.Batchable<sObject> {

    global void execute(Database.BatchableContext BC, List<Application__c> items) {

        Set<Id> linkedEntityIds = new Set<Id>();
        List<Id> contactIds = new List<Id>();

        for (Application__c app : items) {
            contactIds.add(app.Applicant__c);
            linkedEntityIds.add(app.Applicant__c);
            linkedEntityIds.add(app.Id);
        }

        List<Contact_Document__c> contactDocuments = [SELECT Id FROM Contact_Document__c WHERE Contact__c IN :contactIds];

        for(Contact_Document__c cDoc : contactDocuments){
            linkedEntityIds.add(cDoc.Id);
        }

        try{
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ShareType FROM ContentDocumentLink WHERE LinkedEntityId IN :linkedEntityIds AND ShareType = 'V'];
            System.debug('Number of records processed - ' + contentDocumentLinks.size());

            for (ContentDocumentLink link : contentDocumentLinks) {
                link.ShareType = 'I';
            }
            update contentDocumentLinks;
        }
        catch(Exception e) {
            System.debug(e.getMessage());
            System.debug('No records for the systems affected');
        }
    }

    global void finish(Database.BatchableContext param1) {

    }

    global Iterable<SObject> start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Applicant__c, Id FROM Application__c WHERE Source_System__c = 'Agent Portal' OR Source_System__c = 'IDP' OR Source_System__c = 'OES']);
    }
}