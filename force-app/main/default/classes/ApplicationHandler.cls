/*
* @author       Ant Custodio
* @date         JUN.16.2017
* @description  Handler class for Application Trigger
* @deprecated   Use ApplicationTriggerHandler instead
* @revision     
* JUL.10.2019   Shalini Mendu - for SFTHB-122 
* FEB.10.2020   Shalini Mendu - for SFTN-455 
* FEB.10.2020   Shalini Mendu - for SFTN-455
*               KL            - SFTLG-903, 'no match' scenario submission of App
* JUN.22.2023   Martin Cadman - Added logic to allow applications with a Hybrid source system to have an affiliation created
* FEB.05.2024   Nick Guia     - Marked class as deprecated
* NOV.??.2024                 - HDR scholarship additions
* DEC.04.2024   Martin Cadman - Stopped case sensitive comparisons of agent code end dating affiliations
* DEC.10.2024   Martin Cadman - Fixed issue revealed by additional logging when updating affiliations EPCP-4132
*/
public with sharing class ApplicationHandler {

    public static final String CUSTOMER_COMMUNITY_GENERAL_PROFILE = 'Customer Community General User';
    public static final String PARTNER_COMMUNITY_LOGIN_USER = 'Monash Partner Community Login User';
    public static final String DATA_VALIDATION_READY = 'Data Validation Ready';
    public static final String SENT_FOR_SUBMISSION = 'Sent for Submission';
    public static final String FEE_PAYMENT_MODE = 'Application Fee Waiver Code';
    public static final String SUBMITTED = 'Submitted';
    public static final String LOI_English_LANGUAGE = 'English Language Instruction in secondary school';
    public static final String LOI_COUNTRY = 'Country of secondary schooling';
    public static final String DRAFT = 'Draft';
    public static final String GRT_SCHOLARSHIP_APPLICATION_ONLY = 'Scholarship application only';
    
    /*
    * @author       Ant Custodio
    * @date         16.Jun.2017
    * @description  This method limits the user to have only one draft application 
    * @revision     
    */
    public static void onlyAllowOneDraft(List<Application__c> applicationList) {
        if(userinfo.getName() != 'Automated Process'){
            Profile profileRec = [  SELECT  Id, Name 
                                  FROM    Profile 
                                  WHERE   Id =: userInfo.getProfileId() 
                                  LIMIT   1 ];
            
            //ONLY RUN FOR DOMESTIC APPLICANTS
            if (profileRec.Name == CUSTOMER_COMMUNITY_GENERAL_PROFILE) {
                //query on the user to get the contact Id
                User userRec = [    SELECT  Id,
                                ContactId
                                FROM    User
                                WHERE   Id =: userInfo.getUserId() ];
                //count the number of draft applications. If this is found at least 1, stop the insert
                Integer appCount = [SELECT  COUNT()
                                    FROM    Application__c
                                    WHERE   Applicant__c =: userRec.ContactId
                                    AND Status__c = 'Draft' ];
                if (appCount > 0) {
                    //display error on the page. this will stop all application inserts on bulk
                    for (Application__c appRecord: applicationList) {
                        if (appRecord.Status__c == 'Draft' ) {
                            appRecord.addError('You can only have one Draft Application');
                        }
                    }
                }
            }
        }
    }
    
    /*
    * @author       Shalini Mendu
    * @date         10.Jul.2019
    * @description  This method validates the application data that comes with the submission to CRM
    * @revision
    */
    public static void validateData(List<Application__c> applicationList, Map<Id, Application__c> appMapOld)
    {

        for(Application__c app: applicationList)
        {
            if(app.Status__c == DATA_VALIDATION_READY && appMapOld.get(app.Id).Status__c!=DATA_VALIDATION_READY && app.Source_System__c!=null
                    && app.Source_System__c!='my.app')
                if(DataValidatorFactory.getValidator(app.Source_System__c)!=null)
                    DataValidatorFactory.getValidator(app.Source_System__c).validateApplicationData(app.Id);
        }
    }
  
    /*
     * @author       Shalini Mendu
     * @date         17.Jul.2019
     * @description  This method submits the documents of an Application to Callista
     * @revision     created
     * @revision     20/09/2024 Sethu Venna Updated to exclude Graduate Research from course work 
     *               and include new logic for Graduate Research
     */
    public static void submitDocuments(List<Application__c> applicationList, Map<Id, Application__c> appMapOld)
    {
        Application__c app = applicationList[0];
        Set<Id> grAppIdSet = new Set<Id>();
        
        if(app.Type_of_Study__c != Constants.STUDYTYPE_GRADUATERESEARCH) {
            if(app.Status__c == SUBMITTED && appMapOld.get(app.Id).Status__c == SENT_FOR_SUBMISSION)
            {
                SubmitDocumentsonAppSubmit.submitDocumentsToCallista(app.Id);
            }
        }

        for(Application__c appRec : applicationList) {
            if( appRec.Status__c == SUBMITTED && 
                appMapOld.get(appRec.Id).Status__c == SENT_FOR_SUBMISSION && 
                appRec.Type_of_Study__c == Constants.STUDYTYPE_GRADUATERESEARCH) 
            {
                grAppIdSet.add(appRec.Id);
            }
        }
        if(grAppIdSet.isEmpty() == false) {
            List<Id> conDocIdList = new List<Id>();
            List<Contact_Document__c> conDocList = new List<Contact_Document__c>(new ContactDocumentsSelector().selectByApplicationIdWithEmptyCallistaDocId(grAppIdSet));
            for(Contact_Document__c conDocRec : conDocList) {
                conDocIdList.add(conDocRec.Id);
            }
            if(conDocIdList.isEmpty() == false) {
                GRInvocablePostDocumentService.queueFileToSend(conDocIdList);
            }
        }
        
    }
    
    /*
     * @author       Shalini Mendu
     * @date         17.Jul.2019
     * @description  This method redeems the Fee waiver code on the Application in Callista - Applicable only for my.app Applications as the redemptions happens
     *               separately from AP.
     */
    public static void redeemFeeWaiverCode(List<Application__c> applicationList, Map<Id, Application__c> appMapOld)
    {
            Application__c app = applicationList[0];
            if(app.Status__c == SUBMITTED && appMapOld.get(app.Id).Status__c==SENT_FOR_SUBMISSION &&
               app.Fee_Payment_Mode__c== FEE_PAYMENT_MODE && String.isBlank(app.Fee_Waiver_Redeemed__c) &&
               String.isNotBlank(app.Callista_Application_Id__c) && String.isNotBlank(app.Callista_Applicant_Id__c)
               && String.isNotBlank(app.Fee_Waiver_Code__c) )
            {
                ObdRedeemWaiverCode.redeemCode(app.Id);
            }
    }

    /*
     * @description Update the submission progress
     * @revision
     * FEB.20.2024  Nick Guia   - removed unused variable "oldApp"
     */ 
    public class PopulateSubmissionProgress extends TriggerAbstract {

        /*
		 * @description Handle after insert event checking and filtering
 		 */
        public override void process(SObject rec) {
            Application__c app    = (Application__c)rec;
            records.add(app);
        }
        
        /*
         * @description Handle after update event checking and filtering
         */
        public override void process(SObject rec, SObject oldRec) {
            Application__c app    = (Application__c)rec;
            records.add(app);
        }

        /*
         * @description Process changed records
         */
        public override void execute() {
            try {
                if(!records.isEmpty()) {
    
                    Id currentUserId = UserInfo.getUserId();
                    User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :currentUserId];
                    Boolean userValid   = currentUser != null && currentUser.Profile!=null && currentUser.Profile.Name != null && currentUser.Profile.Name.containsIgnoreCase('partner');
    
                    Set<Application__c> applications = new Set<Application__c>((List<Application__c>)records);
                
                    for (Application__c a : applications) {
                        if(userValid && !a.partner_controlled__c ){ 
                           a.Submission_Progress__c = 'Declaration'; // SFTG-2063 Student should have the application open on Declaration Page
                        }
                    }
                }
            } catch (Exception ex) {
                nebula.logger.error(ex.getMessage(), records);
                nebula.logger.exception(ex.getMessage(), ex);
            }
        }
    }
    
   /*
    * @author       Ant Custodio
    * @date         07.Sept.2017
    * @description  This method automatically links the Application__r.Agent__c using the provided Agent_Org_Unit_Code__c
    * @revision     01.05.2023 Moved trigger framework
    *               11.09.2024 If an agency is linked manually, without specifying the org unit code, the ouc is populated. However, if the ouc is populated 
    *                          it will override the manual change. Just specifying an ouc will populate the agency field. 
    */
    public class PopulateAgent extends TriggerAbstract {
        Set<String> orgUnits = new Set<String>(); // A unique list of org unit codes in the batch
        Set<id> agencyIds 	 = new Set<id>();     // A unique list of agency account ids in the batch

        // Handle after insert event checking and filtering
        public override void process(SObject rec) {
            Application__c app = (Application__c)rec;

            try{
                if (String.isnotBlank(app.Agent_Org_Unit_Code__c)) {
                    orgUnits.add(app.Agent_Org_Unit_Code__c.toLowerCase());
                    records.add(app);
                } else {
                    if (app.Agent__c!=null) {
                        agencyIds.add(app.Agent__c);
                        records.add(app);
                    }
                }
            } catch (Exception ex) {
                nebula.logger.error(ex.getMessage(), app);
                nebula.logger.exception(ex.getMessage(), ex);
            } 
        }
        
        /*
         * @description Handle after update event checking and filtering
         */
        public override void process(SObject rec, SObject oldRec) {
            Application__c app    = (Application__c)rec;
            Application__c oldApp = (Application__c)oldRec;
                
            try {
                if (CommonUtilities.fieldHasChanged('Agent_Org_Unit_Code__c', app, oldapp) 
                    || CommonUtilities.fieldHasChanged('Agent__c', app, oldapp)) {
                        if (String.isNotBlank(app.Agent_Org_Unit_Code__c)){
                            orgUnits.add(app.Agent_Org_Unit_Code__c.toLowerCase());
                            records.add(app);
                        } else {
                            if (app.Agent__c !=null ) {
                                agencyIds.add(app.Agent__c);
                                records.add(app);
                            }
                        } 
                    }
            } catch (Exception ex) {
                nebula.logger.error(ex.getMessage(), app);
                nebula.logger.exception(ex.getMessage(), ex);
            }
	    }
        
        /*
         * @description Process any records that have changed - either populate the agency when a new org unit code is added or populate the
         *              org unit code if empty and the application is linked to an agency account.
         */
        public override void execute() {
            try {
                if(!records.isEmpty()) {
                    Set<Application__c> applications = new Set<Application__c>((List<Application__c>)records); // The records for processing
                    Map<String, String> agencies = new Map<String, String>(); // A map with org unit/id and id/org unit combinations

                    for (Account acc : [SELECT Id, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c IN :orgUnits or id in :agencyIds]) {
                        If (String.isNotBlank(acc.Callista_Org_Unit_Code__c)) {
                            agencies.put(acc.Callista_Org_Unit_Code__c.toLowerCase(), String.valueOf(acc.Id));
                        }
                        agencies.put(String.valueOf(acc.id), acc.Callista_Org_Unit_Code__c);
                    }

                    for (Application__c app :applications) {
                        if((String.isNotBlank(app.Source_System__c) && !app?.Source_System__c.containsIgnoreCase('partner')) 
                        || (String.isBlank(app.Source_System__c))) {
                            if (String.isNotBlank(app.Agent_Org_Unit_Code__c)) { // we have an org unit code, which has precedence
							    app.Agent__c = (id)agencies.get(app.Agent_Org_Unit_Code__c?.toLowerCase()); // update the agency lookup
                            } else {
	                            app.Agent_Org_Unit_Code__c = agencies.get(app.agent__c); // up the org unit code from the agency lookup to populate the org unit
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
                nebula.logger.error(ex.getMessage(), records);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }
    
   /*
    * @author Martin Cadman
    * @date   01.05.2023
    * @description If the feature switch is enabled, this before-trigger method will change the owner of an application that is linked to an agency. It does this by
    *              identifying the branch manager user record of the linked agency.
    */
    public class PopulateOwner extends TriggerAbstract {
        Set<String> orgUnits = new Set<String>();
        Feature_Switch__c fs = Feature_Switch__c.getInstance();

        /*
         * @description Handle insert event checking and filtering
         */
        public override void process(SObject rec) {
            Application__c app = (Application__c)rec;
            
            if (fs.Align_Application_Owner__c) {
                if (AgentPortalServices.isValidOrgUnit(app.Agent_Org_Unit_Code__c)) {
                    orgUnits.add(app.Agent_Org_Unit_Code__c.toLowerCase());
                    records.add(app);
                }
            }
        }
        
        /*
         * @description Handle update event checking and filtering
         */
        public override void process(SObject rec, SObject oldRec) {
            Application__c app    = (Application__c)rec;
            Application__c oldApp = (Application__c)oldRec;
            
            if (fs.Align_Application_Owner__c) {
                if (AgentPortalServices.isValidOrgUnit(app.Agent_Org_Unit_Code__c) &&
                    (CommonUtilities.fieldHasChanged('Agent_Org_Unit_Code__c', app, oldapp) 
                     || CommonUtilities.fieldHasChanged('Agent__c', app, oldapp)
                     || CommonUtilities.fieldHasChanged('OwnerId', app, oldapp))) {
                         orgUnits.add(app.Agent_Org_Unit_Code__c.toLowerCase());
                         records.add(app);
                     }
            }
        }
        
        /*
         * @description Run this puppy!
         */
        public override void execute() {
            try {
                if(!records.isEmpty() && !orgUnits.isEmpty() ) {
                    Set<Application__c> applications = new Set<Application__c>((List<Application__c>)records);

                    Set<String> agencyPartners = new Set<String>();
                    for (Account acc : [SELECT Id, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c IN :orgUnits and ispartner = true]){
                        agencyPartners.add(acc.Callista_Org_Unit_Code__c.toLowerCase());
                    }

                    AgentPortalServices.AgencyWrapper aw = AgentPortalServices.buildAgencyMaps(orgUnits); // get the breakdown of agents within an agency
                    
                    for (Application__c app : applications) {
                        if (!aw.agentUsers.keySet().contains(app.OwnerId) 
                         && agencyPartners.contains(app.Agent_Org_Unit_Code__c.toLowerCase())) { // the application is owned outside of the Agency & the agency is a enabled as a partner
                            if (aw.agencyManagers.containsKey(app.Agent_Org_Unit_Code__c.toLowerCase()) 
                                && aw.agencyManagers.get(app.Agent_Org_Unit_Code__c.toLowerCase()) != null
                                && app.OwnerId != aw.agencyManagers.get(app.Agent_Org_Unit_Code__c.toLowerCase()).id) { // the org unit has a branch manager
                                app.OwnerId = aw.agencyManagers.get(app.Agent_Org_Unit_Code__c.toLowerCase()).id; 
                            } else {
                                nebula.logger.warn('Application updated failed. No active branch manager user available for ' + app.Agent_Org_Unit_Code__c, app);
                            }
                        }    
                    }   
                }
            } catch (Exception ex) {
                nebula.logger.error(ex.getMessage(), records);
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Stamps checklist output on application records when its status field is updated to submitted
     * @revision    13/08/2019 - Kristian Vegerano - Created
     */
    public static void submittedApplicationsCalculateChecklistOutput(Map<Id, Application__c> applicationMap, Map<Id, Application__c> oldApplicationMap) {
        try {
            //Initialize Variables
            Map<Id, Application__c> processApplicationsMap = new Map<Id, Application__c>();

            //Filter submitted applications
            for(Application__c loopApplication : applicationMap.values()){
                Application__c oldApplication = oldApplicationMap.get(loopApplication.Id);

                //Check status change - to Submitted
                if(loopApplication.Status__c != oldApplication.Status__c){
                    //Check status is changed to Sent for Submission
                    if(loopApplication.Status__c == 'Submitted'){
                        processApplicationsMap.put(loopApplication.Id, loopApplication);
                    }
                }
            }

            //Checks if there are records to be processed
            if(!processApplicationsMap.isEmpty()){
                //Stamp checklist output fields
                DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(processApplicationsMap.keySet()); 
                rulesDocChecklistEngine.evaluateRules('Application Assessment');  
                
                for(Application__c loopApplication : processApplicationsMap.values()){
                    loopApplication.Checklist_output__c = String.join(rulesDocChecklistEngine.retrieveChecklistItemsEmailInstructions(loopApplication.Id), '');
                    loopApplication.Checklist_output_completed__c = String.join(rulesDocChecklistEngine.retrieveCompleteChecklistItemsEmailInstructions(loopApplication.Id), '');
                }
            }    
        } catch (Exception ex) {
			nebula.logger.exception(ex.getMessage(), ex);
        }
    }

    /**
    * @author Trent De Laney
    * @description Processes campus detail
    * @date MAR.18.2020
    *   APR.18.2023              - Converted to trigger framework
    *   FEB.20.2024  Nick Guia   - removed unused variable "oldApp"
    */
    public class ProcessCampusLocation extends TriggerAbstract {

        public override void process(SObject record) {
            Application__c app = (Application__c)record;
            if (app.Campus_Location__c == null && app.Campus__c != null){
                records.add(app);
            }
        }
        
        public override void process(SObject record, SObject oldRec) {
            //Start process
            Application__c app    = (Application__c)record;

            if (app.Campus_Location__c == null && app.Campus__c != null){
                records.add(app);
            }
        }

        public override void execute() {
            if(!records.isEmpty()) {
                Set<Application__c> applications = new Set<Application__c>((List<Application__c>)records);
                for (Application__c app : applications) {
                    app.Campus_Location__c = MyApplicationUtilities.ConvertCampusToLocation(app.Campus__c);
                }
            }
        }

    }

    /**
     * @author      Kristian Vegerano
     * @description Update application's submission location country 
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public class UpdateSubmissionLocationCountry extends TriggerAbstract {
        /**
         * Handle after insert event checking and filtering
         */
        public override void process(SObject record) {
            //Include application for processing
            records.add(record);
        }
        
        /**
         * Handle after update event checking and filtering
         */
        public override void process(SObject record, SObject oldRec) {
            //Start process
            Application__c contextApplication = (Application__c)record;
            Application__c contextOldApplication = (Application__c)oldRec;

            //Check status change
            if(contextApplication.Status__c != contextOldApplication.Status__c){
                //Check status is changed to Sent for Submission
                if(contextApplication.Status__c == Label.ApplicationStatus_Sent_for_Submission){
                    records.add(record);
                }
            }

            //Check agent change
            if(contextApplication.Agent__c != contextOldApplication.Agent__c){
                records.add(record);
            }

            //Check applicant change - mostlikely will not happen
            if(contextApplication.Applicant__c != contextOldApplication.Applicant__c){
                records.add(record);
            }
        }
        
        /*
         * Run functionality logic
         */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                Set<Application__c> uRecords = new Set<Application__c>((List<Application__c>)records);
                ApplicationHelper appHelper = new ApplicationHelper();
                appHelper.executeUpdateSubmissionLocationCountry(new Map<Id, Application__c>(new List<Application__c>(uRecords)));
            }
        }
    }
    
    /**
     * @author      KL
     * @description SFTLG-903: moving duplicate processing out of WR Assessment process, into overall App submit process
     * @revision    15.05.2020 - KL: Created
     */
    public class PerformDupCheck extends TriggerAbstract {

        List<Async_Process__e> eventsToPublish = new List<Async_Process__e>();

        public override void process(SObject record) {
            //Include application for processing
            Application__c contextApplication = (Application__c)record;
            if (contextApplication.Status__c == MyApplicationUtilities.APP_PENDING_MERGE_STATUS) {
                records.add(record);
            }
        }

        /**
         * Handle after update event checking and filtering
         */
        public override void process(SObject record, SObject oldRec) {
            Application__c contextApplication = (Application__c)record;
            Application__c contextOldApplication = (Application__c)oldRec;

            //Check status change
            if(contextApplication.Status__c != contextOldApplication.Status__c){
                //Check status is changed to Sent for Submission
                if(contextApplication.Status__c == MyApplicationUtilities.APP_PENDING_MERGE_STATUS){
                    records.add(record);
                }
            }
        }

        /**
         * Run functionality logic
         */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                for (Application__c appInLoop : (List<Application__c>) records) {
                    Async_Process__e evt = createPayload(appInLoop.Id);
                    this.eventsToPublish.add(evt);
                }

                if(!eventsToPublish.isEmpty()) {
                    EventBus.publish(this.eventsToPublish);
                }    
            }
        }

        private Async_Process__e createPayload(Id appId) {
            Async_Process__e evt;

            if(appId != null) {
                Feature_Switch__c fs = Feature_Switch__c.getInstance();
                String processName ='';
                if(fs.Enable_Enhanced_Admissions_Contact_Merge__c) {
                    processName='AdmissionDupCheckServices.PerformMatchAndMerge';
                }
                else{
                    processName='DupCheckServices.PerformMatchAndMerge';
                }
                AsyncProcessPayload payload = new AsyncProcessPayload();
                payload.put ('appId', new Set<Id> {appId});
                evt = new Async_Process__e (
                    Process_Name__c = processName, 
                    Parameter__c = payload.serialize()
                    );
            }
            return evt;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Generate checklist item when application records has its status field is updated to submitted
     * @revision    13/08/2019 - Kristian Vegerano - Created
     */
    public class SubmittedApplicationsGenerateChecklistItems extends TriggerAbstract {
        
        /**
         * Handle after update event checking and filtering
         */
        public override void process(SObject record, SObject oldRec) {
            //Start process
            Application__c contextApplication = (Application__c)record;
            Application__c contextOldApplication = (Application__c)oldRec;

            //Check status change - to Submitted
            if(contextApplication.Status__c != contextOldApplication.Status__c){
                //Check status is changed to Sent for Submission
                if(contextApplication.Status__c == 'Submitted'){
                    records.add(record);
                }
            }
        }
        
        /**
         * Run functionality logic
         */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                Set<Application__c> uRecords = new Set<Application__c>((List<Application__c>)records);
                ApplicationHelper appHelper = new ApplicationHelper();
                appHelper.applicationGenerateChecklistItems(new Map<Id, Application__c>(new List<Application__c>(uRecords)));
            }
        }
    }

 
    /*******************************************************************************
     * @author:      Shalini Mendu
     * @date:        11.Jan.2020
     * Send LOI English results to Callista
     * @param List of changed Application__c
     * @param Map of old Id, Application__c from the trigger
    *******************************************************************************/
   public static void sendLOI(List<Application__c> newAppList, Map <Id, Application__c> oldMap)
    {
        for(Application__c newApp : newAppList){
                Application__c oldApp =   oldMap.get(newApp.Id);
            if( newApp.English_Entry_Mode__c!=null && newApp.Meets_Minimum_English__c!=null &&
                 (newApp.English_Entry_Mode__c.startsWithIgnoreCase(LOI_English_LANGUAGE) ||
                 newApp.English_Entry_Mode__c.startsWithIgnoreCase(LOI_COUNTRY)) &&  
                ( newApp.English_Entry_Mode__c!=oldApp.English_Entry_Mode__c ||
                 newApp.Meets_Minimum_English__c!=oldApp.Meets_Minimum_English__c ) ){
                    ObdLOIEnglishInterface.fireOutboundRequest(newApp.Id, newApp.English_Entry_Mode__c, newApp.Meets_Minimum_English__c );
                }
        }   
    }

    /**
     * @author      Vinothraja
     * @description Validate delete of Applications when a Partner Deletes an Application
     *  - Only Draft Applications can be deleted
     *  - Only Partner Controlled Applications can be deleted
     * @revision    10/12/2021 - Created
     */
    public without sharing class ValidateDelete extends TriggerAbstract {
        private Profile profileRec {
            get{
                //query Profile of the invoking user
                if(profileRec == null){
                    profileRec = [  SELECT  Id, Name 
                                        FROM    Profile 
                                        WHERE   Id =: userInfo.getProfileId() 
                                        LIMIT   1 ];
                }
                return profileRec;
            } 
            set;
        }
        /**
         * Handle before delete event validation
         */
        public override void process(SObject record) {
            Application__c application = (Application__c) record;
            //bypass Automated Process
            if(userinfo.getName() != 'Automated Process'){
                //ONLY RUN FOR PARTNER USERS
                if (profileRec.Name == PARTNER_COMMUNITY_LOGIN_USER) {
                    //Check if the Application is Not Partner-Controlled (or) if Partner-Controlled, whether it is in Draft Stage
                    if(!application.Partner_Controlled__c || (application.Partner_Controlled__c && String.isNotBlank(application.Status__c) && !application.Status__c.equalsIgnoreCase('Draft'))){
                            // Throw error
                            record.addError('Only Partner-controlled Draft Applications can be deleted');
                    }
                }
            }
        }
        
        /**
         * Run functionality logic
         */
        @SuppressWarnings('PMD.EmptyStatementBlock')
        public override void execute() {
        }
    }

    /**
    * @author      Shalini Mendu 
    * @description Create Affiliation records for Partner Portal Applications
    * @revision    27/03/2023 - Shalini Mendu - Created
    * @revision    03/05/2023 - Use Toggle to allow Affiliations for Agentportal applications
    *              25/08/2023   Nick Guia   - Bulkified code; removed unused variables
    */
    public class AddModifyAffiliationRecords extends TriggerAbstract {

        Environment_Settings__c envSettings = Environment_Settings__c.getOrgDefaults();
        Boolean allowAPAffiliations = envSettings.AgentPortal_Affiliation__c;
      
        /**
        * Handle after insert event checking and filtering
        */
        public override void process(SObject record) {
            Application__c contextApplication = (Application__c)record;
            //Select Applications that have source system as Partner or Agentportal(in combination with the toggle)
            if( contextApplication.Agent__c != null && contextApplication.Applicant__c!=null 
                && (contextApplication.Source_System__c == 'Partner' || contextApplication.Source_System__c == 'AgentPortal' || contextApplication.Source_System__c == 'OES')
                && allowAPAffiliations)
            {
                records.add(contextApplication);
            }
            
            // Force hybrid through the process. These are 'submitted' agency applications created by Callista.
            if (contextApplication.Source_System__c == 'Hybrid'
                    && contextApplication.Agent__c != null 
                    && contextApplication.Applicant__c!= null 
                    && allowAPAffiliations) 
            {
                records.add(contextApplication);
            }
        }

        /**
        * Handle after update event checking and filtering
        */
        public override void process(SObject record, SObject oldrecord) 
        {
            Application__c contextApplication = (Application__c)record;
            Application__c oldApp = (Application__c)oldrecord;
            //Select Applications that have source system as Partner or Agentportal(in combination with the toggle)and changed to Submitted status 
            if((oldApp.Status__c!='Submitted' && contextApplication.Status__c == 'Submitted' && 
                contextApplication.Agent__c != null && contextApplication.Applicant__c!=null && 
                    (contextApplication.Source_System__c == 'Partner' || contextApplication.Source_System__c == 'AgentPortal'|| contextApplication.Source_System__c == 'OES')
                     && allowAPAffiliations))
            {
                records.add(contextApplication);
            }

            // Force hybrid through the process. These are 'submitted' agency applications created by Callista.
            // HYBIRD may now be redundant. todo - verify this.
            if (contextApplication.Source_System__c == 'Hybrid' 
                && contextApplication.Agent__c != null 
                && contextApplication.Applicant__c!= null 
                && allowAPAffiliations) 
            {
                records.add(contextApplication);
            }
        }
      
        public override void execute() {
            if(!records.isEmpty()) {
                try {
                    AffiliationManageService service = new AffiliationManageService();
                    service.upserAffiliationsFromApplication((List<Application__c>) records);
                } catch(Exception ex) {
                	nebula.logger.exception(ex.getMessage(), ex);
                }
            }
        }
    }

    /*
     * @author       SMendu
     * @date         12.02.2024 
     * @description  Upsert Affiliations on Agent transfers(mainly from Callista)
     */
    public class UpsertAffiliationsonAgentTransfer extends TriggerAbstract {

        Map<Id, Application__c> oldApplicationMap = new Map<Id, Application__c> ();

        // Handle after update event checking and filtering
        public override void process(SObject rec, SObject oldRec) {
            Application__c app    = (Application__c)rec;
            Application__c oldApp = (Application__c)oldRec;

            // If the code is changed or the agency lookup has changed, including removed
            if ((app.Agent_Org_Unit_Code__c != oldapp.Agent_Org_Unit_Code__c) // this last comparison should be case insensitive DANO-356
            || CommonUtilities.fieldHasChanged('Agent__c', app, oldapp)) {
				// The agency has changed so an affiliation may need to be end dated
                oldApplicationMap.put( app.Id, oldApp);
                records.add(app);
            }
        }
        
        // Affilition creation or end date addition
        public override void execute() {
            try {
                if(!records.isEmpty()) {
                    List<Application__c> applications =(List<Application__c>)records;
                    Map<String, Affiliation__c> affiliationKeyMap = new Map<String, Affiliation__c>();
                    Affiliation__c newAff, oldAff = null;
                    AffiliationManageService aff = new AffiliationManageService();
                    for (Application__c app :applications) {
                        //skip MonashAbroad applications 
                        if ((String.isNotBlank(app.Source_System__c) && !app.Source_System__c.containsIgnoreCase('partner')) 
                        || (String.isBlank(app.Source_System__c))) {
                            //Run Affiliations upsert for updates 
                            if (oldApplicationMap.get(app.Id)!=null) {
                                //Check the Agent does not belong to one of the Excluded values
                                if (AgentPortalServices.isValidOrgUnit(app.Agent_Org_Unit_Code__c)) {
                                    // If the agency code was removed, nothing to update
                                    if (app.Agent__c != null ) {
                                        //Create a new Affiliation for the updated Agent - granting Read access 
                                        newAff = aff.createAgencyAccessFromApplication(app);
                                        affiliationKeyMap.put(newAff.Composite_Key__c, newAff);
                                    }
                                }
                                //Remove access from the Affiliation for the old Agent - removing accessing(No Sharing)
                                //This wil create an end dated affiliation if for some reason it didn't exist
                                Application__c oldApp = oldApplicationMap.get(app.Id);
                                if (AgentPortalServices.isValidOrgUnit(oldApp.Agent_Org_Unit_Code__c)) {
                                    oldAff = aff.removeAgencyAccessFromApplication(oldApp);
                                    affiliationKeyMap.put(oldAff.Composite_Key__c, oldAff);
                                }
                            }
                        }
                    }

                    List<Affiliation__c> affUpsert = affiliationKeyMap.values();
                    if (affUpsert.size() > 0) {
    					List<Database.UpsertResult> resultAff = Database.upsert(affUpsert, affiliation__c.Composite_Key__c, false);
                        for (Database.UpsertResult aResult : resultAff) {
                            // If there are any errors log all of the results 
                            if (!aResult.isSuccess()) {
                                nebula.logger.warn('Error upserting affiliations', resultAff);
                                break;
                            }
                        }
                    }

                }
            } catch (Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            }
        }
    }

    /**
     * @description Send GR application to callista
     * @param applicationList
     * @param appMapOld
    */
    public static void submitGRApplication(List<Application__c> applicationList, Map<Id, Application__c> appMapOld) {
        try{
            Integer availableLimit;
            for(Application__c app : applicationList) {
                if(app.Type_of_Study__c == Constants.STUDYTYPE_GRADUATERESEARCH && 
                    app.GR_Callista_Document_Submission_Date__c != null &&
                    appMapOld.get(app.Id).GR_Callista_Document_Submission_Date__c != app.GR_Callista_Document_Submission_Date__c) {
                    
                    availableLimit = Limits.getLimitQueueableJobs() - Limits.getQueueableJobs();
                    GRSendApplicationToCallistaQueuable queueable = new GRSendApplicationToCallistaQueuable(app.Id, app.Applicant__c);
                    if(availableLimit > 0) {
                        System.enqueueJob(queueable);
                    }
                }
            }
        }
        catch(Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex); 
        }
        Nebula.Logger.saveLog();
    }
}