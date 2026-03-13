/*
 * @author	Shalini Mendu
 * @date         3.AUG.2020
 *
 * @revision Shalini Mendu  22/08/2019 - SFTN-172 - Adding two new fields to Update integration related to PrecedentId.
 *                          27/08/2019 - SFTN-173 - Adding a new field to Update integration related to Recruitment Ref code.
 *                          13/09/2019 - SFTN-223 - Populating Recruitment Ref code only for International applicants and skipping for Domestic applicants.
 *       Pulling out code - 11/10/2019 - SFTN-97  - Populating Submission location(Admission International Table)
 *                          06/11/2019 - SFTN-328 - ACP Duplicate created in CRM
 *                          29/11/2019 - SFTN-537 - Renamed class for consistency
 *                          16/01/2020 - SFTN-453 - Request for Advanced Standing indicator should be derived from the Application
 *           Martin Cadman  12/02/2020 - SFTN-648 - Added logic to derive the Person ID from the ADM key if unavailable on the Contact 
 *                      KL  16/06/2020 - SFTLG-869 - Adding Agency (Account) + Agent (Contact) fields out of Salesforce for mapping into the outbound Payload structure
 *                      KL  23/06/2020 - SFTLG-869 - Minor fixes based on testing outcome in SIT, removing all fields but Org Unit Code
 *          Shalini Mendu    4/08/2020 - SFTG-1255 - Rewriting class- Bulkifying outbound ACP call to Callista
 *                          20/10/2020 - SFTG-1499 - Agent Org Unit code in Outbound ACP is incorrect for My.app international
 *                          13/09/2020 - SFTG-2212 - Remove offerRound element from Outbound ACP payload
 *                          22/02/2022 - SFTG-2429/SFTG-2519/SFTG-2520 - ACP creation in Callista (BDP)
 *    17.04.2023 Ken McGuire: Changed Comments__c (255 characters) to LongComments__c (4000 characters)
 * *               Ken McGuire -    2023-05-03 - Removed comments__c field from request object        
 *           Sachin Shetty  05/09/2023 - EPCP-2980 - Added a static property - eventList that collects ObdACP__e events (Used for testing only)  
 *                                                 - Updated publishObdACPPEs method to return the collected events
 */
