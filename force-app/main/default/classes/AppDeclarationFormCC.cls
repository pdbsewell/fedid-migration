/*******************************************************************************
* @author       Ryan Wilson
* @date         03.May.2017         
* @description  controller class for appDeclarationForm.cmp
* @revision     
* 15/09/2018 -  Stefan Scheit    - Changed class to with sharing
* 05/05/2019 -  Suman Gunaganti  - SF-2781 Removed Application Document provided object reference
* 18/03/2020 -  Shalini Mendu    - SFTLG-813-As a my.app applicant I do not want to pay an application fee if I apply for a Malaysian course on 21-Mar-2020 MYT
*               Kristian Vegerano- Commented out validation for malaysia open day
* 13/05/2020 -  KL               - SFTLG-902 - adding "pendig merge" before "sent for submission" status for contact merge
* 09/03/2022 -  Vinothraja       - SFTG-2477 Added Validations for My.App applications
* 13/09/2022 Ken McGuire Security Updates
* 05/12/2022 Ken McGuire Error Logging
* 28/05/2023 -  Vinothraja       - SFTG-3317 Bypassed for certain validations, during APNG App submission
* 06/08/2024 -  BGreenalnd       - SFTG-3888 Bypassed for certain validations, for residency sub status   'INTRNTNL.O'
* 28/10/2024 -  Girish P       - DANO-281 Bypassed for Callista call for fee waiver, when under maintenance
* 11/10/2024 -  Vishal Gupta   - Update Sequence_Number__c on Application_Qualification_Provided__c for Grad Research
* 14/02/2025 - Davey Yu        - MGROI-706 Don't validate for access and equity on Graduate Research Applications
*******************************************************************************/
public with sharing class AppDeclarationFormCC {
    
    public static final String FIELD_CITIZENSHIP = 'citizenship';
    public static final String FIELD_COURSE_PREFERENCE = 'course_preference';
    public static final String FIELD_QUALIFICATIONS = 'qualifications';
    public static final String FIELD_UNDER_18 = 'under_18';
    public static final String FIELD_SPONSORSHIP = 'sponsorship';
    public static final String FIELD_DOCUMENTS = 'documents';
    public static final String FIELD_ERRORS = 'errors';
    public static final String FIELD_APPLICATION_STATUS = 'application_status';
    public static final String FIELD_PAYMENT = 'payment';
    public static final String FIELD_CONTACT = 'contact';

    /*******************************************************************************
    * @description returns a student application record for editing by the student 
    * @revision 13/09/2022 Ken McGuire Security Updates - current
    *******************************************************************************/
    @AuraEnabled
    public static Application__c retrieveApplication(String applicationId) {
        return loadApplicationForStudentEditing(applicationId);
    }

    /*******************************************************************************
    * @description validates an application prior to submission 
    * @revision 13/09/2022 Ken McGuire Security Updates - current
    *******************************************************************************/
    @AuraEnabled
    public static Map<String, Object> validateApplication(String applicationId) {

        Map<String, Object> mapResults = new Map<String, Object>();

        List<Map<String, Object>> errors = getValidationErrors(applicationId,false);
        if (errors.size() > 0) {
            // return the errors
            mapResults.put(FIELD_ERRORS, errors);
        }
        return mapResults;
    }
    
    /*******************************************************************************
    * @description validates an application upon submission 
    * @revision 13/09/2022 Ken McGuire Security Updates - current
    *******************************************************************************/    
    @AuraEnabled
    public static Map<String, Object> validateAndSubmitApplication(String applicationId) {

        Map<String, Object> mapResults = new Map<String, Object>();

        List<Map<String, Object>> errors = getValidationErrors(applicationId,true);
        if (errors.size() > 0) {
            // return the errors
            mapResults.put(FIELD_ERRORS, errors);
        } else {
            // submit
            try {
                acceptDeclaration(applicationId);
                mapResults.put(FIELD_APPLICATION_STATUS, 'Submitted');
            } catch (Exception e) {
                LogUtilityException.logException(e,'AppliAppDeclarationFormCC.acceptDeclaration');
                throw new AuraHandledException('Unable to update your details: ' + e.getMessage());
            }
        }
        return mapResults;
    }


    /* Validation for Fee waiver code **/
    @AuraEnabled
    public static List<String> validateFeeWaiverCodeEntry(Application__c app) {
        list<String> errorMessages = new List<String>();


        if (app.Fee_Payment_Mode__c == 'Application Fee Waiver Code' && String.isBlank(app.Fee_Waiver_Code__c)) {
            errorMessages.add('Please enter a valid Waiver Code.');
        }
        return errorMessages;
    }

  
 /*********************************************************************************************
    * Changes made to update the status field only from international students */
    @TestVisible
    private static Application__c acceptDeclaration(String applicationId) {
        Application__c applicationRecord = [
                SELECT Id, Submitted_Date__c, Declaration_Accepted__c, Applicant__c, Applicant__r.FirstName,
                        Applicant__r.LastName, Name, Status__c, Fee_Payment_Mode__c, Type_of_Study__c, Partner_Name__c, Submitted_Date_Time__c,
                        Declaration_Text__c, (SELECT Qualification_Type__c, Sequence_Number__c from Application_Qualifications__r ORDER BY Qualification_Type__c)
                FROM Application__c
                WHERE Id = :applicationId
        ];
        String typeOfStudy = applicationRecord.Type_of_Study__c;
        // SFTLG-902 start
        // applicationRecord.Status__c = 'Sent for Submission';
        applicationRecord.Status__c = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
        // SFTLG-902 end
        applicationRecord.Submitted_Date__c = Date.today();
        applicationRecord.Submitted_Date_Time__c = DateTime.now();
        applicationRecord.Declaration_Accepted__c = true; 

        if(String.isNotBlank(typeOfStudy) && typeOfStudy.equalsIgnoreCase(Constants.STUDYTYPE_GRADUATERESEARCH)) {
            for(MyGRAppSetting__mdt metadataRecord : MyGRAppAddQualificationController.fetchDeclarationOptions()) {
                if(applicationRecord.Declaration_Text__c != null) {
                    applicationRecord.Declaration_Text__c += metadataRecord.Declaration_Text__c + '\n';
                } 
                else {
                    applicationRecord.Declaration_Text__c = metadataRecord.Declaration_Text__c + '\n';
                }
            }
        }

        DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{applicationRecord.Id}); 
        rulesDocChecklistEngine.evaluateRules('Application Assessment');
        
        applicationRecord.Checklist_output__c = String.join(rulesDocChecklistEngine.retrieveChecklistItemsEmailInstructions(applicationRecord.Id), '');
        applicationRecord.Checklist_output_completed__c = String.join(rulesDocChecklistEngine.retrieveCompleteChecklistItemsEmailInstructions(applicationRecord.Id), '');
        update applicationRecord;

        List<Contact_Document__c> docs = [
                SELECT d.Id, d.Submitted__c
                FROM Contact_Document__c d
                WHERE d.Contact__c = :applicationRecord.Applicant__c AND d.Submitted__c = FALSE
        ];

        for (Contact_Document__c doc : docs) {
            doc.Submitted__c = true;
        }
        if (docs.size() > 0) {
            update docs;
        }            

        //SFTG-2576 SFTG-2609 - call partner account creation logic for direct my.app study abroad courses
        
        if (String.isNotBlank(typeOfStudy) && (typeOfStudy.equalsIgnoreCase(Constants.MONASH_ABROAD_SA_STUDY_TYPE) || typeOfStudy.equalsIgnoreCase(Constants.MONASH_ABROAD_EX_STUDY_TYPE))) {
            // Current Institution is filled - check
            if(String.isNotBlank(applicationRecord.Partner_Name__c)){
                // commit the partner account record
                List<Async_Process__e> associateApplicationToPartnerEventsToPub = new List<Async_Process__e>();

                // prepare payload
                Id partnerAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
                AsyncProcessPayload payload = new AsyncProcessPayload();
                payload.put('applicationId', JSON.serializePretty(applicationRecord.Id));
                payload.put('partnerAccountName', JSON.serializePretty(applicationRecord.Partner_Name__c));
                payload.put('partnerAccountRecordTypeId', JSON.serializePretty(partnerAccountRecordTypeId));
                // send event
                associateApplicationToPartnerEventsToPub.add(new Async_Process__e(
                    Process_Name__c = 'appAddQualificationCC.AssociateApplicationPartner',
                    Parameter__c = payload.serialize()
                ));
                EventBus.publish(associateApplicationToPartnerEventsToPub);
            }
        }

        //update the application qualifications for grad research app to send the sequence number to callista
        if(applicationRecord.Type_of_Study__c == 'Graduate Research') {
            populateApplicationQualificationSequenceNumber(applicationRecord.Application_Qualifications__r);
        }
        return applicationRecord;
    }

    /*******************************************************************************
    * @description returns validation errors in an application
    * @revision 13/09/2022 Ken McGuire Security Updates
    *******************************************************************************/
    public static List<Map<String, Object>> getValidationErrors(String applicationId, boolean forSubmission) {
        
        Application__c applicationRecord = loadApplicationForInternalProcessing(applicationId);

        // [ {section:section, errors: [error messages] } ]
        List<Map<String, Object>> listSectionAndErrors = new List<Map<String, Object>>();

        List<String> errorMessages = new List<String>();
        
        
        if(applicationRecord.Applicant__r == null ){
            if (forSubmission == true) {
                listSectionAndErrors.add(makeSectionErrorTuple(FIELD_CONTACT, 'Personal Details', new List<String>{'Applicant missing from applicaiton'}));
            }      
        }else {
            errorMessages = PersonalDetailsController.ValidateMandatoryFields(applicationRecord.Applicant__r);
            if (errorMessages.size() > 0) {
                listSectionAndErrors.add(makeSectionErrorTuple(FIELD_CONTACT, 'Personal Details', errorMessages));
            }
        }

        // skip citizenship validation if campus location is online
        if(applicationRecord.Campus_Location__c != 'Online'){
            errorMessages = validateCitizenshipSection(applicationRecord);
            if (errorMessages.size() > 0) {
                listSectionAndErrors.add(makeSectionErrorTuple(FIELD_CITIZENSHIP, 'Citizenship', errorMessages));
            }
        }

        errorMessages = validateAccessEquity(applicationRecord);
        if (errorMessages.size() > 0) {
            listSectionAndErrors.add(makeSectionErrorTuple(FIELD_CITIZENSHIP, 'Access and Equity', errorMessages));
        }

        
        errorMessages = validateACPSection(applicationRecord);
        if (errorMessages.size() > 0)
            listSectionAndErrors.add(makeSectionErrorTuple(FIELD_COURSE_PREFERENCE, 'Study Preferences', errorMessages));

        //SFTD-521 - check if the applicant is a current or previous student. If they are don't require qualifications
        String applicantStudentType = 'NoMatch';
        if(applicationRecord != null){
            if(applicationRecord.Applicant__c != null){
                //Setup correct parameter
                String searchPersonId = applicationRecord.Applicant__r.Previous_Monash_ID__c;
                if(applicationRecord.Applicant__r.Person_ID_unique__c != null){
                    searchPersonId = applicationRecord.Applicant__r.Person_ID_unique__c;
                }
                //Call logic to determine applicant student type
                if(searchPersonId != null && applicationRecord.Applicant__r.BirthDate != null){
                    applicantStudentType = MyApplicationUtilities.findCurrentPreviousStudent(searchPersonId, applicationRecord.Applicant__r.BirthDate);
                }
            }
        }
        //Only require quals if the applicant is not a current nor a previous student
        if(applicantStudentType == 'NoMatch'){
            errorMessages = validateQualSection(applicationRecord);
            if (errorMessages.size() > 0){
                listSectionAndErrors.add(makeSectionErrorTuple(FIELD_QUALIFICATIONS, 'Qualifications & Work Experience', errorMessages));
            }
        }
    
        errorMessages = validateSponsorSection(applicationRecord);
        if (errorMessages.size() > 0)
            listSectionAndErrors.add(makeSectionErrorTuple(FIELD_SPONSORSHIP, 'Sponsorship', errorMessages));
        
        // Validations for payments
		if (
			applicationRecord.Fee_Payment_Mode__c == 'Application Fee Waiver Code' 
            && (PaymentUtils.admissionsMaintenanceMDT==null || !PaymentUtils.admissionsMaintenanceMDT
				?.Status__c.equalsIgnoreCase(PaymentUtils.CALLISTA_META_STATUS))
            ){
            errorMessages = validateFeeWaiverCodeEntry(applicationRecord);
            if (errorMessages.size() > 0) {
                listSectionAndErrors.add(makeSectionErrorTuple(FIELD_PAYMENT, 'payment', errorMessages));
            } else {
                String validationMsg = validateFeeWaiverBeforeSubmit(applicationRecord);
                if (String.isNotBlank(validationMsg))
                    errorMessages = new List<String>{
                            validationMsg
                    };
                if (errorMessages.size() > 0)
                    listSectionAndErrors.add(makeSectionErrorTuple(FIELD_PAYMENT, 'payment', errorMessages));
            }
        } else if (applicationRecord.Fee_Payment_Mode__c == 'Credit Card' && forSubmission == true && applicationRecord.Fee_Payment__c == false) {
            listSectionAndErrors.add(makeSectionErrorTuple(FIELD_PAYMENT, 'payment', new List<String>{'Applicaiton Requires Payment'}));
            
        }
        
        // Validations for submitted applications
        if (forSubmission == true) {
            // validate that payment is made for an application which requires payment.
            errorMessages = validateApplicationPayment(applicationRecord);
            if (errorMessages.size() > 0)
                listSectionAndErrors.add(makeSectionErrorTuple(FIELD_DOCUMENTS, 'Documents', errorMessages));
        }
        // SFTG-2477 Validation for mandatory documents
        errorMessages = validateDocumentsSection(applicationId);
        if (errorMessages.size() > 0)
            listSectionAndErrors.add(makeSectionErrorTuple(FIELD_DOCUMENTS, 'Documents', errorMessages));
    
        return listSectionAndErrors;
    }
   
    private static list<String> validateApplicationPayment(Application__c applicationRecord) {
        list<String> errorMessages = new List<String>();
        if (applicationRecord.Fee_Payment_Mode__c != null && applicationRecord.Fee_Payment_Mode__c == 'Credit Card' && applicationRecord.Fee_Payment__c == false) {
             errorMessages.add('payment is missing');
        }
        return errorMessages;
    }
    
    
    /** Validating - Fee waiver code again on Submit
     * Modified on 3/01/2019 - To include 'Expired' condition
     * **/
    public static String validateFeeWaiverBeforeSubmit(Application__c applicationRecord) {
        String resWS = PaymentUtils.ValidateWaiverCode(applicationRecord.Fee_Waiver_Code__c, applicationRecord.Id, true);

        if (resWS == 'Error')
            return 'The fee waiver code ' + applicationRecord.Fee_Waiver_Code__c + ' is invalid. Please try with a new waiver code to proceed with your application.'; else if (resWS == 'SystemError')
            return 'There was an error with the fee waiver code ' + applicationRecord.Fee_Waiver_Code__c + '. Please re-enter the waiver code to proceed with your application.'; else if (resWS == 'Redeemed')
            return 'The fee waiver code ' + applicationRecord.Fee_Waiver_Code__c + ' is already redeemed. Please enter a valid waiver code to proceed with your application.'; else if (resWS == 'Expired')
            return 'The fee waiver code ' + applicationRecord.Fee_Waiver_Code__c + ' has expired and cannot be used.Please enter a valid waiver code to proceed with your application.'; else
                return '';
    }

    private static Map<String, Object> makeSectionErrorTuple(String sectionName, String sectionLabel, List<String> errorMessages) {
        Map<String, Object> tupleSection = new Map<String, Object>();
        tupleSection.put('section', sectionName);
        tupleSection.put('label', sectionLabel);
        tupleSection.put('errors', errorMessages);
        return tupleSection;
    }

    /**
     * see if the Residency_Status__c of the applicant is filled, if true some fields are mandetory
     * @author  Majid Reisi Dehkordi
     * @date    31/07/2018
     * @param   contactId      id of the contact
     * @return  Retrieve the Citizenship Type Code of the contact
     * 
     *  5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes - part of indonesian implementation
     *  06/08/2024 -  BGreenalnd       - SFTG-3888 Bypassed for certain validations, for residency sub status   'INTRNTNL.O'
     */
    public static List<String> INTERNATIONAL_CITIZENSHIP_TYPES = new List<String>{
            'INTRNTNL', 'INT-TEP', 'DOM-SUN', 'INT-SUN', 'INT-SUN-P', 'INT-IDN', 'INT-IDN-P' 
    };
    //SFTG-3888
    public static List<String> INTERNATIONAL_STUDY_ONLINE_TYPES = new List<String>{
        'INTRNTNL.O'	
    };

    static public List<String> validateCitizenshipSection(Application__c userApplication) {
        list<String> errorMessages = new List<String>();
        // ignore question validations if current user is a partner
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :currentUserId];

        String residencyStatus = userApplication.Residency_Status__c;
        String residencySubStatus = userApplication.Residency_Sub_status__c;
        if (null == residencyStatus || '' == residencyStatus) {
            if(userApplication.Campus_Location__c != 'South Africa'){
                errorMessages.add('Citizenship Type is missing');
            }
        } else if (INTERNATIONAL_CITIZENSHIP_TYPES.indexOf(residencyStatus) >= 0 && INTERNATIONAL_STUDY_ONLINE_TYPES.indexOf(residencySubStatus) == -1 && userApplication.Type_of_Study__c != 'Graduate Research') {
            if (userApplication.Citizenship_Country__c == null) {
                errorMessages.add('Country of Citizenship is missing');
            }

            if (userApplication.Visa_Type__c != null || userApplication.Residency_Status__c == 'INT-SUN-P') {

                if (userApplication.Residency_Status__c == 'INTRNTNL' && String.isBlank(userApplication.Australian_Immigration_Office_Issued__c) 
                    && INTERNATIONAL_STUDY_ONLINE_TYPES.indexOf(residencySubStatus) == -1)
                    errorMessages.add('Australian Immigration Office Issued is not valid');

                // ignore question validations if current user is a partner
                if(!currentUser.Profile.Name.containsIgnoreCase('partner')){
                    if (String.isBlank(userApplication.Visa_Number__c))
                        errorMessages.add('Visa Number is not valid');

                    if (String.isBlank(userApplication.Passport_Number__c))
                        errorMessages.add('Passport Number is not valid');

                    if (userApplication.Visa_Start_Date__c == null)
                        errorMessages.add('Visa Start Date is not valid');

                    if (userApplication.Visa_End_Date__c == null)
                        errorMessages.add('Visa End Date is not valid');
                }
            }

            // ignore question validations if current user is a partner
            if(!currentUser.Profile.Name.containsIgnoreCase('partner') && userApplication.Type_of_Study__c != 'Graduate Research'){     
                if (userApplication.Residency_Status__c == 'INT-SUN' 
                    && (userApplication.Student_Pass_Availability__c == null 
                        || userApplication.Student_Pass_Availability__c == '')) {
                    errorMessages.add('Student Pass availability is not valid');
                }
                if (userApplication.Residency_Status__c == 'INTRNTNL' 
                    || userApplication.Residency_Status__c == 'INT-TEP' 
                    || userApplication.Residency_Status__c == 'INT-SUN-P'
                    || userApplication.Residency_Status__c == 'INT-SUN') {

                    if (userApplication.Criminal_History_Opt_In__c==null || userApplication.Criminal_History_Opt_In__c== 'No' )
                        errorMessages.add('You must consent to collecting sensitive information about criminal history.');
                        
                    if (userApplication.Refused_entry_visa_to_any_country__c == null)
                        errorMessages.add('Refused entry visa to any country is not valid');

                    if (userApplication.Breached_visa_condition__c == null)
                        errorMessages.add('Breached visa condition is not valid');

                    if (userApplication.Medical_health_prevent_visa__c == null)
                        errorMessages.add('Medical/health prevent visa is not valid');

                    if (userApplication.Protection_visa_in_any_country__c == null)
                        errorMessages.add('Protection visa in any country is not valid');

                    if (userApplication.Convicted_of_crime_offence__c == null)
                        errorMessages.add('Convicted of crime/offence is not valid');
                }
            }
        } else if(userApplication.Type_of_Study__c == 'Graduate Research'){
            //Validation for malaysia, indonesia, indonesia pr and other nationality for HDR
            if(!currentUser.Profile.Name.containsIgnoreCase('partner') ){
            
                if ((userApplication.Residency_Status__c == 'DOM-PR' || userApplication.Residency_Status__c == 'INTRNTNL') && userApplication.Citizenship_Country__c == null) {
                    errorMessages.add('Country of Citizenship is missing');
                }
                if (userApplication.Applied_For_Permanent_Residency__c && (userApplication.Residency_Status__c == 'DOM-SUN' || userApplication.Residency_Status__c == 'DOM-IDN'
                || userApplication.Residency_Status__c == 'DOM-IDN-PR' || userApplication.Residency_Status__c == 'INTRNTNL')){
                    if(userApplication.PR_Application_Date__c == null){
                        errorMessages.add('Permanent residency application date is not valid');
                    }
                    if(userApplication.Passport_Number__c == null){
                        errorMessages.add('Passport number is not valid');
                    }
                }
                if(userApplication.Residency_Status__c == 'DOM-PR'){//Australian Permanent Resident
                    if(userApplication.Passport_Number__c == null){
                        errorMessages.add('Passport number is not valid');
                    }
                }
            }
        }
        return errorMessages;
    }

    public static String DOMESTIC_AUS = 'DOM-AUS';
    private static List<String> validateAccessEquity(Application__c userApplication) {
        List<String> errorMessages = new List<String>();

        // ignore question validations if current user is a partner
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :currentUserId];

        if(!currentUser.Profile.Name.containsIgnoreCase('partner')){
            if ((userApplication.Disability_Opt_In__c==null || userApplication.Disability_Opt_In__c =='No') && userApplication.Type_Of_Study__c != 'Graduate Research'){
                errorMessages.add('You must consent to collecting sensitive information about disabilities.');
            }

            if (String.isBlank(userApplication.HasDisabilities__c) && userApplication.Type_Of_Study__c != 'Graduate Research') {
                errorMessages.add('Please select an answer for Access and Equity question');
            }

            // ATSI is only for DOM-AUS
            if (userApplication.Residency_Status__c == DOMESTIC_AUS) {

                if (String.isBlank(userApplication.Applicant__r.Aboriginal_or_Torres_Strait_Islander__c) && userApplication.Campus_Location__c == 'Australia') {
                    errorMessages.add('Please select an answer for the Australian Aboriginal and/or Torres Strait Islander question');
                }
            }
        }

        return errorMessages;
    }

    /**
     * decription of the code
     * @author  Majid Reisi Dehkordi
     * @date    14/08/2018
     * @param   userApplication     application of the user
     * @return  Retrieves the error messages related to Online Credit Section
     */
    static public List<String> validateACPSection(Application__c userApplication) {
        List<String> errorMessages = new List<String>();

        List<Application_Course_Preference__c> appCourses = [
                SELECT Id, Course_Code__c, Course_Offering__r.Active__c
                FROM Application_Course_Preference__c
                WHERE Application__c = :userApplication.Id
        ];

        if (appCourses.isEmpty()) {
            errorMessages.add('Please add the courses you want to apply to continue.');
        }
        if (!appCourses.isEmpty() && isInvalidACPBundle(appCourses)) {
            errorMessages.add('The courses you selected cannot be submitted as a standalone application.');
        }

        if (appCourses.size() > 0) {
            for (Application_Course_Preference__c pref : appCourses) {
                if (!pref.Course_Offering__r.Active__c) {
                    errorMessages.add('Some course preference(s) you have selected are no longer available and are marked for your action. Please remove them from your list, then search again to find an available course offering.');
                    break;
                }
            }
        }

        // SFTG-2477 Validate Unit Preferences for Monash Abroad applications
        if(userApplication.Type_of_Study__c == 'Study Abroad' || userApplication.Type_of_Study__c =='Exchange') {
            Map<String, String> resultsMap = ApplicationNavigationController.validateStudyPlans(userApplication.Id);

            if (resultsMap.containsKey('UnitPreferenceSelection')) {
                    errorMessages.add(resultsMap.get('UnitPreferenceSelection'));
            }
        }
        return errorMessages;
    }

    /**
     * decription of the code
     * @author  Majid Reisi Dehkordi
     * @date    14/08/2018
     * @param   userApplication     application of the user
     * @return  Retrieves the error messages related to Online Credit Section
     */
    static public List<String> validateQualSection(Application__c userApplication) {
        List<String> errorMessages = new List<String>();


        List<Contact_Qualification__c> conQuals = [
                SELECT Id, Qualification_type__c , RecordType.Name
                FROM Contact_Qualification__c
                WHERE RecordType.Name IN ('Tertiary Education', 'Secondary Education', 'Other Qualification')
                AND Contact__c = :userApplication.Applicant__c
        ];

        // Check if Tertiary Education is included
        Boolean hasTertiaryEducation = false;
        for (Contact_Qualification__c cq : conQuals) {
            if (cq.RecordType.Name == 'Tertiary Education') {
                hasTertiaryEducation = true;
            }
        }

        // get all application Ids
        List<Application__c> allApps = [
                SELECT Id, Agent__c, AgentName__c, Type_of_Study__c, Partner_Name__c
                FROM Application__c
                WHERE Applicant__c = :userApplication.Applicant__c
        ];
        
        List<Id> appIds = new List<Id>();
        String typeOfStudy = '';
        for (Application__c app : allApps) {
            appIds.add(app.Id);
            // SFTG-2477 - check Current Institution & Tertiary Education are both filled for Current Application (Study Abroad and Exchange only)
            if (app.id == userApplication.id) {
                typeOfStudy = app.Type_of_Study__c;
                if (String.isNotBlank(typeOfStudy) && (typeOfStudy.equalsIgnoreCase(Constants.MONASH_ABROAD_SA_STUDY_TYPE) || typeOfStudy.equalsIgnoreCase(Constants.MONASH_ABROAD_EX_STUDY_TYPE))) {
                    // Current Institution is filled - check
                    if (String.isBlank(app.Partner_Name__c)){
                        errorMessages.add('Please add your Current Institution to continue.'); 
                    }

                    // Tertiary Education is filled - check
                    if (!hasTertiaryEducation) {
                        errorMessages.add('Please add your Tertiary qualifications to continue.'); 
                    }
                }
            }
        }

        // get all work experiences attached to a valid application (excludes deleted applications)
        List<Application_Work_Experience_Provided__c> appWorkExperiences = new List<Application_Work_Experience_Provided__c>();
        if (appIds.size() > 0) {
            appWorkExperiences = [
                    SELECT Id
                    FROM Application_Work_Experience_Provided__c
                    WHERE Application__c IN :appIds
                    //WHERE Application__c = :userApplication.id
            ];
        }

        // show qualification validation error if there are no contact qualification, work experience or no current institution
        if (String.isNotBlank(typeOfStudy) && !typeOfStudy.equalsIgnoreCase(Constants.MONASH_ABROAD_SA_STUDY_TYPE) && !typeOfStudy.equalsIgnoreCase(Constants.MONASH_ABROAD_EX_STUDY_TYPE)  && conQuals.isEmpty() && appWorkExperiences.isEmpty()) {
            errorMessages.add('Please add your qualifications or work experience to continue.');
        } 
        return errorMessages;
    }

    /**
     * decription of the code
     * @author  Majid Reisi Dehkordi
     * @date    14/08/2018
     * @param   userApplication     application of the user
     * @return  Retrieves the error messages related to Online Credit Section
     */
    static public List<String> validateSponsorSection(Application__c userApplication) {
        list<String> errorMessages = new List<String>();

        if (userApplication.Is_Sponsored__c) {
            if (String.isBlank(userApplication.Sponsor_Name__c))
                errorMessages.add('Please fill in the Sponsor name field.');
            if (userApplication.Sponsorship_Status__c == '--Select--')
                errorMessages.add('Please fill in the Sponsor status field.');
        }

        return errorMessages;
    }
    /**
     * decription Checks whether there are any errors in the Documents section
     * @author  Vinothraja
     * @date    09/03/2022
     * @param   userApplication     application of the user
     * @return  Retrieves the error messages related to Online Credit Section
     */
    static public List<String> validateDocumentsSection(String appId) {
        list<String> errorMessages = new List<String>();

        DocumentChecklistAssessmentServices.runRules('Application Assessment', appId);

        Map<String, Object> resultsMap = ApplicationNavigationController.validateApplicantDocuments(appId);

        if (resultsMap.containsKey('status') && resultsMap.get('status') == 'ValidationError') {
                errorMessages.add('Please upload all mandatory Documents to continue.');
        }

        return errorMessages;
    }

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         5.June.2018
    * @description  The ACPs that the student have selected cannot be submitted as a standalone application.
    * @revision
    *******************************************************************************/
    private static Boolean isInvalidACPBundle(List<Application_Course_Preference__c> selectedACPS) {
        Boolean isBundleInvalid = false;

        Set<String> notStandalone = new Set<String>();
        notStandalone.add('3626'); // Monash English Briding
        notStandalone.add('3623'); // Monash English Briding
        //notStandalone.add('Diploma Part 2A');

        // Count all the courses, if all of them are not applicable as standalone
        // return bundle is not valid.
        Integer numberOfACPs = 0;
        for (Application_Course_Preference__c acpTemp : selectedACPS)
            if (notStandalone.contains(acpTemp.Course_Code__C))
                numberOfACPs++;

        if (numberOfACPs == selectedACPS.size())
            isBundleInvalid = true;

        return isBundleInvalid;
    }

    
    @TestVisible
    private static Boolean under18(string appId) {
        //Get the current application
        Application__c app = [Select a.id, a.Applicant__c From Application__c a where a.id = :appId];
        Contact applicant = [Select c.id, c.Birthdate From Contact c where c.id = :app.Applicant__c];
        if (applicant != null && applicant.Birthdate != null) {
            if (math.floor(applicant.Birthdate.daysBetween(date.TODAY()) / 365.2425) < 18) {
                return true;
            }
        }
        return false;
    }

    private static Application__c loadApplicationForStudentEditing(Id applicationId) {
                List<Application__c> applicationRecords = [
                SELECT Id, Source_System__c,Declaration_Accepted__c, Applicant__c, Applicant__r.FirstName, Applicant__r.First_Name__c, Applicant__r.Last_Name__c,
                        Applicant__r.LastName, Name, Status__c, Applicant__r.Citizenship__c, Fee_Payment_Mode__c, Fee_Amount__c,Fee_Payment__c
                FROM Application__c
                WHERE Id = :applicationId
        ];
        return applicationRecords.size() == 0 ? null : applicationRecords[0];
    }
    
    private static Application__c loadApplicationForInternalProcessing(Id applicationId) {
                List<Application__c> applicationRecords = [
                SELECT Id, Status__c, Type_of_Study__c, Source_System__c, Applying_for_Credit__c, Is_Sponsored__c, Sponsor_Name__c,
                        Sponsorship_Status__c, Guardian_Full_Name__c, Guardian_Phone_Number__c,
                        Guardian_Relationship__c, Guardian_Email_Address__c,
                        Applicant__c, Residency_Status__c, HasDisabilities__c, Student_Pass_Availability__c,
                        Citizenship_Country__c, Visa_Type__c, Australian_Immigration_Office_Issued__c, Visa_Number__c,
                        Passport_Number__c, Visa_Start_Date__c, Visa_End_Date__c,
                        Refused_entry_visa_to_any_country__c, Breached_visa_condition__c,
                        Medical_health_prevent_visa__c, Protection_visa_in_any_country__c,Fee_Amount__c,
                        Criminal_History_Opt_In__c, Applied_For_Permanent_Residency__c, PR_Application_Date__c
                        , Disability_opt_In__c
                        , Residency_Sub_status__c
                        ,Convicted_of_crime_offence__c, Access_and_Equity_Question__c,  Fee_Payment_Mode__c,Fee_Payment__c, Fee_Waiver_Code__c, Campus_Location__c,
                        Applicant__r.Id, Applicant__r.FirstName, Applicant__r.LastName, Applicant__r.first_name__c, Applicant__r.last_name__c,
                        Applicant__r.Aboriginal_or_Torres_Strait_Islander__c, Applicant__r.Previous_Monash_ID__c, Applicant__r.Person_ID_unique__c, Applicant__r.BirthDate,
                        Applicant__r.Salutation, Applicant__r.Gender__c, Applicant__r.Phone, Applicant__r.HomePhone, Applicant__r.MobilePhone, Applicant__r.Email, Applicant__r.Personal_Email__c, Applicant__r.MailingStreet, Applicant__r.MailingCity,
                        Applicant__r.MailingCountry, Applicant__r.MailingPostalCode, Applicant__r.MailingState, Applicant__r.Previously_Studied_at_Monash__c
                    
                FROM Application__c
                WHERE Id = :applicationId
        ];
        return applicationRecords.size() == 0 ? null : applicationRecords[0];
    }
    
       
    /*******************************************************************************
    * @author       Shalini Mendu
    * @date         26.June.2023
    * @description  Update other fields when the Applicant clicks on Applicant Declaration Accepted button from my.app
    * @revision
    *******************************************************************************/
    @AuraEnabled
    public static Boolean updateApplicationWithStudentDeclarationAccepted(String applicationId)
    {
        Application__c app = [select agent__R.name,applicant__r.First_Name__c, applicant__r.Last_Name__c, applicant__r.Id,applicant__r.email,ownerId,Name, declaration_Accepted__c,Status__c from Application__c where Id=:applicationId];
        app.Declaration_Accepted__c = true; 
        app.Status__c = AgentPortalConstants.STUDENT_DECLARATION_ACCEPTED;
        app.Student_Accepted_Timestamp__c = DateTime.now();
        Boolean retFlag = false;
        try{
            update app;
            retFlag = true;
        }catch(Exception ex)
        {
            LogUtilityException.logException(ex,'AppliAppDeclarationFormCC.updateApplicationWithStudentDeclarationAccepted');
            throw new AuraHandledException('Unable to update your status: ' + ex.getMessage());
        }
        return retFlag;
    }
    /*******************************************************************************
    * @author       Vishal Gupta
    * @date         11.Oct.2024
    * @description  Update Sequence_Number__c on Application_Qualification_Provided__c for Grad Research
    * @param aqpList
    * @revision
    *******************************************************************************/
    public static void populateApplicationQualificationSequenceNumber(List<Application_Qualification_Provided__c> aqpList) {
        Set<String> recordTypeNames = new Set<String>();
        Integer seqNumber = 0;
        for(Application_Qualification_Provided__c aqp : aqpList) {
            if(!recordTypeNames.contains(aqp.Qualification_Type__c)) {
                recordTypeNames.add(aqp.Qualification_Type__c);
                seqNumber = 1;
            }
            aqp.Sequence_Number__c = seqNumber;
            seqNumber++;
        }
        update aqpList; 
    }
}