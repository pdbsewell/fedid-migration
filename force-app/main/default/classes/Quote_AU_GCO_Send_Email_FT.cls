/**
* @author Shalini Mendu
* @date 29/10/2024
* @group Test Class for Quote_AU_GCO_Send_Email flow
* @description  Test Class to test the functionality of Quote_AU_GCO_Send_Email Flow
* @history    Initial Creation
*
**/
@isTest// Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class Quote_AU_GCO_Send_Email_FT {
   /**
     * @description Setup test data
     */
   
     @testSetup static void setup() {
          
        Test.loadData(OrgUnitBundleMapping__c.sObjectType, 'OrgUnitBundleMappingDataTest');
        Contact testContact = StudFirst_TestHelper.createApplicant();
 		testContact.Person_ID_unique__c = '12345678';
        insert testContact;
         //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        insert testApplication;
        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        //Create LOV
        List<List_of_Values__c> lovList = new List<List_of_Values__c>{
        new List_of_Values__c(
            Unique_Key__c = 'OFFER-G-CO',
            Value__c = 'SATISFIED',
            System_Code__c = 'COND-OFFER'
            
        )};
        upsert lovList;
        List<List_of_Values__c> lovListret = [select System_Code__c from List_of_Values__c limit 1];
           
        //Create Course__c
        Course__c markc = new Course__c();
        markc.Name = 'MARK1234';
        markc.Abbreviation__c = 'MARK';
        markc.Course_Code__c = 'MARK1234';
        markc.Course_Description__c = 'Bachelor of Marketing';
        markc.Title__c = 'Bachelor of Marketing';
        markc.Short_Title__c = 'Bachelor of Marketing';
        markc.Type__c ='Course-All';
        markc.Version__c = '1';
        markc.Status__c = 'Active';
        markc.Specialisation_Code__c = 'MARK1234';
        markc.Duration_FT__c = 1.5;
        markc.Faculty_Code__c = '50000563';
        insert markc;
       
        //Create Course_Offering__c
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(markc);
        testOffering.Mix_Unique_Id__c = '1234567';
        testOffering.Course_Version_Number__c  = 1;
        testOffering.Override_Reviewed__c = true;
        insert testOffering;

         //Create  ACP
        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Academic_CI_Sequence_Number__c = 1;
        acp.Academic_Calendar_Type__c = '';
        acp.Admission_CI_Sequence_Number__c = 1;
        acp.Admission_Calendar_Type__c = '';
        acp.Admission_Category__c = 'UG-IS';
        acp.Applicant__c = testContact.Id;
        acp.Application__c = testApplication.Id;
        acp.Attendance_Mode__c = '';
        acp.Attendance_Type__c = 'FT';
        acp.Commencement_Period__c = '';
        acp.Course_Offering__c = testOffering.Id;
        acp.Course_Title__c = 'Master Of Nothing';
        acp.Course_Version_Number__c = 1;
        acp.Location_Code__c = '';
        acp.Outcome_Status__c = '';
        acp.Preference_Number__c = '';
        acp.Status__c = '';
        acp.Attendance_Mode_Description__c = 'On Campus';
        acp.Attendance_Type_Description__c = 'FULL TIME';
        acp.Location_Code__c = 'CLAYTON';
        acp.Type_of_Place_Description__c = 'Test type of place';
        acp.Preference_Number__c = '1';
        acp.Agreed_Start_Date__c = Date.today();
        acp.Revised_End_Date__c = Date.today().addMonths(12);
        acp.Outcome_Status_LOV__c = lovListret[0].id;
        acp.Offer_Response_Date__c = Date.today().addMonths(1);
        acp.Course__c =  markc.Id;
        acp.Course_Code__c =  markc.Course_Code__c;
        acp.Course_Version_Number__c =1;
        acp.Course_Code_Unique__c = markc.Course_Code__c;
        acp.Intake_Period__c = '2025/1';
        acp.Conditional_Automation__c = 'Generic';

        insert acp;
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc.Id,Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(Application_Course_Preference__c=acp.Id, SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c = Test.getStandardPricebookId(), SBQQ__Status__c='Created',Sub_Status__c='In Progress',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c = opp.CloseDate, SBQQ__Primary__c = true),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id), true);       

    }

    /**
    * @description Tests quote has processed successfully and email sent
    */
    @isTest 
    static void test_QuoteProcess()
    {
       
        // GIVEN - All CPQ data has been set up 
        QuoteTriggerHandler.lockUserCreation = true;
        
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, SBQQ__Opportunity2__c,
                                   Sub_Status__c, SBQQ__PrimaryContact__c,Template_Type__c
                                   FROM SBQQ__Quote__c];
        
        SBQQ__Quote__c oldQuote = quotes[0];
        
        oldQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_IN_REVIEW;
        oldQuote.Sub_Status__c = Constants.QUOTE_SUBSTATUS_QAPREVIEW;

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestDocument(true, 'pdf'));

        ContentDocumentLink cdLink = new ContentDocumentLink();
        cdLink.LinkedEntityId = oldQuote.Id;
        cdLink.ContentDocumentId = documentList[0].Id;
        cdLink.ShareType = 'V';
        cdLink.Visibility = 'AllUsers';

        insert cdLink;
        // WHEN- QUOTE Sub_Status__c  has been updated to Constants.QUOTE_SUBSTATUS_QAPREVIEW
        Test.startTest();
            update oldQuote;
        Test.stopTest();
        // THEN - It triggers the flow and the action verifies the appropriate output
        Assert.areEqual (Constants.QUOTE_SUBSTATUS_QAPREVIEW, oldQuote.Sub_Status__c );


   }

    //Creating test content document
    static ContentDocument createTestDocument(Boolean allAccess, String fileExtension) 
    {
        // create a file
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
            Title='Header_Picture1',
            PathOnClient ='/Header_Picture1.' + fileExtension,
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
        
        if(allAccess) {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = UserInfo.getOrganizationId();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'C';
            cdLink.Visibility = 'AllUsers';
        
            insert cdLink;
        }
    
        return file;
    }
}