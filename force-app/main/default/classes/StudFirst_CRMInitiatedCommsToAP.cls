/*******************************************************************************
* @author       Anterey Custodio
* @date         24.Aug.2017
* @description  class used to send communications from CRM to Agent Portal
* @revision		
*******************************************************************************/
global with sharing class StudFirst_CRMInitiatedCommsToAP {

	public static final String EMAIL_ATTACHMENT = 'Attachment';
	public static final String EMAIL_BODY = 'Body';
	public static final String EMAIL_SUBJECT = 'Subject';
	public static final String EMAIL_TOADDRESS = 'Additional To';
	public static final String EMAIL_TASK_STR = 'Email: ';

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         24.Aug.2017
	* @description  method used to send communications to Agent Portal
	* @parameter 	List<Task>
	* @revision		
	*******************************************************************************/
	WebService static void notifyAgentByTask(List<Task> taskList) {

        List<String> taskIds = new List<String>();
        for (Task taskRec: taskList) {
        	taskIds.add(taskRec.Id);
        }
        notifyAgent(taskIds);
    }

    /*******************************************************************************
	* @author       Anterey Custodio
	* @date         24.Aug.2017       
	* @description  method used to send communications to Agent Portal
	* @parameter 	List<Case.Id>
	* @revision		Ant Custodio, 3/May/2018 - only submit API request if Agent Org
	*					Unit Code is not blank AND if applicantId OR personId is not
	*					blank
	*******************************************************************************/
	WebService static void notifyAgent(List<String> taskIds) {
		List<StudFirst_CRMInitiatedCommsToAP_Req> requestList = new 
			List<StudFirst_CRMInitiatedCommsToAP_Req>();
		Set<String> caseIds = new Set<String>();

		for (Task taskRec: [SELECT	Id, WhatId
							FROM 	Task
							WHERE 	Id IN: taskIds AND 
									Type = 'Internal Email']) {
			caseIds.add(taskRec.WhatId);
		}
		String admissionsRecType = CommonServices.recordTypeId('Case','Admissions');
		for (Case caseRec: [	SELECT	Id,
										Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c,
										Application_Course_Preference__r.Application__r.Agent_Org_Unit_Code__c,
										Application_Course_Preference__r.Application__c,
										Application_Course_Preference__r.Application__r.Callista_Student_Id__c,
										(	SELECT 	Id,
													Description,
													WhatId,
													Subject,
													CreatedDate
											FROM 	Tasks
											WHERE 	Id IN: taskIds AND
													Type = 'Internal Email' )
								FROM 	Case
								WHERE 	Id 	IN: caseIds AND
										RecordTypeId =: admissionsRecType AND
										Notify_Agent__c = true ]) {
			
			for (Task taskRec: caseRec.Tasks) {
				Map<String, String> contentMap = splitContent(taskRec.Description);
				StudFirst_CRMInitiatedCommsToAP_Req crmToApReq = new StudFirst_CRMInitiatedCommsToAP_Req();
				crmToApReq.enquiryRecordId = taskRec.WhatId;
				crmToApReq.agentOrgUnitId = caseRec.Application_Course_Preference__r.Application__r.Agent_Org_Unit_Code__c;
				crmToApReq.applicantId = caseRec.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c;
				crmToApReq.personId = caseRec.Application_Course_Preference__r.Application__r.Callista_Student_Id__c;
				//populate subject
				crmToApReq.subject = taskRec.Subject;
				if (taskRec.Subject.contains(EMAIL_TASK_STR)) {
					crmToApReq.subject = taskRec.Subject.replace(EMAIL_TASK_STR, '');
				}
				crmToApReq.messageBody = contentMap.get(EMAIL_BODY);
				//TODO ATTACHMENT LINKS crmToApReq.apNotifWrapper.attachmentLinks = contentMap.get(EMAIL_ATTACHMENT);
				
				//ACUSTODIO, 3/May/2018 - added this condition to only perform a request when the required fields are present
				//CONDITION: IF agentOrgUnitId is NOT BLANK AND (crmToApReq.personId OR crmToApReq.applicantId) is NOT BLANK
				if (!String.isBlank(crmToApReq.agentOrgUnitId) && (!String.isBlank(crmToApReq.personId) || !String.isBlank(crmToApReq.applicantId)) ) {
					requestList.add(crmToApReq);
				}
			}
		}

		//send a request to Agent Portal so that the Agents will be notified
		if (!requestList.isEmpty()) {
			for (StudFirst_CRMInitiatedCommsToAP_Req request: requestList) {
				StudFirst_CRMToAPQueueable campaignMemberJob = new StudFirst_CRMToAPQueueable(JSON.serialize(request));
		        Id jobID = System.enqueueJob(campaignMemberJob);
			}
		}
    }

    /*******************************************************************************
	* @author       Ant Custodio
	* @date         24.Aug.2017
	* @description  splits the content of the email
	* @triggered 	On Insert of Task
	* @revision     
	*******************************************************************************/
	private static Map<String, String> splitContent (String content) {
		Map<String, String> contentMap = new Map<String, String>();
		
		//split to key value pairs. New key is defined by new line (\n) and key|value is separated by colon (:)
		String[] descSplit = content.split('\n');

		for (Integer i=0; descSplit.size()>i; i++) {
		    String[] keyValStr = descSplit[i].split(':');
		    
		    if (descSplit[i] != '') {
		        if (keyValStr.size() > 1) {
		            contentMap.put(keyValStr[0], keyValStr[1]); 
		        } else if (keyValStr[0] == EMAIL_BODY) {
		            String bodyStr = '';
		            for (Integer j=(i+1); descSplit.size()>j; j++) {
		               	//put a new line if not the last character
		                if (j != (descSplit.size()-1)) {
		                    bodyStr += descSplit[j] + '\n';
		                } else {
		                    bodyStr += descSplit[j];
		                }
		            }
		            contentMap.put(keyValStr[0], bodyStr); 
		            break;
		        }
		    }
		}

		return contentMap;
	}
}