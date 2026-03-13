/**
 * @author           Majid Reisi Dehkordi
 * @description      For a variety of reasons a file/attachment may fail in transfer in Callista
 *                   This class is to ensure that this is happening regularly
 * @history         
 */
global class SendDocSchedulable implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Get a list of all contact documents that have failed to transfer
        // No of all unsuccessful contact docs (Attachment related) in the range of 1-10 days that their contact have (a) application(s) that is/are in Callista
		List<Contact_Document__c> cds = new List<Contact_Document__c>();
        cds = [Select id 
               FROM contact_document__c
               WHERE createddate >= :Date.Today().addDays(-10) AND createddate <= :Date.Today().addDays(-1)
               AND Email_Attachment_Id__c != null 
               AND Document_Status__c = false
               AND Contact__c IN 
               (SELECT Applicant__c 
                FROM Application__c 
                where Callista_Applicant_Id__c != null 
                AND Callista_Applicant_Id__c != null
               ) 
               order by id];
        
        If(test.isrunningtest())
        {
            cds = [Select id FROM contact_document__c WHERE Email_Attachment_Id__c != null order by id];
        }

		List<id> cdIds = new List<id>();

		for(Contact_Document__c cdVar: cds)
		{
    				cdIds.add(cdVar.id);
		}
		
        // Get the unsuccessful attachments
		List<Attachment> attachmentsToCNDCs = [Select id,parentid,Name,OwnerId from attachment where parentid in : cdIds];

		Map<id, id> contactDocumentToAttachmentMap = new Map<id, id>();
		Map<id, Integer> contactDocumentToAttachmentNoMap = new Map<id, Integer>();
		for(Attachment attachmentVar: attachmentsToCNDCs)
		{
			contactDocumentToAttachmentMap.put(attachmentVar.parentid, attachmentVar.id);
            if(contactDocumentToAttachmentNoMap.get(attachmentVar.parentid) == null) {
				contactDocumentToAttachmentNoMap.put(attachmentVar.parentid, 1);
            } else {
				contactDocumentToAttachmentNoMap.put(attachmentVar.parentid, contactDocumentToAttachmentNoMap.get(attachmentVar.parentid)+1);
            }
		}
        
		Integer numberOfContactDocumentsWithZeroAttachment  = 0;
		Integer numberOfContactDocumentsWithOneAttachment  = 0;
		Integer numberOfContactDocumentsWithTwoAttachments  = 0;
		Integer numberOfContactDocumentsWithThreeAttachments  = 0;
		Integer numberOfContactDocumentsWithMoreThan3Attachments  = 0;
		Integer totalNumberOfAttachmentsOnCNDCs = 0;
		List<id> cNDCIdsWithOneAttachment = new List<id>();
        
        // Find out the relation between the number of contact documents and attachments
		for(id cNDCId: contactDocumentToAttachmentMap.keySet())
		{
			totalNumberOfAttachmentsOnCNDCs += contactDocumentToAttachmentNoMap.get(cNDCId);
			if(contactDocumentToAttachmentNoMap.get(cNDCId) == null)
    			numberOfContactDocumentsWithZeroAttachment++;
			if(contactDocumentToAttachmentNoMap.get(cNDCId) == 1)
			{
				numberOfContactDocumentsWithOneAttachment++;
				cNDCIdsWithOneAttachment.add(cNDCId);
			}
			if(contactDocumentToAttachmentNoMap.get(cNDCId) == 2)
			{
				numberOfContactDocumentsWithTwoAttachments++;
			}
			if(contactDocumentToAttachmentNoMap.get(cNDCId) == 3)
				numberOfContactDocumentsWithThreeAttachments++;
			if(contactDocumentToAttachmentNoMap.get(cNDCId) > 3)
			{
				numberOfContactDocumentsWithMoreThan3Attachments++;
			}
		}

		List<ContentDocumentLink> cDLs = new List<ContentDocumentLink>();
    
        if(cNDCIdsWithOneAttachment.size() != 0) {
			cDLs = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :cNDCIdsWithOneAttachment];
        }
		
        Map<id, id> cNDCToFileMap = new Map<id, id>();
		Map<id, Integer> cNDCToFileNoMap = new Map<id, Integer>();
		List<id> cNDCIdsWithOneFile = new List<id>();
        
		for(ContentDocumentLink cDLVar: cDLs)
		{
			cNDCToFileMap.put(cDLVar.LinkedEntityId, cDLVar.ContentDocumentId);
            if(cNDCToFileNoMap.get(cDLVar.LinkedEntityId) == null) {
				cNDCToFileNoMap.put(cDLVar.LinkedEntityId, 1); 
            } else {
				cNDCToFileNoMap.put(cDLVar.LinkedEntityId, cNDCToFileNoMap.get(cDLVar.LinkedEntityId)+1);
            }
		}
        
		Integer numberOfContactDocumentsWithIncorrectNumberOfFiles  = 0;
        Integer numberOfContactDocumentsWithOneFile  = 0;
		Integer totalNumberOfFilesOnCNDCs = 0;
		// To find out the relation between the number of contact documents and files
		for(id cNDCId: cNDCToFileNoMap.keySet())
		{
			totalNumberOfFilesOnCNDCs += cNDCToFileNoMap.get(cNDCId);
			if(cNDCToFileNoMap.get(cNDCId) == 1)
			{
				numberOfContactDocumentsWithOneFile++;
				cNDCIdsWithOneFile.add(cNDCId);
			}
			if(cNDCToFileNoMap.get(cNDCId) != 1)
				numberOfContactDocumentsWithIncorrectNumberOfFiles++;
		}

		List<Attachment> attachmentsThatNeedToBeCovertedToFiles = new List<Attachment>();
		if(cNDCIdsWithOneAttachment.size() != 0)
			attachmentsThatNeedToBeCovertedToFiles = [Select id,parentid,Name,OwnerId from attachment where parentid IN : cNDCIdsWithOneAttachment];

        //Send the unsuccessfull contact documents that are related to enquiries
		ContactDocumentPostAppPB.QueueFileToSend(cNDCIdsWithOneAttachment);

		List<Contact_Document__c> cds2 = [Select id
										 FROM contact_document__c 
										 WHERE createddate >= :Date.Today().addDays(-10) AND createddate <= :Date.Today().addDays(-1)
										 AND Submitted__c = true
										 AND Document_Status__c = false
										 AND Email_Attachment_Id__c = null
										 AND Contact__c IN (SELECT Applicant__c 
															FROM Application__c 
															WHERE Callista_Applicant_Id__c != null 
															AND Callista_Application_Id__c != null 
															AND Status__c = 'Submitted') 
										ORDER BY id];

		List<id> cdIdsWithoutResponseWithoutDocumentStatuslinkedToFile = new List<id>();
		for(Contact_Document__c cdVar: cds2)
		{
				cdIdsWithoutResponseWithoutDocumentStatuslinkedToFile.add(cdVar.id);
		}

        //Send the unsuccessfull contact documents that are related to my.app files
		ContactDocumentPostAppPB.QueueFileToSend(cdIdsWithoutResponseWithoutDocumentStatuslinkedToFile);
    }
}