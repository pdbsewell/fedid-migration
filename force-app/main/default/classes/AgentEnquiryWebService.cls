/**
 * @Class              : AgentEnquiryWebService.cls
 * @Description        : Webservice class for handling enquiries from Agents 
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 
 * 2023-09-11     Vinothraja   Created 
 * 2023-11-22     Vinothraja   Added logging of API requests
 */
@RestResource(urlMapping='/v2/AgentEnquiryWebService')
global with sharing class AgentEnquiryWebService {
    static Feature_Switch__c fs = Feature_Switch__c.getInstance();

    // label : 'Pre-Application Enquiry'
    @TestVisible
    private static final Id CASE_RECTYPE_ADMISSIONS = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
    @TestVisible
    private static final Id CASE_RECTYPE_MUM_ADMISSIONS = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MUM_Admissions').getRecordTypeId();
    @TestVisible
    private static final Id CASE_RECTYPE_PRE_APP = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SR_Enquiry').getRecordTypeId();
    @TestVisible
    private static String DEFAULT_STUDENT_TYPE { get { return 'International'; } set; }
    @TestVisible
    private ACPSelector acpSelectorClass;
    @TestVisible
    private static AgentEnquiryWebService myself {
        get {
            if(myself == null) {
                myself = new AgentEnquiryWebService(new ACPSelector());
            }
            return myself;
        } set;
    }
    
    /**
	 * @description     creates an enquiry or comment on an enquiry  
	 * @param           JSON that can be serialized into AgentPortalPayload.CreateEnquiryRequest object
	 * @return          JSON that follows AgentPortalPayload.CreateApplicantResponse object
	 */
    @HttpPost
    global static void handleCreateEnquiry() {
        // Initialize 
        AgentPortalPayload.CreateEnquiryRequest requestWrapper;
        AgentPortalPayload.CreateEnquiryResponse responseWrapper = new AgentPortalPayload.CreateEnquiryResponse();
        RestRequest request = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');
       
        try {

            // Deserialize request
            requestWrapper = (AgentPortalPayload.CreateEnquiryRequest) JSON.deserialize(request.requestBody.toString(), 
                                                                                        AgentPortalPayload.CreateEnquiryRequest.class);
            // due to the criticality of this task, we'll leave this for now to enable debugging in SIT
            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('AgentEnquiryWebService', 'handleCreateEnquiry', request.requestBody.toString());
            }            
            //Check for Submitted status 
            String status = myself.checkForApplicationInSubmittedStatus(requestWrapper);
            if(status == AgentPortalConstants.ACP_NOT_FOUND)
            {
                responseWrapper.caseRecord = null;
                responseWrapper.description = AgentPortalConstants.ACP_NOT_FOUND;
                responseWrapper.success = false;
                responseWrapper.exceptionRecord = new AgentEnquiryWebServiceException(AgentPortalConstants.ACP_NOT_FOUND);
            }else if(status == AgentPortalConstants.APPLICATION_STATUS_DID_NOT_MATCH)
            {
                responseWrapper.caseRecord = null;
                responseWrapper.description = AgentPortalConstants.APPLICATION_STATUS_DID_NOT_MATCH;
                responseWrapper.success = false;
                responseWrapper.exceptionRecord = new AgentEnquiryWebServiceException(AgentPortalConstants.APPLICATION_STATUS_DID_NOT_MATCH);

            }else{
                Case enquiry = myself.createEnquiry(requestWrapper);
                insert enquiry;
                Case retEnquiry = [select Subject,Origin, OwnerId,Category_Level_1__c,Category_Level_2__c,
                                    RecordTypeId,Enquiry_Type__c,External_Stakeholder__c,Student_Type__c,Description,
                                    Application_Course_Preference__c,Id,Initiated_by__c,CaseNumber 
                                    from Case where id=:enquiry.Id ];
                responseWrapper.caseRecord = retEnquiry;
                responseWrapper.success = true;
                responseWrapper.description = AgentPortalConstants.ENQUIRY_CREATED;

            }
          
        } catch (Exception ex) {
            // Set error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, 'Enquiry creation failed!');
        }
        // Set response
        RestContext.response.responseBody = responseWrapper.responseBody;
    }

    /**
     * @description create an Enquiry recod based on the request payload
     * @param payload 
     * @return `Case`
     */
    @TestVisible
    private Case createEnquiry(AgentPortalPayload.CreateEnquiryRequest payload) {
        
        // first, get the ACP record based on the payload references.
        // this will be used to derive some field values on the enquiry
        Application_Course_Preference__c acp = getACPRecord(payload.enquiry.references);

        // second, create the enquiry record
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = getEnquiryRecordType(payload.enquiry.recordtypeDeveloperName);
        caseRecord.Subject = payload.enquiry.subject;
        caseRecord.Description = payload.enquiry.content;
        caseRecord.Origin = payload.enquiry.origin;
        caseRecord.Category_Level_1__c = payload.enquiry.categoryLevel1;
        caseRecord.Category_Level_2__c = payload.enquiry.categoryLevel2;
        caseRecord.Enquiry_Type__c = payload.enquiry.enquiryType;
        caseRecord.Student_Type__c = DEFAULT_STUDENT_TYPE;
        caseRecord.Application_Course_Preference__c = acp?.Id; // acp
        caseRecord.Initiated_by__c  = payload.runningUser?.Contact?.Id; // agent

        /**
         * Contact and Account have to be explicitly assigned here, otherwise
         * the case trigger / PB / flow would populate it with agent contact/account
         */
        caseRecord.ContactId = acp.Application__r.Applicant__c; // applicant
        caseRecord.AccountId = acp.Application__r.Applicant__r.AccountId; // applicant household
        // external stakeholder (agency) - is populated by Case Trigger 
        // visibility to Agents is by default true to APNG Enquiries
        caseRecord.is_Visible_to_External_Stakeholder__c = true;
		// Case Summary population - for summary file generation
        if (AgentPortalConstants.ALLOWED_REC_TYPES_FOR_SUMMARY_FILE_GENERATION.contains(payload.enquiry.recordtypeDeveloperName) 
            && payload.enquiry.origin?.equalsIgnoreCase(AgentPortalConstants.APNG_WEB_ORIGIN)) {
                caseRecord.Summary__c = 'Sent: ' + Datetime.now() + ' \n';
                caseRecord.Summary__c += 'Subject: ' + payload.enquiry.subject + '\n\n';
                caseRecord.Summary__c += payload.enquiry.content;
        }
	
        return caseRecord;
    }

    /**
     * @description check if the Application attached to the ACP on the payload is in 'Submitted' status
     * NOTE:
     *  - payload contains ACPID under references
     *    ACP record ID is to be used to query the record.
     * @param references : 
     * @return `Application_Course_Preference__c`
     */
    @TestVisible
    private  String checkForApplicationInSubmittedStatus(AgentPortalPayload.CreateEnquiryRequest payload) {
        Application_Course_Preference__c acp = getACPRecord(payload.enquiry.references);
		// Check if ACP is non-null
        if(acp == null) {
            return AgentPortalConstants.ACP_NOT_FOUND;
        }
		// Check if Application is in any of the Submitted statuses
        if (acp.Application__c != null && AgentPortalConstants.APP_SUBMITTED_STATUS.contains(acp.Application__r.status__c)) {
            return AgentPortalConstants.APPLICATION_STATUS_MATCHED;
        } else {
            return AgentPortalConstants.APPLICATION_STATUS_DID_NOT_MATCH;
        }   
    }

    /**
     * @description get the Enquiry record type based on category level 1
     * @param payloadCategoryLevel1 
     * @return `Id`
     */
    @TestVisible
    private Id getEnquiryRecordType(String recordTypeName) {
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName);
        return recTypeInfo!=null? recTypeInfo.getRecordTypeId():null;
    }

    /**
     * @description query the ACP record so we can link it to the enquiry.
     * NOTE:
     *  - payload could contains multiple CDM_Reference. If there are multiple, the current assumption is that the last index's
     *    ACP record ID is to be used to query the record.
     *  - TBC : why do we need a list of CDM_Reference? 
     * @param references : 
     * @return `Application_Course_Preference__c`
     */
    @TestVisible
    private Application_Course_Preference__c getACPRecord(List<AgentPortalPayload.CDM_Reference> references) {
        Application_Course_Preference__c returnRec;

        // get record id from the reference
        String recordId;
        for (AgentPortalPayload.CDM_Reference ref : references) {
            if (ref.key.equalsIgnoreCase('crmACP')) {
                recordId = ref.value[0]?.id; // get the ACP's record ID
            }
        }

        // query ACP based on the record ID
        if(String.isNotBlank(recordId)) {
            List<String> acpFieldsToQuery = new List<String>{
                'Id',
                'Name',
                'Course_Title__c',
                'Application__c',
                'Application__r.Applicant__c',
                'Application__r.Applicant__r.AccountId',
                'Application__r.Status__c',
                'Application__r.Owner.Id'
            };
            List<Application_Course_Preference__c> acpList = this.acpSelectorClass.selectFieldsById(acpFieldsToQuery, new Set<Id> { recordId });
            if(acpList != null && !acpList.isEmpty()) {
                returnRec = acpList[0];
            }
        }
        
        return returnRec;
    }

    // for mocking
    @TestVisible
    private AgentEnquiryWebService(ACPSelector acpSel) {
        this.acpSelectorClass = acpSel;
    }

    global class AgentEnquiryWebServiceException extends Exception{}
}