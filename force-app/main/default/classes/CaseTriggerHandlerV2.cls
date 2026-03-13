/**
 * @author Nick Guia
 * @description Trigger Handler for case object.This is part of code refactor to fix too many SOQL error.
 *              To mitigate amount of effort to required, Trigger handler criteria will not be implemented for now,
 *              and will be part of future code optimization.
 * @revision    Anterey Custodio, 23.Jan.2017 - only fire trigger if it is one of these record types
 *              Nick Guia, 04.Dec.2017 - moved retrieve method to CaseUtilities and modified logic
 *              APRivera, 05.June.2017 - Added logic for case age accurate calculations
 *              APRivera, 19.June.2017 - Decommission Queue Business Time Logic this is a test
 *              APRivera, 10.June.2018 - Refactored - Uses New bindExtended Framework
 *              KEVasco (GrowthOps), 03.Sep.2019 - Added PredictPropensityToTransfer
 *              Nick Guia, 28.OCT.2019  - Added ManageRelatedLead
 *              APRivera, 02.March.2020 - Included MonCon Support recordtype on Contact Course Linking logic
 *              ayush.agrawal@monash.edu - Exclude MonCon Support cases from default enquiry type logic.
 *              KL, 31.August.2020 - Changes fro SFTG-1377, to exclude unneeded processing for MUM Enquiries
 *              APRivera, 18.May.2021 - SA-438, Added logic for Case Skill-based routing
 *              Inderpal Dhanoa - 27.July.2021 - sync the Approver/Rejecter with Enquiry (ENGAGEIE-995)
 *              Rajesh Punjabi - Update owner id for merged cases (SS-71)  30-05-2022
 *              Rajesh Punjabi  - Remove merge case parent-child functionality 11-09-2023
 *              Vinothraja - 25.Sept.2023 - Added logic to Associate Agency to APNG Enquiries at the time of creation
 *              Vinothraja - 03.Oct.2023 - Added logic to Create Summary File after an APNG Enquiry creation
 *              Martin - 13/11/2023 - Removed Enquiry Age History references
 *              Inderpal Dhanoa - 17/06/2024 - OCR Sync MCT-404
 *              Inderpal Dhanoa - 17-07-2024 - Enq sync Logic MCT-442
 *              Inderpal Dhanoa - 23-07-2024 - OCR sync Logic update MCT-455
 *              Mac Domingo - 07/06/2024 - Added logic to create archive audit records. 
 *              Mac Domingo - 01/08/2024 - Fixed heaps of PMD errors
 */

 public class CaseTriggerHandlerV2 {
    
    public static Id academicProgressAssessmentCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Academic_Progress_Assessment').getRecordTypeId();
    public static Id mroEnquiryRt = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
    public static Boolean runOnce = false;
    public static String priorityMedium = 'Medium';
    public static String priorityLow = 'Low';
     /**
     * @author  Rajesh Punjabi
     * @description Set Account for MRO record with Contact RT=Student
     * @event: After Update
    */
    public class UpdateAccountForMROEnquiries extends TriggerAbstract {
        Set<Id> setContactIds = new Set<Id>();
        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if (caseRecord.RecordTypeId == mroEnquiryRt && caseRecord.ContactId != null && (oldCaseRecord.ContactId != caseRecord.ContactId || oldCaseRecord.AccountId != caseRecord.AccountId)) {
                setContactIds.add(caseRecord.ContactId);
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.updateAccountforKnownToMonashContact(records, setContactIds);
            }
            LogUtilityException.getLimits();
        }
    }

     /**
      * @author			ayush.agrawal@monash.edu
      * @date:			13-04-2021
      * @description	Generate course linking fields for related course attempt
      * 					for Monash Forms submissions.
      */
     public class MapCourseLinkingFieldsForMonashForms extends TriggerAbstract {

         public override void process(SObject record) {
             Case c = (Case)record;
             if(c.Origin == 'Web - Monash Forms' && c.Course_Attempt__c != null) {
                 records.add(c);
             }
         }

         public override void execute() {
             if(!records.isEmpty()) {
                 CaseServicesV2.mapCourseLinkingFieldsForMonashForms(records);
             }
         }
     }

    /**
    * @author:	   inderpal.dhanoa@monash.edu
    * @description Auto-link OCR to Enquiry if the Weightage exceeds certain numbr to Case Trigger
    * @revision    JUN.9.2024  Inderpal - Created
    */
    public class LinkOCRToMCEnquiry extends TriggerAbstract {
        public Set<String> setEnqIdWithClientQuestionWeightage = new Set<String>();
        public override void process(SObject record, SObject oldRec) {
            Case cse = (Case)record;
            Case oldCse = (Case)oldRec;
            if (!runOnce && cse.RecordTypeId == MonConCaseServices.MONCONSUPPORT_RECTYPEID && cse.Weightage__c != oldCse.Weightage__c && 
                cse.Weightage__c > = Integer.valueOf(Label.JRGWeightageCriteria) && (oldCse.Weightage__c == null || Integer.valueOf(oldCse.Weightage__c) == 0) && 
                cse.Enquiry_Type__c == 'JRG' && FeatureManagement.checkPermission('Validate_Retention_Enquiry') && cse.Alias__c.contains('-')) {
                    setEnqIdWithClientQuestionWeightage.add(String.valueOf(cse.Id) + '@@@Client_Question@@@'+ String.valueOf(cse.Weightage__c) + '@@@Client_Question@@@' + cse.Description);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!setEnqIdWithClientQuestionWeightage.isEmpty()){
                MonConCaseServices.syncOCRWithEnquiry(setEnqIdWithClientQuestionWeightage);
                runOnce = true;
            }
            LogUtilityException.getLimits();
        }
    }

    /**
    * @description Auto-links contact's Course to enquiry.
    *              Moved from EnquiryCourseInformationCC (when case is loaded to console) to Case Trigger
    * @revision    JUL.9.2019  APRivera - Created
    *              MAR.4.2020  APRivera - Added Contact linking upon creation for MonCon Support Cases
    *              MAY.1.2024  Tom Gangemi
    *                  - Exclude Monash Forms records that are handled by MapCourseLinkingFieldsForMonashForms
     *                 - Break conditional into chunks for readability and add comments
     *             JUL.30.2024  IDhanoa - Added MF linking upon Enquiry Type update
    */
    public class LinkCourseWhenContactLinks extends TriggerAbstract {
        public Set<Id> setContactIds = new Set<Id>();
        public override void process(SObject record) {
            Case cse = (Case)record;

            Boolean isOpenWithContact = cse.ContactId != null && cse.Status == 'Open';

            Boolean formLinked = cse.Origin == 'Web - Monash Forms' && cse.Course_Attempt__c != null;

            Boolean recordTypesRuleA = cse.RecordTypeId == MonConCaseServices.SPECON_RECTYPEID
                || cse.RecordTypeId == MonConCaseServices.MONCON_RECTYPEID
                || cse.RecordTypeId == MonConCaseServices.COMPLAINT_RECTYPEID;

            // Above RTs get course link set if open, has contact, not linked via form, and not already linked
            // (not sure what Managing Faculty != '' is supposed to do but leaving it just in-case)
            Boolean ruleA = recordTypesRuleA && isOpenWithContact && !cse.Course_Linked__c
                && String.valueOf(cse.Managing_Faculty__c) != '' && !formLinked;

            // Non-Form MonConSup cases always get course link set here
            Boolean ruleB = cse.RecordTypeId == MonConCaseServices.MONCONSUPPORT_RECTYPEID  && isOpenWithContact
                && cse.Origin != 'Web - Monash Forms';

            if(ruleA || ruleB) {
                records.add(cse);
                setContactIds.add(cse.ContactId);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Case cse = (Case)record;
            Case oldCse = (Case)oldRec;

            Boolean recordTypesRuleA = cse.RecordTypeId == MonConCaseServices.SPECON_RECTYPEID
                || cse.RecordTypeId == MonConCaseServices.MONCON_RECTYPEID
                || cse.RecordTypeId == MonConCaseServices.COMPLAINT_RECTYPEID;

            // Update if open and contact has changed
            Boolean ruleA = recordTypesRuleA && cse.ContactId != null && cse.ContactId != oldCse.ContactId
                && cse.Status == 'Open' && String.valueOf(cse.Managing_Faculty__c) != '';

            // MonConSup cases always get updated
            Boolean ruleB = cse.RecordTypeId == MonConCaseServices.MONCONSUPPORT_RECTYPEID
                && cse.ContactId != null && cse.Origin != 'Web - Monash Forms';

            // Checks if the Managing Faculty is set to a NULL value and the Controlling Picklist Enquiry Type has a dependent MF value
            Boolean ruleC = validateRuleC(cse, oldCse);
            if(ruleA || ruleB || ruleC) {
                records.add(cse);
                setContactIds.add(cse.ContactId);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                MonConCaseServices.linkCourseToCase(records, setContactIds);
            }
            LogUtilityException.getLimits();
        }

        /**
        * @description This method Checks if there is a dependent Managing Faculty picklist value 
        * @param    cse Case new record
        * @param    oldCse Case old record
        * @return   Boolean value if the record should be considered or not
        */
        public Boolean validateRuleC(Case cse, Case oldCse){
            String mcEnquiryTypeIgnore = String.valueOf(Label.Monash_Connect_Enquiry_Type_Ignore);
            Set<String> ignoreEnqType = new Set<String> ();
            String objectName = 'Case'; 
            String dependentField = 'Managing_Faculty__c' ; //Define dependent picklist value
            ignoreEnqType.addAll(mcEnquiryTypeIgnore.split(';'));
            Map<String, List<String>> controllingFieldByDepndntField = new Map<String, List<String>>(); 
            // if MF field has a dependent picklist value and is now Empty   
            if(cse.RecordTypeId == MonConCaseServices.MONCON_RECTYPEID && cse.Enquiry_Type__c != oldCse.Enquiry_Type__c && 
            String.isBlank(String.ValueOf(cse.Managing_Faculty__c)) && cse.ContactId != null && !ignoreEnqType.contains(cse.Enquiry_Type__c)){
                if(controllingFieldByDepndntField.isEmpty()){
                    Schema.sObjectField dependToken = Schema.getGlobalDescribe().get( objectName ).getDescribe().fields.getMap().get( dependentField );
                    MonConCaseServices.FieldDependencyWrapper obj = MonConCaseServices.getDependentPicklistValuesViaDependentFieldAPI(dependToken);
                    controllingFieldByDepndntField = obj.fieldDependencyMap;
                }
                // Check if the Selected Enquiry type has a dependent picklist value for Managing Faculty field,
                if(controllingFieldByDepndntField.containsKey(cse.Enquiry_Type__c)){
                    return true;
                }    
            }
            return false;
        }
    }

    /**
    * @description This method pre-populates the Categories according to the selected Enquiry Reason for Change
    * @revision    JUN.11.2019  APRivera   - Refactored
    */
    public class PrepopulateCategory extends TriggerAbstract {
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            Boolean isCategory3OnlyPopulated = SEBSCaseServices.bIsCategory3OnlyPopulated(caseRecord);
            if (caseRecord.RecordTypeId == SEBSCaseServices.SEBS_RECTYPEID && isCategory3OnlyPopulated
                    && caseRecord.Origin == CaseUtilities.ORIGIN_WEB) {
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                SEBSCaseServices.populateCategoryByReasonForChange(records);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @description map course code text to a course code record on insert.
     *              if specialisation has been passed in, then use that field over basic course code
     * @revision    JUN.11.2019  APRivera   - Refactored
     */
    public class MapCourseCode extends TriggerAbstract {
        public Set<String> setCourses = new Set<String>();
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            //if (CaseUtilities.isAllowedRecordType(caseRecord.RecordTypeId)){
            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId){
                if(caseRecord.Course__c == null && (caseRecord.Course_Code__c > '' || caseRecord.Course_Specialisation__c > '')) {
                    records.add(caseRecord);
                    if(caseRecord.Course_Code__c > '') {
                        setCourses.add(caseRecord.Course_Code__c); // eg D6001
                    }
                    if(caseRecord.Course_Specialisation__c > ''){
                        setCourses.add(caseRecord.Course_Code__c + caseRecord.Course_Specialisation__c); // eg D6001D60013
                    } 
                }
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.mapCourseCode(records, setCourses);
            }
            LogUtilityException.getLimits();
        }

    }

    /**
     * @author       Ryan Wilson
     * @date         16/09/2016
     * @description  Added populating Queue name and Enquiry response time in business hours
     * @revision
     *   DEC.04.2017  Nick Guia  - moved from CaseServices as part of code optimisation
     *   JUN.25.2018  APRivera   - Used the case.BusinessHoursId in Enquiry_Response_Time_Business_Hours__c calculation instead of default BusinessHoursId
     *   JUN.11.2019  APRivera   - Refactored
     */
    public class MaintainLastQueueOwner extends TriggerAbstract {
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId && caseRecord.OwnerId.getSobjectType() == Group.SObjectType){
                records.add(caseRecord);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId
                    && ((caseRecord.OwnerId != oldCaseRecord.OwnerId && caseRecord.OwnerId.getSobjectType() == Group.SObjectType)
                    || caseRecord.First_Response_Date_Time__c != null)){
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.maintainLastQueueOwner(records);
            }
            LogUtilityException.getLimits();
        }
    }
	
	/**
     * @author       Inderpal Dhanoa
     * @date         27/07/2021
     * @description  Sync the Approver & Rejecter for Enterprise Case  
     */
    public class SyncApproverRejecter extends TriggerAbstract {

        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId == CaseUtilities.entprseRecordTypeId && caseRecord.MonashCollege_Outcome__c != oldCaseRecord.MonashCollege_Outcome__c 
                && (caseRecord.MonashCollege_Outcome__c == 'Approved' || caseRecord.MonashCollege_Outcome__c == 'Not Approved')){
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.syncApproverRejecter(records);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
    * @description purpose is to intercept new web cases and see if there is an email address we can link case to.
    *              query uses SOSL so one query per case after efficient check done, but is only done for inbound web cases
    *              that couldnt match via more efficient SOQL query first, so extremely unlikely to exceed limit
    * @revision     JUN.11.2019  APRivera   - Refactored
    */
    public class CheckForAndLinkToContacts extends TriggerAbstract {
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId){
                if(caseRecord.ContactId == null && caseRecord.SuppliedEmail > '' ) {
                    records.add(caseRecord);
                }
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.checkForAndLinkToContacts(records);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @description purpose is to map provided Record Type Name into an Id if possible,
     *              and only if is empty at insert (usually from a web form)
     * @revision
     *   DEC.04.2017  Nick Guia  - moved from CaseServices as part of code optimisation
     * @revision     JUN.11.2019  APRivera   - Refactored
     */
    public class SetRecordTypeIdUsingCaseType extends TriggerAbstract {
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.Case_Type__c > ''){
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.setRecordTypeIdUsingCaseType(records);
            }
            LogUtilityException.getLimits();
        }
    }

	 /**
    * @description purpose is to keep the Enquiry Organisation Object in Sync with the External Orgs linked to the Opportunity 
    * @author     MAY.19.2021  idha0002  
    */
    public class syncEnquiryOrganisationAndEnquiry extends TriggerAbstract {
	
		public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId == CaseUtilities.entprseRecordTypeId && !String.isBlank((String)caseRecord.Opportunity__c)){
                records.add(caseRecord);
            }
        }
        
        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId == CaseUtilities.entprseRecordTypeId && caseRecord.Opportunity__c != oldCaseRecord.Opportunity__c){
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.updateEnquiryOrganisation(records); 
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @description set default values on a new case if a user has valid defaults in place (service console user)
     * @revision     JUN.11.2019  APRivera   - Refactored
     */
    public class SetDefaultsOnNewCases extends TriggerAbstract {
        public User usr = UserServices.contextUser;
        Id monConSupportCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            Boolean userHasDefaults = (usr.Queue__c != null && usr.Location__c != null && usr.Enquiry_Role__c != null && usr.My_Information_LastUpdate__c == Date.today());
            Boolean userHasEnquiryRecordTypeDefault = (usr.Default_Enquiry_Record_Type__c != null);
            Boolean isMonConSupportCase = (caseRecord.RecordTypeId == MonConCaseServices.MONCONSUPPORT_RECTYPEID);
            //Setup My Information Details
            if(userHasDefaults || userHasEnquiryRecordTypeDefault || isMonConSupportCase){
                //Exclude enquiries created from Live agent from being overwritten
                if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId && caseRecord.Origin != Label.Chat && caseRecord.RecordTypeId != monConSupportCaseRecordTypeId){
                    records.add(caseRecord);
                }
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.setDefaultsOnNewCases(records, usr);
            }
            LogUtilityException.getLimits();
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         05/06/2018
    * @description  Method that will set the value of Business Hours for Monash Connect Enquiries
    * @revision     04/06/2018 - Initial Version
    *               JUN.11.2019  APRivera   - Refactored
    *******************************************************************************/
	/*
    public class UpdateCaseBusinessHoursForMCCase extends TriggerAbstract {

        public Set<String> setCaseOwner = new Set<String>();

        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId == MonConCaseServices.MONCON_RECTYPEID){
                records.add(caseRecord);
                setCaseOwner.add(caseRecord.Case_Owner_String__c);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId == MonConCaseServices.MONCON_RECTYPEID
                    && (caseRecord.Status != oldCaseRecord.Status || caseRecord.OwnerId  != oldCaseRecord.OwnerId)){
                records.add(caseRecord);
                setCaseOwner.add(caseRecord.Case_Owner_String__c);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                MonConCaseServices.updateCaseBusinessHoursForMCCase(records, setCaseOwner);
            }
            LogUtilityException.getLimits();
        }
    }
    */


    /**
     * @author Kristian Vegerano
     * @description handles all after update events. Filter event criteria here
     * @param caseList - Trigger.new context variable
     * @revision     JUN.11.2019  APRivera   - Refactored
     */
    public class AssociateContactToPostApplicationEnquiries extends TriggerAbstract {
        public Set<String> setMonashStudentIds = new Set<String>();
        public Set<String> setApplicationIds = new Set<String>();
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId == StudRecCaseServices.POST_APPLICATION_RECTYPEID &&
                    (caseRecord.Monash_Student_Form_ID__c != null || caseRecord.Monash_Application_ID__c != null)){
                if(caseRecord.Monash_Student_Form_ID__c != null){
                    setMonashStudentIds.add(caseRecord.Monash_Student_Form_ID__c);
                }
                if(caseRecord.Monash_Application_ID__c != null){
                    setApplicationIds.add(caseRecord.Monash_Application_ID__c);
                } 
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                StudRecCaseServices.associateContactToPostApplicationEnquiries(records,setMonashStudentIds,setApplicationIds);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @author Kristian Vegerano
     * @description Associates a Monash College Enquiry to a contact record on create
     * @param caseList - Trigger.new context variable
     * @revision     JUN.11.2019  APRivera   - Refactored
     */
    public class AssociateContactToMonashCollegeEnquiries extends TriggerAbstract {
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId == MonashCollegeCaseServices.PROFESSIONALYEAR_RECTYPEID
                    && caseRecord.ContactId == null && caseRecord.SuppliedEmail != null){
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                MonashCollegeCaseServices.associateContactToMonashCollegeEnquiries(records);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @author          Kristian Vegerano
     * @description     Defaults the enquiry's enquiry type to current course if the related contact has Monash Person ID
     * @param           caseList - Trigger.new context variable
     * @revision     JUN.11.2019  APRivera   - Refactored
     */
    public class DefaultMonashCollegeEnquiryType extends TriggerAbstract {
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId == MonashCollegeCaseServices.PROFESSIONALYEAR_RECTYPEID
                    && caseRecord.Enquiry_Type__c == null && caseRecord.ContactId != null){
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                MonashCollegeCaseServices.defaultMonashCollegeEnquiryType(records);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @description if case contact changes, then clear the case account field to overcome known issue in console presently
     * @revision
     *              DEC.04.2017  Nick Guia  - moved from CaseServices as part of code optimisation
     *                           - modified logic to use maps instead of utilising index
     *              JUN.11.2019  APRivera   - Refactored
     */
    public class ClearAccountFieldOnContactChange extends TriggerAbstract {
        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if (caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId
                    && (oldCaseRecord.ContactId != null && oldCaseRecord.ContactId != caseRecord.ContactId
                    || oldCaseRecord.ContactId != caseRecord.ContactId && caseRecord.ContactId == null)) {
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.clearAccountFieldOnContactChange(records);
            }
            LogUtilityException.getLimits();
        }
    }


    /**
     * @author          Kristian Vegerano
     * @description     Filter to ensure that only enquiries with owner changed will be processed
     * @param           newMap - map of case records on the trigger batch
     *                  oldMap - map of case records with previous values on the trigger batch
     * @revision
     *                  JUN.11.2019  APRivera   - Refactored
     */
    public class TransferEnquiryOwnership extends TriggerAbstract {
        public Environment_Settings__c environmentSettings = CaseUtilities.environmentSettings;
        public Map<Id, Case> mapOldCasesByIds = new Map<Id, Case>();
        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(environmentSettings.Transfer_Enquiry_Rule_Active__c) {
                if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.outboundCallRecordTypeId) {
                    //Only run the logic when the user updating the enquiry is an internal user excluding the user stated on the transfer enquiry rule exclude user custom setting
                    if (UserInfo.getName() != environmentSettings.Transfer_Enquiry_Rule_Exclude_User__c && UserInfo.getUserType() == 'Standard') {
                        //Only process open cases where owner has been changed to a queue
                        if (caseRecord.OwnerId != null && caseRecord.OwnerId != oldCaseRecord.OwnerId && !caseRecord.IsClosed) {
                            records.add(caseRecord);
                            mapOldCasesByIds.put(oldCaseRecord.Id, oldCaseRecord);
                        }
                    }
                }
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.transferEnquiryOwnership(records, mapOldCasesByIds);
                environmentSettings = null;
                CaseUtilities.environmentSettings = null;
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @description if is an inbound case via webform - as defined by suppliedName != null - then add a course
     *              interest record
     *              Addresses the need to have all course interests represented consistently
     *              ie. via a course interest record.
     * @revision
     *              DEC.04.2017     Nick Guia   - moved from CaseServices as part of code optmisation.
     *              JUN.18.2019  APRivera   - Refactored
     */
    public class AddCourseInterests extends TriggerAbstract {
        public Set<Id> setCaseIds = new Set<Id>();
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            String strExcludedEnquiryType = Label.Enquiry_Interest_Exclusions;
            if(caseRecord.Enquiry_Type__c != null){
                if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId && !strExcludedEnquiryType.contains(caseRecord.Enquiry_Type__c) &&
                        (caseRecord.Course__c != null || caseRecord.Managing_Faculty__c > '' || caseRecord.Supplied_Area_of_Interest__c > '') &&
                        (caseRecord.Origin != null && caseRecord.Origin.indexOf('Email') == -1) ){
                    setCaseIds.add(caseRecord.Id);
                }
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!setCaseIds.isEmpty()){
                CaseServicesV2.addCourseInterests(setCaseIds);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @author              Kristian Vegerano
     * @description         Method that sends an email to faculty which includes the attachment submitted from the form
     * @param newMap        Trigger.newMap context variable
     * @revision            JUN.18.2019  APRivera   - Refactored
     */
    public class MgeDefaultValuesIncludeAttachmentOnEmailToFaculty extends TriggerAbstract {
        public Set<Id> setCaseIds = new Set<Id>();
        public override void process(SObject record) {
            Case caseRecord = (Case) record;
            if(caseRecord.RecordTypeId == MGECaseServices.MGE_RECTYPEID && caseRecord.Origin == CaseUtilities.ORIGIN_WEB_RDR){
                records.add(caseRecord);
                setCaseIds.add(caseRecord.Id);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if (!records.isEmpty()) {
                MGECaseServices.mgeDefaultValuesIncludeAttachmentOnEmailToFaculty(records,setCaseIds);
            }
            LogUtilityException.getLimits();
        }

    }

     /**
     * @description monitors case changes for case closed to case open, and sets datetime if occurs
     * @revision
     *   DEC.04.2017  Nick Guia  - moved from CaseServices as part of code optimisation
     *   JUN.18.2019  APRivera   - Refactored
     */
    public class ManageReopenedDateTime extends TriggerAbstract {
        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId &&
                    oldCaseRecord.IsClosed == true && caseRecord.IsClosed == false){
                records.add(new Case(Id = caseRecord.Id, Enquiry_Reopened__c = Datetime.now()));
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                TriggerCommon.disableTrigger('Case'); // to prevent recursion
                update records;
                TriggerCommon.enableTrigger('Case');
            }
            LogUtilityException.getLimits();
        }
    }

    /**
     * @author       Ryan Wilson
     * @date         20/01/2017
     * @description  Method to do callout to Calabrio to get the agents call id
     * @revision
     *   DEC.04.2017  Nick Guia  - moved from CaseServices as part of code optimisation
     *   JUN.18.2019  APRivera   - Refactored
     */
//    public class CheckForActiveCall extends TriggerAbstract {
//        public override void process(SObject record, SObject oldRec) {
//            Case caseRecord = (Case)record;
//            if(caseRecord.RecordTypeId != CaseUtilities.outboundCallRecordTypeId) {
//                if(!TriggerCommon.inFutureContext && caseRecord.Origin == 'Phone'){
//                    records.add(caseRecord);
//                }
//            }
//        }
//
//        public override void execute() {
//            //Checks if there are records to be processed
//            if(!records.isEmpty()){
//                CaseServicesV2.checkforActiveCall(records);
//            }
//            LogUtilityException.getLimits();
//        }
//    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         05/06/2018
    * @description  Method that will set the value of Business Hours for Monash Connect Enquiries
    * @revision     04/06/2018 - Initial Version
    *               JUN.11.2019  APRivera   - Refactored
    *               FEB.12.2020  APRivera   - Used Set as placeholder of all Case origin to limit records
    *                                         to be retrieved from Custom Metadata
    *               AUG.31.2020  KL         - added logic to exclude MUM Cases
    *******************************************************************************/
    public class SetEnquiryOriginCategory extends TriggerAbstract {
        public Set<String> setCaseOrigin = new Set<String>();
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId &&
               caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId && caseRecord.Origin != null && caseRecord.RecordTypeId != CaseUtilities.mumRecordTypeId){
                if(!setCaseOrigin.contains(caseRecord.Origin)){
                    setCaseOrigin.add(caseRecord.Origin);
                } 
                records.add(caseRecord);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId &&
               caseRecord.RecordTypeId != CaseUtilities.pdRecordTypeId &&
                    oldCaseRecord.Origin != null || oldCaseRecord.Origin != caseRecord.Origin){
                if(!setCaseOrigin.contains(caseRecord.Origin)){
                    setCaseOrigin.add(caseRecord.Origin);
                } 
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.setEnquiryOrigin(records, setCaseOrigin);
            }
            LogUtilityException.getLimits();
        }
    }


    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Class that will create or link Entitlement to enquiry
    * @revision     27/05/2019 - Initial Version
    *               JUN.11.2019  APRivera   - Refactored
    *******************************************************************************/
    public class CreateLinkEntitlementToCase extends TriggerAbstract {
        public Set<Id> setAcctIds = new Set<Id>();
        public override void process(SObject record) {
            //Instantiate ChannelMapping Map and Retrieves custom metadata
            Map<String, System_Settings__mdt> mapChMappingSLA = MonConCaseServices.getMappingSLASByStrings();
            Case caseRecord = (Case)record;
            if(mapChMappingSLA.containsKey(caseRecord.Channel_Mapping__c) && caseRecord.RecordTypeId == MonConCaseServices.MONCON_RECTYPEID
                    && caseRecord.EntitlementId == null && caseRecord.AccountId != null && caseRecord.Enquiry_Owner_Role__c != 'Spam'){
                records.add(caseRecord);
                setAcctIds.add(caseRecord.AccountId);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                MonConCaseServices.createOrLinkEntitlementToCase(records,setAcctIds);
            }
            LogUtilityException.getLimits();
        }
    }


    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Class that will autocomplete case milestones once violated.
    * @revision     27/05/2019 - Initial Version
    *               JUN.11.2019  APRivera   - Refactored
    *******************************************************************************/
    public class AutoCompleteCaseMilestone  extends TriggerAbstract{
        public List<Id> lstCaseIds = new List<Id>();
        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId == MonConCaseServices.MONCON_RECTYPEID
                    && oldCaseRecord.SLA_Breach_DateTime__c != caseRecord.SLA_Breach_DateTime__c){
                lstCaseIds.add(caseRecord.Id);
            }
        }

        public override void execute() {
            Datetime dtCompletionDate = System.now();
            //Checks if there are records to be processed
            if(!lstCaseIds.isEmpty()){
                MonConCaseServices.insertCaseCommentOnSLAViolation(lstCaseIds);
                MonConCaseServices.completeMilestone(lstCaseIds, 'Monash Connect Milestone', dtCompletionDate);
            }
            LogUtilityException.getLimits();
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  updates case business waiting time
    * @revision     JUN.11.2019  APRivera   - Refactored
    *******************************************************************************/
    public class UpdateCaseBusinessWaitingTime extends TriggerAbstract {
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.outboundCallRecordTypeId) {
                if(caseRecord.OwnerId != null && caseRecord.Status == 'Open'){
                    records.add(caseRecord);
                }
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.outboundCallRecordTypeId) {
                if(caseRecord.OwnerId != null && caseRecord.OwnerId != oldCaseRecord.OwnerId &&
                        caseRecord.Status == 'Open' && caseRecord.Status != oldCaseRecord.Status){
                    records.add(caseRecord);
                }
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                CaseServicesV2.updateCaseBusinessWaitingTime(records);
            }
            LogUtilityException.getLimits();
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         27/05/2019
    * @description  Clone Email Attachment To Contact Document Using Cases
    * @revision     JUN.11.2019  APRivera   - Refactored
    *******************************************************************************/
    public class CloneEmailAttachmentToContactDocumentUsingCases extends TriggerAbstract {
        public Map<Id, Case> newCaseMap = new Map<Id, Case>();
        public Map<Id, Case> oldCaseMap = new Map<Id, Case>();

        public override void process(SObject record, SObject oldRec) {
            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(caseRecord.RecordTypeId == AdmissionsCaseServices.ADMISSIONS_RECTYPEID){
                records.add(caseRecord);
                newCaseMap.put(caseRecord.Id, caseRecord);
                oldCaseMap.put(oldCaseRecord.Id, oldCaseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                AttachmentServices.cloneEmailAttachmentToContactDocumentUsingCases(oldCaseMap, newCaseMap);
            }
            LogUtilityException.getLimits();
        }

    }

    /**
    *  @author         Kristian Vegerano
    *  @description    Method that would check current / future / past course enquiries required fields before letting it get solved.
    *  Revisions
    *                  18/06/2019 - Russell Cadapan - Refactored
    */
    public class ValidateFutureCourseEnquiriesBeforeClosing extends TriggerAbstract {

        Set<Id> setCaseIds = new Set<Id>();

        public override void process(SObject record, SObject oldRec) {
            Environment_Settings__c environmentSettings = CaseUtilities.environmentSettings;

            Case caseRecord = (Case)record;
            Case oldCaseRecord = (Case)oldRec;

            if(caseRecord.RecordTypeId != academicProgressAssessmentCaseRecordTypeId && caseRecord.RecordTypeId != CaseUtilities.outboundCallRecordTypeId) {
                if(environmentSettings.MC_Future_Course_Validation__c){
                    // if the enquiry contact is not null
                    if(caseRecord.ContactId != null){
                        // if the enquiry owner is a user
                        if(caseRecord.OwnerId.getSobjectType() == User.SObjectType){
                            // if the status changed OR enquiry type changed
                            if((caseRecord.Status != null && caseRecord.Status != oldCaseRecord.Status) ||
                                    (caseRecord.Enquiry_Type__c != null && caseRecord.Enquiry_Type__c != oldCaseRecord.Enquiry_Type__c)){
                                //Filter Future Course Enquiries
                                if(caseRecord.Enquiry_Type__c == Label.Future_Course){
                                    records.add(caseRecord);
                                    setCaseIds.add(caseRecord.Id);
                                }
                            }
                        }
                    }
                }
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                MonConCaseServices.validateFutureCourseEnquiriesBeforeClosing(records, setCaseIds);
            }
            LogUtilityException.getLimits();
        }
    }
    /**
    *  @author         Russell Cadapan
    *  @description    Method to update Guest Type field
    *  Revisions
    *                  18/06/2019 - Russell Cadapan - Refactored
    */
    public class WebtoCaseOwnerAssignment extends TriggerAbstract {
        public override void process(SObject record) {
            Case caseRecord = (Case)record;

            if(caseRecord.RecordTypeId == MonConCaseServices.MONCON_RECTYPEID && caseRecord.SuppliedEmail != null && caseRecord.SuppliedEmail !='') {
                records.add(caseRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                MonConCaseServices.WebtoCaseOwnerAssignment(records);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
	 *  @author         Kevin Evasco (GrowthOps)
     *  @description    Run prediction model on trigger records and writeback prediction outcome, explanation and recommendation.
     */
//    public class PredictPropensityToTransfer extends TriggerAbstract {
//        public override void process(SObject record) {
//        }
//
//        public override void execute() {
//            CaseServicesV2.predictPropensityToTransfer();
//            LogUtilityException.getLimits();
//        }
//
//    }

    /**
	 *  @author         Nick Guia
	 *  @description    Filters Case records that requires processing to populate
	 *                  the Lead__c field based on Contact's related Lead
     * @revision
	 *                  MAR.19.2020  Nick Guia   - Added filter for Future Course Enquiry Type
	 */
	public class ManageRelatedLead extends TriggerAbstract {

		public override void process(SObject record) {
			Case caseRec = (Case) record;
			if(caseRec.Enquiry_Type__c != null && caseRec.Enquiry_Type__c.equalsIgnoreCase('Future Course') 
				&& caseRec.ContactId != null && caseRec.Lead__c == null) 
			{
				records.add(caseRec);
			}
		}

		public override void process(SObject record, SObject oldRec) {
			Case caseRec = (Case) record;
			Case oldCase = (Case) oldRec;
			if(caseRec.Enquiry_Type__c !=null && caseRec.Enquiry_Type__c.equalsIgnoreCase('Future Course')) {
				if(caseRec.ContactId != null && caseRec.Lead__c == null) {
					//when contact was populated, but lead was not
					records.add(caseRec);
				} else if(oldCase.ContactId != null && caseRec.ContactId == null) {
					//when related contact was removed, remove related Lead as well
					caseRec.Lead__c = null;
				}
			}
        }

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServices.populateCaseLead(records);
            }
        }
    }
    
    /** 
	 * @author			ayush.agrawal@monash.edu
	 * @description	    Populate category levels 1 and 2 based on enquiry summary for
	 * 					post-application enquiries. This is to replace the process builder
	 * 					SR_Internal_Enquiry_Populate_Cat_Fields.
     * @date			19-03-2021
	 */
	public class MapCategoryLevelsForPostApplicationCases extends TriggerAbstract {

        public override void process(SObject record) {
			Case c = (Case)record;
            Id postApplicationCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Application_Enquiry').getRecordTypeId();
			if(c.RecordTypeId == postApplicationCaseRecordTypeId) {
				records.add(c);
			}
		}

		public override void process(SObject record, SObject oldRecord) {
			Case c = (Case)record;
            Id postApplicationCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Application_Enquiry').getRecordTypeId();
			if(c.RecordTypeId == postApplicationCaseRecordTypeId) {
				records.add(c);
			}
		}

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.mapCategoryLevelsForPostApplicationCases(records);
            }
        }
    }
    
    /**
	 * @author			ayush.agrawal@monash.edu
	 * @description 	Generate Latest_Transferred_Date__c and Enquiry_Reopened__c for student
	 * 					recruitment. This is to replace the process builder
	 * 					Student_Recruitment_Latest_Transferred_Date.
     * @date:			20-03-2021
	 */
	public class GenerateStudentRecruitmentTrackingDates extends TriggerAbstract {
        
        Map<Id, Case> oldCaseMap = new Map<Id, Case>();
        
        public override void process(SObject record, SObject oldRecord) {
            Case c = (Case)record;
            Case oldCase = (Case)oldRecord;
            if(c.OwnerId != oldCase.OwnerId) {
                records.add(c);
                oldCaseMap.put(oldCase.Id, oldCase);
            }
        }

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.generateStudentRecruitmentTrackingDates(records, oldCaseMap);
            }
        }
    }
    
    /**
	 * @author      	ayush.agrawal@monash.edu
	 * @description 	Populate case wrap-up values based on enquiry origin for
	 * 					post-application enquiries. This is to replace the process builder
	 * 					Student_Recruitment_Post_Application_Enquiry_Type.
     * @date:			20-03-2021
	 */
	public class MapOriginToOtherValuesForPostApplicationCases extends TriggerAbstract {

		public override void process(SObject record) {
			Case c = (Case)record;
            Id postApplicationCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Application_Enquiry').getRecordTypeId();
			if(c.RecordTypeId == postApplicationCaseRecordTypeId) {
				records.add(c);
			}
		}

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.mapOriginToOtherValuesForPostApplicationCases(records);
            }
        }
    }
    
    /**
	 * @author  		ayush.agrawal@monash.edu
	 * @description 	Map enquiry origin to enquiry type for Monash College cases. This
	 * 					is to replace the process builder Manage_Incoming_Monash_College_Enquiries.
     *  @date:			20-03-2021
	 */
	public class MapOriginToEnquiryTypeForMonashCollege extends TriggerAbstract {

		public override void process(SObject record) {
			Case c = (Case)record;
			if(c.Origin == 'Email - enquiries@monashcollege.edu.au') {
				records.add(c);
			}
		}

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.mapOriginToEnquiryTypeForMonashCollege(records);
            }
        }
    }
    
    /**
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Set priority high based on supplied email for Insurance enquiries. This
	 * 					is to replace the process builder High_Priority_Insurance_Addresses.
	 */
	public class SetPriorityForInsuranceCases extends TriggerAbstract {

		public override void process(SObject record) {
			Case c = (Case)record;
            
			Id insuranceCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Enquiry').getRecordTypeId();
            
			if(c.RecordTypeId == insuranceCaseRecordTypeId) {
				records.add(c);
			}
		}

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.setPriorityForInsuranceCases(records);
            }
        }
    }
    
    /**
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Populate case wrap-up values based on enquiry origin for
	 * 					standard enquiries. This is to replace the process builder
	 * 					Faculty_field_updates and Monash_Connect_CoE_Email_Redirect.
	 */
	public class MapOriginToOtherValuesForStandardCases extends TriggerAbstract {

		public override void process(SObject record) {
			Case c = (Case)record;
            Id standardCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
			if(c.RecordTypeId == standardCaseRecordTypeId) {
				records.add(c);
			}
		}

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.mapOriginToOtherValuesForStandardCases(records);
            }
        }
    }
    
    /**
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Customize subject for enquiries related to manual unit enrolment. This
	 * 					is to replace the process builder Manual_unit_Enrolment.
	 */
	public class MapSubjectForManualUnitEnrolment extends TriggerAbstract {

		public override void process(SObject record) {
			Case c = (Case)record;
            
			if(c.Origin == 'Web - Manual Enrolment' && c.Category_Level_2__c == 'Manual Enrolment') {
				records.add(c);
			}
		}

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.mapSubjectForManualUnitEnrolment(records);
            }
        }
    }
    
    /**
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Populate case values based on enquiry origin for
	 * 					hr enquiries. This is to replace the process builder
	 * 					HR_myDevelopment_Web2Case.
	 */
	public class MapOriginToOtherValuesForHRCases extends TriggerAbstract {

		public override void process(SObject record) {
			Case c = (Case)record;
            
			if(c.Origin == 'Web - myDevelopment Staff') {
				records.add(c);
			}
		}

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.mapOriginToOtherValuesForHRCases(records);
            }
        }
    }
    
    /**
	 * @author:			ayush.agrawal@monash.edu
	 * @group:			Student Admin
	 * @description:	Generate default values for Academic Progress
	 * 					Assessment cases.
	 */
	public class SetDefaultsForAcademicProgressAssessment extends TriggerAbstract {

		public override void process(SObject record) {
			Case c = (Case)record;
            
			if(
                c.RecordTypeId == academicProgressAssessmentCaseRecordTypeId && c.Origin != 'My Engagement and Support' && (String.IsBlank(c.Category_Level_2__c) || c.Category_Level_2__c != 'Appeal') ){
				records.add(c);
			}
		}

        public override void execute() {
            if(!records.isEmpty()) {
                CaseServicesV2.setDefaultsForAcademicProgressAssessment(records);
            }
        }
    }

    /**
     * @author:			angelo.rivera@monash.edu
     * @date:			26-04-2021
     * @description:	Add Skill Requirement to cases going through case routing.
     */
    public class CaseRoutingEngine extends TriggerAbstract {
        public override void process(SObject record) {
            Case c = (Case)record;
            if(c.RecordTypeId != academicProgressAssessmentCaseRecordTypeId) {
                records.add(c);
            }
        }

        public override void execute() {
            if(!records.isEmpty()) {
                SkillRoutingServices.addSkillRequirements(records);
            }
        }
    }


    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         28/05/2021
    * @description  Case routing engine on update
    * @revision     27/05/2019 - Initial Version
    *******************************************************************************/
    public class CaseRoutingEngineOnUpdate extends TriggerAbstract{
        public Set<Id> setCaseIds = new Set<Id>();
        public override void process(SObject record, SObject oldRec) {
            Case c = (Case)record;
            Case oldCaseRecord = (Case)oldRec;
            if(c.OwnerId != oldCaseRecord.OwnerId && c.LastModifiedDate != oldCaseRecord.CreatedDate){
                records.add(c);
                setCaseIds.add(c.Id);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                SkillRoutingServices.addSkillRequirementsOnUpdate(records, setCaseIds);
            }
            LogUtilityException.getLimits();
        }
    }
    
    /**
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			2021-11-11
	 * @description:	Generate UUID for all records if they don't already have it on record creation.
	 */
	public class GenerateUuidIfMissing extends TriggerAbstract {
		public override void process(SObject record) {
			Case c = (Case)record;
			if(String.isEmpty(c.UUID__c)) {
                c.UUID__c = new Uuid().getValue();
			}
		}
    }
    
    /*******************************************************************************
    * @author       Rajesh Punjabi
    * @date         30/05/2022
    * @Trigger		After Update.
    * @description  Merge Enquiries - SS-71
    * @revision     31/05/2022 - Initial Version
    * @revision     21/07/2022 - Fixed the code to accept three cases at one time.
    * @revision     26/07/2022 - [SS-104] Merge enquiries questions store as Case Comments. 
    * @revision     11/09/2023 - Exclusing MRO record type from Case Merge (Parent-Child) related List.
    *******************************************************************************/
    public class CaseOwnershipUpdate extends TriggerAbstract{
        Set<Id> setMasterId = new Set<Id>();
        Map<Id, String> mapMasterIdQuestion = new Map<Id, String> ();
        
        public override void process(SObject record, SObject oldRec) {
            Case oCase = (Case)record;
            Case oOldCase = (Case)oldRec;
            if(oCase.Status == 'Merged' && oOldCase.Status != 'Merged' && oCase.RecordTypeId != mroEnquiryRt){
                records.add(oCase);
            }
        }
        
        public override void execute() {
            if(!records.isEmpty()){
                System.enqueueJob(new CaseMergeQueuable(records));
            }
        }
    }

    /**
     * @description  SA-2268 Retain the first user-owner as a CaseTeamMember for DoI Cases
     */
    @SuppressWarnings('PMD.ApexSharingViolations')
    public class DoiRetainFirstOwner extends TriggerAbstract{

        public final String doiCTM = 'DoI Initial Assignee';
        Id doiRtId = MonConCaseServices.m_recTypeDevelpNameRecId.get('Declaration_of_Interest');

        public override void process(SObject record) {
            // after insert
            process(record, null);
        }

        public override void process(SObject record, SObject oldRec) {
            // after update
            Case cse = (Case)record;
            Case oldCse = (Case)oldRec;

            Boolean ownerIsNew = cse.OwnerId != null && (oldRec == null || cse.OwnerId != oldCse.OwnerId);
            if(cse.RecordTypeId == doiRtId && ownerIsNew && cse.OwnerId.getSobjectType() == User.SObjectType)
            {
                // DoI case has been assigned to a different user
                records.add(cse);
            }
        }

        public override void execute() {
            if(!records.isEmpty()) {
                Map<Id,Case> cases = new Map<Id,Case>((Case[])records);
                CaseTeamRole ctr = [SELECT Id FROM CaseTeamRole WHERE Name = :doiCTM];

                // collect CTMs by case
                Map<Id, CaseTeamMember[]> ctmsByCaseId = new Map<Id, CaseTeamMember[]>();
                for(CaseTeamMember ctm :[
                    SELECT ParentId, MemberId, TeamRoleId
                    FROM CaseTeamMember WHERE ParentId IN :cases.keySet()
                ]) {
                    CaseTeamMember[] caseCtms = ctmsByCaseId.get(ctm.ParentId);
                    if(caseCtms == null) {
                        ctmsByCaseId.put(ctm.ParentId, new CaseTeamMember[]{ctm});
                    } else {
                        caseCtms.add(ctm);
                    }
                }

                CaseTeamMember[] newCtms = new CaseTeamMember[0];

                // add initial assignee CTM for cases that don't have one
                for(Case c :cases.values()) {
                    Boolean hasDoiInitialAssignee = false;
                    if(ctmsByCaseId.containsKey(c.Id)) {
                        for(CaseTeamMember ctm :ctmsByCaseId.get(c.Id)) {
                            if(ctm.TeamRoleId == ctr.Id) {
                                hasDoiInitialAssignee = true;
                                break;
                            }
                        }
                    }

                    if(!hasDoiInitialAssignee) {
                        newCtms.add(new CaseTeamMember(
                            ParentId = c.Id,
                            MemberId = c.OwnerId,
                            TeamRoleId = ctr.Id
                        ));
                    }
                }

                insert newCtms;
            }
        }
    }

    /**
     * @description Whenever a SpecCon case is transferred to a new user, update the Latest Transferred Date field.
     */
    public class SetLatestTransferredDate extends TriggerAbstract {
        public override void process(SObject record, SObject oldRec) {
            Case cse = (Case)record;
            Case oldCse = (Case)oldRec;
            if(!cse.IsClosed && cse.OwnerId != oldCse.OwnerId && cse.OwnerId != null &&
                cse.OwnerId.getSobjectType() == User.SObjectType && cse.RecordTypeId == MonConCaseServices.SPECON_RECTYPEID)
            {
                // case ownership has changed to a new user
                records.add(cse);
            }
        }

        public override void execute() {
            for(Case cse : (List<Case>)records) {
                cse.Latest_Transferred_Date__c = Datetime.now();
            }
        }
    }

    /**
	 *  @author         Vinothraja
	 *  @description    Filters Case records from APNG and populates the 
	 *                  1. the external_stakeholder__c field based on the related ACP
     *                  2. and external_stakeholder_email__c field based on the Agent creating the enquiry
     *  @revision
	 *  25/09/2023   Vinothraja      Created
	 */
    @SuppressWarnings('PMD.ApexSharingViolations')
    public class AssociateAgencyToAPNGEnquiries extends TriggerAbstract {
        public Set<String> acpIds = new Set<String> ();
        public Set<String> setValidEnquiryTypes = new Set<String> {'Post Application', 'Future Course', 'Late Registration - International'};
        public String agentEmail;
        public override void process(SObject record) {
            Case enquiry = (Case)record;
            // Handling APNG Enquiries
            if(hasValidRecordType(enquiry) && hasValidEnquiryType(enquiry) && enquiry.Application_Course_Preference__c != null) {
                acpIds.add(enquiry.Application_Course_Preference__c);
                records.add(enquiry);
            }
        }

        public override void execute() {
            if(!records.isEmpty()) {
                new ApplicantCaseServices().populateExternalStakeholder(records, acpIds);
                // Population of External Stakeholder email
                agentEmail = [SELECT Contact.Email FROM User WHERE id = :UserInfo.getUserId() LIMIT 1]?.Contact.Email;
                If (String.isNotBlank(agentEmail)){
                    new ApplicantCaseServices().populateExternalStakeholderEmail(records, agentEmail);
                }
            }
        }
        // checks if the Enquiry's Record Type is one of the valid ones for APNG
        private boolean hasValidRecordType(Case enquiry) {
            if (enquiry.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Application_Enquiry').getRecordTypeId()) {
                return true;
            } 
            if (enquiry.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId()) {
                return true;
            }
            if (enquiry.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MUM_Admissions').getRecordTypeId()) {
                return true;
            }
            return false;
        }
        // checks if the Enquiry's Type is one of the valid ones for APNG
        private boolean hasValidEnquiryType(Case enquiry) {
            if (enquiry.Enquiry_Type__c != null && setValidEnquiryTypes.contains(enquiry.Enquiry_Type__c)) {
                return true;
            }
            return false;
        }
    }
    /**
	 *  @author         Vinothraja
	 *  @description    Filters Case records from APNG and creates the Summary
     *                  file to be sent to Callista
     * @revision
	 * 03/10/2023   Vinothraja      Created
	 */
    public class CreateSummaryFileForAPNGEnquiries extends TriggerAbstract {
        public List<String> caseIDs = new List<String> ();

        public override void process(SObject newRec) {
            Case newEnquiry = (Case)newRec;
            // Handling APNG Enquiries
            if(hasValidRecordType(newEnquiry) 
                && newEnquiry.Application_Course_Preference__c != null
                && String.isNotBlank(newEnquiry.Origin) && newEnquiry.Origin.equalsIgnoreCase(AgentPortalConstants.APNG_WEB_ORIGIN)
                && String.isNotBlank(newEnquiry.Status) && newEnquiry.Status.equalsIgnoreCase('Open')) {
                	caseIDs.add(newEnquiry.Id);
            }
        }

        public override void execute() {
            if(!caseIDs.isEmpty()) {
                StudFirst_CasePBC.createEnquirySummaryToACP(caseIDs);
            }
        }
        // checks if the Enquiry's Record Type is one of the valid ones for APNG
        private boolean hasValidRecordType(Case enquiry) { 
            if (enquiry.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId()) {
                return true;
            }
            if (enquiry.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MUM_Admissions').getRecordTypeId()) {
                return true;
            }
            return false;
        }
    }

    /**
    * @description This method creates an Archive Audit record upon Case deletion
    * @revision    JUN.07.2024  Mac Domingo   - Created
    */
    @SuppressWarnings('PMD.ApexSharingViolations')
    public class CreateArchiveAudit extends TriggerAbstract {
        List<Archive_Audit__c> archiveAuditList = new List<Archive_Audit__c>();
        public override void process(SObject record) {
            Case caseRecord = (Case)record;
            //Only create Archive Audit when the Archive and Purge Date has a value and either the Contact or Account field is populated in the case record
            if(caseRecord.Archive_Date__c != null && caseRecord.Purge_Date__c != null && (caseRecord.ContactId != null || caseRecord.AccountId != null)) {
                Archive_Audit__c arcAudits = new Archive_Audit__c(
                    Case_Number__c = caseRecord.CaseNumber,
                    Contact__c = caseRecord.ContactId,
                    Account__c = caseRecord.AccountId,
                    Archive_Date__c = Date.today(),
                    RecordId__c = caseRecord.Id,
                    Object_Type__c = 'Case'
                );
                archiveAuditList.add(arcAudits);
            }                                         
        }

        public override void execute() {
            if (!archiveAuditList.isEmpty()) {
                // Insert Archive_Audit__c records
                Nebula.Logger.info('Archive Audit List Size ' + archiveAuditList.size());
            
                // Perform the insert and get the save results
                Database.SaveResult[] saveResults = Database.insert(archiveAuditList, false);
            
                // Loop through the save results and handle errors
                for (Integer i = 0; i < saveResults.size(); i++) {
                    Database.SaveResult sr = saveResults[i];
                    if (!sr.isSuccess()) {
                        // Log the error message for the failed record along with the recordId
                        Archive_Audit__c failedRecord = archiveAuditList[i];
                        for (Database.Error err : sr.getErrors()) {
                            Nebula.Logger.error('Error inserting record (RecordId: ' + failedRecord.RecordId__c + '): ' + err.getMessage());
                        }
                    }
                }
            }            
            Nebula.Logger.saveLog();              
        }
    }
}