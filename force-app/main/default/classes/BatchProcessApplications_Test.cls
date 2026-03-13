/*******************************************************************************
* @author       J.Mapanao
* @date         17.DEC.2019        
* @description  Test Class for BatchProcessApplications.cls
* @revision     17.DEC.2019 - J.Mapanao - Initial Created
*******************************************************************************/
@isTest(isParallel=true)
private class BatchProcessApplications_Test {
    static testMethod void test_ProcessApplicationsBatch_Sc1() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;
        
        // Create Test Case
        Case enquiry = StudFirst_TestHelper.createEnquiry();
        enquiry.Legacy_Enquiry_ID__c = 'legenq001';
        enquiry.ContactId = contact.Id;
        enquiry.Course__c = test_Course.Id;
        insert enquiry;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Application_Course_Preference__c test_ACP = StudFirst_TestHelper.createCoursePreferences(app, contact, test_Course_Offering, test_Course);
        test_ACP.Legacy_Application_ID__c = 'legenq001';
        test_ACP.Cancelled__c = true;
        test_ACP.Result__c = 'Fail';
        insert test_ACP;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Assert.isTrue([SELECT Id, Course_Result__c FROM Application_Course_Preference__c WHERE Id =: test_ACP.Id].Course_Result__c == 'Fail', 'ERROR: ACP Course Result not updated to Fail');
    }

    static testMethod void test_ProcessApplicationsBatch_Sc2() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;
        
        // Create Test Case
        Case enquiry = StudFirst_TestHelper.createEnquiry();
        enquiry.Legacy_Enquiry_ID__c = 'legenq001';
        enquiry.ContactId = contact.Id;
        enquiry.Course__c = test_Course.Id;
        insert enquiry;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Application_Course_Preference__c test_ACP = StudFirst_TestHelper.createCoursePreferences(app, contact, test_Course_Offering, test_Course);
        test_ACP.Legacy_Application_ID__c = 'legenq001';
        test_ACP.Cancelled__c = true;
        test_ACP.Result__c = 'Test';
        test_ACP.Certification_Completed__c = true;
        test_ACP.Certification_Completed_Without_Points__c = false;
        test_ACP.Attendance_Certificate__c = false;
        insert test_ACP;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Assert.isTrue([SELECT Id, Course_Result__c FROM Application_Course_Preference__c WHERE Id =: test_ACP.Id].Course_Result__c == 'Pass with credit points', 'ERROR: ACP Course Result not updated to Pass with credit points');
    }

    static testMethod void test_ProcessApplicationsBatch_Sc3() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;
        
        // Create Test Case
        Case enquiry = StudFirst_TestHelper.createEnquiry();
        enquiry.Legacy_Enquiry_ID__c = 'legenq001';
        enquiry.ContactId = contact.Id;
        enquiry.Course__c = test_Course.Id;
        insert enquiry;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Application_Course_Preference__c test_ACP = StudFirst_TestHelper.createCoursePreferences(app, contact, test_Course_Offering, test_Course);
        test_ACP.Legacy_Application_ID__c = 'legenq001';
        test_ACP.Cancelled__c = true;
        test_ACP.Result__c = 'Test';
        test_ACP.Certification_Completed__c = false;
        test_ACP.Certification_Completed_Without_Points__c = true;
        test_ACP.Attendance_Certificate__c = false;
        insert test_ACP;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Assert.isTrue([SELECT Id, Course_Result__c FROM Application_Course_Preference__c WHERE Id =: test_ACP.Id].Course_Result__c == 'Pass', 'ERROR: ACP Course Result not updated to Pass');
    }

    static testMethod void test_ProcessApplicationsBatch_Sc4() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;
        
        // Create Test Case
        Case enquiry = StudFirst_TestHelper.createEnquiry();
        enquiry.Legacy_Enquiry_ID__c = 'legenq001';
        enquiry.ContactId = contact.Id;
        enquiry.Course__c = test_Course.Id;
        insert enquiry;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Application_Course_Preference__c test_ACP = StudFirst_TestHelper.createCoursePreferences(app, contact, test_Course_Offering, test_Course);
        test_ACP.Legacy_Application_ID__c = 'legenq001';
        test_ACP.Cancelled__c = true;
        test_ACP.Result__c = 'Test';
        test_ACP.Certification_Completed__c = false;
        test_ACP.Certification_Completed_Without_Points__c = false;
        test_ACP.Attendance_Certificate__c = true;
        insert test_ACP;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Assert.isTrue([SELECT Id, Course_Result__c FROM Application_Course_Preference__c WHERE Id =: test_ACP.Id].Course_Result__c == 'Attended', 'ERROR: ACP Course Result not updated to Attended');
    }

    static testMethod void test_ProcessApplicationsBatch_Sc5() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        contact.Company__c = 'Test_Company';
        contact.OtherPostalCode = '3000';
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;
        
        // Create Test Case
        Case enquiry = StudFirst_TestHelper.createEnquiry();
        enquiry.Legacy_Enquiry_ID__c = 'legenq001';
        enquiry.ContactId = contact.Id;
        enquiry.Course__c = test_Course.Id;
        insert enquiry;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Application_Course_Preference__c test_ACP = StudFirst_TestHelper.createCoursePreferences(app, contact, test_Course_Offering, test_Course);
        test_ACP.Legacy_Application_ID__c = 'legenq001';
        test_ACP.Cancelled__c = true;
        test_ACP.Result__c = 'Test';
        test_ACP.Certification_Completed__c = false;
        test_ACP.Certification_Completed_Without_Points__c = false;
        test_ACP.Attendance_Certificate__c = true;
        insert test_ACP;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Notes__c, Postcode__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areNotEqual(res_Payment.Notes__c, null, 'ERROR: Payment Notes is blank');
        Assert.areNotEqual(res_Payment.Postcode__c, null, 'ERROR: Payment Postcode is blank');
    }

    static testMethod void test_ProcessApplicationsBatch_Sc6() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;
        
        // Create Test Case
        Case enquiry = StudFirst_TestHelper.createEnquiry();
        enquiry.Legacy_Enquiry_ID__c = 'legenq001';
        enquiry.ContactId = contact.Id;
        enquiry.Course__c = test_Course.Id;
        insert enquiry;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Application_Course_Preference__c test_ACP = StudFirst_TestHelper.createCoursePreferences(app, contact, test_Course_Offering, test_Course);
        test_ACP.Legacy_Application_ID__c = 'legenq001';
        test_ACP.Cancelled__c = true;
        test_ACP.Result__c = 'Test';
        test_ACP.Certification_Completed__c = false;
        test_ACP.Certification_Completed_Without_Points__c = false;
        test_ACP.Attendance_Certificate__c = true;
        insert test_ACP;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Notes__c, Postcode__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areNotEqual(res_Payment.Notes__c, null, 'ERROR: Payment Notes is blank');
        Assert.areNotEqual(res_Payment.Postcode__c, null, 'ERROR: Payment Postcode is blank');
    }

    /*
     *  Payment Type 1 and 2
     */
    static testMethod void test_ProcessApplicationsBatch_Sc7() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Payment_ID__c = '1';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment_1 = [SELECT Id, Payment_Type__c, Credit_Card_Type__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual(res_Payment_1.Payment_Type__c, 'Credit_Card', 'ERROR: Payment Type is not Credit_Card');
        Assert.areEqual(res_Payment_1.Credit_Card_Type__c, 'Visa', 'ERROR: Payment Credit Card Type is not Visa');

        test_Payment.Legacy_Payment_ID__c = '2';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
    }

    /*
     *  Payment Type 3 and 4
     */
    static testMethod void test_ProcessApplicationsBatch_Sc8() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Payment_ID__c = '3';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment_1 = [SELECT Id, Payment_Type__c, Credit_Card_Type__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('Credit_Card', res_Payment_1.Payment_Type__c, 'ERROR: Payment Type is not Credit_Card');
        Assert.areEqual(null, res_Payment_1.Credit_Card_Type__c, 'ERROR: Payment Credit Card Type is not blank');

        test_Payment.Legacy_Payment_ID__c = '4';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
    }

    /*
     *  Payment Type 5 and 6
     */
    static testMethod void test_ProcessApplicationsBatch_Sc9() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Payment_ID__c = '5';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment_1 = [SELECT Id, Payment_Type__c, Credit_Card_Type__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('Cheque', res_Payment_1.Payment_Type__c, 'ERROR: Payment Type is not Cheque');
        Assert.areEqual(null, res_Payment_1.Credit_Card_Type__c, 'ERROR: Payment Credit Card Type is not blank');

        test_Payment.Legacy_Payment_ID__c = '6';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
    }

    /*
     *  Payment Type 7 and 8
     */
    static testMethod void test_ProcessApplicationsBatch_Sc10() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Payment_ID__c = '7';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment_1 = [SELECT Id, Payment_Type__c, Credit_Card_Type__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('Money_Order', res_Payment_1.Payment_Type__c, 'ERROR: Payment Type is not Money_Order');
        Assert.areEqual(null, res_Payment_1.Credit_Card_Type__c, 'ERROR: Payment Credit Card Type is not blank');

        test_Payment.Legacy_Payment_ID__c = '8';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
    }

    /*
     *  Payment Type 9 and 10
     */
    static testMethod void test_ProcessApplicationsBatch_Sc11() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Payment_ID__c = '9';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment_1 = [SELECT Id, Payment_Type__c, Credit_Card_Type__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual(null, res_Payment_1.Payment_Type__c, 'ERROR: Payment Type is not blank');
        Assert.areEqual(null, res_Payment_1.Credit_Card_Type__c, 'ERROR: Payment Credit Card Type is not blank');

        test_Payment.Legacy_Payment_ID__c = '10';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
    }

    /*
     *  Payment Type 11 and 13
     */
    static testMethod void test_ProcessApplicationsBatch_Sc12() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Payment_ID__c = '11';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment_1 = [SELECT Id, Payment_Type__c, Credit_Card_Type__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('Credit_Card', res_Payment_1.Payment_Type__c, 'ERROR: Payment Type is not Credit_Card');
        Assert.areEqual('Diners Club', res_Payment_1.Credit_Card_Type__c, 'ERROR: Payment Credit Card Type is not Diners Club');

        test_Payment.Legacy_Payment_ID__c = '13';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
    }

    /*
     *  Payment Expiration Month Jan and Feb
     */
    static testMethod void test_ProcessApplicationsBatch_Sc14() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Credit_Card_Expiry__c = 'Jan-17';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('January', res_Payment.Credit_Card_Expiry_Month__c, 'ERROR: Payment Credit_Card_Expiry_Month__c is not Jan');

        test_Payment.Legacy_Credit_Card_Expiry__c = 'Feb-17';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
        //Assert.isTrue([SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id].Credit_Card_Expiry_Month__c == 'Feb', 'ERROR: Payment Credit_Card_Expiry_Month__c is not Feb');
    }

    /*
     *  Payment Expiration Month Mar and Apr
     */
    static testMethod void test_ProcessApplicationsBatch_Sc15() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Credit_Card_Expiry__c = 'Mar-17';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('March', res_Payment.Credit_Card_Expiry_Month__c, 'ERROR: Payment Credit_Card_Expiry_Month__c is not Mar');

        test_Payment.Legacy_Credit_Card_Expiry__c = 'Apr-17';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
        //Assert.isTrue([SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id].Credit_Card_Expiry_Month__c == 'Apr', 'ERROR: Payment Credit_Card_Expiry_Month__c is not Apr');
    }

    /*
     *  Payment Expiration Month May and Jun
     */
    static testMethod void test_ProcessApplicationsBatch_Sc16() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Credit_Card_Expiry__c = 'May-17';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('May', res_Payment.Credit_Card_Expiry_Month__c, 'ERROR: Payment Credit_Card_Expiry_Month__c is not May');

        test_Payment.Legacy_Credit_Card_Expiry__c = 'Jun-17';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
        //Assert.isTrue([SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id].Credit_Card_Expiry_Month__c == 'Jun', 'ERROR: Payment Credit_Card_Expiry_Month__c is not Jun');
    }

    /*
     *  Payment Expiration Month Jul and Aug
     */
    static testMethod void test_ProcessApplicationsBatch_Sc17() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Credit_Card_Expiry__c = 'Jul-17';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('July', res_Payment.Credit_Card_Expiry_Month__c, 'ERROR: Payment Credit_Card_Expiry_Month__c is not Jul');

        test_Payment.Legacy_Credit_Card_Expiry__c = 'Aug-17';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
        //Assert.isTrue([SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id].Credit_Card_Expiry_Month__c == 'Aug', 'ERROR: Payment Credit_Card_Expiry_Month__c is not Aug');
    }

    /*
     *  Payment Expiration Month Sep and Oct
     */
    static testMethod void test_ProcessApplicationsBatch_Sc18() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Credit_Card_Expiry__c = 'Sep-17';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('September', res_Payment.Credit_Card_Expiry_Month__c, 'ERROR: Payment Credit_Card_Expiry_Month__c is not Sep');

        test_Payment.Legacy_Credit_Card_Expiry__c = 'Oct-17';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
    }

    /*
     *  Payment Expiration Month Nov and Dec
     */
    static testMethod void test_ProcessApplicationsBatch_Sc19() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Credit_Card_Expiry__c = 'Nov-17';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Credit_Card_Expiry_Month__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual('November', res_Payment.Credit_Card_Expiry_Month__c, 'ERROR: Payment Credit_Card_Expiry_Month__c is not Nov');

        test_Payment.Legacy_Credit_Card_Expiry__c = 'Dec-17';
        update test_Payment;
        String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
        Database.executeBatch(new BatchProcessApplications(query),200);
    }

    /*
     *  Payment Expiration Month Nov and Dec
     */
    static testMethod void test_ProcessApplicationsBatch_Sc20() {
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;

        // Create Course
        Course__c test_Course = StudFirst_TestHelper.createCourse();
        insert test_Course;

        // Create Course Offering
        Course_Offering__c test_Course_Offering = StudFirst_TestHelper.createCourseOffering(test_Course);
        test_Course_Offering.Legacy_Course_Offering_ID__c = 'legenq001';
        insert test_Course_Offering;

        // Create Test Application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(contact);
        app.Legacy_Enquiry_ID__c = 'legenq001';
        app.Legacy_Application_ID__c = 'legenq001';
        app.Legacy_Course_Offering_ID__c = 'legenq001';
        app.Legacy_Submitted_Date__c = '01/25/1992';
        insert app;

        Payment__c test_Payment = StudFirst_TestHelper.createPayment(test_Course_Offering, contact, app);
        test_Payment.Legacy_Application_ID__c = 'legenq001';
        test_Payment.Date_receipt_sent__c = Datetime.now();
        test_Payment.Legacy_Credit_Card_Expiry__c = 'Nov-Nov';
        insert test_Payment;

        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {
            String query = 'SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c';
            Database.executeBatch(new BatchProcessApplications(query),200);
        }        
        Test.stopTest();
        Payment__c res_Payment = [SELECT Id, Credit_Card_Expiry_Year__c FROM Payment__c WHERE Id =: test_Payment.Id];
        Assert.areEqual(null, res_Payment.Credit_Card_Expiry_Year__c, 'ERROR: Payment Credit_Card_Expiry_Year__c is not blank');
    }


    private static User createTestUser() {
        // Setup test data
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'pdtstusr', Email='pdtestuser@pdorg.com', 
        EmailEncodingKey='UTF-8', LastName='pdtestuser', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@mailinator.com.pd');

        System.runAs(adminUser) {
            Nebula.Logger.info('Running as Admin User');
            insert u;
        }

        return u;      
    }
}