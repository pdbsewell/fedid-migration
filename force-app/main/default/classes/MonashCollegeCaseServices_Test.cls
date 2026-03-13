/**
 * @author          Kristian Vegerano
 * @description     Test class for MonashCollegeCaseServices class
 * @group           Test Class
 * @revision        SEPT.12.2019 - Kristian Vegerano - Created
 */
@IsTest(isParallel=true)
private class MonashCollegeCaseServices_Test {

    /**
     * @author          Kristian Vegerano
     * @description     Tests MonashCollegeCaseServices.associateContactToMonashCollegeEnquiries with the enquiry having its SuppliedName not populated
     * @revision        SEPT.12.2019 KVegerano  - Created
     */
    @isTest 
    static void testAssociateContactToMonashCollegeEnquiriesWithoutSuppliedName() {
        //Initialize test records
        Id professionalYearRecordTypeId = MonashCollegeCaseServices.PROFESSIONALYEAR_RECTYPEID;

        //Start Test
        Test.startTest();

        Case testMonashCollegeEnquiry = new Case();
        testMonashCollegeEnquiry.ContactId = null;
        testMonashCollegeEnquiry.RecordTypeId = professionalYearRecordTypeId;
        testMonashCollegeEnquiry.SuppliedEmail = 'testsuppliedemail@testsuppliedemail.com';
        insert testMonashCollegeEnquiry;

        //End Test
        Test.stopTest();

        //Evaluate results - ensure that the enquiry did not get its contact field automatically populated
        Case resultEnquiry = [SELECT Id, ContactId FROM Case WHERE Id = :testMonashCollegeEnquiry.Id];
        System.assertEquals(resultEnquiry.ContactId, null);
    }

    /**
     * @author          Kristian Vegerano
     * @description     Tests MonashCollegeCaseServices.associateContactToMonashCollegeEnquiries with the enquiry having its SuppliedName populated
     * @revision        SEPT.12.2019 KVegerano  - Created
     */
    @isTest 
    static void testAssociateContactToMonashCollegeEnquiriesWithSuppliedName() {
        //Initialize test records
        Id professionalYearRecordTypeId = MonashCollegeCaseServices.PROFESSIONALYEAR_RECTYPEID;

        //Start Test
        Test.startTest();

        Case testMonashCollegeEnquiry = new Case();
        testMonashCollegeEnquiry.ContactId = null;
        testMonashCollegeEnquiry.RecordTypeId = professionalYearRecordTypeId;
        testMonashCollegeEnquiry.SuppliedEmail = 'testsuppliedemail@testsuppliedemail.com';
        testMonashCollegeEnquiry.SuppliedName = 'FirstName MiddleName LastName';
        insert testMonashCollegeEnquiry;

        //End Test
        Test.stopTest();

        //Evaluate results - ensure that the enquiry got its contact field automatically populated
        Case resultEnquiry = [SELECT Id, ContactId FROM Case WHERE Id = :testMonashCollegeEnquiry.Id];
        System.assertNotEquals(resultEnquiry.ContactId, null);
    }

    /**
     * @author          Kristian Vegerano
     * @description     Tests MonashCollegeCaseServices.associateContactToMonashCollegeEnquiries with the enquiry having its SuppliedName populated and the value on supplied name reaching the contact's name fields character limit
     * @revision        SEPT.12.2019 KVegerano  - Created
     */
    @isTest 
    static void testAssociateContactToMonashCollegeEnquiriesWithLongSuppliedName() {
        //Initialize test records
        Id professionalYearRecordTypeId = MonashCollegeCaseServices.PROFESSIONALYEAR_RECTYPEID;

        //Start Test
        Test.startTest();

        Case testMonashCollegeEnquiry = new Case();
        testMonashCollegeEnquiry.ContactId = null;
        testMonashCollegeEnquiry.RecordTypeId = professionalYearRecordTypeId;
        testMonashCollegeEnquiry.SuppliedEmail = 'testsuppliedemail@testsuppliedemail.com';
        testMonashCollegeEnquiry.SuppliedName = 'FirstName SecondName ThirdName FourtName FifthName SixthName LastName';
        insert testMonashCollegeEnquiry;

        //End Test
        Test.stopTest();

        //Evaluate results - ensure that the enquiry got its contact field automatically populated
        Case resultEnquiry = [SELECT Id, ContactId FROM Case WHERE Id = :testMonashCollegeEnquiry.Id];
        System.assertNotEquals(resultEnquiry.ContactId, null);
    }

    /**
     * @author          Kristian Vegerano
     * @description     Tests MonashCollegeCaseServices.defaultMonashCollegeEnquiryType
     * @revision        SEPT.12.2019 KVegerano  - Created
     */
    @isTest 
    static void testDefaultMonashCollegeEnquiryType() {
        //Initialize test records
        Id professionalYearRecordTypeId = MonashCollegeCaseServices.PROFESSIONALYEAR_RECTYPEID;
        Contact testContact = new Contact(LastName = 'TestLastName',
                                          Person_ID_unique__c = '18649257');
        insert testContact;

        //Start Test
        Test.startTest();

        Case testMonashCollegeEnquiry = new Case();
        testMonashCollegeEnquiry.ContactId = testContact.Id;
        testMonashCollegeEnquiry.RecordTypeId = professionalYearRecordTypeId;
        testMonashCollegeEnquiry.Enquiry_Type__c = null;
        insert testMonashCollegeEnquiry;

        //End Test
        Test.stopTest();

        //Evaluate results - ensure that the enquiry type got populated with current course
        Case resultEnquiry = [SELECT Id, Enquiry_Type__c FROM Case WHERE Id = :testMonashCollegeEnquiry.Id];
        System.assertEquals(resultEnquiry.Enquiry_Type__c, Label.Current_Course);
    }
}