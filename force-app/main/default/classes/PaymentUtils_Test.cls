/*******************************************************************************
* @author       Trent
* @description  test coverage for payment utils

* @change History:
* @revision 	Ken McGuire - handle mononymous name
*******************************************************************************/
@isTest
private class PaymentUtils_Test {

    @testSetup static void setUpData() {
        Contact con = new Contact();
        con.Person_Id_unique__c = 'IdAA';
        con.LastName = 'LastnameAA';
        con.FirstName = 'FirstnameAA';
        con.Previous_Monash_ID__c = '1000234567';
        insert con;

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
        application.Fee_Waiver_Code__c	 = 'somecode';
        application.Fee_Payment__c = false;
        application.Residency_Status__c = 'INTRNTNL';
        insert application;

        //Scenario 2 for Domestic Applicant
        //create Contact 2
        Contact con2 = new Contact();
        con2.Person_Id_unique__c = 'IdAB2';
        con2.LastName = 'LastnameAB2';
        insert con2;
        
        //create Application 2
        Application__c application2 = new Application__c();
        application2.Applicant__c = con2.Id;
        application2.Campus_Location__c = null;
        application2.Status__c = 'Submitted';
        application2.From_Portal__c  = true;
        application2.Fee_Amount__c = 0;
        application2.Fee_Payment__c = false;
        application2.Residency_Status__c = 'DOM-AUS';
        insert application2;
        
                
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        Qualification__c qual2 = StudFirst_TestHelper.createQualification('Tertiary');
        insert qual2;

        Qualification__c qual3 = StudFirst_TestHelper.createQualification('Other');
        insert qual3;

        Qualification__c qual4 = StudFirst_TestHelper.createQualification('English');
        insert qual4;


        // Create Contact Qualifications
        Contact_Qualification__c contactQualification1 = StudFirst_TestHelper.createContactQualification(con, qual1, 'Secondary Education');
        insert contactQualification1;

        Contact_Qualification__c contactQualification2 = StudFirst_TestHelper.createContactQualification(con, qual2, 'Tertiary Education');
        insert contactQualification2;

        Contact_Qualification__c contactQualification3 = StudFirst_TestHelper.createContactQualification(con, qual3, 'Other Qualification');
        insert contactQualification3;

        Contact_Qualification__c contactQualification4 = StudFirst_TestHelper.createContactQualification(con, qual4, 'English Test');
        insert contactQualification4;

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
        wc.ServiceId__c = '76532345336343';
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
    @IsTest
    static void test_Payments() {
        List<User> u = [select Id from User where lastname ='TestingUserPayments' limit 1];
        Application__c app1 = [Select a.Id From Application__c a limit 1];
        app1.OwnerId =  u[0].Id;
        update app1;
            
        Test.startTest();

        System.runAs(u[0]) {
            Application__c app = [Select a.Id, a.Fee_Amount__c, a.Fee_Waiver_Code__c, a.Fee_Waiver_Redeemed__c From Application__c a];
            String url = PaymentGatewayController.GetRequest([Select Id from Application__c].Id);
            Assert.isTrue(url.contains('https://wupay.com?'));
            Assert.areEqual('somecode',PaymentGatewayController.GetWaiverCode(app.Id));
            Assert.isNotNull(PaymentGatewayController.GetCoursePreferences(app.Id));
            Assert.areEqual(false, PaymentGatewayController.CoursePreferenceFee(app.Id));
            Assert.areEqual( '123', PaymentUtils.ValidateWaiverCode('123', app.Id, true));
            Assert.areEqual( '123',PaymentUtils.RedeemWaiverCode('123', app.Id, 4444, 555));
            PaymentGatewayController.clearFeeWaiverCode(app.Id);
            Assert.areEqual('somecode', app.Fee_Waiver_Code__c);
            PaymentGatewayController.savePaymentType(app.Id, 'Western Union');
            //System.assertEquals(100, PaymentGatewayController.GetFeeAmount([Select Id from Application__c WHERE Residency_Status__c = 'INTRNTNL'].Id));   
            PaymentGatewayController.getPaymentType(app.Id);
            Assert.areEqual(false,  PaymentGatewayController.internationalStudent(app.Id));
            PaymentGatewayController.RedeemWaiverCode('somecode', app.Id);
            Assert.areEqual('123', PaymentGatewayController.WaiverCodeAvailiable('somecode', app.Id, false));
            PaymentUtils.updateCRMRedeemCode('somenewcode', app.Id);
            System.assertEquals(null, app.Fee_Waiver_Redeemed__c);
        }
        Test.stopTest();
    }
    @IsTest
    static void test_Payments2() {
       
		//User 2
		List<User> u2 = [select Id from User where lastname ='TestingUserPayments2' limit 1];
        Application__c app2 = [Select a2.Id From Application__c a2 limit 1];
        app2.OwnerId =  u2[0].Id;
        update app2;     

        Test.startTest();
        System.runAs(u2[0]) {
            Application__c app3 = [Select Id from Application__c WHERE Residency_Status__c = 'DOM-AUS' LIMIT 1];
            Assert.areEqual(0, PaymentGatewayController.GetFeeAmount(app3.Id));
        }
        Test.stopTest();
    }
    @IsTest
    public static void test_redeemCodeAvailable(){
        Assert.areEqual(true, PaymentUtils.redeemCodeAvailable('somecode'), 'Unable to find valid waiver code');
    }
    
    @IsTest
    public static void testMononymous() {
        // Given
        String buyerId ='';
        String name='Test'; 
        String email='test@test.com';
        String amount= '100';
        String phone='12345';
        String country ='Australia';
        // When
        PaymentUtils.WURequest testRequest = new PaymentUtils.WURequest(buyerId,name,email,amount, phone,country);
        // Then
        Assert.areEqual(name, testRequest.firstName,'Mononymous First Name should contain Full Name');
       	Assert.areEqual(name, testRequest.lastName,'Mononymous Last Name should contain Full Name');
    }
    @IsTest
    public static void testAdmissionsUnderMaintenance() {
        // Given
        // When
        Admissions_Settings__mdt admissionMaintenanceConfig= PaymentUtils.admissionsMaintenanceMDT;
        String admissionMaintenanceStatus= PaymentUtils.CALLISTA_META_STATUS;
        // Then
        // Callista Under Maintenance config exists
        Assert.areEqual(admissionMaintenanceConfig.DeveloperName,'CallistaFeeWaiverNotAvailable','Admissions Maintenance Config does not exists');
        Assert.areEqual(admissionMaintenanceStatus,'Under Maintenance', 'Admissions Maintenance status is not Under Maintenance');
    }
}