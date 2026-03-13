public without sharing class BulkFileOpener {

    @AuraEnabled
    public static string[] GetAllDocuments(string recordId)
    {
        List<string> versions = new List<string>();
        Set<Id> cdlIds = new Set<Id>();
        ContentDocumentLink[] ids = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        for(ContentDocumentLink link : ids) {
            cdlIds.add(link.ContentDocumentId);
        }
        if(!cdlIds.isEmpty()) {
            for(ContentVersion cv :[SELECT Id FROM ContentVersion where ContentDocumentId = :cdlIds]) {
                versions.add(cv.Id);
            }
        }
        return versions;
    }
}