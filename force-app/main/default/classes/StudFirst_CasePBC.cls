public with sharing class StudFirst_CasePBC {
   
    private static final String AGENT_PERSON_ID = Label.CALLISTA_AGENT_PERSON_ID;
    private static final String NOTEDOCTYPE = 'CRM_EMAIL';
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         14.Aug.2017        
	* @description  method that Copies the content of the summary field on the 
						enquiry and put it as a .txt attachment on the ACP
	* @revision     
	*******************************************************************************/
	@InvocableMethod(label='Create Enquiry Summary To ACP' description='Copy the content of the summary field on the enquiry and put it as a .txt attachment on the ACP')
	public static void createEnquirySummaryToACP (List<String> caseIds) {
		List<Attachment> attList = new List<Attachment>();

		for (Case caseRec: [SELECT 	Id,
									CaseNumber,
									Summary__c,
									Application_Course_Preference__c,
									Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c
							FROM 	Case 
							WHERE 	Id IN: caseIds AND
									Application_Course_Preference__c != '' ]) {
			// To check if the case summary is null or empty and if that wan't the case then ...
			if (caseRec.Summary__c != null && caseRec.Summary__c != '' ) {
				//add the attachments and link it to the created contact documents 
				Attachment attRec = new Attachment();
				attRec.Body = Blob.valueOf(caseRec.Summary__c);
				attRec.Name = caseRec.CaseNumber + '_Summary';
				attRec.ParentId = caseRec.Id;
				attRec.ContentType = 'text/plain';
				attList.add(attRec);

				StudFirst_DocumentDTO doc = new StudFirst_DocumentDTO();
				 // External Applicant Id
	            doc.externalApplicantId = caseRec.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c;
	            // Agent
	            doc.Agent = new StudFirst_DocumentDTO.Agent();
	            doc.Agent.agentPersonId = AGENT_PERSON_ID;
	            // Document
	            doc.document = new StudFirst_DocumentDTO.Document();
	            doc.document.type = NOTEDOCTYPE;
	            doc.document.filename = caseRec.CaseNumber + '_Summary';
				doc.document.contentType = attRec.ContentType;
	            doc.document.comments = 'Enquiry Source: ' + caseRec.CaseNumber;
	            Blob documentBlob = attRec.Body;
	            doc.document.binary = EncodingUtil.base64Encode(documentBlob);

	            //Submit Summary text file to Callista
				StudFirst_SubmitEnquirySummary.sendRequest(JSON.serialize(doc), doc.externalApplicantId);
			}
			
		}

		//insert the attachment
		if (!attList.isEmpty()) {
			insert attList;
		}
	}
}