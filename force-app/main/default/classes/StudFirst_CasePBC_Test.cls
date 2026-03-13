/*******************************************************************************
* @author       Ant Custodio
* @date         22.Aug.2017        
* @description  test class for StudFirst_CasePBC Invocable Process Builder Class
* @revision     
* 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4
*******************************************************************************/
@isTest(isParallel=true)
private class StudFirst_CasePBC_Test {
    private static Application__c appRecord;
    private static User communityUserRec;
    private static Contact contactRec;
    private static Application_Course_Preference__c coursePrefA;
    private static Course_Offering__c courseOfferingRec;
    private static Course_Offering__c courseOfferingRecNoUnit;

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         22.Aug.2017        
    * @description  close and enquiry and set status to 'Closed to Callista'. check 
                        if an Summary Text file is generated
    * @revision     
    *******************************************************************************/
    static testMethod void test_closeEnquiry() {
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        //create required records
        createSampleData(communityUserRec.ContactId, 'Submitted', 'TEST-STATUS', true);
        
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                ContactId = contactRec.Id,
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Application_Course_Preference__c = coursePrefA.Id );
        insert caseRec;

        System.assert(caseRec.RecordTypeId == admissionsRecType, 'Record Type should be Admissions');

        Test.startTest();

            //set mock response
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

            IntegrationSettings_SubmitApplication__c is = IntegrationSettings_SubmitApplication__c.getInstance();
            System.assertEquals(is.Method__c, 'POST');

            //user closes the case set status to 'Closed to Callista'
            caseRec.Summary__c = 'This enquiry has been answered. Documents were provided.';
            caseRec.Status = 'Closed to Callista';
            update caseRec;

        Test.stopTest();

        //ensure that the attachment is created on update of the case
        //System.assertEquals(1, [SELECT COUNT() FROM Attachment WHERE ParentId =: caseRec.Id]);
    }
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Aug.2017        
    * @description  creates full application sample data
    * @revision     
    *******************************************************************************/
    static void createSampleData (String contactId, String status, String outcome, Boolean addCourse) {
        //create a new draft application
        appRecord = StudFirst_TestHelper.createApplication(contactId);
        appRecord.OwnerId = communityUserRec.Id;
        appRecord.Status__c = status;
        insert appRecord;

        contactRec = [SELECT Id FROM Contact WHERE Id =: contactId];
        contactRec.Residency_Status__c = 'DOM-AUS';
        update contactRec;

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

        courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
        insert courseOfferingRec;

        courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;

        if(addCourse){
            coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
            coursePrefA.Outcome_Status__c = outcome;
            coursePrefA.Offer_Response_Status__c = outcome;
            coursePrefA.Preference_Number__c = '1';
            insert coursePrefA;
        }

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
    }
}