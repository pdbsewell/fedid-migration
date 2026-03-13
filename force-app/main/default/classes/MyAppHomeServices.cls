/**
 * @author      Kristian Vegerano
 * @description Container class for all utility methods used on my app community
 * @group       My App Community Services
 * @revision    30/05/2019 - Kristian Vegerano - Created
 *              13/05/2020 - KL - adding "pending merge" before "sent for submission" status for contact merge
 *              08/07/2020 - Martin Cadman - removed source system filter from acp query SFTLG-1025
 *              10/08/2020 - JM - Added source system filter from application query to exclude Course Transfer Application/ACP's on my.app
 *              09/08/2022 - Ken McGuire - Security uplift
 *              16/09/2022 - Vinothraja - SFTG-2866 Added logic to fetch Study Type based qns 
 *              2024-07-11   Vishal Gupta    MGROI-283 changing the study type options for new degree selector
 * *            2024-09-06   Davey Yu        MGROI-281 Update Summary view in home page for Graduate Research
 */
public with sharing class MyAppHomeServices {
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';
    public static String FIELD_CAMPUS_LOCATIONS = 'campusLocations';
    private static String GRAD_RESEARCH_EMABRGOE_REASON = 'GradResearch';
    /**
     * @author       Kristian Vegerano
     * @description  Retrieve all necessary data 
     * @date         30/01/2020
     * @param        communityUserId
     * @return       Map<String, Object> - multiple returned results
     */
    @AuraEnabled
    public static Map<String, Object> retrieveHomeDetails(Id communityUserId) {
        Map<String, Object> resultMap = new Map<String, Object>();
        // Validate input
        if(ExperienceAuthenticationServices.isUnsafe(communityUserId)){return unsafeParameterMessage();} 
        

        //Retrieve current user details
        User currentUserDetails = [SELECT Id, FirstName, LastName, ContactId,Contact.Preferred_Name__c, Contact.FirstName, Contact.First_Name__c, CreatedbyId, Email, Name FROM User WHERE Id = :communityUserId];
        resultMap.put('CURRENT_USER_DETAILS', currentUserDetails);
        resultMap.put('SOURCE_SYSTEM', 'DEFAULT');
        
        Boolean isSSOUser = false;
        Boolean hasCourseAttempts = false;
        if(currentUserDetails != null){
            isSSOUser = PersonalDetailsController.isSSOUser(currentUserDetails.contactId);
            resultMap.put('IS_SSO_USER', isSSOUser);

            List<Map<String, Object>> courseAttemptsList = StudyPreferenceServiceGR.getCourseAttempts(currentUserDetails.contactId);
            if(courseAttemptsList.size() > 0){
                hasCourseAttempts = true;
            }
            resultMap.put('CourseAttempts', hasCourseAttempts);
        }

    

        Id idd = currentUserDetails.CreatedbyId;
        List<User> uNameList = [select Name from User where id=:idd];
        if(uNameList.size()>0) {
            resultMap.put('CURRENT_USER_CREATEDBY', uNameList[0].Name);
        }
        //Retrieve draft application
        List<Application__c> draftApplicationList = new List<Application__c>();
        for(Application__c loopApplication : [SELECT Id, Name, Submitted_Date__c,Source_system__c, Owner.Name, Submission_Progress__c, CreatedDate, LastModifiedDate, Status__c, Campus_Location__c, Type_of_Study__c, Graduate_Research_Application_Type__c,
                                                     (SELECT Id, Preference_Number__c, Application__c, Application__r.Name, Application__r.Submitted_Date__c, Application__r.Status__c,
                                                             Application__r.Credit_Intention__c, Application__r.Citizenship_Classification__c, Unit_Set_Description__c, Course_Title__c, Course_Code__c, 
                                                             Course_Offering__r.Attendance_Mode_Description__c, Course_Offering__r.Location_Description__c, Course_Offering__r.Attendance_Type__c, Course_Offering__r.Attendance_Type_Description__c,
                                                             Course_Offering__r.Admission_Calendar_Description__c, Course_Offering__r.Type_of_Place_Description__c, 
                                                             Outcome_Status_LOV__c, Outcome_Status_LOV__r.System_Code__c, Outcome_Status_LOV__r.Applicant_Value__c, Outcome_Status_LOV__r.Value__c, 
                                                             Offer_Response_Status_LOV__c, Offer_Response_Status_LOV__r.Applicant_Value__c, Offer_Response_Status_LOV__r.Value__c, Offer_Response_Date__c, 
                                                             Conditional_Offer_Status_LOV__r.Value__c, Conditional_Offer_Status_LOV__r.Applicant_Value__c, Offer_Condition__c, 
                                                             Conditional_Offer_Satisfied_Date__c, Actual_Offer_Response_Date__c, Admission_Category__c, LastModifiedDate,
                                                             Documentation_Status_LOV__c, Conditional_Offer_Status_LOV__c, Documentation_Status_LOV__r.Value__c, Proposed_Commencement_Date__c, Application__r.Type_of_Study__c,
                                                             Application__r.Scholarship_Round_Description__c , Application__r.Graduate_Research_Application_Type__c, Attendance_Mode__c
                                                      FROM Application_Course_Preferences__r 
                                                      ORDER BY Preference_Number__c ASC)
                                              FROM Application__c
                                              WHERE Applicant__c = :currentUserDetails.ContactId
                                                AND Status__c in ( 'Draft', 'Sent Draft Application to Applicant', 'Applicant Declaration Accepted')
                                              ORDER BY Name DESC]){
            draftApplicationList.add(loopApplication);
        }
        if(!draftApplicationList.isEmpty()){
            resultMap.put('DRAFT_APPLICATIONS', draftApplicationList);
           resultMap.put('SOURCE_SYSTEM', draftApplicationList[0].Source_system__c);

        }

        //Retrieve submitted application
        List<Application__c> submittedApplicationList = new List<Application__c>();
        for(Application__c loopApplication : [SELECT Id, Name, Submitted_Date__c, Submission_Progress__c, CreatedDate, LastModifiedDate, Status__c, Source_System__c,Campus_Location__c, Type_of_Study__c, Graduate_Research_Application_Type__c,
                                                     (SELECT Id, Preference_Number__c, Application__c, Application__r.Name, Application__r.Submitted_Date__c, Application__r.Status__c,
                                                             Application__r.Credit_Intention__c, Application__r.Citizenship_Classification__c, Unit_Set_Description__c, Course_Title__c, Course_Code__c, 
                                                             Course_Offering__r.Attendance_Mode_Description__c, Course_Offering__r.Location_Description__c, Course_Offering__r.Attendance_Type__c, Course_Offering__r.Attendance_Type_Description__c,
                                                             Course_Offering__r.Admission_Calendar_Description__c, Course_Offering__r.Type_of_Place_Description__c, 
                                                             Outcome_Status_LOV__c, Outcome_Status_LOV__r.System_Code__c, Outcome_Status_LOV__r.Applicant_Value__c, Outcome_Status_LOV__r.Value__c, 
                                                             Offer_Response_Status_LOV__c, Offer_Response_Status_LOV__r.Applicant_Value__c, Offer_Response_Status_LOV__r.Value__c, Offer_Response_Date__c, 
                                                             Conditional_Offer_Status_LOV__r.Value__c, Conditional_Offer_Status_LOV__r.Applicant_Value__c, Offer_Condition__c, 
                                                             Conditional_Offer_Satisfied_Date__c, Actual_Offer_Response_Date__c, Admission_Category__c, LastModifiedDate,
                                                             Documentation_Status_LOV__c, Conditional_Offer_Status_LOV__c, Documentation_Status_LOV__r.Value__c, Proposed_Commencement_Date__c, Application__r.Type_of_Study__c,
                                                             Application__r.Scholarship_Round_Description__c, Application__r.Graduate_Research_Application_Type__c, Attendance_Mode__c                            
                                                      FROM Application_Course_Preferences__r
                                                      WHERE (Admission_Category__c LIKE '%VTAC%' AND Offer_Response_Status_LOV__r.Value__c NOT IN (null, 'NOT-APPLIC','PENDING'))
                                                           OR
                                                            (not Admission_Category__c LIKE '%VTAC%')
                                                      ORDER BY Preference_Number__c ASC)
                                               FROM Application__c
                                              WHERE Applicant__c = :currentUserDetails.ContactId
                                                AND (
                                                    Status__c = 'Submitted' OR 
                                                    Status__c = 'Sent for Submission' OR 
                                                    Status__c = 'Review' OR 
                                                    Status__c = :MyApplicationUtilities.APP_PENDING_MERGE_STATUS OR
                                                    Status__c = 'Agent Declaration Accepted'
                                                )
                                                AND Source_System__c != 'CCT'
                                              ORDER BY Submitted_Date__c DESC, Name DESC]){
            //Show application if have acp
            if(loopApplication.Application_Course_Preferences__r != null){
                if(loopApplication.Application_Course_Preferences__r.size() > 0){
                    submittedApplicationList.add(loopApplication);
                }
            }
        }
        if(!submittedApplicationList.isEmpty()){
            resultMap.put('SUBMITTED_APPLICATIONS', submittedApplicationList);
        }

        //Retrieve checklist details
        Map<String, Object> checklistResultMap = MyAppHomeServices.retrievePendingChecklistAndUnreadComments(currentUserDetails.ContactId);
        for(String resultKey : checklistResultMap.keySet()){
            resultMap.put(resultKey, checklistResultMap.get(resultKey));
        }

        //Retrieve environment switch for campus location
        Map<String, Boolean> campusLocationSwitchMap = StudyLocationController.retrieveEnvironmentSettingFeature('CampusLocation');
        Map<String, List<String>> studyTypeSwitchMap = StudyLocationController.retrieveStudyTypeMap('StudyType');
        Map<String, Map<String, List<String>>> studyTypeQuestions = StudyLocationController.retrieveStudyTypeQuestionsMap(studyTypeSwitchMap);

        //Add campus location results as options
        List<Map<String, String>> campusLocationOptions = new List<Map<String, String>>();

        Map<String, String> campusLocationResults = MyApplicationUtilities.getPicklistOptionsMap('Campus_Location__c', 'Application__c');
        for(String loopCampusLocation : campusLocationResults.keySet()){
            //check if the campus location is available
            Boolean isAvailable = true;
            List<Map<String, String>> studyTypeOptions = new List<Map<String, String>>();


            String valueWithRemovedWhiteSpace = loopCampusLocation.remove(' ');
            if(campusLocationSwitchMap.containsKey(valueWithRemovedWhiteSpace)){
                isAvailable = campusLocationSwitchMap.get(valueWithRemovedWhiteSpace);
            }

            if(isAvailable){
                Map<String, String> option = new Map<String, String>();
                option.put(FIELD_VALUE, loopCampusLocation);
                option.put(FIELD_LABEL, campusLocationResults.get(loopCampusLocation));
                campusLocationOptions.add(option);
                List<String> stTypes = studyTypeSwitchMap.get(valueWithRemovedWhiteSpace);
                if(stTypes!=null){
                    Map<String, List<String>> mapStudyTypeQuestions = studyTypeQuestions.get(valueWithRemovedWhiteSpace);
                    for(String studyType : mapStudyTypeQuestions.keySet()) {
                        for (String question : mapStudyTypeQuestions.get(studyType)) {
                            Map<String, String> stOption = new Map<String, String>();
                            stOption.put(FIELD_VALUE, studyType);
                            stOption.put(FIELD_LABEL, question);
                            studyTypeOptions.add(stOption);
                        }
                    }
                }
                resultMap.put(loopCampusLocation, studyTypeOptions);
            }
        }

        // determine if the there are units available for study abroad
        Map<String, Set<String>> availableVirtualCourseUnitsMap = PartnerApplicationService.retrieveAvailableVirtualCourseUnits();
        // if there are no units available for online study abroad then remove campus location online
        if(!availableVirtualCourseUnitsMap.containsKey(Constants.MONASH_ABROAD_SA_STUDY_TYPE)){
            // remove campus location online
            for(Integer counter = (campusLocationOptions.size()-1); counter >= 0; counter--){
                Map<String, String> optionItem = campusLocationOptions[counter];
                if(optionItem.get('label') == 'Online'){
                    campusLocationOptions.remove(counter);
                }
            } 
        }

        resultMap.put(FIELD_CAMPUS_LOCATIONS, campusLocationOptions);
        resultMap.putAll(Constants.MY_APP_STUDYTYPE_SUBHEADING);
        
        // added custom permission check for testers to bypass testing
        resultMap.put('BYPASS_GRADRES_SWTICH', FeatureManagement.checkPermission('Graduate_Research_Switch_Bypass'));
        
        return resultMap;
    }

    /**
     * @author       Trent De Laney
     * @description  Creates a new application in my.app portal
     * @date         21 Feb 2019 at 3:28:52 pm
     * @param        contactId
     * @param        location
     * @param        courseType
     * @return       String - draft application id
     * @revision     29/01/2020 - Kristian Vegerano - Added method in this class (MyAppHomeServices) from ApplicationNavigationHomeController class
     */
    @AuraEnabled
    public static String createApplication(String contactId, String location, String courseType) {
        // Validate input
        if(ExperienceAuthenticationServices.isUnsafe(new List<String>{contactId,location,courseType})) {return null;}
        Application__c applicationRecord = new Application__c();
        applicationRecord.Applicant__c = contactId;
        String returnValue = '';
        List<Application__c> apps = [SELECT Id, Type_Of_Study__c 
                                     FROM Application__c
                                     WHERE Status__c = 'Draft' 
                                     AND Applicant__c = :contactId
                                    ];
        if (apps.size() > 0) {
            throw new AuraHandledException('You may only have 1 Application at a time');
        } else {
            applicationRecord.From_Portal__c = true;
            applicationRecord.Status__c = 'Draft';
            applicationRecord.Campus_Location__c = location;

            if(courseType.contains('Graduate Research;')) {
                applicationRecord.Type_of_Study__c = courseType.split(';')[0];
                applicationRecord.Graduate_Research_Application_Type__c = courseType.split(';')[1];
                //MGROI-432 Set Embargoed Reason as GradResearch
                applicationRecord.Embargoed_Reason__c = GRAD_RESEARCH_EMABRGOE_REASON;
            } else {
                applicationRecord.Type_of_Study__c = courseType;
            }                
            
            applicationRecord.Source_System__c = 'my.app';
            applicationRecord.Duration_of_Study__c = location == 'Online' ? '1' : null;
            insert applicationRecord;
            
            //insert junction object records if there are any. //this will not apply for Grad Research applications
            if(!courseType.contains('Graduate Research;')) {
                MyAppHomeServices.insertChildRecords(applicationRecord.Id, contactId);
            }
            
            returnValue = applicationRecord.Id;
        }
        return returnValue;
    }

    /**
     * @author       Trent De Laney
     * @description  Inserts the child records for previous applications to ensure they are linked for future submissions
     * @date         21 Feb 2019 at 3:32:12 pm
     * @param        appId
     * @param        contactId
     * @revision     29/01/2020 - Kristian Vegerano - Added method in this class (MyAppHomeServices) from ApplicationNavigationHomeController class
     */
    private static void insertChildRecords(String appId, String contactId) {
        //Get all work exp
        List<Work_Experience__c> workExp = [
                SELECT Id
                FROM Work_Experience__c
                WHERE Contact__c = :contactId
        ];

        if(workExp.size() > 0){
            //Create the new list to be inserted
            List<Application_Work_Experience_Provided__c> appWorkExp = new List<Application_Work_Experience_Provided__c>();
            for (Work_Experience__c work : workExp){
                Application_Work_Experience_Provided__c newAppWork = new Application_Work_Experience_Provided__c();
                newAppWork.Work_Experience__c = work.Id;
                newAppWork.Application__c = appId;
                appWorkExp.add(newAppWork);
            }

            insert appWorkExp;
        }
    }

    /**
     * @description Cancel the draft application by deleting it
     *
     * @param applicationId - the application record to cancel
     *
     * @revision     12/02/2020 - Kristian Vegerano - Added method in this class (MyAppHomeServices) from appHomeOffersCC class
     */
    @AuraEnabled
    public static void cancelApplication(Id applicationId) {
        // Validate input
        if(ExperienceAuthenticationServices.isUnsafe(applicationId)) {return;}
        if(null != applicationId) {
            Application__c updateApplication = new Application__c(Id = applicationId,
                                                                  Status__c = 'Cancelled');
            update updateApplication;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves pending checklist items and unread comments grouped by application
     * @param applicantId
     * @return Map<String, Object>
     * @revision    12/08/2019 - Kristian Vegerano - Created
     */
    public static Map<String, Object> retrievePendingChecklistAndUnreadComments(Id applicantId) {
        //Initialize Variables
        Set<String> pendingChecklistStatus = new Set<String> {'Requested', 'Insufficient'};
        Map<String, Object> resultMap = new Map<String, Object>();
        Map<Id, Integer> applicationCommentsMap = new Map<Id, Integer>();
        Map<Id, Integer> applicationUnreadCommentsMap = new Map<Id, Integer>();
        Map<Id, Integer> applicationOutstandingChecklistItems = new Map<Id, Integer>();

        //Query all outstanding checklists related to the applicant
        for(Document_Checklist__c loopChecklist : [SELECT Id, Application__c, Status__c, 
                                                            Contact_Qualification__c, Contact_Qualification__r.RecordType.Name,
                                                             (SELECT Id, NotesSeen__c 
                                                              FROM Document_Checklist_Comments__r)
                                                      FROM Document_Checklist__c
                                                      WHERE Contact__c = :applicantId]){
            //Initialize checklist comment count
            if(!applicationCommentsMap.containsKey(loopChecklist.Application__c)){
                applicationCommentsMap.put(loopChecklist.Application__c, 0);
            }
            //Initialize checklist unread comment count
            if(!applicationUnreadCommentsMap.containsKey(loopChecklist.Application__c)){
                applicationUnreadCommentsMap.put(loopChecklist.Application__c, 0);
            }
            //Initialize outstanding checklist count
            if(!applicationOutstandingChecklistItems.containsKey(loopChecklist.Application__c)){
                applicationOutstandingChecklistItems.put(loopChecklist.Application__c, 0);
            }

            //Increment outstanding checklists
            if(pendingChecklistStatus.contains(loopChecklist.Status__c)){
                //if the checklist is related to GR application referee, then we dont need to show the pending checklist icon
                if(loopChecklist.Contact_Qualification__c != null && loopChecklist.Contact_Qualification__r.RecordType.Name == 'Referees') {
                    continue;
                }               
                applicationOutstandingChecklistItems.put(loopChecklist.Application__c, applicationOutstandingChecklistItems.get(loopChecklist.Application__c) + 1);
            }

            //Run through each content notes
            if(loopChecklist.Document_Checklist_Comments__r != null){
                for(Document_Checklist_Comment__c loopComment : loopChecklist.Document_Checklist_Comments__r){
                    //Increment comment count
                    applicationCommentsMap.put(loopChecklist.Application__c, applicationCommentsMap.get(loopChecklist.Application__c) + 1);
                    
                    //Increment unread comment count
                    if(loopComment.NotesSeen__c == false){
                        applicationUnreadCommentsMap.put(loopChecklist.Application__c, applicationUnreadCommentsMap.get(loopChecklist.Application__c) + 1);
                    }
                }
            }
        }

        //Store results to map
        resultMap.put('OUTSTANDING_CHECKLIST', applicationOutstandingChecklistItems);
        resultMap.put('APPLICATION_COMMENT_COUNT', applicationCommentsMap);
        resultMap.put('APPLICATION_UNREAD_COMMENT_COUNT', applicationUnreadCommentsMap);

        return resultMap;
    }

    /**
     * @description Update an ACP to a status and updates the actual offer response date to today.
     *                 acp.Offer_Response_Status_LOV__c is a lookup field and data dependent.
     *
     * @param acp - the acp record to update
     * @param sValue - the Value__c of the LOV record to search for, assumes that such a record exists
     *
     * @revision     12/02/2020 - Kristian Vegerano - Added method in this class (MyAppHomeServices) from appHomeOffersCC class
     */
    private static void updateACPToValue(Application_Course_Preference__c acp, String sValue) {
        //Find the LOV
        List<List_of_Values__c> lovs = [SELECT Id, Applicant_Value__c, Type__c, Value__c
                                        FROM List_of_Values__c
                                        WHERE Value__c =: sValue
                                            AND Type__c = 'ADM_OFFER_RESP_STATUS'];

        if(lovs.size() == 1) {
            List_of_Values__c lovResponse = lovs[0];
            acp.Offer_Response_Status_LOV__c = lovResponse.Id;

            //Converting to Australia/Sydney as the my.app user is defaulted to 'GMT'
            DateTime currenttime = DateTime.now();
            String strConvertedDate = currenttime.format('dd/MM/yyyy', 'Australia/Sydney');
            List<String> sp = strConvertedDate.split('/');
            Date dt = Date.newInstance(Integer.valueOf(sp[2]), Integer.valueOf(sp[1]), Integer.valueOf(sp[0]));

            // Do not set the Offer response date for 'ACCEPT-CND'
            if(sValue!='ACCEPT-CND'){
                acp.Actual_Offer_Response_Date__c = dt;
            }

            update acp;
        }
    }

    /**
     * @description When an applicant rejects an offer in the UI, updates the acp status to the correct LOV
     *
     * @param acp - the acp record to update
     *
     * @revision     12/02/2020 - Kristian Vegerano - Added method in this class (MyAppHomeServices) from appHomeOffersCC class
     */
    @AuraEnabled
    public static void doRejectACP(Application_Course_Preference__c acp) {
        Application_Course_Preference__c safeACP = cleanACP(acp);
        if (safeACP == null) return;
        updateACPToValue(safeACP, 'REJECTED');
    }

    /**
     * @description When an applicant accepts an offer in the UI, updates the acp status to the correct LOV
     *
     * @param acp - the acp record to update
     *
     * @revision     12/02/2020 - Kristian Vegerano - Added method in this class (MyAppHomeServices) from appHomeOffersCC class
     * @revision     24/05/2021 - Shalini Mendu - Added more conditions to update the Offer status value -SFTG-2646
     */
    @AuraEnabled
    public static void doAcceptACP(Application_Course_Preference__c acp) {
        Application_Course_Preference__c safeACP = cleanACP(acp);
        if (safeACP == null) return;
        
        String acceptType = 'ACCEPTED';
        //Added more conditions to update the Offer status value
        if(safeACP.Outcome_Status_LOV__r.Value__c == 'OFFER'){
            acceptType = 'ACCEPTED';
        }else  if(safeACP.Outcome_Status_LOV__r.Value__c == 'OFFER-COND'){
            if(safeACP.Conditional_Offer_Status_LOV__r.Value__c == 'WAIVED' || safeACP.Conditional_Offer_Status_LOV__r.Value__c == 'SATISFIED' && 
              (safeACP.Documentation_Status_LOV__r.Value__c == 'DOC-UNCERT' || safeACP.Documentation_Status_LOV__r.Value__c == 'DOC-ENROL') &&
               safeACP.Conditional_Offer_Satisfied_Date__c!=null && !safeACP.Conditions_Must_Be_Satisfied__c){
                acceptType = 'ACCEPTED';
            } else if(safeACP.Conditional_Offer_Status_LOV__r.Value__c == 'PENDING'){
                acceptType = 'ACCEPT-CND';
            }
        } else if(safeACP.Outcome_Status_LOV__r.Value__c == 'OFFER-PROV'){
            acceptType = 'ACCEPT-PRV';
        }
      
        updateACPToValue(acp, acceptType);
    }
    
    /**
     * @description Method to clean an Application Course Preference data object and its related fields
     *
     * @param maybeUnsafeACP - the application course preference to clean
     *
     * @return Application_Course_Preference__c
     */
    private static Application_Course_Preference__c cleanACP(Application_Course_Preference__c maybeUnsafeACP) {
        // Guard
        if (maybeUnsafeACP == null) return null;
        // validate application course preference
        Map<String,Object> populatedFields = maybeUnsafeACP.getPopulatedFieldsAsMap();
        if (ExperienceAuthenticationServices.isUnsafe(populatedFields.values())) {return null;}
        // Valiate related records
        if (populatedFields.containsKey('Course_Offering__c') && ExperienceAuthenticationServices.isUnsafe(maybeUnsafeACP.Course_Offering__c)) {return null;}
        if (populatedFields.containsKey('Outcome_Status_LOV__r') && ExperienceAuthenticationServices.isUnsafe(maybeUnsafeACP.Outcome_Status_LOV__r)) {return null;}
        if (populatedFields.containsKey('Conditional_Offer_Status_LOV__r') && ExperienceAuthenticationServices.isUnsafe(maybeUnsafeACP.Conditional_Offer_Status_LOV__r)) {return null;}
        if (populatedFields.containsKey('Documentation_Status_LOV__r') && ExperienceAuthenticationServices.isUnsafe(maybeUnsafeACP.Documentation_Status_LOV__r)) {return null;}
        
        // Clean application course preference and related records
        Application_Course_Preference__c cleanedACP;
        String acpStringFields = 'Id,Offer_Response_Status_LOV__c,Course_Code__c,Course_Title__c,Type_of_Place_Description__c,Applicant_Value__c,Credit_Intention__c,Conditional_Offer_Satisfied_Date__c,Offer_Response_Date__c,Conditions_Must_Be_Satisfied__c';
        String coFields = 'Id,Attendance_Mode_Description__c,Admission_Calendar_Description__c';
        String lovFields = 'Id,Value__c';
        Course_Offering__c co = populatedFields.containsKey('Course_Offering__c') ? (Course_Offering__c)ExperienceAuthenticationServices.stripSObject(maybeUnsafeACP.Course_Offering__r,coFields) : null;
        List_of_Values__c outLov = populatedFields.containsKey('Outcome_Status_LOV__r') ? (List_of_Values__c) ExperienceAuthenticationServices.stripSObject(maybeUnsafeACP.Outcome_Status_LOV__r,lovFields) : null;
        List_of_Values__c conLov = populatedFields.containsKey('Conditional_Offer_Status_LOV__r') ?  (List_of_Values__c) ExperienceAuthenticationServices.stripSObject(maybeUnsafeACP.Conditional_Offer_Status_LOV__r,lovFields) : null;
        List_of_Values__c docLov =  populatedFields.containsKey('Documentation_Status_LOV__r') ? (List_of_Values__c) ExperienceAuthenticationServices.stripSObject(maybeUnsafeACP.Documentation_Status_LOV__r,lovFields) : null;
        cleanedACP = (Application_Course_Preference__c) ExperienceAuthenticationServices.stripSObject(Application_Course_Preference__c.sObjectType,populatedFields,acpStringFields);
        cleanedACP.Course_Offering__r = co;
        cleanedACP.Outcome_Status_LOV__r = outLov;
        cleanedACP.Conditional_Offer_Status_LOV__r = conLov;
        cleanedACP.Documentation_Status_LOV__r = docLov;

        // return cleaned data object and related records
        return cleanedACP;
    }
    /**
     * @description checking the authentication
     * @return  Map<String,String>
     */
    private static Map<String,String> unsafeUserInputMessage() {
        return ExperienceAuthenticationServices.userMessage(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }
    /**
     * @description checking the authentication
     * @return  Map<String,String>
     */
    private static Map<String,String> unsafeParameterMessage() {
        return ExperienceAuthenticationServices.userMessage(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }
}