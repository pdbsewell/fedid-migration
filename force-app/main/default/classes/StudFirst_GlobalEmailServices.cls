/*******************************************************************************
* @author		Ant Custodio
* @date         19.Sept.2017     
* @description  contains all the generic methods by Student First (AA) 
					for Email Message object
* @revision     Ant Custodio, 7.May.2018 - Added without sharing to the class
					so that the admins can just include the class to the profile
					if they want it to be used for them, regardless of the fields
					queried/used on the methods
*******************************************************************************/
global without sharing class  StudFirst_GlobalEmailServices {
	/*******************************************************************************
	* @author		Ant Custodio
	* @date         19.Sept.2017     
	* @description  Method called by button on Email Message to resend the same email
						to the same recipient
	* @revision     16.Oct.2017 - Ant Custodio removed cloning of emailmessages 
						and attachments and used setTargetObjectId instead
					20.Mar.2018 - Ant Custodio, instead of getting emails from 
						Applicant, just reuse the email used on the original email
					11.Apr.2018 - Ant Custodio, added 2 parameters so that the 'To'
						and 'CC' can be overwritten
						renamed resendEmail to sendToProvidedEmailAddresses
	*******************************************************************************/
	@AuraEnabled
	public static Boolean sendToProvidedEmailAddresses(String emlMsgId, 
													String toAddresses, 
													String ccAddresses, 
													String bccAddresses,
													Boolean notifyAgent,
													Boolean overrideRecipients) {
		Boolean isSuccess = true;
		
		if (emlMsgId != '') {
			List<Attachment> attList = [	SELECT 	Id, Body,
													ContentType, Description,
													Name, OwnerId,
													ParentId
											FROM 	Attachment
											WHERE 	ParentId =: emlMsgId	];
			
			List<EmailMessage> emlMsgRecList = retrieveEmailMessageById(emlMsgId);

			if (!emlMsgRecList.isEmpty()) {
				try {
					EmailMessage emlMsgClone = emlMsgRecList[0].clone();
					// Modification by Majid Reisi Dehkordi 12/10/207
					// Read the emails from the App_AdmissionEmails (which is a custom label)
					// Seperate them by a comma and allocate those admissions emalis to 
					// admissionEmails field
					Set<String> admissionEmails = new Set<String>(((String)System.Label.App_AdmissionEmails).split(','));
					// End of Modification by Majid Reisi Dehkordi 12/10/2017

					String owaStr = '';
					//get the From Address from the Org wide email address
					for(OrgWideEmailAddress owa : [	SELECT	Id, Address, DisplayName 
													FROM	OrgWideEmailAddress 
													WHERE 	Address IN: admissionEmails	]){
						if (owa.Address == emlMsgClone.FromAddress) {
		                	owaStr = owa.Id;
		                }
		            }
					//build the email message
					Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
					
		        	//if overrideRecipients is true, use those instead
		        	if (overrideRecipients) {
		        		emlMsgClone.ToAddress = toAddresses;
		        		emlMsgClone.CcAddress = ccAddresses;
		        		emlMsgClone.BccAddress = bccAddresses;
					}
					
					semail.setToAddresses(splitEmailsBySemiColon(emlMsgClone.ToAddress));
					
					if (!String.isBlank(emlMsgClone.CcAddress)) {
						semail.setCcAddresses(splitEmailsBySemiColon(emlMsgClone.CcAddress));
					}
					if (!String.isBlank(emlMsgClone.BccAddress)) {
		        	 	semail.setBccAddresses(splitEmailsBySemiColon(emlMsgClone.BccAddress));
			        }
					
			        
			        semail.setBccSender(false);
			        semail.setSubject(emlMsgClone.Subject);
			        semail.setPlainTextBody(emlMsgClone.TextBody);
			        semail.setHtmlBody(emlMsgClone.HtmlBody);
			        semail.setWhatId(emlMsgClone.ParentId);
			        if (owaStr != '') {
			        	semail.setOrgWideEmailAddressId(owaStr);
			        }
			        
			        Messaging.EmailFileAttachment[] files = new Messaging.EmailFileAttachment[]{};
	        		for(attachment attRec : attList) {
						Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
						efa.setBody(attRec.Body);
						efa.setContentType(attRec.ContentType);
						efa.setFileName(attRec.Name);
						files.add(efa);
					}
		            
					if(!files.isEmpty()) {
						semail.setFileAttachments(files);
					}
					
					//insert the cloned email message
					insert emlMsgClone;
					
					//ACUSTODIO, 26.Sept.2017 - Sends the Email to the Agent Portal as well
					List<Case> caseRecList = [	SELECT 	Id,
														ContactId,
														Notify_Agent__c,
														Application_Course_Preference__r.Applicant__c,
														Application_Course_Preference__r.Application__r.Agent_Org_Unit_Code__c,
														Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c,
														Application_Course_Preference__r.Application__r.Callista_Student_Id__c,
														Subject,
														Description
												FROM 	Case 
												WHERE 	Id =: emlMsgClone.ParentId
												LIMIT	1	];
					
					if (!caseRecList.isEmpty()) {
						if (notifyAgent) {
							//send the email to Agent Portal if notify agent flag is true
							sendToAgentPortal(caseRecList);
						}
						if (!Test.isRunningTest()) {
						Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ semail });
						}
						//insert the attachments related to the email
						List<Attachment> attListClone = new List<Attachment>();
						
						for (Attachment attRec: attList.deepClone(false,false,false)){
							attRec.ParentId = emlMsgClone.Id;
							attListClone.add(attRec);
						}
						
						insert attListClone;
						
						//creates an activity under the case and contact
						String textBodyStr = generateTaskDescription(emlMsgClone, attList);
						createResendActivity(emlMsgClone, caseRecList[0].ContactId, textBodyStr);
					}

				} catch (Exception ex) {
					isSuccess = false;
					Exception_Log__c exLog = ExLog.writeExlog('ApexClass Exception. Line: '+ex.getLineNumber(), 'StudFirst_GlobalEmailServices', 'sendToProvidedEmailAddresses', emlMsgId, ex);
					insert exLog;
				}
			}
		}
		
		return isSuccess;
	}
	
	/*******************************************************************************
	* @author		Ant Custodio
	* @date         11.Apr.2018     
	* @description  Method called by button on Email Message to resend the same email
						to the same recipient. 
					This method only requires the EmailMessage Id instead of 3
	* @revision     
	*******************************************************************************/
	@future(callout=true)
	WebService static void resendEmail(String emlMsgId) {
		List<EmailMessage> emlMsgRecList = retrieveEmailMessageById(emlMsgId);
		if (!emlMsgRecList.isEmpty()) {
			sendToProvidedEmailAddresses(	emlMsgRecList[0].Id, null, null, null, 
											emlMsgRecList[0].Parent.Notify_Agent__c, 
											false);
		}
	}

	/*******************************************************************************
	* @author		Ant Custodio
	* @date         19.Sept.2017     
	* @description  Splits emails by semicolon
	* @revision     
	*******************************************************************************/
	private static List<String> splitEmailsBySemiColon(String stringToSplit) {
		List<String> emailSplit = new List<String>();
		if (!String.isBlank(stringToSplit)) {
			if (stringToSplit.contains(';')) {
				stringToSplit = stringToSplit.trim();
				for (String emailStr: stringToSplit.split(';')) {
					emailSplit.add(emailStr);
				}
			} else {
				emailSplit.add(stringToSplit);
			}
		}
		return emailSplit;
	}

	/*******************************************************************************
	* @author		Ant Custodio
	* @date         26.Sept.2017     
	* @description  send a request to Agent Portal
	* @revision     Ant Custodio, 22.Mar.2018 - updated so that it only sends if it 
						has an agent unique Id
	*******************************************************************************/
	public static void sendToAgentPortal(List<Case> caseList) {
		List<StudFirst_CRMInitiatedCommsToAP_Req> requestList = new 
			List<StudFirst_CRMInitiatedCommsToAP_Req>();
		for (Case caseRec: caseList) {
			StudFirst_CRMInitiatedCommsToAP_Req crmToApReq = new StudFirst_CRMInitiatedCommsToAP_Req();
			crmToApReq.enquiryRecordId = caseRec.Id;
			crmToApReq.agentOrgUnitId = caseRec.Application_Course_Preference__r.Application__r.Agent_Org_Unit_Code__c;
			crmToApReq.applicantId = caseRec.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c;
			crmToApReq.personId = caseRec.Application_Course_Preference__r.Application__r.Callista_Student_Id__c;
			crmToApReq.subject = caseRec.Subject;
			crmToApReq.messageBody = caseRec.Description;
			requestList.add(crmToApReq);
		}

		//send a request to Agent Portal so that the Agents will be notified
		if (!requestList.isEmpty()) {
			for (StudFirst_CRMInitiatedCommsToAP_Req request: requestList) {
				//check first if the agent org Id is present before doing a callout
				if (!String.isBlank(request.agentOrgUnitId)) {
					System.debug('@@@ request: ' + JSON.serialize(request));
					StudFirst_CRMToAPQueueable campaignMemberJob = new StudFirst_CRMToAPQueueable(JSON.serialize(request));
			        Id jobID = System.enqueueJob(campaignMemberJob);
				}
			}
		}
	}
	
	/*******************************************************************************
	* @author		Ant Custodio
	* @date         20.Mar.2018     
	* @description  creates a resend activity on the enquiry and contact object
	* @revision     
	*******************************************************************************/
	private static void createResendActivity(EmailMessage emlMsg, String contactId, String textBodyStr) {
		Task taskRec = new Task();
		taskRec.Description = truncateString(textBodyStr, 32000);
		taskRec.WhatId = emlMsg.ParentId;
		taskRec.Status = 'Completed';
		taskRec.Subject = truncateString('Email Resend: ' + emlMsg.Subject, 255);
		taskRec.Type = 'Email';
		taskRec.WhoId = contactId;
		
		insert taskRec;
	}
	
	/*******************************************************************************
	* @author		Ant Custodio
	* @date         20.Mar.2018     
	* @description  truncates the string to the specified length
	* @revision     
	*******************************************************************************/
	private static String truncateString(String fieldStr, Integer maxWidth) {
		if (!String.isBlank(fieldStr)) {
			fieldStr = fieldStr.abbreviate(maxWidth);
		}
		return fieldStr;
	}
	
	/*******************************************************************************
	* @author		Ant Custodio
	* @date         20.Mar.2018     
	* @description  generates the task Description using the Email Message
	* @revision     
	*******************************************************************************/
	private static String generateTaskDescription(EmailMessage emlMsg, List<Attachment> attList) {
		String textBodyStr = '';
		if (emlMsg != null) {
			String attachmentNames = '';
			for (Integer i=0; i<attList.size(); i++) {
				attachmentNames += attList[0].Name;
				if (i < attList.size()-1) {
					attachmentNames += ', ';
				}
			}
			
			textBodyStr = 	'Additional To: ' + emlMsg.ToAddress + '\n' + 
							'CC: ' + ((String.isBlank(emlMsg.CcAddress)) ? '' : emlMsg.CcAddress) + '\n' +
							'BCC: ' + ((String.isBlank(emlMsg.BccAddress)) ? '' : emlMsg.BccAddress) + '\n' +
							'Attachment: ' + ((String.isBlank(attachmentNames)) ? '' : attachmentNames) + '\n' +
							'Subject: ' + emlMsg.Subject + '\n' +
							'Body:\n' + emlMsg.TextBody;
		}
		return textBodyStr;
	}
	
	/*******************************************************************************
	* @author		Ant Custodio
	* @date         4.Apr.2018     
	* @description  retrieves the email message record using the provided Id
	* @revision     
	*******************************************************************************/
	@AuraEnabled
	public static List<EmailMessage> retrieveEmailMessageById(String emlMsgId) {
		List<EmailMessage> emlMsgList = new List<EmailMessage>();
		
		if (!String.isBlank(emlMsgId)) {
			emlMsgList = [	SELECT 	Id, BccAddress, CcAddress,
									FromAddress, FromName, 
									Headers, HtmlBody,
									Incoming, ParentId, Status,
									Subject, TextBody, ToAddress,
									Parent.Notify_Agent__c
							FROM 	EmailMessage
							WHERE 	Id =: emlMsgId
							LIMIT 	1	];
		}
		
		return emlMsgList;
	}
}