/*
 * @author          Shalini Mendu
 * @date            18/04/2019
 * @description     To display the resultset of the Contact Documents with preview link on each of them
 * @Revision History Initial version
 * 
 */
public class FileViewerCC {
    /**
    * @description Retrieve the related Contact_Docs and ContentDocuments
    * @param appId appId passed as a parameter to the component
    * @param docType docType passed as a parameter to the component
    * @return Returns Map of Contact Documents and the ContentDocument
    */
    @AuraEnabled
    public static Map<String, Object> getContactDocuments(Id appId, String docType) {
        //Retrieve the Application by appId parameter
        List<Application__c> listApps = [
                SELECT a.Id, a.Applicant__c
                FROM Application__c a
                WHERE a.Id = :appId
        ];

        //Retrieve all the ContentDocumentLink relating to ApplicationId
        if (listApps.size() > 0) {
            List<ContentDocumentLink> cdLink1List = [SELECT Id,ContentDocumentId,ShareType, Visibility from ContentDocumentLink where LinkedEntityId = :appId];
            System.debug('cdLink1List =='+cdLink1List );
            List<String> cDocList = new List<String>();

            //add all the linked ContentDocumentId's to a List
            for (ContentDocumentLink dcLink22:cdLink1List)
                cDocList.add(dcLink22.ContentDocumentId);


            if(cDocList.size()==0)
                return null;

            //add docType as a filter if it is passed in the paramter
            //updated by Suman to support multiple doctypes
            List<string> doctypeList = doctype<>Null? docType.split(','): new List<string>();
            String docTypeStr = String.isNotBlank(docType)? 'AND d.Document_Type__c IN :doctypeList':'';
            //change ends here
          


            List<ContentDocumentLink> cdLink2List = [SELECT Id,ShareType, LinkedEntityId, Visibility from ContentDocumentLink where ContentDocumentId = :cDocList];
            List<string> contDocList = new List<string>();
            String contactDocumentIdPrefix = Contact_Document__c.sObjectType.getDescribe().getKeyPrefix();
            for(ContentDocumentLink cdd:cdLink2List)
            {
                if(String.valueOf(cdd.LinkedEntityId).startsWith(contactDocumentIdPrefix))
                {
                    contDocList.add(string.valueof(cdd.LinkedEntityId));
                }
            }
            if(contDocList.size()==0)
                return null;
            //Query all the Contact_Document__c records for the related Contact for this Application
            String soqlStr = 'SELECT d.Id, toLabel(d.Document_Type__c), d.LastModifiedDate, d.Contact__c, d.Type__c, d.Comments__c, d.Filename__c, d.Submitted__c ' +
                    ' FROM Contact_Document__c d '+ ' WHERE ID In:contDocList  AND d.Submitted__c = true '+ docTypeStr +
                    + ' ORDER BY d.Submitted__c DESC';

            System.debug(LoggingLevel.DEBUG, 'soqlStr =='+soqlStr);

            Contact_Document__c[] documents = Database.query(soqlStr);
            //Retrieve ContentDocuments
            List<ContentDocument> cDocAppList = [SELECT Id, Title from ContentDocument where Id = :cDocList];
            List<Contact_Document__c> docList = new  List<Contact_Document__c>();
            Map<String, ContentDocument> idLinkMap = new Map<String, ContentDocument>();

            //Loop over each Contact_Document to match with the file name/Title
            //on each of the ContentDocuments retrieved
            Set<Id> cDocIdSet = new Set<Id>();
            for(Contact_Document__c cDoc:documents)
            {
                docList.add(cDoc);
                for (ContentDocument doc : cDocAppList)
                {
                    String fNameWithoutExt = cDoc.Filename__c.substringBeforeLast('.');
                    String CDocNameWithoutExt = doc.Title.substringAfter('_');
                    System.debug(LoggingLevel.DEBUG, 'ContactDocName='+fNameWithoutExt+'ContentDocName='+CDocNameWithoutExt);
                    if (fNameWithoutExt == CDocNameWithoutExt)
                    {
                        cDocIdSet.add(cDoc.Id);

                        idLinkMap.put(cDoc.Id, doc);
                    }

                }
            }

            Map<String, Object> sendMap = new Map<String, Object>();
            //Fill up the return values of map
            sendMap.put('documents',docList);
            sendMap.put('idLinkMap',idLinkMap);

            return sendMap;
        }
        return null;

    }

}