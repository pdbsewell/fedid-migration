/*******************************************************************************
* @author       Anterey Custodio
* @date         24.Jul.2017         
* @description  extension class for StudFirst_SendEmail global action page that
				lets CRM users send an email through the defined object
* @revision     19.Jul.2019: Suman Gunaganti: Updated as part user story SFTDC-487
*******************************************************************************/
public with sharing class StudFirst_SendEmailCE {

	public Application_Course_Preference__c acpRecord {get;set;}
	public Case caseRec {get;set;}
	private final String admissionsRecTypeId = CommonServices.recordTypeId('Case', 'Admissions');
	private final String mumAdmissionsRecTypeId = CommonServices.recordTypeId('Case', 'MUM_Admissions');
	public String toAddressesList {get;set;}
	private final Set<String> SRA_QUEUES = new Set<String>{'SRA_IA_MU_Docs', 'SRA_IA_MC_Docs', 'SRA_IA_IRS_Fees'};
	public String roleName {get;set;}
	public Boolean notifyAgent {get;set;}
	public Boolean isVisibleToAgent {get;set;}


	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         24.Jul.2017        
	* @description  constructor used if it is called as a controller
	* @revision     Ant Custodio, 24.Nov.2017 - updated which email to use on the 
						'To' Address
	*******************************************************************************/
	public StudFirst_SendEmailCE(ApexPages.StandardController stdController) {
		String acpId = ApexPages.currentPage().getParameters().get('id');
		if (acpId != null && acpId != '') {
			List<String> admissionsEnquiryRecordTypes = new List<String>();
			admissionsEnquiryRecordTypes.add(admissionsRecTypeId);
			admissionsEnquiryRecordTypes.add(mumAdmissionsRecTypeId);
			acpRecord = [  	SELECT 	Id, Application__c,
									Application__r.Applicant__c,
									Application__r.Applicant__r.Personal_Email__c,
									Application__r.Applicant__r.Email,
									Application__r.Applicant__r.IT_account_disabled__c,
									Application__r.Applicant__r.Monash_Email_Address__c,
									Agent_Email__c,
									Location_Code__c,
									(	SELECT	Id, Notify_Agent__c , is_Visible_to_External_Stakeholder__c
										FROM 	Cases__r 
										WHERE 	RecordTypeId IN :admissionsEnquiryRecordTypes
										ORDER BY CreatedDate DESC LIMIT 1 )
	                        FROM 	Application_Course_Preference__c 
	                        WHERE 	Id =: acpId ];
	        caseRec = new Case();
	        notifyAgent = false;
			isVisibleToAgent = false;
	        List<String> toEmails = new List<String>();
	        Boolean addMonashEmail = false;
	        if (System.label.App_AddMonashEmailAsDefault == 'true' && !acpRecord.Application__r.Applicant__r.IT_account_disabled__c) {
	        	addMonashEmail = true;
	        }

	        if (acpRecord.Application__r.Applicant__c != null) {
	        	if (!String.isBlank(acpRecord.Application__r.Applicant__r.Personal_Email__c)) {
	        		toEmails.add(acpRecord.Application__r.Applicant__r.Personal_Email__c);
	        	} else if (!String.isBlank(acpRecord.Application__r.Applicant__r.Email)) {
	        		toEmails.add(acpRecord.Application__r.Applicant__r.Email);
	        	}

	        	if (addMonashEmail && !String.isBlank(acpRecord.Application__r.Applicant__r.Monash_Email_Address__c)) {
	        		toEmails.add(acpRecord.Application__r.Applicant__r.Monash_Email_Address__c);
	        	}
	        }

	        if (!String.isBlank(acpRecord.Agent_Email__c)) {
	        	notifyAgent = true;
				isVisibleToAgent = true;
	        	toEmails.add(acpRecord.Agent_Email__c);
	        }

	        //join the string
	        toAddressesList = String.join(toEmails, ',');

	        if (!acpRecord.Cases__r.isEmpty()) {
	        	//if no emails have been sent for the latest enquiry OR if there is a draft email message in it, reuse it instead
	        	Boolean reuseCase = true;
	        	for (EmailMessage emlMsgRec: [	SELECT	Id, Status 
        										FROM 	EmailMessage 
        										WHERE	ParentId =: acpRecord.Cases__r[0].Id ]) {
	        		if (emlMsgRec.Status != '5') { //5 means draft
	        			reuseCase = false;
	        		}
	        	}

	        	if (reuseCase) {
	        		caseRec = acpRecord.Cases__r[0];
	        		caseRec.Notify_Agent__c = notifyAgent;
					caseRec.is_Visible_to_External_Stakeholder__c = isVisibleToAgent;
	        		caseRec.Status = 'Draft';
	        	}
	        }

	        //get running user's role name
	        List<UserRole> userRole = [	SELECT	Id, Name 
										FROM 	UserRole 
										WHERE 	Id =: userInfo.getUserRoleId() ];
			if (!userRole.isEmpty()) {
				roleName = userRole[0].Name;
			}
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'There seems to be a problem with this page. Please contact the administrator.'));
			ExLog.add('Send Email Global Action', 'StudFirst_SendEmailCE.cls', 'StudFirst_SendEmailCE()' , 'Application Course Preference Id not found');
		}
	}

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         24.Jul.2017        
	* @description  only create a case when there aren't any
	* @revision     
	*******************************************************************************/
	public void createCaseIfNoneRelated() {
		try {
			//relate a case to it if it does not have an existing one
			if (caseRec.Id == null) {
				createCase();
			} else {
				update caseRec;
			}
		} catch (Exception ex) {
			ExLog.add('Error on updating/inserting Case: ', 'StudFirst_SendEmailCE', 'createCaseIfNoneRelated' , ex);
		}
	}

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         27.Jul.2017        
	* @description  creates a case record with admissions record type
	* @revision     
	*******************************************************************************/
	private void createCase() {
		caseRec = new Case();
		caseRec.Origin = 'Email - mu.documents';
		if (roleName == 'SRA Fees Mgr' || roleName == 'SRA Fees Staff') {
			caseRec.Origin = 'Email - irsfees';
		} else if (roleName == 'SRA Admissions Mgr (MC)' || roleName == 'SRA Admissions Staff (MC)') {
			caseRec.Origin = 'Email - mc.documents';
		}
		caseRec.ContactId = acpRecord.Application__r.Applicant__c;
		caseRec.Application_Course_Preference__c = acpRecord.Id;
		caseRec.RecordTypeId = admissionsRecTypeId;
		caseRec.Notify_Agent__c = notifyAgent;
		caseRec.is_Visible_to_External_Stakeholder__c = isVisibleToAgent;

		caseRec.Status = 'Draft';

		//Malaysia Admission implementation - SFTG-1522
		//Set the origin to Email - MUM Admissions if the acp's location is malaysia
		if(acpRecord.Location_Code__c == 'Malaysia'){
			caseRec.Origin = 'Email - MUM Admissions';
		}
		//Set the record type to mum enquiry if the acp's location is malaysia
		if(acpRecord.Location_Code__c == 'Malaysia'){
			caseRec.RecordTypeId = mumAdmissionsRecTypeId;
		}
		//Set the status to Open if the acp's location is malaysia
		if(acpRecord.Location_Code__c == 'Malaysia'){
			caseRec.Status = 'Draft';
		}

		//Fetching the assignment rules on case
		AssignmentRule AR = new AssignmentRule();
		AR = [	SELECT 	Id 
				FROM 	AssignmentRule 
				WHERE 	SobjectType = 'Case' AND 
						Active = true 
				LIMIT 	1 ];

		//Creating the DMLOptions for "Assign using active assignment rules" checkbox
		Database.DMLOptions dmlOpts = new Database.DMLOptions();
		dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;

		//Setting the DMLOption on Case instance
		caseRec.setOptions(dmlOpts);
		insert caseRec;
	}
}