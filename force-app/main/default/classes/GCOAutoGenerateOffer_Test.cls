/**
 * @author      Shalini Mendu
 * @description Test Class for GCOAutoGenerateOffer.cls
 * @revision    02/11/2024 - Created
 */
@isTest//Test.getStandardPricebookId() cannot be called from parallel Apex tests
private class  GCOAutoGenerateOffer_Test {


    @testSetup
    static void setup() {
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('User');
        TriggerCommon.disableTrigger('Application__c');
        TriggerCommon.disableTrigger('Application_Course_Preference__c');
       
        Test.loadData(OrgUnitBundleMapping__c.sObjectType, 'OrgUnitBundleMappingDataTest');
        Contact testContact = StudFirst_TestHelper.createApplicant();
        insert testContact;
         //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        insert testApplication;
        
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
        insert testOffering;

         //Create  ACP
        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Academic_CI_Sequence_Number__c = 1;
        acp.Academic_Calendar_Type__c = '';
        acp.Admission_CI_Sequence_Number__c = 1;
        acp.Admission_Calendar_Type__c = '';
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
        insert acp;
         

        //Submit the application
        testApplication.Status__c = 'Submitted';
        update testApplication;
        
         //Create standardPricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

        Pricebook2 pricebook = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(), true);
        //add product bundles
        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        insert bundles;

        //Add configuration attribute to the bundle.
        SBQQ__ConfigurationAttribute__c configAttribute = (SBQQ__ConfigurationAttribute__c)TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Application_Course_Preference__c',SBQQ__TargetField__c='Application_Course_Preference__c', SBQQ__Product__c=bundles[0].Id),true);
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pricebook.Id), true);

        //Product Feature Creation
        SBQQ__ProductFeature__c pf = (SBQQ__ProductFeature__c)TestDataFactory.createSObject(new SBQQ__ProductFeature__c(SBQQ__ConfiguredSKU__c=bundles[0].Id,SBQQ__Number__c=1),true);
    
        TriggerCommon.enableTrigger('Application__c');
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('User');
    }

     /**
    * @description Tests Opportunity creation
    */
    @isTest 
    static void test_GCOOpportunityCreation()
    {
        //GIVEN - All the CPQ related data is set up correctly
        Pricebook2 pb = [SELECT ID FROM Pricebook2 WHERE External_ID__c = 'AU_INT'];
        Course__c course = [SELECT ID, Name, Course_Code__c, Version__c FROM Course__c WHERE Name = 'MARK1234' LIMIT 1];
      
        Course_Fee__c fee = (Course_Fee__c)TestDataFactory.createSObject(new Course_Fee__c(Course__c = course.Id, pricebook__c = pb.Id), true);
        Product2[] products = [SELECT Id, External_ID__c FROM Product2 WHERE Course__c = :course.Id];
        List<PricebookEntry> pbelist = [SELECT Id, UnitPrice,IsActive , Product2.External_Id__c , PriceBook2Id  FROM PricebookEntry WHERE Pricebook2.isStandard = false ];
        
        Product2 pr = [select Course_Code__c,External_Id__c from Product2 where External_Id__c like 'Mark%' ];
        pr.External_Id__c = 'MARK1234';
        update pr;
        
        Test.startTest();
            //WHEN - GCOAutoGenerateOffer.sendApplication is invoked with the eligible ACP
            Application_Course_Preference__c acp = [select id,Course_Product_Id__c,name,Application__r.Agent__c,Application__r.Id,Application__c, Applicant__c,Course_Start_Date_Updated__c,Course_Code__c,Course_Offering__c,Offer_Response_Date__c,Revised_End_Date__c,Agreed_Start_Date__c, Course_Title__c, Outcome_Status_LOV__r.System_Code__c from Application_Course_Preference__c];
            GCOAutoGenerateOffer.sendApplication(new List<String>{acp.Id});
        Test.stopTest();
        //THEN - An opportunity is created with Offer type assigned as COND-OFFER
        Assert.areEqual ('COND-OFFER', [SELECT offer_type__C from opportunity].offer_type__c);

    }

}