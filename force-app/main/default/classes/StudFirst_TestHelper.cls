/*
    AUTHOR : Vineeth Batreddy
    DESCRIPTION : This class is used to create records for unit tests
    * @revision Suman Gunaganti(2019-07-05): (SF-2781) Removed Application Document provided object reference
    Modified by Shalini Mendu for SFTHB-122 on 10.Jul.2019
*/
@isTest
public without sharing class StudFirst_TestHelper {

    static String TEST_COURSE_CODE = 'M00001';
    static String GTE_RISK_LEVEL_2 = '2';

    /**
    * @description create test Application
    * @param applicant
    * @return Application__c
    */
    public static Application__c createApplication(Contact applicant) {
        Application__c application = new Application__c();
        application.Applicant__c = applicant.Id;
        application.Campus_Location__c = null;
        application.Visa_Type__c = null;
        application.Australian_Immigration_Office_Issued__c = null;
        application.Visa_Number__c = null;
        application.Passport_Number__c = null;
        application.Visa_Start_Date__c = null;
        application.Visa_End_Date__c = null;
        application.Refused_entry_visa_to_any_country__c = null;
        application.Breached_visa_condition__c = null;
        application.Medical_health_prevent_visa__c = null;
        application.Protection_visa_in_any_country__c = null;
        application.Convicted_of_crime_offence__c = null;
        application.HasDisabilities__c = 'Yes';
        application.Residency_Status__c = 'DOM-AUS';
        return application;
    }

    /**
    * @description create test Applicant
    * @param N/A
    * @return Contact
    */
    public static Contact createApplicant() {
        Contact applicant = new Contact();
        applicant.FirstName = 'Joe';
        applicant.LastName = 'Bloggs';
        applicant.Salutation = 'Mr';
        applicant.Gender__c = 'M';
        applicant.Preferred_Name__c = 'RD';
        applicant.Previous_Surname__c = 'Something';
        applicant.Previously_Studied_at_Monash__c = false;
        applicant.Previous_Monash_Institution__c = '';
        applicant.Previous_Monash_ID__c = '';
        applicant.Birthdate = System.today();
        applicant.Email = 'applicant@mailinator.com';
        applicant.MailingStreet = '1 smile street';
        applicant.MailingCity = 'Melbourne';
        applicant.MailingState = 'Victoria';
        applicant.MailingCountry = 'Australia';
        applicant.MailingPostalCode = '3000';
        applicant.Residency_Status__c = 'INT-TEP';
        return applicant;
    }
    /*******************************************************************************
  * @author       Shalini Mendu
  * @date         10.Jul.2019
  * @description  Method to create an international applicant to CRM
  * @param N/A
  * @return Contact
  * @revision
  *******************************************************************************/
    public static Contact createInternationalApplicant() {
        Contact applicant = new Contact();
        applicant.LastName='Chen';
        applicant.FirstName='Alex';
        applicant.Other_Given_Name__c='aChen';
        applicant.Salutation='Mr';
        applicant.Gender__c='M';
        applicant.Birthdate= Date.today().addYears(-20);
        applicant.Preferred_Name__c='Sridhar';
        applicant.Previous_Surname__c='Raj';
        applicant.Previously_Studied_at_Monash__c= false;
        applicant.Previous_Monash_ID__c='123456';
        applicant.Email='abc@yahoo.com.au';
        applicant.Previous_Monash_Institution__c='Monash University';
        applicant.MailingStreet='860 GandhiNagar';
        applicant.MailingCity='Hyderabad';
        applicant.MailingState='Andhra Pradesh';
        applicant.MailingCountry='India';
        applicant.MailingPostalCode='5000044';
        applicant.HomePhone='+911412345678';
        applicant.Phone='+911412345678';
        applicant.MobilePhone='+91412345678';
        applicant.Status__c='CURRENT';
        applicant.Residency_Status__c='INTRNTNL';
        return applicant;
    }
    /*******************************************************************************
      * @author       Shalini Mendu
      * @date         10.Jul.2019
      * @description  This method validates the application data that comes with the submission to CRM
      * @param con
      * @param ctry
      * @return Application__c, Country_Attribute__c
      * @revision
      *******************************************************************************/
    public static Application__c createInternationalApplication(Contact con, Country_Attribute__c ctry) {
        Application__c app = new Application__c();
        app.Applicant__c = con.Id;
        app.Visa_Start_Date__c= Date.valueOf('2018-02-22');
        app.Visa_End_Date__c= Date.valueOf('2012-02-22');
        app.Visa_Type__c='162';
        app.Visa_Number__c='visa123';
        app.Passport_Number__c='A123898';
        app.Residency_Status__c='INTRNTNL';
        app.Citizenship_Country__c = ctry.Id;
        return app;
    }

    /**
    * @description create Applicant
    * @param contact
    * @return Contact
    */
    public static Contact insertApplicant(Contact contact) {
        insert contact;
        return contact;
    }

    /**
    * @description create CoursePreferences
    * @param application
    * @param applicant
    * @param courseOffering
    * @param course
    * @return Application_Course_Preference__c
    */
    public static Application_Course_Preference__c createCoursePreferences(Application__c application, Contact applicant, Course_Offering__c courseOffering, Course__c course) {
        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Academic_CI_Sequence_Number__c = 1;
        acp.Academic_Calendar_Type__c = '';
        acp.Admission_CI_Sequence_Number__c = 1;
        acp.Admission_Calendar_Type__c = '';
        acp.Applicant__c = applicant.Id;
        acp.Application__c = application.Id;
        acp.Attendance_Mode__c = '';
        acp.Attendance_Type__c = 'FT';
        acp.Commencement_Period__c = '';
        acp.Course_Code__c = TEST_COURSE_CODE;
        acp.Course_Offering__c = courseOffering.Id;
        acp.Course_Title__c = 'Master Of Something';
        acp.Course_Version_Number__c = 1;
        acp.Course__c = course.Id;
        acp.Location_Code__c = '';
        //acp.Location__c = '';
        //acp.Order__c = 1;
        acp.Outcome_Status__c = '';
        acp.Preference_Number__c = '';
        acp.Status__c = '';
        acp.Attendance_Mode_Description__c = 'On Campus';
        acp.Attendance_Type_Description__c = 'FULL TIME';
        acp.Location_Code__c = 'CLAYTON';
        acp.Type_of_Place_Description__c = 'Test type of place';
        acp.Unit_Set_Code__c = 'MM00000';
        acp.Unit_Set_Description__c = 'set description';

        return acp;
    }

    /**
    * @description create ContactQualification
    * @param applicant
    * @param q
    * @param rType
    * @return Contact_Qualification__c
    */
    public static Contact_Qualification__c createContactQualification(Contact applicant, Qualification__c q, String rType) {
        Contact_Qualification__c cq = new Contact_Qualification__c();
        cq.Contact__c = applicant.Id;
        cq.Country__c = 'Australia';
        cq.Date_Achieved__c = System.today();
        cq.First_Year_Enrolled__c = '';
        cq.Institution_Code__c = '';
        cq.Institution_Name__c = 'Institution';
        cq.Instruction_in_English__c = true;
        cq.Last_Year_Enrolled__c = '';
        cq.Other_Institution__c = '';
        cq.Other_Qualification_Comments__c = '';
        cq.Other_Qualification__c = '';
        cq.Qualification__c = q.Id;
        cq.Score__c = '3';
        cq.State__c = '';
        cq.State__c = '';
        cq.Status__c = '';

        cq.Year_of_Completion__c = '';
        cq.isTestCompleted__c = true;
        Map<String,RecordType> recordTypes = getRecordTypes('Contact_Qualification__c');

        cq.RecordType = recordTypes.get(rType);
        cq.RecordTypeId = recordTypes.get(rType).Id;
        //for Admission Test
        cq.Listening__c = '8';
        cq.Reading__c = '8';
        cq.Writing__c = '8';
        cq.Speaking__c = '8';
        return cq;
    }

    /**
    * @description create Work Experience
    * @param applicant
    * @return Work_Experience__c
    */
    public static Work_Experience__c createWorkExperience(Contact applicant) {
        Work_Experience__c we = new Work_Experience__c();
        we.Contact__c = applicant.Id;
        we.Position__c = '';
        we.Employer_Name__c = '';
        we.Start_Date__c = System.today();
        we.End_Date__c = System.today();
        we.Contact_Person_First_Name__c = '';
        we.Contact_Person_Last_Name__c = '';

        return we;
    }

    /**
    * @description create CourseOffering
    * @param course
    * @return Course_Offering__c
    */
    public static Course_Offering__c createCourseOffering(Course__c course) {
        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course__c = course.Id;
        courseOffering.Academic_CI_Sequence_Number__c = 1;
        courseOffering.Academic_Calendar_Type__c = '2019';
        courseOffering.Admission_CI_Sequence_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM';
        courseOffering.Attendance_Mode__c = 'SCG';
        courseOffering.Attendance_Type__c = 'PT';
        courseOffering.Course_Code__c = TEST_COURSE_CODE;
        courseOffering.Course_Title__c = 'Master Of Something';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Description__c = 'July-2019';
        courseOffering.Attendance_Mode_Description__c = 'On Campus';
        courseOffering.Attendance_Type_Description__c = 'FULL TIME';
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Course_Type_Group__c = 'OPG';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Type_of_Place_Description__c = 'Test type of place';
        courseOffering.Type_of_Place_Code__c = 'PC001';
        courseOffering.Unit_Set_Code__c = 'MM00000';
        courseOffering.Unit_Set_Description__c = 'set description';
        courseOffering.Active__c = true;
        courseOffering.Mix_Unique_Id__c = AgentPortalTestDataFactory.util.generateRandomString(10);
        return courseOffering;
    }

    /**
    * @description createCourseOfferingNoUnitSet
    * @param course
    * @return Course_Offering__c
    */
    public static Course_Offering__c createCourseOfferingNoUnitSet(Course__c course) {
        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course__c = course.Id;
        courseOffering.Academic_CI_Sequence_Number__c = 1;
        courseOffering.Academic_Calendar_Type__c = '2019';
        courseOffering.Admission_CI_Sequence_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM';
        courseOffering.Attendance_Mode__c = 'SCD';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Course_Code__c = 'M00002';
        courseOffering.Course_Title__c = 'Master Of Something Too';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Description__c = 'January-2019';
        courseOffering.Attendance_Mode_Description__c = 'On Campus';
        courseOffering.Attendance_Type_Description__c = 'FULL TIME';
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Course_Type_Group__c = 'OPG';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Type_of_Place_Code__c = 'PC002';
        courseOffering.Active__c = true;
        courseOffering.Mix_Unique_Id__c = AgentPortalTestDataFactory.util.generateRandomString(10);
        return courseOffering;
    }

    /**
    * @description createCourse
    * @param n/a
    * @return Course__c
    */
    public static Course__c createCourse() {
        Course__c course = new Course__c();
        course.Name = '12345';
        course.Type__c = 'Course-All';

        return course;
    }

    /**
    * @description createQualification
    * @param name
    * @return Qualification__c
    */
    public static Qualification__c createQualification(String name) {
        Qualification__c q = new Qualification__c();
        q.Qualification_Name__c = name;
        q.Overseas__c = false;
        q.Callista_Code__c = AgentPortalTestDataFactory.util.generateRandomString(5);
        //for Admission Test
        q.Sub_score_Type__c = 'Listening; Reading; Speaking; Writing';

        return q;
    }
    /*
    public static Application_Document_Provided__c createApplicationDocument(String applicationId, String contactDocumentId) {
        Application_Document_Provided__c adp = new Application_Document_Provided__c();
        adp.Contact_Document__c = contactDocumentId;
        adp.Application__c = applicationId;

        return adp;
    }
*/
    /**
    * @description createContactDocument
    * @param contactId
    * @param cqId
    * @return Contact_Document__c
    */
    public static Contact_Document__c createContactDocument(String contactId, String cqId) {
        Contact_Document__c cd = new Contact_Document__c();
        cd.Contact__c = contactId;
        cd.Contact_Qualification__c = cqId;
        cd.Comments__c = 'My comments';
        cd.Filename__c = 'Test File';
        cd.Document_Type__c = 'OTHERDCTYP';

        return cd;
    }
    /**
    * @description createDocumentChecklist
    * @param app
    * @param con
    * @param cq
    * @param docType
    * @return Document_Checklist__c
    */
    public static Document_Checklist__c createDocumentChecklist(Application__c app, Contact con, Contact_Qualification__c cq, String docType) {
        Document_Checklist__c dc = new Document_Checklist__c();
        dc.Application__c = app.id;
        dc.Checklist_Requirement__c = 'Proof of Residency';
        dc.Type__c = docType;
        if (String.isNotBlank(docType) && docType == 'Residency'){
            dc.Allowed_Document_Type__c = 'OTHERDCTYP;PRF_ID';
        } else {
            dc.Allowed_Document_Type__c = 'OTHERDCTYP;SCHPREDRES';
        }
        dc.Status__c = 'Requested';
        dc.Contact__c = con.Id;
        if (cq != null){
            dc.Contact_Qualification__c = cq.id;
        }
        dc.Unique_ID__c = dc.Application__c + '-' + dc.Type__c ;

        return dc;
    }

    /**
    * @description createAttachment
    * @param parentId
    * @return Attachment
    */
    public static Attachment createAttachment(String parentId) {
        Attachment attachment = new Attachment();
        attachment.Name = 'Test File';
        attachment.ParentId = parentId;
        attachment.ContentType = 'PDF';
        attachment.Description = 'Test File';
        attachment.Body = Blob.valueOf('Hello');

        return attachment;
    }
    /**
    * @description getRecordTypes
    * @param obj
    * @return Map<String,RecordType>
    */
    public static Map<String,RecordType> getRecordTypes(String obj) {
        //Query for the record types of an object
        List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType= :obj and isActive=true];

        //Create a map between the RecordType Name and RecordType
        Map<String,RecordType> recordTypes = new Map<String,RecordType>{};
        for(RecordType rt: rtypes) {
            recordTypes.put(rt.Name, rt);
        }
        return recordTypes;
    }


    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  creates and returns a domestic applicant profile community user
    * @param na
    * @return User
    * @revision
    *******************************************************************************/
    public static User createCommunityUser () {
        User userRec;
        try {
            String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

            Account accountRecord = new Account(name ='AccountTest') ;
            insert accountRecord;

            Contact contactRecord = new Contact();
            contactRecord.FirstName = 'First';
            contactRecord.LastName = 'Last';
            contactRecord.AccountId = accountRecord.Id;
            contactRecord.Residency_Status__c = 'INT-TEP';
            contactRecord.MailingCountry = 'AUSTRALIA';
            insert contactRecord;

            Integer rnd = Integer.valueOf(Math.random()*9999);
            userRec = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd)+'monash@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'INT-TEP',
                Street = '',
                App_Address_Type__c = 'POSTAL');
            insert userRec;

            /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
             * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
            User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            System.runAs(thisUser) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = userRec.Id);
                insert psa;
            }

        } catch (Exception ex) {

            ExLog.add('ApplicationPortalCC Test Class', 'ApplicationPortalCC_Test', 'createCommunityUser' , ex.getMessage());
        }

        return userRec;
    }


    /*******************************************************************************
        * @author       Andrew Yeo
        * @date         24.July.2018
        * @description  creates Contact and Community User for International Applicants
        * @param na
        * @return User
        * @revision
        *******************************************************************************/
    public static User createContactAndCommunityUser() {
        User userRec;
        try {
            String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

            Account accountRecord = new Account(name ='AccountTest') ;
            insert accountRecord;

            Contact contactRecord = new Contact();
            contactRecord.FirstName = 'First';
            contactRecord.LastName = 'Last';
            contactRecord.Citizenship__c = 'INTERNATIONAL';
            contactRecord.AccountId = accountRecord.Id ;
            contactRecord.Residency_Status__c = 'INT-TEP';
            insert contactRecord;

            Integer rnd = Integer.valueOf(Math.random()*9999);
            userRec = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd)+'monash@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'INT-TEP',
                Street = '',
                App_Address_Type__c = 'POSTAL');
            insert userRec;
            /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
             * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
            System.runAs(userRec) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = userRec.Id);
                insert psa;
            }

        } catch (Exception ex) {

            ExLog.add('ApplicationPortalCC Test Class', 'ApplicationPortalCC_Test', 'createCommunityUser' , ex.getMessage());
        }
        return userRec;
    }

    /**
    * @description create contact and user for Australian international application -INTRNTNL
    * @param na
    * @return User
    */
    public static User createContactAndCommunityUserIntrntnl() {
        User userRec;
        try {
            String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

            Account accountRecordIntrntnl = new Account(name ='AccountTestIntrntnl') ;
            insert accountRecordIntrntnl;

            Contact contactRecordIntrntnl = new Contact();
            contactRecordIntrntnl.FirstName = 'First';
            contactRecordIntrntnl.LastName = 'Last';
            //contactRecord.Citizenship__c = 'INTERNATIONAL';
            contactRecordIntrntnl.AccountId = accountRecordIntrntnl.Id ;
            //contactRecord.Residency_Status__c = 'INT-TEP';
            insert contactRecordIntrntnl;

            Integer rnd = Integer.valueOf(Math.random()*9999);
            userRec = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd)+'monash@mutesting.edu',
                ContactId = contactRecordIntrntnl.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'INT-TEP',
                Street = '',
                App_Address_Type__c = 'POSTAL');
            insert userRec;
            /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
             * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
            System.runAs(userRec) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = userRec.Id);
                insert psa;
            }

        } catch (Exception ex) {

            ExLog.add('ApplicationPortalCC Test Class', 'ApplicationPortalCC_Test', 'createCommunityUser' , ex.getMessage());
        }
        return userRec;
    }

    /**
    * @description create contact and user for Partner Portal
    * @param na
    * @return User
    */
    public static User createContactAndPartnerPortalUser() {
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Account testAccount = new Account(Name = 'TestAccount', RecordTypeId = partnerRecordTypeId, OwnerId = UserInfo.getUserId());
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com', OwnerId = UserInfo.getUserId());
        insert testContact;
        ExperienceAuthenticationServices.generatePartnerUser('{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User","DelegatedAdmin":' + true + '}');
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :Constants.PARTNER_PERMISSION_SET LIMIT 1];
        User partnerUser = [SELECT Id, ContactId, ProfileId FROM User WHERE Profile.Name = :Constants.PARTNER_USER_PROFILE AND IsActive = true AND Username LIKE '%testemail@testemail.com%' LIMIT 1];
        System.runAs(partnerUser) {
            insert new PermissionSetAssignment(AssigneeId = partnerUser.id, PermissionSetId = ps.Id);
        }
        return partnerUser;
    }

    /**
    * @description create Australian international application INTRNTNL
    * @param contactRecordIntrntnl
    * @return Application__c
    */
    public static Application__c createInternationalApplication(Contact contactRecordIntrntnl) {
        Application__c application = new Application__c();
        application.Applicant__c = contactRecordIntrntnl.Id;
        application.Campus_Location__c = 'Australia';
        application.Residency_Status__c = 'INTRNTNL';
        application.applicant__r = contactRecordIntrntnl;

        return application;
    }

    /**
    * @description Create contact and user for Australian Domestic application - DOM-AUS
    * @param na
    * @return User
    */
    public static User createContactAndCommunityUserDomAus() {
        User userRec;
        try {
            String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

            Account accountRecordDomAus = new Account(name ='AccountTestDomAus') ;
            insert accountRecordDomAus;

            Contact contactRecordDomAus = new Contact();
            contactRecordDomAus.FirstName = 'First';
            contactRecordDomAus.LastName = 'Last';
            contactRecordDomAus.AccountId = accountRecordDomAus.Id ;
            insert contactRecordDomAus;

            Integer rnd = Integer.valueOf(Math.random()*9999);
            userRec = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd)+'monash@mutesting.edu',
                ContactId = contactRecordDomAus.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                //App_Residency_Status__c = 'DOM-AUS',
                Street = '',
                App_Address_Type__c = 'POSTAL');
            insert userRec;
            /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
             * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
            System.runAs(userRec) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = userRec.Id);
                insert psa;
            }

        } catch (Exception ex) {

            ExLog.add('ApplicationPortalCC Test Class', 'ApplicationPortalCC_Test', 'createCommunityUser' , ex.getMessage());
        }
        return userRec;
    }

    /**
    * @description Create Australian Domestic application DOM-AUS
    * @param contactRecordDomAus
    * @return Application__c
    */
    public static Application__c createAusDomesticApplication(Contact contactRecordDomAus) {
        Application__c applicationDomAus = new Application__c();
        applicationDomAus.Applicant__c = contactRecordDomAus.Id;
        applicationDomAus.Campus_Location__c = 'Australia';
        applicationDomAus.Residency_Status__c = 'DOM-AUS';
        applicationDomAus.applicant__r = contactRecordDomAus;
        return applicationDomAus;
    }

    /**
    * @description Create contact and user for DOM-SUN
    * @param contactRecordDomAus
    * @return User
    */
    public static User createContactAndCommunityUserDomSun() {
        User userRec;
        try {
            String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

            Account accountRecordDomSun = new Account(name ='AccountTestDomAus') ;
            insert accountRecordDomSun;

            Contact contactRecordDomSun = new Contact();
            contactRecordDomSun.FirstName = 'FirstDomSun';
            contactRecordDomSun.LastName = 'LastDomSun';
            contactRecordDomSun.AccountId = accountRecordDomSun.Id ;
            insert contactRecordDomSun;

            Integer rnd = Integer.valueOf(Math.random()*9999);
            userRec = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd)+'monash@mutesting.edu',
                ContactId = contactRecordDomSun.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                //App_Residency_Status__c = 'DOM-AUS',
                Street = '',
                App_Address_Type__c = 'POSTAL');
            insert userRec;
            /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
             * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
            System.runAs(userRec) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = userRec.Id);
                insert psa;
            }

        } catch (Exception ex) {
            ExLog.add('ApplicationPortalCC Test Class', 'ApplicationPortalCC_Test', 'createCommunityUser' , ex.getMessage());
        }
        return userRec;
    }

    /**
    * @description Create Malaysian Campus application - DOM-SUN
    * @param contactRecordDomSun
    * @return Application__c
    */
    public static Application__c createMalaysiaDomesticApplication(Contact contactRecordDomSun) {
        Application__c applicationMas = new Application__c();
        applicationMas.Applicant__c = contactRecordDomSun.Id;
        applicationMas.Campus_Location__c = 'Malaysia';
        applicationMas.Residency_Status__c = 'DOM-SUN';
        applicationMas.applicant__r = contactRecordDomSun;
        return applicationMas;
    }

    /**
    * @description Australian international application for Birthday and Previous Monash Id check
    * @param na
    * @return User
    */
    public static User createContactAndCommunityUserMon() {
        User userRecMon;
        try {
            String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

            Account accountRecordMon = new Account(name ='AccountTestMon') ;
            insert accountRecordMon;

            Contact contactRecordMon = new Contact();
            contactRecordMon.FirstName = 'First';
            contactRecordMon.LastName = 'Last';
            contactRecordMon.AccountId = accountRecordMon.Id ;
            contactRecordMon.Previous_Surname__c = '99998888';
            insert contactRecordMon;

            Integer rnd = Integer.valueOf(Math.random()*9999);
            userRecMon = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd)+'monash@mutesting.edu',
                ContactId = contactRecordMon.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                //App_Residency_Status__c = 'DOM-AUS',
                Street = '',
                App_Address_Type__c = 'POSTAL');
            insert userRecMon;
            /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
             * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
            System.runAs(userRecMon) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = userRecMon.Id);
                insert psa;
            }

        } catch (Exception ex) {
            ExLog.add('ApplicationPortalCC Test Class', 'ApplicationPortalCC_Test', 'createCommunityUser' , ex.getMessage());
        }
        return userRecMon;
    }

    /**
    * @description create Application
    * @param contactRecordMon
    * @return Application__c
    */
    public static Application__c createInternationalApplicationMon(Contact contactRecordMon) {
        Application__c applicationMon = new Application__c();
        applicationMon.Applicant__c = contactRecordMon.Id;
        applicationMon.Campus_Location__c = 'Australia';
        applicationMon.Residency_Status__c = 'INTRNTNL';
        applicationMon.applicant__r = contactRecordMon;
        return applicationMon;
    }

    /**
    * @description create Contact for Monash Id and Birthdate comparison
    * @param na
    * @return Contact
    */
    public static Contact createContactMon() {
        Contact contMon = new Contact();
        contMon.FirstName = 'Jonnie';
        contMon.LastName = 'Lee';
        contMon.Salutation = 'Mr';
        contMon.Gender__c = 'M';
        contMon.Preferred_Name__c = 'Tester';
        contMon.Person_ID_unique__c = '99998888';
        contMon.Birthdate = System.today();
        contMon.Email = 'testcontact123@mailinator.com';
        return contMon;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns an tertiary institution record
    * @param na
    * @return Institution__c
    * @revision
    *******************************************************************************/

    public static Institution__c createTertiaryInstitution(){
        Institution__c tertInsRec = new Institution__c();
        tertInsRec.Country__c = 'Australia';
        tertInsRec.Institution_Code__c = '834';
        tertInsRec.Institution_Name__c = 'CANNING COLLEGE AUSTRALIA';
        tertInsRec.Type__c = 'Tertiary';
        return tertInsRec;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns a tertiary qualification record
    * @param na
    * @return Qualification__c
    * @revision
    *******************************************************************************/
    public static Qualification__c createTertiaryQualification () {
        String TERTIARY_RECORDTYPE = Schema.SObjectType.Qualification__c.getRecordTypeInfosByName().get('Tertiary Qualification').getRecordTypeId();
        Qualification__c tertqualRec = new Qualification__c();
        tertqualRec.Callista_Code__c = 'AP';
        tertqualRec.Overseas__c = false;
        tertqualRec.Qualification_Name__c = 'APPRENTICESHIP';
        tertqualRec.RecordTypeId = TERTIARY_RECORDTYPE;
        return tertqualRec;
    }

    /**
   * @description createOtherQualification
   * @param na
   * @return Qualification__c
   */
    public static Qualification__c createOtherQualification () {
        String ENGLISH_TEST_RECORDTYPE = Schema.SObjectType.Qualification__c.getRecordTypeInfosByName().get('Admission Test').getRecordTypeId();
        Qualification__c otherQualRecord = new Qualification__c();
        otherQualRecord.Callista_Code__c = 'AP';
        otherQualRecord.Overseas__c = false;
        otherQualRecord.Qualification_Name__c = 'Other Qualification';
        otherQualRecord.RecordTypeId = ENGLISH_TEST_RECORDTYPE ;

        return otherQualRecord;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns an tertiary institution record
    * @param na
    * @return Institution__c
    * @revision
    *******************************************************************************/
    public static Institution__c createSecondaryInstitution () {
        Institution__c secInsRec = new Institution__c();
        secInsRec.Country__c = 'Australia';
        secInsRec.Institution_Code__c = '196';
        secInsRec.Institution_Name__c = 'ST LEONARDS COLLEGE - IB';
        secInsRec.State__c = 'VIC';
        secInsRec.Type__c = 'Secondary';
        return secInsRec;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns a Secondary qualification record
    * @param na
    * @return Qualification__c
    * @revision
    *******************************************************************************/
    public static Qualification__c createSecondaryQualification () {
        String SECONDARY_RECORDTYPE = Schema.SObjectType.Qualification__c.getRecordTypeInfosByName().get('Secondary Qualification').getRecordTypeId();
        Qualification__c secondQualRec = new Qualification__c();
        secondQualRec.Callista_Code__c = 'FY-TRINITY';
        secondQualRec.Overseas__c = false;
        secondQualRec.Qualification_Name__c = 'TRINITY FOUNDATION YEAR';
        secondQualRec.State__c = 'VIC';
        secondQualRec.RecordTypeId = SECONDARY_RECORDTYPE;
        return secondQualRec;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns a English Test record
    * @param na
    * @return Qualification__c
    * @revision
    *******************************************************************************/
    public static Qualification__c createEnglishTest () {
        String ENGLISH_TEST_RECORDTYPE = Schema.SObjectType.Qualification__c.getRecordTypeInfosByName().get('Admission Test').getRecordTypeId();
        Qualification__c englishTest = new Qualification__c();
        englishTest.Available_on_Portal__c = true;
        englishTest.Callista_Code__c = 'IELTS';
        englishTest.Overseas__c = false;
        englishTest.Qualification_Name__c = 'IELTS (INTERNATIONAL ENGLISH LANGUAGE TESTING SERVICE)';
        englishTest.RecordTypeId = ENGLISH_TEST_RECORDTYPE;
        return englishTest;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns a contact document record
    * @param contactId
    * @return Contact_Document__c
    * @revision
    *******************************************************************************/
    public static Contact_Document__c createContactDocument (String contactId) {
        Contact_Document__c docRec = new Contact_Document__c();
        docRec.Comments__c = 'certificate';
        docRec.Contact__c = contactId;
        docRec.Document_Type__c = 'ACCEPT-ADM';
        docRec.Filename__c = 'certificate.pdf';
        return docRec;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  populates an existing work experience record
    * @param workExpRecord
    * @return Work_Experience__c
    * @revision
    *******************************************************************************/
    public static Work_Experience__c populateWorkExperienceRecord (Work_Experience__c workExpRecord) {
        workExpRecord.Position__c = 'Developer';
        workExpRecord.Employer_Name__c = 'Descenture';
        workExpRecord.Start_Date__c = date.today().addMonths(-12);
        workExpRecord.End_Date__c = date.today().addMonths(-1);
        workExpRecord.Contact_Person_Phone__c = '123456';
        workExpRecord.Contact_Person_First_Name__c = 'Steph';
        workExpRecord.Contact_Person_Last_Name__c = 'Curry';
        workExpRecord.Contact_Person_Email__c = 'scurry30@gmail.com.test';
        workExpRecord.Contact_Person_Street__c = '7000 Coliseum Way';
        workExpRecord.Contact_Person_City__c = 'Oakland';
        workExpRecord.Contact_Person_State__c = 'California';
        workExpRecord.Contact_Person_PostalCode__c = '94621';
        return workExpRecord;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns a citizenship type custom setting
    * @param na
    * @return Callista_Citizenship_Type__c
    * @revision
    *******************************************************************************/
    public static Callista_Citizenship_Type__c createCitizenshipTypeRecord () {
        Callista_Citizenship_Type__c citizenshipType = new Callista_Citizenship_Type__c();
        citizenshipType.Name = 'DOM-AUS';
        citizenshipType.Description__c = 'AUSTRALIAN CITIZEN (INCL AUS CITIZENS WITH DUAL CITIZENSHIP)';
        citizenshipType.Explanation__c = 'I am an Australian citizen (with or without dual citizenship)';
        citizenshipType.Type__c = 'DOMESTIC';
        citizenshipType.Campus_of_Study__c = 'Australian campus and any location not listed below';
        return citizenshipType;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns a Australian Postcodes custom setting
    * @param na
    * @return Australian_Postcodes__c
    * @revision
    *******************************************************************************/
    public static Australian_Postcodes__c createAustralicanPostcodeRecord () {
        Australian_Postcodes__c ausPostal = new Australian_Postcodes__c();
        ausPostal.Name = '3000';
        return ausPostal;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017
    * @description  returns an application record
    * @param applicantId
    * @return Application__c
    * @notes        [OVERLOADED TO RETRIEVE IDS INSTEAD OF ACTUAL CONTACT]
    * @revision
    *******************************************************************************/

    public static Application__c createApplication(String applicantId) {
        Application__c application = new Application__c();
        application.Applicant__c = applicantId;
        application.Passport_Number__c = 'A1234567';
        application.Campus_Location__c = null;
        application.Visa_Type__c = null;
        application.Australian_Immigration_Office_Issued__c = null;
        application.Visa_Number__c = null;
        application.Passport_Number__c = null;
        application.Visa_Start_Date__c = null;
        application.Visa_End_Date__c = null;
        application.Refused_entry_visa_to_any_country__c = null;
        application.Breached_visa_condition__c = null;
        application.Medical_health_prevent_visa__c = null;
        application.Protection_visa_in_any_country__c = null;
        application.Convicted_of_crime_offence__c = null;
        return application;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         25.May.2017
    * @description  creates an Application qualification record
    * @param appId
    * @param conQualId
    * @return Application_Qualification_Provided__c
    * @revision
    *******************************************************************************/
    public static Application_Qualification_Provided__c createAppQualProvided(String appId, String conQualId) {
        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appId;
        aqpRecord.Contact_Qualification__c = conQualId;
        return aqpRecord;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         25.May.2017
    * @description  creates an Application qualification record
    * @param appId
    * @param workExpRecordId
    * @return Application_Work_Experience_Provided__c
    * @revision
    *******************************************************************************/
    public static Application_Work_Experience_Provided__c createAppWorkExpProvided(String appId, String workExpRecordId) {
        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appId;
        aweRecord.Work_Experience__c = workExpRecordId;
        return aweRecord;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         30.May.2017
    * @description  creates an Application qualification record
    * @param appId
    * @param contactId
    * @param acpId
    * @return Document_Requested__c
    * @revision
    *******************************************************************************/
    public static Document_Requested__c  createDocRequestRecord(String contactId, String appId, String acpId) {
        Document_Requested__c docReqRecord = new Document_Requested__c();
        docReqRecord.Additional_Documents__c = 'TEST';
        docReqRecord.Applicant__c = contactId;
        docReqRecord.Application__c = appId;
        docReqRecord.Application_Course_Preference__c = acpId;
        return docReqRecord;
    }
    /**
    * @description createOutcomeStatus
    * @param na
    * @return Callista_Outcome_Status__c
    */
    public static Callista_Outcome_Status__c createOutcomeStatus() {
        Callista_Outcome_Status__c outcomeStatus = new Callista_Outcome_Status__c();
        outcomeStatus.Name = 'TEST-STATUS';
        outcomeStatus.FSPortal_Status__c = 'Testing';
        outcomeStatus.Explanation__c = 'This is a test';
        outcomeStatus.Status__c = 'Test';
        return outcomeStatus;
    }

    /*******************************************************************************
                Ryan Wilson - Helper methods for the Assessment plan
    *******************************************************************************/
    /**
    * @description createCourseOfferingForAssessment
    * @param na
    * @return List<Course_Offering__c>
    */
    public static List<Course_Offering__c> createCourseOfferingForAssessment() {
        List<Course_Offering__c> courseOffers = new List<Course_Offering__c>();
        for(Integer i=1; i<=2; i++){
            Course_Offering__c courseOffering = new Course_Offering__c();
            courseOffering.Academic_CI_Sequence_Number__c = 1;
            courseOffering.Academic_Calendar_Type__c = '2019';
            courseOffering.Admission_CI_Sequence_Number__c = 1;
            courseOffering.Admission_Calendar_Type__c = 'ADM';
            courseOffering.Attendance_Mode__c = 'IN';
            courseOffering.Attendance_Type__c = 'FT';
            courseOffering.Course_Code__c = 'M0000'+i;
            courseOffering.Course_Title__c = 'Master Of Something Too';
            courseOffering.Course_Version_Number__c = 1;
            courseOffering.Admission_Calendar_Description__c = 'January-2019';
            courseOffering.Attendance_Mode_Description__c = 'On Campus';
            courseOffering.Attendance_Type_Description__c = 'FULL TIME';
            courseOffering.Citizenship_Type__c = 'DOM-AUS';
            courseOffering.Course_Type_Group__c = 'OPG';
            courseOffering.Location_Code__c = 'CITY';
            courseOffering.Type_of_Place_Code__c = 'FULL-FEE';
            courseOffering.Faculty__c = 'Faculty of Law';
            courseOffering.Active__c = true;
            //courseOffering.Mix_Unique_Id__c = '1234567';
            courseOffers.add(courseOffering);
        }
        return courseOffers;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         29.Jun.2017
    * @description  Create Queue with members
    * @param arName
    * @param allowQueueInsert
    * @return Group
    * @revision
    *******************************************************************************/
    public static Group createGroupWithMembers(String arName, Boolean allowQueueInsert) {
        Group assessorGroupRec = new Group();
        assessorGroupRec.Name = arName;
        assessorGroupRec.Type = 'Queue';
        insert assessorGroupRec;
        GroupMember groupMemberRec = new GroupMember();
        groupMemberRec.GroupId = assessorGroupRec.Id;
        groupMemberRec.UserOrGroupId = UserInfo.getUserId();
        insert groupMemberRec;
        //if true, add queue to the group
        if (allowQueueInsert) {
            List<QueueSobject> queueList = new List<QueueSobject>();
            QueueSobject queueRec = new QueueSobject();
            queueRec.QueueId = assessorGroupRec.Id;
            queueRec.SobjectType = 'Assessment_Plan_Task__c';
            queueList.add(queueRec);
            QueueSobject queueRec2 = new QueueSobject();
            queueRec2.QueueId = assessorGroupRec.Id;
            queueRec2.SobjectType = 'Assessment_Plan__c';
            queueList.add(queueRec2);
            insert queueList;
        }
        return assessorGroupRec;
    }
    /**
    * @description createEncumbranceAdmin
    * @param contactId
    * @return Encumbrance__c
    */
    public static Encumbrance__c createEncumbranceAdmin(Id contactId) {
        Encumbrance__c enc = new Encumbrance__c();
        enc.Name = 'Test Admin Encumbrance';
        enc.enc_category__c = 'Administrative';
        enc.Contact__c = contactId;
        return enc;
    }
    /**
    * @description createEncumbranceAcademic
    * @param contactId
    * @param course
    * @return Encumbrance__c
    */
    public static Encumbrance__c createEncumbranceAcademic(Id contactId, Course__c course) {
        Encumbrance__c enc = new Encumbrance__c();
        enc.Name = 'Test Academic Encumbrance';
        enc.enc_category__c = 'Academic';
        enc.Contact__c = contactId;
        enc.enc_course_code__c = course.Course_Code__c;
        return enc;
    }
    /**
    * @description createGTERiskCountryAttribute
    * @param na
    * @return Country_Attribute__c
    */
    public static Country_Attribute__c createGTERiskCountryAttribute() {
        Country_Attribute__c countryAttr = new Country_Attribute__c();
        countryAttr.GTE_Risk_Rating__c = GTE_RISK_LEVEL_2;
        return countryAttr;
    }
    /*******************************************************************************
    * @author       Suman Gunaganti
    * @date         12.Dec.2019
    * @description  Creates contentdocument links for the records
    * @param allAccess
    * @param appId
    * @param cdId
    * @return ContentDocument
    * @revision
    *******************************************************************************/
    public static ContentDocument createTestDocument(Boolean allAccess, String appId, String cdid){
        // create a file
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
            Title='Test File',
            PathOnClient ='/Test File.jpg',
            VersionData = bodyBlob,
            origin = 'H'
        );
        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id =: cv.Id];

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId
        FROM ContentDocument
        WHERE id=:cv.ContentDocumentId];
        ContentDocument file = documents[0];

        if(allAccess)
        {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = appId;
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'v';
            cdLink.Visibility = 'AllUsers';

            insert cdLink;

            ContentDocumentLink cdLink2 = new ContentDocumentLink();
            cdLink2.LinkedEntityId = cdid;
            cdLink2.ContentDocumentId = cv.ContentDocumentId;
            cdLink2.ShareType = 'v';
            cdLink2.Visibility = 'AllUsers';

            insert cdLink2;
        }

        return file;
    }

    /*******************************************************************************
    * @author       J.Mapanao
    * @date         16.Dec.2019
    * @description  Creates case
    * @param na
    * @return Case
    * @revision
    *******************************************************************************/
    public static Case createEnquiry() {
        String ADMISSIONS_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Admissions').getRecordTypeId();
        Case enq = new Case();
        enq.Subject = 'Test Case';
        enq.Description = 'Test';
        enq.Heard_About_From__c = 'Banners';
        enq.Origin = 'Web';
        enq.Student_Type__c = 'International';
        enq.Category_Level_1__c = 'Other';
        enq.Enquiry_Type__c = 'Future Student';
        enq.Managing_Faculty__c = 'Other';
        enq.Status = 'Open';
        enq.RecordTypeId = ADMISSIONS_RECORDTYPE;
        return enq;
    }

    /*******************************************************************************
    * @author       J.Mapanao
    * @date         16.Dec.2019
    * @description  Creates payment
    * @param co
    * @param contact
    * @param application
    * @return Payment__c
    * @revision
    *******************************************************************************/
    public static Payment__c createPayment(Course_Offering__c co, Contact contact, Application__c application) {
        Payment__c payment = new Payment__c();
        payment.Application__c = application.Id;
        payment.Contact__c = contact.Id;
        payment.Course_Offering__c = co.Id;
        payment.Street__c = '1 Brighton Road';
        payment.Suburb__c = 'Hampton';
        payment.State__c = 'Victoria';
        payment.Postcode__c = '3163';
        //payment.Payment_Type__c = 'Credit Card';
        payment.Payment_Status__c = 'Not Processed';
        payment.Send_Receipt__c = false;
        payment.Quantity__c = 1;
        payment.Payment_Amount__c = 100;
        return payment;
    }

    /**
     * @description cache the digitary integration profile
     */
    public static Profile DIGITARY_INTEGRATION_PROFILE {
        get {
            if (DIGITARY_INTEGRATION_PROFILE == null) {
                DIGITARY_INTEGRATION_PROFILE = [
                    SELECT Id
                    FROM Profile
                    WHERE Name = 'Integration - Digitary'
                ];
            }
            return DIGITARY_INTEGRATION_PROFILE;
        }
        set;
    }

    /**
     * @description cache the integration profile
     */
    public static Profile INTEGRATION_PROFILE {
        get {
            if (INTEGRATION_PROFILE == null) {
                INTEGRATION_PROFILE = [
                    SELECT Id
                    FROM Profile
                    WHERE Name = 'Minimum Access - API Only Integrations'
                ];
            }
            return INTEGRATION_PROFILE;
        }
        set;
    }

    /**
     * @description cache the Digitary Permission Set Group.
     */
    public static PermissionSetGroup DIGITARY_PERMISSIONSET_GROUP {
        get {
            if (DIGITARY_PERMISSIONSET_GROUP == null) {
                DIGITARY_PERMISSIONSET_GROUP = [
                    SELECT Id, Status
                    FROM PermissionSetGroup
                    WHERE DeveloperName = 'Integration_Digitary'
                    LIMIT 1
                ];
                if (DIGITARY_PERMISSIONSET_GROUP.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(DIGITARY_PERMISSIONSET_GROUP.Id);
                }
            }
            return DIGITARY_PERMISSIONSET_GROUP;
        }
        set;
    }

    /**
     * @description Creates an Integration User.
     * @return `User`
     */
    public static User createIntegrationUser() {
        User integrationUser = new User(
            FirstName = 'Test Minimal Access API',
            LastName = 'User',
            Email = 'test.minimal.access.api.user@example.com',
            Username = 'test.minimal.access.api.user' + Datetime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = INTEGRATION_PROFILE.Id,
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        return integrationUser;
    }

    /**
     * @description Creates a Digitary Integration User.
     * @return `User`
     */
    public static User createDigitaryIntegrationUser() {
        User digitaryIntegrationUser = new User(
            FirstName = 'Digitary Minimal Access API',
            LastName = 'User',
            Email = 'digitary.minimal.access.api.user@example.com',
            Username = 'digitary.minimal.access.api.user' + Datetime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = DIGITARY_INTEGRATION_PROFILE.Id,
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        return digitaryIntegrationUser;
    }

    /**
     * @description Assigns the required permission set group to the integration user.
     * @param integrationUser
     * @return `PermissionSetAssignment`
     */
    public static PermissionSetAssignment createDigitaryIntegrationPermissionSetAssignment(User integrationUser) {
        return new PermissionSetAssignment(
            AssigneeId = integrationUser.Id,
            PermissionSetGroupId = DIGITARY_PERMISSIONSET_GROUP.Id
        );
    }

    /**
     * @description Builds a Digitary API User.
     * @return `User`
     */
    public static User buildDigitaryApiUser() {
        User digitaryApiUser;
        // use runAs to avoid DML exception
        System.runAs(new User(Id = UserInfo.getUserId())) {
            digitaryApiUser = createDigitaryIntegrationUser();
            insert digitaryApiUser;
            insert createDigitaryIntegrationPermissionSetAssignment(digitaryApiUser);
        }
        return digitaryApiUser;
    }

    /**
     * @description Builds a Minimal Access API User.
     * @return `User`
     */
    public static User buildMinimalAccessApiUser() {
        User minimalAccessApiUser;
        // use runAs to avoid DML exception
        System.runAs(new User(Id = UserInfo.getUserId())) {
            minimalAccessApiUser = createIntegrationUser();
            insert minimalAccessApiUser;
        }
        return minimalAccessApiUser;
    }
}