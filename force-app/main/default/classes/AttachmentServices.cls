/**
 * @description AA Class that contains all operations related to Attachments
 * @author      Ant Custodio
 * @since       AUG.3.2017
 * @revision
 * 	JUL.05.2019 	- Suman Gunaganti 	- (SF-2781) Removed Application Document provided object reference
 * 	JAN.18.2022 	- Vinothraja 		- (SFTG-2167) Removed calls to AssessmentServices, as it is removed as part of WR Decommission 
 * 	JUL.25.2024 	- Nick Guia 		- (DANO-149) Added stop-gap solution to prevent leaking Contact Documents to a different owner
 */
public without sharing class AttachmentServices {

	private static final String AGENT_PERSON_ID = Label.CALLISTA_AGENT_PERSON_ID;
    private static final String NOTEDOCTYPE = 'CRM_EMAIL';
    private static final String admissionsRecType = CommonServices.recordTypeId('Case','Admissions');
	private static final String NEBULA_TAG = 'AttachmentServices';
    public static Boolean runOnce = false;

	@TestVisible
	private static final String PRIVATE_CONTACT_DOC_CMDT_FEATURE_NAME = 'CASE_PRIVATE_CONTACT_DOC_CRITERIA';
	@TestVisible
	private static final List<SystemSettingWrapper.CasePrivateContactDocumentCriteria> PRIVATE_CONTACT_DOC_CIRTERIA {
		get {
			if(PRIVATE_CONTACT_DOC_CIRTERIA == null) {
				PRIVATE_CONTACT_DOC_CIRTERIA = new List<SystemSettingWrapper.CasePrivateContactDocumentCriteria>();
				for(System_Settings__mdt mdt : SystemSettingsUtil.getInstance().getByFeature(PRIVATE_CONTACT_DOC_CMDT_FEATURE_NAME)) {
					PRIVATE_CONTACT_DOC_CIRTERIA.add(
						(SystemSettingWrapper.CasePrivateContactDocumentCriteria)
						SystemSettingWrapper.parse(mdt, SystemSettingWrapper.CasePrivateContactDocumentCriteria.class)
					);
				}
			}
			return PRIVATE_CONTACT_DOC_CIRTERIA;
		} set;
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         3.Aug.2017         
	* @description  Clones the Email Attachment to the related Contact whenever the 
	*				applicant replied to the email. 
	*				This creates:
	*					- Contact Document record
	*					- Application Documents Provided record
	*					- Attachment record
	* @revision     Ant Custodio - 15.Aug.2017 - sends a summary of the email message
						to Callista as a text file
	*******************************************************************************/
	public class cloneEmailAttachmentToContactDocument implements Triggers.Handler {
		public void run(){
			List<Attachment> attList = new List<Attachment>();
			String emailMsgPrefix = EmailMessage.sobjecttype.getDescribe().getKeyPrefix();

			for (Attachment attRec: (List<Attachment>)Trigger.new) {
				if (attRec.ParentId != null) {
					//only include attachments that are linked to an EmailMessage
					String attParentIdPrefix = String.valueOf(attRec.ParentId).subString(0,3);
					if (emailMsgPrefix == attParentIdPrefix) {
						attList.add(attRec);
					}
				}
			}

			if (!attList.isEmpty()) {
				cloneEmailAttachmentsToContactDocument(attList, new Map<String, String>(), true, false, true);
			}
			
		}
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         19.Oct.2017         
	* @description  when a case is related to ACP, link the attachment related to it
						as well.
	* @revision     Ant Custodio, 20.Nov.2017 - This method now fires when contact
						is changed
	*******************************************************************************/
	public static void cloneEmailAttachmentToContactDocumentUsingCases(Map<Id, Case> oldMap, Map<Id, Case> newMap) {
		Map<String, String> caseIdMap = new Map<String, String>();
		for(Case caseInstance : newMap.values()) {
        	if(	
        		//runs when ACP is populated OR when Contact is populated
        		(oldMap.get(caseInstance.Id).Application_Course_Preference__c == null && 
        		newMap.get(caseInstance.Id).Application_Course_Preference__c != null)
        		||
        		(oldMap.get(caseInstance.Id).ContactId == null && 
        		newMap.get(caseInstance.Id).ContactId != null)
				||
				(oldMap.get(caseInstance.Id).Latest_Inbound_Email__c != newMap.get(caseInstance.Id).Latest_Inbound_Email__c && 
        		newMap.get(caseInstance.Id).Latest_Inbound_Email__c != null)
        		&&
        		//Only run for Admissions Record Type
        		newMap.get(caseInstance.Id).RecordTypeId == admissionsRecType )
        	{

        		caseIdMap.put(caseInstance.Id, caseInstance.Application_Course_Preference__c);
        	}
        }
        if (!caseIdMap.isEmpty() && !runOnce) {
        	Map<String, String> emlMsgAppIdMap = new Map<String, String>();
        	//get all the emailmessage related to this Case
	        for (EmailMessage emlMsg: [	SELECT	Id, 
												Parent.Application_Course_Preference__c, 
												Parent.Application_Course_Preference__r.Application__c 
	        							FROM	EmailMessage
	        							WHERE	ParentId IN: caseIdMap.keySet()
	        									AND Incoming = true]) {
	        	emlMsgAppIdMap.put(emlMsg.Id, emlMsg.Parent.Application_Course_Preference__r.Application__c);
	        }
	        if (!emlMsgAppIdMap.isEmpty()) {
	        	//get all the attachments for this email message
	        	Map<Id,Attachment> attToCloneMap = new Map<Id, Attachment>();
	        	for (Attachment attRec: [	SELECT 	Id, Name, Body, OwnerId,
			    									ContentType, ParentId, BodyLength 
			    							FROM 	Attachment 
			    							WHERE 	ParentId IN: emlMsgAppIdMap.keySet() ]) {
	        		attToCloneMap.put(attRec.id, attRec);
	        	}
				
				for(Contact_Document__c cd : [ SELECT Email_Attachment_Id__c 
											   FROM Contact_Document__c
											   WHERE Email_Attachment_Id__c IN: attToCloneMap.KeySet()]){
					attToCloneMap.remove(cd.Email_Attachment_Id__c);							   	
				}
	        	if (!attToCloneMap.isEmpty()) {
	        		cloneEmailAttachmentsToContactDocument(attToCloneMap.Values(), caseIdMap, true, false, true);
		        }
	        }
	        runOnce = true;
        }
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         19.Oct.2017         
	* @description  Creates corresponding Contact_Document__c and Application_Document_Provided__c
						for each inserted Attachment
	* @revision     
	*******************************************************************************/
	public static void cloneEmailAttachmentsToContactDocument(List<Attachment> emlMsgAttachments, Map<String, String> caseIdMap,
		Boolean updateTheCase, Boolean overrideDocCheck, Boolean createEmailSummary) {
		
		//call method that exclude: attachments that were already inserted AND attached to Email Message
		Map<String, List<Attachment>> emlMsgAttMap = generateEmailMsgMap(emlMsgAttachments, !updateTheCase);
		
		if (!emlMsgAttMap.isEmpty()) {

			//get parent email message so that the parent fields can be used
			Map<String, EmailMessage> emlMsgMap = retrieveApplicantEmailMessageMap (emlMsgAttMap);
			//map for collecting contact documents that needs to be inserted
			Map<String, Contact_Document__c> cdToInsertMap = new Map<String, Contact_Document__c>();
			//used for mapping application Id to ACPs
			Map<String, Application_Course_Preference__c> acpAppMap = new Map<String, Application_Course_Preference__c>();
			//set for collecting case IDs if the attachment is too big / a small jpg image
			Set<String> caseIds = new Set<String>();
			try {
				List<EmailMessage> emlMsgList = emlMsgMap.values();

				if (!caseIdMap.isEmpty()) { //if this method is called on premise and the Parent Case has an ACP, it will go here
					
					for (Application_Course_Preference__c acpRec: [	SELECT 	Id,
																			Application__c,
																			Applicant__c,
																			Application__r.Callista_Applicant_Id__c
																	FROM 	Application_Course_Preference__c
																	WHERE 	Id IN: caseIdMap.values()]) {
						acpAppMap.put(acpRec.Id, acpRec);
					}

					emlMsgList = [	SELECT 	Id, ParentId, 
											FromAddress,
											MessageDate,
											ToAddress,
											CcAddress,
											Subject,
											TextBody,
											Has_Large_Small_Document_Received__c,
											Parent.ContactId, 
											Parent.CaseNumber,
											Parent.Application_Course_Preference__c,
											Parent.Application_Course_Preference__r.Application__c,
											Parent.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c,
											Parent.RecordType.DeveloperName,
											Parent.Origin
									FROM 	EmailMessage 
									WHERE 	ParentId IN: caseIdMap.keySet()
											AND Incoming = true ];
				}

				//collects email messages that needs to be updated when the file is >5MB or if it is an image file less than 50KB
				Map<Id, EmailMessage> emlMsgToUpdateMap = new Map<Id, EmailMessage>();

				if (!emlMsgList.isEmpty()) { //if this method is called from attachment trigger and the Parent Case has an ACP, it will go here
					
					//for each attachment, create one Contact Document
					for (EmailMessage emlMsg: emlMsgList) {
						String contactId = emlMsg.Parent.ContactId;
						if (caseIdMap.containsKey(emlMsg.ParentId)) {
                            if (!acpAppMap.isEmpty()) {
								contactId = acpAppMap.get(caseIdMap.get(emlMsg.ParentId)).Applicant__c;
                            }
						}

						if (emlMsgAttMap.containsKey(emlMsg.Id) && contactId != null) {
							for (Attachment attRec: emlMsgAttMap.get(emlMsg.Id)) {
								//ONLY RUN if the file size is less than 5MB and if the file size is less than 50KB it shouldn't be image
								Boolean isFileBigOrSmall = true;

								if(theFileIsQualifiedToBeSentToCallista(attRec.BodyLength, getFileType(attRec.Name,attRec.ContentType)) || overrideDocCheck) {
									isFileBigOrSmall = false;
									Contact_Document__c cdRec = new Contact_Document__c();
									cdRec.Comments__c = 'Enquiry Source: ' + emlMsg.Parent.CaseNumber;
									cdRec.Contact__c = contactId;
									cdRec.Document_Type__c = 'OTHERDCTYP';
									cdRec.Filename__c = attRec.Name;
									cdRec.Email_Attachment_Id__c = attRec.Id;
                                    cdRec.Application__c = emlMsg.Parent.Application_Course_Preference__r.Application__c <> NULL? emlMsg.Parent.Application_Course_Preference__r.Application__c: Null;

									/**
									 * IMPORTANT:
									 * As part of the stop gap solution for DANO-149, This must be set to TRUE when the Case criteria applies
									 * @see https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/690094153/UniCRM+Email+Threading+Impact+on+document+visibility+in+My.App+APNG
									 */
									if(isContactDocumentInternalOnly((Case) emlMsg.Parent)) {
										cdRec.Internal_Only__c = true;
									} else {
										// otherwise, as-is
										cdRec.Internal_Only__c = false;
									}
	
									cdToInsertMap.put(emlMsg.Id+'-'+attRec.Name+'-'+attRec.BodyLength, cdRec);
								}

								if (isFileBigOrSmall || Test.isRunningTest()) {
									//adding caseIds to be used for update
									caseIds.add(emlMsg.ParentId);
									if (!emlMsg.Has_Large_Small_Document_Received__c) {
										emlMsg.Has_Large_Small_Document_Received__c = true;
										emlMsgToUpdateMap.put(emlMsg.ParentId, emlMsg);
									}
								}
							}
						}
					}
				}

				//updates the case if there is a large document or a jpg file smaller than 50KB
				if(!caseIds.isEmpty() && updateTheCase) {	
					updateCaseStatusToLargeSmallDoc(caseIds);
				}

				//update the email message records that have large/small documents attached to it
				if (!emlMsgToUpdateMap.isEmpty()) {
					update emlMsgToUpdateMap.values();
				}

				if (!cdToInsertMap.isEmpty()) {
					insert cdToInsertMap.values();

					//insert ADPs And Attachment Records to Contact Document
					Set<String> adpIds = insertADPsAndAttachments(emlMsgList, emlMsgAttMap, cdToInsertMap, caseIdMap, acpAppMap, createEmailSummary);
				}

			} catch (Exception e) {
				Nebula.Logger.error(e.getMessage(), e).addTag(NEBULA_TAG);
			}
	    }
		Nebula.Logger.saveLog();
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         20.Oct.2017
	* @description  updates the case if there is a large document or a 
						jpg file smaller than 50KB
	* @revision     
	*******************************************************************************/
	private static Set<String> insertADPsAndAttachments(List<EmailMessage> emlMsgList, Map<String, List<Attachment>> emlMsgAttMap, 
														Map<String, Contact_Document__c> cdToInsertMap, Map<String, String> caseIdMap, 
														Map<String, Application_Course_Preference__c> acpAppMap, boolean createEmailSummary) {
		Set<String> adpIds = new Set<String>();
		List<Attachment> attToInsertList = new List<Attachment>();
        /*
		List<Application_Document_Provided__c> adpToInsertList = new List<Application_Document_Provided__c>();
		*/

		// map Contact Document Id (parent of Attachment) with ContentVersion record
		Map<Id, ContentVersion> attachmentCVs = new Map<Id, ContentVersion>();

		// key = contact document Id, value = Internal visibility or not. Used for setting ContentDocumentLink.Visibility
		Map<Id, Boolean> internalOnlyMapByContactDocId = new Map<Id, Boolean>();

		Map<Id,Id> cNDCIdToAppIdMap = new Map<Id,Id>();
		List<ContentDocumentLink> cDLs = new List<ContentDocumentLink>();

		try{
			if (!emlMsgList.isEmpty()) {
				for (EmailMessage emlMsg: emlMsgList) {
					String attFileNames = '';
					String appId = emlMsg.Parent.Application_Course_Preference__r.Application__c;
					String applicantId = emlMsg.Parent.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c;

					if (emlMsgAttMap.containsKey(emlMsg.Id)) {
						for (Attachment attRec: emlMsgAttMap.get(emlMsg.Id)) {
							if (caseIdMap.containsKey(emlMsg.ParentId)) {
								String acpId = caseIdMap.get(emlMsg.ParentId);
								if (emlMsg.Parent.Application_Course_Preference__c == null && acpAppMap.containsKey(acpId)) {
									appId = acpAppMap.get(acpId).Application__c;
									applicantId = acpAppMap.get(acpId).Application__r.Callista_Applicant_Id__c;
								}
							}

							String keyToUse = emlMsg.Id+'-'+attRec.Name+'-'+attRec.BodyLength;
							if (cdToInsertMap.containsKey(keyToUse)) {
								//next, add the attachments to the created contact documents 
								Attachment attToInsert = attRec.clone();
								attToInsert.ParentId = cdToInsertMap.get(keyToUse).Id;
								attToInsertList.add(attToInsert);
								
								//lastly, create a junction object between the contact document and the application
								/*Application_Document_Provided__c adpRec = new Application_Document_Provided__c();
								adpRec.Application__c = appId;
								adpRec.Contact_Document__c = attToInsert.ParentId;
								adpToInsertList.add(adpRec);*/
								cNDCIdToAppIdMap.put(attToInsert.ParentId, appId);
								
								//collect the file names (to be used on generating email summary file)
								attFileNames += attRec.Name + '\n';

								ContentVersion cv = new ContentVersion();
								//S - Salesforce  , check details on above link
								cv.ContentLocation = 'S';
								cv.PathOnClient = attToInsert.Name;
								//H - Chatter   , check details on above link
								cv.Origin = 'H';
								cv.OwnerId = attToInsert.OwnerId;
								cv.Title = attToInsert.Name;
								cv.VersionData = attToInsert.Body;
								
								//Creates a contentdocumentlink with share type of ReadOnly (V) and InternalUsers
								cv.FirstPublishLocationId = attToInsert.ParentId;								
								attachmentCVs.put(attToInsert.ParentId,cv);

								/**
								 * map resulting ContentDocumentLink.Visibility based on EmailMessage > Case
								 */
								try {
									Case parentCase = (Case) emlMsg.Parent;
									Boolean isInternalOnly = isContactDocumentInternalOnly(parentCase);
									internalOnlyMapByContactDocId.put(attToInsert.ParentId, isInternalOnly);
								} catch (Exception e) {
									Nebula.Logger.error(e.getMessage(), e).addTag(NEBULA_TAG);
								}
							}
						}
						if(createEmailSummary)
						{
							//submit the Email Message TextBody to Callista as a text file
							submitEmailMessageToCallista(emlMsg, applicantId, attFileNames);
						}
					}
				}
			}

			//insert the attachment and the ADP junction object
			if (!attToInsertList.isEmpty()) {
				insert attToInsertList;
			}
			
			Map<Id, Id> fileIdToContentDocumentIdMap = new Map<id,id>();
			//Insert the content versions from attachment data
			Set<String> contentDocumentLinkCombination = new Set<String>();
			if(attachmentCVs.values().size() > 0 ) {
				insert attachmentCVs.values();

				list<id> cVIds = new list<id>();
				for(ContentVersion cVVar:attachmentCVs.values())
					cVIds.add(cVVar.id);
				for(ContentVersion cVTemp:[SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cVIds])
					fileIdToContentDocumentIdMap.put(cVTemp.id,cVTemp.ContentDocumentId);

				//Change to loop through map key to get the parentId (contact document)
				for (Id contactDocumentId : attachmentCVs.keySet()) {
					//Create link to the application
					ContentDocumentLink cDL = new ContentDocumentLink();
					cDL.ContentDocumentId = fileIdToContentDocumentIdMap.get(attachmentCVs.get(contactDocumentId).id);
					cDL.LinkedEntityId = cNDCIdToAppIdMap.get(contactDocumentId);
					cDL.ShareType = 'I';

					/**
					 * If Contact Document should be set to Internal only, set visibility of ContentDocumentLink to 'InternalUsers'
					 */
					if(internalOnlyMapByContactDocId.containsKey(contactDocumentId) && internalOnlyMapByContactDocId.get(contactDocumentId)) {
						cDL.Visibility = 'InternalUsers';
					} else {
						cDL.Visibility = 'AllUsers';
						//Stamp combination for creating link to the contact document - preparation for making the converted document be visible on my.app
						if(fileIdToContentDocumentIdMap.containsKey(attachmentCVs.get(contactDocumentId).id)){
							contentDocumentLinkCombination.add(fileIdToContentDocumentIdMap.get(attachmentCVs.get(contactDocumentId).id) + '-' + contactDocumentId);
						}
					}

					cDLs.add(cDL);
				}

				//Commit document content links if there are items to be inserted
				if(!cDLs.isEmpty()){
					insert cDLs;
				}

				//Update existing CDLs to extend sharing
				//Updates the content document link automatically created from ContentVersion.FirstPublishLocationId to have ShareType of I and Visibility of AllUsers to make it visible on my.app
				if(!contentDocumentLinkCombination.isEmpty()){
					List<ContentDocumentLink> updateLinks = new List<ContentDocumentLink>();
					for(ContentDocumentLink loopLink : [SELECT Id, ContentDocumentId, LinkedEntityId
														FROM ContentDocumentLink 
														WHERE LinkedEntityId IN :attachmentCVs.keySet()]){
						//Check if the content document link is included on the combination
						if(contentDocumentLinkCombination.contains(loopLink.ContentDocumentId + '-' + loopLink.LinkedEntityId)){
							updateLinks.add(new ContentDocumentLink(Id = loopLink.Id,
																	ContentDocumentId = loopLink.ContentDocumentId,
																	LinkedEntityId = loopLink.ContentDocumentId,
																	ShareType = 'I',
																	Visibility = 'AllUsers'));
						}
					}

					//Commit CDL update
					if(!updateLinks.isEmpty()){
						update updateLinks;
					}
				}
			}

		/*	if (!adpToInsertList.isEmpty()) {
				insert adpToInsertList;
				//get the Ids and use it to send documents to callista
				for (Application_Document_Provided__c adpRec: adpToInsertList) {
					adpIds.add(adpRec.Id);
				}
			}	*/							

			for(contact_document__c cd: cdToInsertMap.values())
			{
				cd.Post_Submission__c = true;
				cd.Submitted__c = true;
			}
			update cdToInsertMap.values();
		
		} catch(Exception e) {
			Nebula.Logger.error(e.getMessage(), e).addTag(NEBULA_TAG);
		}

		Nebula.Logger.saveLog();

		return Null;
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         20.Oct.2017
	* @description  updates the case if there is a large document or a 
	*					jpg file smaller than 50KB
	* @revision     Majid Reisi Dehkordi 31/10/2017 Update on the where clause
	*				in order to specify a more specific update requirment
	*******************************************************************************/
	private static void updateCaseStatusToLargeSmallDoc(Set<String> caseIds) {
		//Here the cases are queried from the database and then they get updated.
		List<Case> cases = new List<Case>();
		for (Case caseRec: [Select id, Status from Case where id IN: caseIds AND Status != 'Large/Small Document']) {
			caseRec.Status = 'Large/Small Document';
			cases.add(caseRec);
		}
		
		if (!cases.isEmpty()) {
			update cases;
		}
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         15.Aug.2017         
	* @description  submits the Email Message TextBody to Callista as a text file
	* @revision     
	*******************************************************************************/
	private static void submitEmailMessageToCallista (EmailMessage emlMsg, String externalApplicantId, String attachmentFileNames) {
		StudFirst_DocumentDTO doc = new StudFirst_DocumentDTO();
		// External Applicant Id
        doc.externalApplicantId = externalApplicantId;
        // Agent
        doc.Agent = new StudFirst_DocumentDTO.Agent();
        doc.Agent.agentPersonId = AGENT_PERSON_ID;
        // Document
        doc.document = new StudFirst_DocumentDTO.Document();
        doc.document.type = NOTEDOCTYPE;
        doc.document.filename = emlMsg.Parent.CaseNumber + '_Email_' + emlMsg.Id;
		doc.document.contentType = 'text/plain';
        doc.document.comments = 'Enquiry Source: ' + emlMsg.Parent.CaseNumber;
        

        String docBody = 'From: ' + emlMsg.FromAddress + '\n';
		docBody += 'Sent: ' + emlMsg.MessageDate.format() + '\n';
		docBody += 'To: ' + emlMsg.ToAddress + '\n';
		if (emlMsg.CcAddress != null) {
			docBody += 'CC: ' + emlMsg.CcAddress + '\n';
		}
		if (emlMsg.Subject != null) {
			docBody += 'Subject: ' + emlMsg.Subject + '\n';
		}
		docBody += '\n' + emlMsg.TextBody;

        if (attachmentFileNames != '') {
        	docBody += '\n\nAttachments:\n' + attachmentFileNames;
        }
        Blob documentBlob = Blob.valueOf(docBody);
        doc.document.binary = EncodingUtil.base64Encode(documentBlob);

        //Submit Summary text file to Callista
		StudFirst_SubmitEnquirySummary.sendRequest(JSON.serialize(doc), doc.externalApplicantId);
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         4.Aug.2017         
	* @description  Returns a Map using the List of Attachments
	* 				KEY = EmailMessage.Id
	*				VALUE = List<Attachment>
	* @revision     
	*******************************************************************************/
	private static Map<String, List<Attachment>> generateEmailMsgMap (List<Attachment> attToMapList, Boolean overrideFlag) {
		String emailMsgPrefix = EmailMessage.sobjecttype.getDescribe().getKeyPrefix();
		Map<String, List<Attachment>> emlMsgAttMap = new Map<String, List<Attachment>>();
		
		for (Attachment attRec: attToMapList) {
			String attParentIdPrefix = String.valueOf(attRec.ParentId).subString(0,3);
			if (emailMsgPrefix == attParentIdPrefix) {
				if (emlMsgAttMap.containsKey(attRec.ParentId)) {
					List<Attachment> attList = emlMsgAttMap.get(attRec.ParentId);
					attList.add(attRec);
					emlMsgAttMap.put(attRec.ParentId, attList);
				} else {
					emlMsgAttMap.put(attRec.ParentId, new List<Attachment> {attRec});
				}
			}
		}

		return emlMsgAttMap;
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         4.Aug.2017         
	* @description  Retrieves the Applicant's EmailMessage
	*				Criteria:
	* 					- if the Email Message Parent Case = 'Admissions'
	* 					- it only works on Inbound Emails
	* 					- it only works for direct Applicants (Applicants without agents)
	* @revision     
	*******************************************************************************/
	private static Map<String, EmailMessage> retrieveApplicantEmailMessageMap (Map<String, List<Attachment>> emlMsgAttMap) {
		Map<String, EmailMessage> emlMsgMap = new Map<String, EmailMessage>();

		for ( EmailMessage emlMsgRec: [	SELECT 	Id, ParentId,
												Subject,
												TextBody,
												FromAddress,
												ToAddress,
												CcAddress,
												MessageDate,
												Parent.CaseNumber,
												Parent.Status,
												Parent.ContactId,
												Parent.RecordTypeId,
												Parent.Application_Course_Preference__c,
												Parent.Application_Course_Preference__r.Application__c,
												Parent.Application_Course_Preference__r.Application__r.Applicant__c,
												Parent.Application_Course_Preference__r.Application__r.Status__c,
												Parent.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c,
												Parent.RecordType.DeveloperName,
												Parent.Origin,
												Incoming,
												Has_Large_Small_Document_Received__c
										FROM 	EmailMessage
										WHERE 	Id IN: emlMsgAttMap.KeySet() AND
												Incoming = true AND
												Parent.RecordTypeId =: admissionsRecType AND 
												Parent.ContactId != null AND
												Parent.Application_Course_Preference__c != null] ) {
			emlMsgMap.put(emlMsgRec.Id, emlMsgRec);
		}

		return emlMsgMap;
	}

	public static String getFileType(String nameOfFile, String mimeType){
		// To map the Content type (mime type) to a file type
		Map<String, String> MimeTypeToExnestionMap = new Map<String, String>{
			'application/msword' => 'Word',
			'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'Word',
			
			'text/plain' => 'Text',
			'application/pdf' => 'PDF',
			'application/vnd.ms-excel' => 'Excel',
			//.bmp
			'image/x-windows-bmp' => 'Image',
			'image/bmp' => 'Image',
			//.jpg .jpe
			'image/pjpeg' => 'Image',
			'image/jpeg' => 'Image',
			//gif
			'image/gif' => 'Image',
			//.tif .tiff
			'image/tiff' => 'Image',
			'image/x-tiff' => 'Image',
			//.png
			'image/png' => 'Image',
			//.ico
			'image/x-icon' => 'Image'
		};

		// To map an extension from the end of file to a file type
		Map<String, String> EndOfFileExnestionMap = new Map<String, String>{
			'.doc' => 'Word',
			'.docx' => 'Word',
			'.txt' => 'Text',
			'.pdf' => 'PDF',
			'.xls' => 'Excel',
			//.bmp
			'.bmp' => 'Image',
			//.jpg .jpe
			'.jpg' => 'Image',
			'.jpe' => 'Image',
			'.jpeg' => 'Image',
			//gif
			'.gif' => 'Image',
			//.tif .tiff
			'.tif' => 'Image',
			'.tiff' => 'Image',
			//.png
			'.png' => 'Image',
			//.ico
			'.ico' => 'Image'
		};

		String extensionOfTheFile = 'Unknown';
		// if there is an extension in the filename
		if(nameOfFile.lastIndexOf('.') != -1){
			String tempFileExtension = nameOfFile.substring(nameOfFile.lastIndexOf('.')).toLowerCase();
			if(EndOfFileExnestionMap.containsKey(tempFileExtension)){
				extensionOfTheFile = EndOfFileExnestionMap.get(tempFileExtension);
			}
		}

		// if there is no extension in the filename 
		// and there is a known mime type
		if(extensionOfTheFile == 'Unknown' && MimeTypeToExnestionMap.containsKey(mimeType))
			extensionOfTheFile = MimeTypeToExnestionMap.get(mimeType);

		return extensionOfTheFile;
	}

	public static String getMIMEType(String nameOfFile, String fileType){
		// To map the Content type (mime type) to a file type
		Map<String, String> FileTypeToMIMEMap = new Map<String, String>{
			//text
			'TEXT'           => 'text/plain',
			'CSV'            => 'text/csv',
			//image
			'GIF'            => 'image/gif',
			'JPG'            => 'image/jpeg',
			'JPEG'           => 'image/jpeg',
			'PNG'            => 'image/png',
			'SVG'            => 'image/svg+xml',
			//applications
			'EXCEL'          => 'application/vnd.ms-excel',
			'EXCEL_X'        => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
			'MP4'            => 'application/mp4',
			'PACK'           => 'application/zip',
			'PDF'            => 'application/pdf',
			'POWER_POINT_M'  => 'application/vnd.ms-powerpoint.presentation.macroenabled.12',
			'POWER_POINT_X'  => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
			'WORD_X'         => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
			'ZIP'            => 'application/zip'
		};

		// To map an extension from the end of file to a MIME type
		// Reference: https://it-tools.tech/mime-types
		Map<String, String> EndOfFiletoMIMEMap = new Map<String, String>{
			//text
			'csv'   =>  'text/csv',
			'txt'   =>  'text/plain',
			//image 
			'bmp'   =>  'image/bmp',
			'ico'   =>  'image/vnd.microsoft.icon',
			'gif'   =>  'image/gif',
			'jpe'   =>  'image/jpeg',
			'jpeg'  =>  'image/jpeg',
			'jpg'   =>  'image/jpeg',
			'png'   =>  'image/png',
			'svg'   =>  'image/svg+xml',
			'tif'   =>  'image/tiff',
			'tiff'  =>  'image/tiff',
			'webp'  =>  'image/webp',
			//applications
			'doc'   =>  'application/msword',
			'docx'  =>  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
			'mp4'   =>  'application/mp4',
			'pdf'   =>  'application/pdf',
			'pptm'  =>  'application/vnd.ms-powerpoint.presentation.macroenabled.12',
			'pptx'  =>  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
			'xls'   =>  'application/vnd.ms-excel',
			'xlsx'  =>  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
			'zip'   =>  'application/zip'
		};

		

		String mimeType = '';
		// if there is an extension in the filename
		if(nameOfFile.lastIndexOf('.') != -1){
			String tempFileExtension = nameOfFile.substring(nameOfFile.lastIndexOf('.')).toLowerCase();
			if(EndOfFiletoMIMEMap.containsKey(tempFileExtension)){
				mimeType = EndOfFiletoMIMEMap.get(tempFileExtension);
			}
		}

		// if there is no extension in the filename 
		// and there is a known mime type
		if(mimeType == '' && FileTypeToMIMEMap.containsKey(fileType))
			mimeType = FileTypeToMIMEMap.get(fileType);

		return mimeType;
	}

	public static Boolean theFileIsQualifiedToBeSentToCallista(Integer bodyLengthOfFile, String typeOfFile) {
		Boolean isQualified = true;

		if (bodyLengthOfFile > Integer.valueOf(System.Label.App_MaxFileSizeInBytes))
		{
			isQualified = false;
		}
		else if (bodyLengthOfFile <= Integer.valueOf(System.Label.App_MinFileSizeInBytes) && typeOfFile == 'Image')
		{
			isQualified = false;
		}

		return isQualified;
	}

	/**
	 * @description criteria check to know if the resulting Contact Document from a Case > Email > Attachment
	 * should be set to Internal only i.e. not visible from Experience site.
	 * Assumptions : 
	 * 	-	Case.RecordType.DeveloperName is in the record context
	 *  -	Case.Origin is in the record context
	 * @param caseRecord 
	 * @return `Boolean`
	 */
	public static Boolean isContactDocumentInternalOnly(Case caseRecord) {
		Boolean isInternal = false;
		for(SystemSettingWrapper.CasePrivateContactDocumentCriteria iCriteria : PRIVATE_CONTACT_DOC_CIRTERIA) {
			if(caseRecord.RecordType.DeveloperName == iCriteria.recordTypeDeveloperName &&
				iCriteria.caseOrigin.equalsIgnoreCase(caseRecord.Origin))
			{
				isInternal = true;
			}
		}
		return isInternal;
	}
}