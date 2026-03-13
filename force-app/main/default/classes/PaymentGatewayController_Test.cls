/**
 * @description Test class for PaymentGatewayController class
 * @author Suman Gunaganti
 * @date 16/12/2019     
 * @group Admissions
 * @revision
 *  07/11/2023  Nick Guia   - bulkified test setup
 *                          - removed repetitive queries on test_Payments
 * NG - NOTE:
 * this test class needs to be revisited !!
 *  - do not combine multiple test scopes in a single test method
 *  - create specific test setup data per scenario (or mock) rather than re-updating within the test method
 *  - OR mute the trigger when updating the test setup data
 *  - move asserts after stopTest();
 */
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User
private class PaymentGatewayController_Test { 

    @TestSetup 
    static void setUpData() {

        // create contacts
        List<Contact> contactList = new List<Contact>();

        Contact con = new Contact();
        con.Person_Id_unique__c = 'IdAA';
        con.LastName = 'LastnameAA';
        con.FirstName = 'FirstnameAA';
        con.Previous_Monash_ID__c = '1000234567';
        contactList.add(con);

        //Scenario 2 for Domestic Applicant
        //create Contact 2
        Contact con2 = new Contact();
        con2.Person_Id_unique__c = 'IdAB2';
        con2.LastName = 'LastnameAB2';
        contactList.add(con2);

        insert contactList;

        // create Applications
        List<Application__c> appList = new List<Application__c>();

        Application__c application = new Application__c();
        application.Applicant__c = con.Id;
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
        application.Status__c = 'Submitted';
        application.From_Portal__c  = true;
        application.Fee_Amount__c = 100;
        application.Fee_Waiver_Code__c   = 'somecode';
        application.Fee_Payment__c = false;
        application.Residency_Status__c = 'INTRNTNL';
        appList.add(application);

        // create Application 2
        Application__c application2 = new Application__c();
        application2.Applicant__c = con2.Id;
        application2.Campus_Location__c = null;
        application2.Status__c = 'Submitted';
        application2.From_Portal__c  = true;
        application2.Fee_Amount__c = 0;
        application2.Fee_Payment__c = false;
        application2.Residency_Status__c = 'DOM-AUS';
        appList.add(application2);

        //create Application 3
        Application__c application3 = new Application__c();
        application3.Callista_Application_Id__c = 'TESTCASE001'; // to query specific test setup data
        application3.Applicant__c = con.Id;
        application3.Passport_Number__c = 'A1234567';
        application3.Campus_Location__c = 'Australia';
        application3.Status__c = 'Submitted';
        application3.From_Portal__c  = true; 
        application3.Fee_Amount__c = 100;
        application3.Fee_Waiver_Code__c   = 'somecode';
        application3.Fee_Payment__c = false;
        application3.Source_System__c = 'AgentPortal';
        application3.Fee_Payment_Mode__c = 'Western Union';
        appList.add(application3);

        insert appList;

        // create Qualifications
        List<Qualification__c> qualificationList = new List<Qualification__c>();

        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        qual1.Callista_Code__c = '1231';
        qualificationList.add(qual1);

        Qualification__c qual2 = StudFirst_TestHelper.createQualification('Tertiary');
        qual2.Callista_Code__c = '1232';
        qualificationList.add(qual2);

        Qualification__c qual3 = StudFirst_TestHelper.createQualification('Other');
        qual3.Callista_Code__c = '1233';
        qualificationList.add(qual3);

        Qualification__c qual4 = StudFirst_TestHelper.createQualification('English');
        qual4.Callista_Code__c = '1234';
        qualificationList.add(qual4);

        insert qualificationList;

        // Create Contact Qualifications
        List<Contact_Qualification__c> cqList = new List<Contact_Qualification__c>();

        Contact_Qualification__c contactQualification1 = StudFirst_TestHelper.createContactQualification(con, qual1, 'Secondary Education');
        cqList.add(contactQualification1);

        Contact_Qualification__c contactQualification2 = StudFirst_TestHelper.createContactQualification(con, qual2, 'Tertiary Education');
        cqList.add(contactQualification2);

        Contact_Qualification__c contactQualification3 = StudFirst_TestHelper.createContactQualification(con, qual3, 'Other Qualification');
        cqList.add(contactQualification3);

        Contact_Qualification__c contactQualification4 = StudFirst_TestHelper.createContactQualification(con, qual4, 'English Test');
        cqList.add(contactQualification4);

        insert cqList;

        // Create Work Experience
        Work_Experience__c workExperience = StudFirst_TestHelper.createWorkExperience(con);
        insert workExperience;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        // Create Course Preferences
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(application, con, courseOffering, course);
        coursePreference.Course_Code__c = 'M00001';
        coursePreference.Preference_Number__c = '1';
        insert coursePreference;

        Western_Union_Config__c wc = new Western_Union_Config__c();
        wc.Base_Url__c = 'https://wupay.com';
        wc.Callback_Url__c = 'https://myapp.com';
        wc.ClientId__c ='somerandomcode';
        wc.ServiceId__c = '77853947269002';
        insert wc;

        MIX_API_Config__c mc = new MIX_API_Config__c();
        mc.Base_Url__c = 'https://mix.dev';
        mc.Client_Id__c = 'abcdef';
        mc.Client_Secret__c ='ghijkl';
        insert mc;
       
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;
        Integer rnd = Integer.valueOf(Math.random()*9999);
        //Contact con = [Select Person_Id_unique__c, LastName,FirstName from Contact];
        User applicant = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUserPayments',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                ContactId = con.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'DOM-AUS',
                App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                App_HasDisabilities__c = 'No',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert applicant;
        
        //applicant 2 - test user 2
        User applicant2 = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser2@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUserPayments2',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser2@mutesting.edu',
                ContactId = con2.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'DOM-AUS',
                App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                App_HasDisabilities__c = 'No',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert applicant2;
        
        /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
         * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant.Id);
            insert psa;
            PermissionSetAssignment psa2 = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant2.Id);
            insert psa2;
        }
    }

    /**
     * @description TODO: this test class needs to be revisited !!
     *  - do not combine multiple test scopes in a single test method
     *  - create specific test setup data per scenario (or mock) rather than re-updating within the test method
     */
    static testMethod void test_PaymentsRedeemCode() {

        // GIVEN
        List<User> u = [select Id from User where lastname ='TestingUserPayments' limit 1];
        Application__c appRec = [SELECT Id, Fee_Amount__c, Fee_Waiver_Code__c, OwnerId
                                From Application__c
                                WHERE Callista_Application_Id__c != 'TESTCASE001'
                                AND Residency_Status__c = 'INTRNTNL'
                                LIMIT 1];
        appRec.OwnerId =  u[0].Id;
        update appRec;

        String validateWaiverCodeResult;
        String waiverCodeAvailableResult;

        Test.startTest();

        // WHEN
        System.runAs(u[0]) {
            validateWaiverCodeResult = PaymentUtils.ValidateWaiverCode('123', appRec.Id, true);
            PaymentGatewayController.RedeemWaiverCode('somecode', appRec.Id);
            waiverCodeAvailableResult = PaymentGatewayController.WaiverCodeAvailiable('somecode', appRec.Id, false);
            PaymentUtils.updateCRMRedeemCode('somenewcode', appRec.Id);
            PaymentGatewayController.clearFeeWaiverCode(appRec.Id);
        }

        Test.stopTest();
        
        // THEN
        // requery application to get updates
        appRec = [SELECT Id, Fee_Amount__c, Fee_Waiver_Code__c, Fee_Waiver_Redeemed__c
                From Application__c
                WHERE Id = :appRec.Id
                LIMIT 1];
        Assert.areEqual('123', validateWaiverCodeResult, 'Unexpected waiver code');
        Assert.areEqual('123', waiverCodeAvailableResult, 'Unexpected waiver code');
        Assert.areEqual(null, appRec.Fee_Waiver_Code__c);
        Assert.areEqual('somenewcode', appRec.Fee_Waiver_Redeemed__c);
    }

    /**
     * @description TODO: this test class needs to be revisited !!
     *  - do not combine multiple test scopes in a single test method
     *  - create specific test setup data per scenario (or mock) rather than re-updating within the test method
     *  - OR mute the trigger when updating the test setup data
     *  - move asserts after stopTest();
     */
    static testMethod void test_Payments() {

        Application__c internationalApp;
        Application__c domesticApp;

        for(Application__c appRec : [SELECT Id, Fee_Amount__c, Fee_Waiver_Code__c, OwnerId, Residency_Status__c
                                    From Application__c
                                    WHERE Callista_Application_Id__c != 'TESTCASE001'
                                    AND Residency_Status__c IN ('INTRNTNL', 'DOM-AUS')])
        {
            if(appRec.Residency_Status__c == 'INTRNTNL') {
                internationalApp = appRec;
            } else if(appRec.Residency_Status__c == 'DOM-AUS') {
                domesticApp = appRec;
            }
        }

        List<User> u = [SELECT Id FROM User WHERE lastname ='TestingUserPayments' limit 1];
        internationalApp.OwnerId =  u[0].Id;
        update internationalApp;
        
        //User 2
        List<User> u2 = [SELECT Id FROM User WHERE lastname ='TestingUserPayments2' limit 1];
        domesticApp.OwnerId =  u2[0].Id;
        update domesticApp;

        Test.startTest();

        System.runAs(u[0]) {
            String url = paymentGatewayController.GetRequest(internationalApp.Id);
            System.assert(url.contains('https://wupay.com?'));
            System.assertEquals( 'somecode',PaymentGatewayController.GetWaiverCode(internationalApp.Id));
            System.assertEquals(1,PaymentGatewayController.GetCoursePreferences(internationalApp.Id).size());
            System.assertEquals(false, PaymentGatewayController.CoursePreferenceFee(internationalApp.Id));
            PaymentGatewayController.savePaymentType(internationalApp.Id, 'Western Union');
            PaymentGatewayController.getPaymentType(internationalApp.Id);
            System.assertEquals(false,  PaymentGatewayController.internationalStudent(internationalApp.Id));
       }
        
        internationalApp.Source_system__c = 'AgentPortal';
        update internationalApp;
        
        System.runAs(u2[0]) {
            System.assertEquals(0, PaymentGatewayController.GetFeeAmount(internationalApp.Id));
        }
        
        Test.stopTest();
    }

    /**
     * @description ensure that GetInitData() returns the expected data necessary
     * to initialise the component. I've decided to exclude the assertion of any 
     * wrapper class attributes whose value purely relies on the behaviour of another method
     * e.g. isInternationalStudent = internationalStudent(applicationId);
     */
    @isTest
    static void shouldGetInitData() {

        // GIVEN
        Application__c appRec = [SELECT Id, Fee_Waiver_Code__c, Source_System__c, Fee_Payment_Mode__c
                                FROM Application__c 
                                WHERE Callista_Application_Id__c = 'TESTCASE001' LIMIT 1];
        PaymentGatewayController.InitData initData;

        Test.startTest();

        // WHEN
        initData = PaymentGatewayController.getInitData(appRec.Id);

        Test.stopTest();

        // THEN
        Assert.areEqual(0, initData.feeAmount, 'Unexpected fee amount from an Agent Portal application');
        Assert.areEqual(appRec.Fee_Waiver_Code__c, initData.waiverCode, 'Unexpected waiver code');
        Assert.areEqual(appRec.Fee_Payment_Mode__c, initData.feePaymentMode, 'Unexpected fee payment mode');
        Assert.areEqual(appRec.Source_System__c, initData.sourceSystem, 'Unexpected source system');
        Assert.isNotNull(initData.paymentMaintenanceConfig, 'paymentMaintenanceConfig is not populated. Expecting Maintenance config');
    }

    /**
     * @description should throw an Exception when trying to invoke
     *  getInitData with a null Application Id
     */
    @isTest
    static void shouldThrowAnErrorOnInitDataWithNullApplicationId() {

        // GIVEN
        PaymentGatewayController.InitData initData;
        Id nullAppId;

        Test.startTest();

        // WHEN
        try {
            initData = PaymentGatewayController.getInitData(nullAppId);
            Assert.fail('Expecting to throw an error when given an invalid record Id');
        } catch(Exception e) {
            // THEN
            Assert.isTrue(true);
        }
        

        Test.stopTest();
    }

    /**
     * @description test that the method returns the expected custom label based
     * on the application's campus location
     */
    @isTest
    static void shouldGetProcessingFeeAmountLabelMUA() {

        // GIVEN
        Application__c appRec = new Application__c(Campus_Location__c = 'Australia');
        String feeLabel;

        Test.startTest();

        // WHEN
        feeLabel = PaymentGatewayController.getProcessingFeeAmountLabel(appRec);

        Test.stopTest();

        // THEN
        Assert.areEqual(Label.MY_APP_PROCESSING_FEE_MUA, feeLabel, 'Unexpected process fee amount label returned for this campus location');
    }

    /**
     * @description test that the method returns the expected custom label based
     * on the application's campus location
     */
    @isTest
    static void shouldGetProcessingFeeAmountLabelMUM() {

        // GIVEN
        Application__c appRec = new Application__c(Campus_Location__c = 'Malaysia');
        String feeLabel;

        Test.startTest();

        // WHEN
        feeLabel = PaymentGatewayController.getProcessingFeeAmountLabel(appRec);

        Test.stopTest();

        // THEN
        Assert.areEqual(Label.MY_APP_PROCESSING_FEE_MUM, feeLabel, 'Unexpected process fee amount label returned for this campus location');
    }
    
     /**
     * @description test that the method returns the expected custom label based
     * on the application's campus location
     */
    @isTest
    static void shouldGetProcessingFeeAmountLabelMUAForUpdatedFee() {

        //GIVEN: Feature switch to pick the updated Fee is configured along with other data
	    //for International application
        Feature_Switch__c fs = new Feature_Switch__c(Display_New_Application_Fee__c =true);
        insert fs;

        Application__c appRec = new Application__c(Campus_Location__c = 'Australia');
        String feeLabel;

        Test.startTest();

	    //WHEN: Fee label is retrieved 
        feeLabel = PaymentGatewayController.getProcessingFeeAmountLabel(appRec);

        Test.stopTest();

	    //THEN: The Fee label must reflect the updated Fee
        Assert.areEqual(Label.MY_APP_UPDATED_FEE_MUA, feeLabel, 'Unexpected process fee amount label returned for this campus location');
    }
}