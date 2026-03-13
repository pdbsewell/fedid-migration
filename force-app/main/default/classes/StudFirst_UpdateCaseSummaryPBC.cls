/*******************************************************************************
* @author       Anterey Custodio
* @date         24.Aug.2017        
* @description  Class that's called on Process Builder to put the email content
					on the Summary field on the parent Case
* @revision     Changed by SMen on 26/02 for SFTDC-237
*               Refactoring code by SMen -27/02 for SFTDC-237
*******************************************************************************/
public with sharing class StudFirst_UpdateCaseSummaryPBC {
	//Find the latest 4 Incoming mails to summarize
	@InvocableMethod(label='Update Case Summary' description='Copy the latest 4 Inbound email details and put it on the Parent.Summary Field')
	public static void updateCaseSummary (List<String> parentId) {
		List<Case> caseToUpdateList = new List<Case>();


		for(Case caseRec :[SELECT Id, Summary__c ,( SELECT 	Id, ParentId,
				 Subject,
				 TextBody,
				 FromAddress,
				 ToAddress,
				 CcAddress,
				 MessageDate
		 		FROM EmailMessages  WHERE Incoming=true order by createddate desc LIMIT 4)
		FROM CASE WHERE Id in :parentId])
		{
			//Initialize SummaryBody variable for each Case
			String summaryBody = '';
			for(EmailMessage emlMsg:caseRec.EmailMessages)
				{
					summaryBody += 'From: ' + emlMsg.FromAddress + '\n';
					summaryBody += 'Sent: ' + emlMsg.MessageDate.format() + '\n';
					summaryBody += 'To: ' + emlMsg.ToAddress + '\n';
					if (emlMsg.CcAddress != null) {
						summaryBody += 'CC: ' + emlMsg.CcAddress + '\n';
					}
					if (emlMsg.Subject != null) {
						summaryBody += 'Subject: ' + emlMsg.Subject + '\n';
					}
					summaryBody += '\n' + emlMsg.TextBody + '\n';
				}

			caseRec.Summary__c = summaryBody;
			caseToUpdateList.add(caseRec);
		}

		update caseToUpdateList;
	}
}