public with sharing class ObdACPImplementation extends UniCRMIntegrationPoint implements  Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    @TestVisible
    public List<Id> acpIdList = new List<Id>();
    public List<Application__c> appUpdatesList = new List<Application__c>();
    public List<Application_Course_Preference__c> acpUpdatesList = new List<Application_Course_Preference__c>();
    public List<Id> acpErrorIds = new List<Id>();
    public static Integer BATCHSIZE = 10;

    public ObdACPImplementation() {
        this.acpIdList = new List<Id>();
    }

    //Constructor 
    public ObdACPImplementation (List<Id> recordIdList, Integer batchsizeP)
    {
        this.acpIdList = recordIdList;
        this.doInit('IP07_Callista_ACP_Update');
        BATCHSIZE = batchsizeP;
    }
    
    /**
     * @description Method which gets invoked from the ACP trigger handler class
     * @param  List<ID> ACPRecordIds 
     */
    public static void fireCallistaOutboundRequest(List<Id> recordIds){
        ObdACPImplementation obj = new ObdACPImplementation(recordIds, BATCHSIZE);
        Database.executeBatch(obj, BATCHSIZE);

    }

    //start - Process records from the trigger
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT
        Id,
        Callista_Unique_Key_ADM__c,
        Callista_Applicant_Id__c,
        Admission_Application_Number__c,
        Application__c,
        Application__r.Submitted_Date__c,
        Application__r.CitizenCountryCode__c,
        Application__r.Residency_Status__c,
        Application__r.Credit_Intention__c,
        Application__r.Source_System__c,
        Application__r.Callista_Application_Id__c,
        Application__r.Agent__c,
        Applicant__r.CRM_Id__c,
        Application__r.External_Reference_Id__c,
        Application__r.Name,
        Callista_Unique_Key_AP__c,
        Course_Code__c,
        Basis_For_Adminssion_Type__c,
        Admission_Code__c,
        Application_Sequence_Number__c,
        Course_Version_Number__c,
        Location_Code__c,
        Attendance_Mode__c,
        Attendance_Type__c,
        Unit_Set_Code__c,
        Unit_Set_Version__c,
        Preference_Number__c,
        Documentation_Status_LOV__r.Value__c,
        Entry_Qualification_Status_LOV__r.Value__c,
        Outcome_Status_LOV__r.Value__c,
        Authorising_Person_ID__c,
        Authorised_Date__c,
        Override_Outcome_Reason__c,
        Offer_Date__c,
        Offer_Response_Date__c,
        Offer_Response_Status_LOV__r.Value__c,
        Proposed_Commencement_Date__c,
        Conditional_Offer_Status_LOV__r.Value__c,
        Conditional_Offer_Satisfied_Date__c,
        Conditions_Must_Be_Satisfied__c,
        Actual_Offer_Response_Date__c,
        Deferment_Status_LOV__r.Value__c,
        Deferred_Admission_Ci_Sequence__c,
        Deferred_Admission_Calendar_Type__c,
        Fee_Category__c,
        Fee_Payment_Option__c,
        Correspondence_Category__c,
        Enrolment_Category__c,
        Funding_Source__c,
        Acceptance_Condition__c,
        Offer_Condition__c,
        Agreed_Start_Date__c,
        Offer_Round__c,
        Person_ID__c,
        Academic_Calendar_Type__c,
        Academic_CI_Sequence_Number__c,
        Admission_Category__c,
        Admission_CI_Sequence_Number__c,
        Admission_Calendar_Type__c,
        Requirement_Satisfied_Code__c ,
        Precedent_ID__c,
        Recruitment_Reference_Code__c,
        Application__r.Submission_Location_Country__r.Callista_Code__c,
        Bulk_Data_Processing__r.Transfer_From__r.course_code__c,
        Bulk_Data_Processing__r.Transfer_To__r.course_code__c
        FROM Application_Course_Preference__c
        WHERE  Id in :acpIdList]);
       
    }
   
    //execute - call out to Callista for syncing the inserts/updates
    public void execute(Database.BatchableContext bc, List<sObject> scope) {    
        List<Application_Course_Preference__c> acpActualList =  scope;
        for(Application_Course_Preference__c acp:acpActualList)
        {
            
            if(acp.Person_ID__c == null && acp.Callista_Unique_Key_ADM__c == null)
            {
                //add into Exception list 
                LogUtilityException.logDebug('ObdACPImplementation', acp.Id, 'Unable to add the ACP record as there is no Person ID/ADM key '+acp.Id);

                acp.Callista_Error_Message__c = 'Unable to add the ACP record as there is no Person ID and ADM Key '+acp.Id;
                acp.Callista_Sync_Successful__c = false;
                acpUpdatesList.add(acp);
            }else {
                
                try {
                    ObdACPRequest acpRequest = ObdACPImplementation.createRequest(acp); 
                    Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
                    urlReplaceKeyValuePairs.put('{0}', acp.Person_ID__c != NULL?acp.Person_ID__c:acp.Callista_Unique_Key_ADM__c.left(8));
                    this.constructEndPoint(urlReplaceKeyValuePairs);
                    String prettyJSON = JSON.serializePretty(acpRequest);
                    if(acp.Application__r.Residency_Status__c!=null && acp.Application__r.Residency_Status__c.contains('DOM'))
                    {
                        prettyJSON = removeSubString(prettyJSON, '"recruitmentReferenceCode" : null,');
                        prettyJSON = removeSubString(prettyJSON, '"primaryNationalityCode" : null,');
                    }
                    //remove submissionLocationCode if null
                    prettyJSON = removeSubString(prettyJSON, '"submissionLocationCode" : null,');
                  
                    this.sendMessage(prettyJSON);
                    Application_Course_Preference__c updatedACP = this.updateACPWithWebResponse(acp, acpRequest); 
                    acpUpdatesList.add(updatedACP);

                }catch(System.CalloutException e) {
                    //add Ids to a list to retry Read time out call outs
                    if(e.getmessage() == 'Read timed out'){
                        acpErrorIds.add(acp.Id);
                    }
                   //add Exception log  
                   LogUtilityException.logExceptionMSG('ObdACPImplementation', acp.Id, 'Failed running ObdACPImplementation due to Callout exception'+acp.Id);
                }catch(Exception e)
                {
                   //add Exception log  
                   LogUtilityException.logException (e);
                }
            }
        }
        //Publish Outbound ACP events
        publishObdACPPEs(acpUpdatesList);
    }

    /**
     * @description  Helper method to create the Callista webservice request
     * @param  Application_Course_Preference__c ACPRecord 
     * @Return ObdACPRequest
     */
    public static ObdACPRequest createRequest(Application_Course_Preference__c acpRecord){
        ObdACPRequest acpRequest = new ObdACPRequest();
        ObdACPRequest.Application app = acpRequest.getApplication();
        Account agency = null;
        /********************************************************
        Application Setup
        ********************************************************/
        app.admissionApplNumber = acpRecord.Admission_Application_Number__c != null ? Integer.valueOf(acpRecord.Admission_Application_Number__c) : null;
        app.type = 'application';
        app.submittedDate = String.valueOf(acpRecord.Application__r.Submitted_Date__c);

        /********************************************************
        Needed for Insert
        ********************************************************/
        app.academicCalendarType = acpRecord.Academic_Calendar_Type__c;
        app.academicCiSequenceNumber = acpRecord.Academic_CI_Sequence_Number__c != null ? Integer.valueOf(acpRecord.Academic_CI_Sequence_Number__c) : null;
        app.admissionCalendarType = acpRecord.Admission_Calendar_Type__c;
        app.admissionCiSequenceNum = acpRecord.Admission_CI_Sequence_Number__c != null ? Integer.valueOf(acpRecord.Admission_CI_Sequence_Number__c) : null;
        app.admissionCategory = acpRecord.Admission_Category__c;
     
        /********************************************************
        Course Preference Setup
        ********************************************************/
        ObdACPRequest.CoursePreference pref = app.getCoursePreference();
        pref.type = 'coursePreference';
        pref.basisForAdmissionType = acpRecord.Basis_For_Adminssion_Type__c;
        pref.admissionCode = acpRecord.Admission_Code__c;
        pref.requestForAdvancedStandingIndicator = acpRecord.Application__r.Credit_Intention__c;
    
        if(acpRecord.Application__r.Residency_Status__c!=null && (!acpRecord.Application__r.Residency_Status__c.contains('DOM')))
        {
            pref.recruitmentReferenceCode = acpRecord.Recruitment_Reference_Code__c;    
            if (acpRecord.Application__r.CitizenCountryCode__c == BDPConstants.AUSTRALIA_CALLISTA_CODE) {
                    pref.primaryNationalityCode = '1603';
                } else {
                    pref.primaryNationalityCode = acpRecord.Application__r.citizenCountryCode__c;
                }
        }
        //Set elements for Source System CCT (Course Transfers project)
        if(acpRecord.Application__r.Source_System__c == 'CCT')
        {
            pref.courseCode = acpRecord.Bulk_Data_Processing__r.Transfer_To__r.Course_Code__c;
            pref.transferCourseCode =  acpRecord.Bulk_Data_Processing__r.Transfer_From__r.Course_Code__c;
           
            if(acpRecord.Application__r.Submission_Location_Country__r.Callista_Code__c == BDPConstants.AUSTRALIA_CALLISTA_CODE)
            {
                pref.submissionLocationCode = BDPConstants.VICTORIA_CALLISTA_CODE;
            }else {
                pref.submissionLocationCode = acpRecord.Application__r.Submission_Location_Country__r.Callista_Code__c;
            }
        }else {
            pref.submissionLocationCode = null;
            pref.courseCode = acpRecord.Course_Code__c;
        }
      
        if(acpRecord.Application__r.Residency_Status__c!=null && (acpRecord.Application__r.Residency_Status__c.contains('DOM')))
        {
            pref.primaryNationalityCode = null;
            pref.recruitmentReferenceCode = null;
        }
       
        /********************************************************
        Agency / Agent Setup.  Fields not populated will be pre-defaulted by MiX / Callista integration
        ********************************************************/
        if (acpRecord.Application__r.Residency_Status__c != 'DOM-AUS' && 
            acpRecord.Application__r.Residency_Status__c != 'DOM-NZ' && 
            acpRecord.Application__r.Residency_Status__c != 'DOM-PR' && 
            acpRecord.Application__r.Residency_Status__c != 'DOM-HV') 
        {
            //Retrive Agency record when Agent__c is not blank
            if (acpRecord.Application__r.Agent__c != null) 
            {
                agency = ObdACPImplementation.getAgencyRecord(acpRecord.Application__r.Agent__c);
            }
            //initialise ObdACPRequest.Agent
            ObdACPRequest.Agent agc = new ObdACPRequest.Agent();
            if (acpRecord.Application__r.Source_System__c == 'CCT' )
            {
                agc.agentOrgUnitCode = 'M-DIRECT';
            }else if (acpRecord.Application__r.Source_System__c == 'Partner') {
                agc.agentOrgUnitCode = Constants.PARTNR;
            }else if(acpRecord.Application__r.Source_System__c == 'my.app')
            {
                agc.agentOrgUnitCode = agency!=null?agency.Callista_Org_Unit_Code__c:'M-DIRECT';
            } else
            {
                agc.agentOrgUnitCode = agency!=null?agency.Callista_Org_Unit_Code__c:null;
            }
            pref.agent = agc;
        }

        /********************************************************
        Course Preference Instance Setup
        ********************************************************/
        ObdACPRequest.CoursePreferenceInstance prefInst = new ObdACPRequest.CoursePreferenceInstance();
        prefInst.callistaApplicationId = (acpRecord.Application__r?.Callista_Application_Id__c?.indexOf('-') == -1) ? acpRecord.Application__r.Callista_Application_Id__c : null;
        prefInst.sequenceNumber = acpRecord.Application_Sequence_Number__c != null ? Integer.valueOf(acpRecord.Application_Sequence_Number__c) : null;
        prefInst.preferenceNumber = acpRecord.Preference_Number__c != null ? Integer.valueOf(acpRecord.Preference_Number__c) : null;

        prefInst.courseCode = acpRecord.Course_Code__c;
        prefInst.courseVersionNumber = acpRecord.Course_Version_Number__c != null ? Integer.valueOf(acpRecord.Course_Version_Number__c) : null;
        prefInst.unitSetCode = acpRecord.Unit_Set_Code__c;
        prefInst.unitSetVersion = acpRecord.Unit_Set_Version__c != null ? Integer.valueOf(acpRecord.Unit_Set_Version__c) : null;
        prefInst.locationCode = acpRecord.Location_Code__c;
        prefInst.attendanceMode = acpRecord.Attendance_Mode__c;
        prefInst.attendanceType = acpRecord.Attendance_Type__c;

        //Key Statuses - Maps to Callista system values which is only accepted by the API
        prefInst.documentationStatus = acpRecord.Documentation_Status_LOV__r != null ? acpRecord.Documentation_Status_LOV__r.Value__c : 'PENDING';
        prefInst.entryQualificationStatus = acpRecord.Entry_Qualification_Status_LOV__r != null ? acpRecord.Entry_Qualification_Status_LOV__r.Value__c : 'PENDING';
        prefInst.outcomeStatus = acpRecord.Outcome_Status_LOV__c != null ? acpRecord.Outcome_Status_LOV__r.Value__c : 'IN-PROGRES';

        //Admission outcome information
        prefInst.admissionOutcomeStatusAuthDate = acpRecord.Authorised_Date__c != null ? String.valueOf(acpRecord.Authorised_Date__c) : null;
        prefInst.admissionOutcomeStatusAuthPersonId = acpRecord.Authorising_Person_ID__c;
        prefInst.admissionOutcomeStatusReason = acpRecord.Override_Outcome_Reason__c;

        prefInst.offerDate = acpRecord.Offer_Date__c != null ? String.valueOf(acpRecord.Offer_Date__c) : null;
        prefInst.offerResponseDate = acpRecord.Offer_Response_Date__c != null ? String.valueOf(acpRecord.Offer_Response_Date__c) : null;
        prefInst.offerResponseStatus = acpRecord.Offer_Response_Status_LOV__c != null ? acpRecord.Offer_Response_Status_LOV__r.Value__c : 'NOT-APPLIC';
        prefInst.actualOfferResponseDate = acpRecord.Actual_Offer_Response_Date__c != null ? String.valueOf(acpRecord.Actual_Offer_Response_Date__c) : null;

        //Conditional offer
        prefInst.conditionalOfferStatus = acpRecord.Conditional_Offer_Status_LOV__c != null ? acpRecord.Conditional_Offer_Status_LOV__r.Value__c : 'NOT-APPLIC';
        prefInst.conditionalOfferMustBeSatisfiedIndicator = acpRecord.Conditions_Must_Be_Satisfied__c;
        prefInst.conditionalOfferSatisfiedDate = acpRecord.Conditional_Offer_Satisfied_Date__c != null ? String.valueOf(acpRecord.Conditional_Offer_Satisfied_Date__c) : null;
        prefInst.offerCondition = acpRecord.Offer_Condition__c;

        //Auxillary information
        prefInst.defermentStatus = acpRecord.Deferment_Status_LOV__c != null ? acpRecord.Deferment_Status_LOV__r.Value__c : 'NOT-APPLIC';
        prefInst.feeCategory = acpRecord.Fee_Category__c;
        prefInst.hecsPaymentOption = acpRecord.Fee_Payment_Option__c;
        prefInst.correspondenceCategory = acpRecord.Correspondence_Category__c;
        prefInst.enrolmentCategory = acpRecord.Enrolment_Category__c;
        prefInst.fundingSource = acpRecord.Funding_Source__c;
        prefInst.applicantAcceptanceCondition = acpRecord.Acceptance_Condition__c;
        prefInst.agreedStartDate = acpRecord.Agreed_Start_Date__c != null ? String.valueOf(acpRecord.Agreed_Start_Date__c) : null;
        prefInst.deferredAdmissionCalendarType = acpRecord.Deferred_Admission_Calendar_Type__c;
        prefInst.deferredAdmissionCiSequenceNum = Integer.valueOf(acpRecord.Deferred_Admission_Ci_Sequence__c);
    
        ObdACPRequest.PrecedentInfo preInfo = new ObdACPRequest.PrecedentInfo();
        preInfo.precedentId = acpRecord.Precedent_ID__c != null ? Integer.valueOf(acpRecord.Precedent_ID__c) : null;
        preInfo.requirementSatisfiedCode = acpRecord.Requirement_Satisfied_Code__c;
        if(preInfo.precedentId==null && preInfo.requirementSatisfiedCode==null)
        {
            prefInst.precedents = new List<ObdACPRequest.PrecedentInfo>{} ;
        }
        else {
            prefInst.precedents = new List<ObdACPRequest.PrecedentInfo>{preInfo};
        }

        pref.coursePreferenceInstances.add(prefInst);
        return acpRequest;
    }

    /**
     * @description Method to parse webservice response and update
     * the ACP with the response
    */
    private Application_Course_Preference__c updateACPWithWebResponse(Application_Course_Preference__c acpRecord, ObdACPRequest acpRequest)
    {
        
        //Check for successful response
        if(this.httpResponseCode == 200)
        {
                ObdACPResponse acpResponse = (ObdACPResponse) System.JSON.deserialize(
                                                    JSON.serializePretty(this.getResponseBody()), ObdACPResponse.class);
                acpRecord.Admission_Application_Number__c = acpResponse.applications[0].admissionApplNumber;
                acpRecord.Application_Sequence_Number__c = acpResponse.applications[0].coursePreferences[0].coursePreferenceInstances[0].sequenceNumber;
                String resCourseCode =  acpResponse.applications[0].coursePreferences[0].courseCode;
                if(String.isBlank(acpRecord.Callista_Unique_Key_ADM__c))
                {
                    acpRecord.Callista_Unique_Key_ADM__c = acpRecord.Person_ID__c + '-' + 
                                                            acpRecord.Admission_Application_Number__c+ '-' +
                                                            resCourseCode + '-'+ acpRecord.Application_Sequence_Number__c;
                }
                //Set fields for CCT on Application__c/ACP to receive inbound ACP events
                if(acpRecord.Application__r.Source_System__c=='CCT')
                {
                    Application__c app = new Application__c(Id = acpRecord.Application__c);
                    app.Callista_Application_Id__c =  acpRecord.Person_ID__c + '-' + acpRecord.Admission_Application_Number__c;
                    this.appUpdatesList.add(app);
                    if(String.isBlank(acpRecord.Callista_Unique_Key_AP__c))
                    {
                        acpRecord.Callista_Unique_Key_AP__c = acpRecord.Person_ID__c+'-'+
                                                              acpRecord.Admission_Application_Number__c;
                    }
                }
                    acpRecord.Callista_Sync_Successful__c = true;
        }else {
                    acpRecord.Callista_Sync_Successful__c = false;
        }
        acpRecord.Callista_Submission_Message__c = JSON.serializePretty(acpRequest);
        acpRecord.Callista_Error_Message__c = this.getResponseBody() != null ? JSON.serializePretty(this.getResponseBody()) : String.valueOf(this.httpResponseCode);
        return acpRecord;
    }

    /**
    * @author KL
    * @description Gets all of the Agency (Account) + Agent (Contact) fields out of Salesforce for mapping into the outbound Payload structure
    * @date 16 June 2020
    * @param Id agencyId
    * @return Account agencyRecord
    */
    public static Account getAgencyRecord(Id agencyId){
       
        List<Account> agencies = [
            SELECT Id,
                Callista_Org_Unit_Code__c
            FROM Account
            WHERE Id = :agencyId
        ];

        if(agencies.size() > 0){
            return agencies.get(0);
        }
        else {
            return null;
        }
    }
  
   
   /**
     * @description Method to remove the elements with null values(so that they don't fail in Callista)
     * from the payload
     * @param  String ss - element which has null value
     * @param  String - payload after removing the element
    */
    public String removeSubString(String prettyJSON, String ss)
    {
        String remvString = prettyJSON.contains(ss)?prettyJSON.remove(ss):prettyJSON;
        return remvString;
    }

     /**
     * @description Method to create/publish ObdACP__e on Callista response
     * from the payload
     * @revision
     * Sachin Shetty - Sep 2023 - Added a static property that collects ObdACP__e events (Used for testing only)  
     * @param  List<Application_Course_Preference__c> acpList - List of ACP's
     * @return ObdACP__e event records
    */
    public List<ObdACP__e> publishObdACPPEs(List<Application_Course_Preference__c> acpList)
    {
        List<ObdACP__e> allACPEvList = new List<ObdACP__e>();
        List<ObdACP__e> publishACPEvList = new List<ObdACP__e>();
        try{
            for(Application_Course_Preference__c acp:acpList)
            {
                if(acp.Application__r.Source_System__c  == 'OES'  && !String.isBlank(acp.Callista_Unique_Key_ADM__c) )
                {
                    ObdACP__e obEvent = 
                        new ObdACP__e(
                            crmApplicantId__c = acp.Applicant__r.CRM_Id__c,
                            crmApplicationId__c = acp.Application__r.Name,
                            externalReferenceId__c = acp.Application__r.External_Reference_Id__c,
                            Workflow_Type__c = 'ACP Response Update',
                            Workflow_Status__c =  acp.Callista_Sync_Successful__c,
                            Workflow_Response_Message__c =  acp.Callista_Error_Message__c
                        );  
                        allACPEvList.add(obEvent);
                }
            }
            
            for(ObdACP__e oe: allACPEvList)
            {
                if(String.isBlank(oe.crmApplicantId__c) || String.isBlank(oe.crmApplicationId__c) ||
                    String.isBlank(oe.externalReferenceId__c))
                {
                    LogUtilityException.logDebug('Outbound ACP event ObdACP__e', oe, 'ObdACP__e cannot be published as one of the  references is missing');
                }else
                {
                    publishACPEvList.add(oe);
                    LogUtilityException.logDebug('Outbound ACP event ObdACP__e', oe, 'ObdACP__e Published successfully');
                } 
            }
            if(publishACPEvList.size()>0) 
            {
                EventBus.publish(publishACPEvList);
            }
        
        }catch(Exception e)
        {
            LogUtilityException.logException (e);
        }   
        return allACPEvList;
    }      

    //Commit ACP, Application and Exceptionlog
    public void finish(Database.BatchableContext bc) 
    {   
        //Update ACP
        if(!acpUpdatesList.isEmpty()){
            Database.update(acpUpdatesList, false);
        }
        
        //Update Application
        if(!appUpdatesList.isEmpty()){
            Database.update(appUpdatesList, false);
        }

        //Retry Connection timed out ACPs
        if(!acpErrorIds.isEmpty()){
            ObdACPImplementation.fireCallistaOutboundRequest(acpErrorIds);
        }
    }

}