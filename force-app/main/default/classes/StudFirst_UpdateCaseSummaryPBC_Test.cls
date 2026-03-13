/*******************************************************************************
* @author       Ant Custodio
* @date         24.Aug.2017        
* @description  test class for StudFirst_UpdateCaseSummaryPBC Invocable 
                    Process Builder Class
* @revision     
* @revision         15.MAR.2024 Ven Vairavan > Update Mule4 endpoints.
* @revision         12.MAR.2025 Vinothraja > Fixed test failures
*******************************************************************************/
@isTest(isParallel=true)
private class StudFirst_UpdateCaseSummaryPBC_Test {

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         24.Aug.2017        
    * @description  close and enquiry and set status to 'Closed to Callista'. check 
                        if an Summary Text file is generated
    * @revision     
    *******************************************************************************/
    static testMethod void test_updateCaseSummary() {
        // GIVEN
        // A Valid case record
        Case caseRec = [SELECT Id FROM Case WHERE SuppliedEmail = 'testformEmail@monash.edu' LIMIT 1];

        // WHEN
        Test.startTest();
        // Create an email message for the case
            EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.Id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testToAddress1123@monash.edu',
                                                CcAddress = 'testCCAddress1123@monash.edu',
                                                Incoming = true,
                                                Status = '0'); 
            insert emlMsg;
        Test.stopTest();

        // THEN
        // make sure summary is populated
        Assert.isNotNull([SELECT Summary__c FROM Case WHERE Id =: caseRec.Id LIMIT 1].Summary__c);
    }
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Aug.2017        
    * @description  creates full application sample data
    * @revision     
    *******************************************************************************/
    @TestSetup
    static void createSampleData () {
        //create a community user
        User communityUserRec;
        User u = [SELECT Id 
                        FROM User  
                        WHERE Profile.Name = 'System Administrator' 
                                AND IsActive = true 
                        LIMIT 1];
        System.runAs(u){
            communityUserRec = StudFirst_TestHelper.createCommunityUser();
        }
        Contact contactRec = [SELECT Id FROM Contact WHERE Id =: communityUserRec.ContactId];
        contactRec.Residency_Status__c = 'DOM-AUS';
        update contactRec;

        //create a new draft application
        Application__c appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
        appRecord.OwnerId = communityUserRec.Id;
        appRecord.Status__c = 'Submitted';
        insert appRecord;

        //Tertiary institution & qualification
        Institution__c tertInsRec = StudFirst_TestHelper.createTertiaryInstitution();
        insert tertInsRec;

        Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
        insert outcomeStatus;

        Contact_Qualification__c conQualRec = new Contact_Qualification__c();
        conQualRec.Country__c = 'Australia';
        conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year()-4);
        conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
        conQualRec.Other_Qualification__c = 'Certificate III';
        conQualRec.Institution_Code__c = tertInsRec.Institution_Code__c;
        conQualRec.Institution_Name__c = tertInsRec.Institution_Name__c;
        conQualRec.Status__c = 'CURRENTLY STUDYING';
        conQualRec.Contact__c = contactRec.Id;
        conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert conQualRec;

        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appRecord.Id;
        aqpRecord.Contact_Qualification__c = conQualRec.Id;
        insert aqpRecord;

        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = contactRec.Id;
        insert workExpRecord;

        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        insert contactDocu;

        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appRecord.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord;

        Course__c courseRec = StudFirst_TestHelper.createCourse();
        insert courseRec;

        Course_Offering__c courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
        insert courseOfferingRec;

        Course_Offering__c courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;


        Application_Course_Preference__c coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
        coursePrefA.Outcome_Status__c = 'TEST-STATUS';
        coursePrefA.Offer_Response_Status__c = 'TEST-STATUS';
        coursePrefA.Preference_Number__c = '1';
        insert coursePrefA;


        IntegrationSettings_SubmitApplication__c is = new IntegrationSettings_SubmitApplication__c();
        is.Base_Url__c = 'https://mix-dev.monash.edu';
        is.Path__c = '/la/admissions/v1/applications';
        is.Method__c = 'POST';
        is.Header_ClientId__c = 'c8411f0ca73a4ae6a0c7081a1336630f';
        is.Header_ClientSecret__c = 'cd2d5b9e26fa4999A33FF6A7F12D65AD';
        is.Header_ContentType__c = 'application/json';
        is.Mock_Endpoint_Applications__c = 'http://monash.getsandbox.com/la/admissions/v1/applications';
        is.Enable_Mock__c = false;
        is.Timeout__c = '12000';

        insert is;

        // Create a ADMISSIONS case
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                ContactId = contactRec.Id,
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Application_Course_Preference__c = coursePrefA.Id );
        insert caseRec;
    }
}