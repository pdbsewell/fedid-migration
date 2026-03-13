/**
 * @author      Vishal Gupta
 * @description test class for MyGRAppAddQualificationController
 * @group       My App Community Services
 * @created on  29/07/2024
 */
//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User
@isTest(isParallel=false)
private class MyGRAppAddQualificationController_Test {

    @TestSetup
    static void makeData(){
        Country_Attribute__c ca = new Country_Attribute__c(Name = 'AUSTRALIA');
        insert ca;
    }

    @isTest
    /**
     * @author      vishal gupta
     * @description Tests getting the picklist values for graduate research qualification screen
     *
     * GIVEN there are picklist values are defined in metadata 
     * WHEN the qualification page gets loaded on Graduate Research application
     * THEN system should return the picklist values
     */
    public static void testGetPicklistValues()
    {
        // create community user
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Test.startTest();
        System.runAs(applicant) {
            
            Map<String, Object>  picklistValues = MyGRAppAddQualificationController.getPicklistValues();
            Assert.areNotEqual(NULL, picklistValues.get('QUAL_TYPE'), 'picklist values QUAL_TYPE are not null');
        }

        Test.stopTest();
    }

    @isTest
    /**
     * @author      vishal gupta
     * @description Tests getting the existing contact qualifications for Graduate Research
     *
     * GIVEN there are existing contact qualifications for Graduate Research
     * WHEN the qualification page gets loaded on Graduate Research application
     * THEN system should return the contact qualifications for Graduate Research
     */
    public static void testGetContactQualifications()
    {
        // create community user
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        Test.startTest();
        System.runAs(applicant) {
            List<RecordType> recTypes = [SELECT Id, Name, sObjectType
            FROM        RecordType
            WHERE       sObjectType = 'Contact_Qualification__c'
            AND Name = 'Tertiary Education'
            ];

            RecordType rt = recTypes[0];
            
            Application__c app = StudFirst_TestHelper.createApplication(c.Id);
            app.Type_Of_Study__c = 'Graduate Research';
            insert app;

            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = applicant.ContactId;
            cq.RecordTypeId = rt.Id;
            
            insert cq;

            // create the apq
            Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
            aqp.Contact_Qualification__c = cq.Id;
            aqp.Application__c = app.Id;
            insert aqp;

            List<Contact_Qualification__c> qualifications = MyGRAppAddQualificationController.getContactQualifications(app.Id, 'Tertiary_Education');
            Assert.areEqual(1, qualifications.size(), 'returned 1 qualification');
        }

        Test.stopTest();
    }

    @isTest
    /**
     * @author      vishal gupta
     * @description Tests inserting contact qualifications for Graduate Research
     *
     * GIVEN student has started the Graduate Research application on the portal
     * WHEN the qualification is submitted
     * THEN system should insert the contact qualifications for Graduate Research
     */
    public static void testInsertContactQualification()
    {
        // create community user
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        Test.startTest();
        System.runAs(applicant) {
            Application__c app = StudFirst_TestHelper.createApplication(c.Id);
            app.Type_Of_Study__c = 'Graduate Research';
            insert app;

            Map<String, Object> objResults = MyGRAppAddQualificationController.upsertQualificationToContact(c.Id, app.Id, new Contact_Qualification__c(), 'Tertiary_Education');
            Assert.areNotEqual(NULL, objResults.get('contact_qualification_id'), 'Graduate research contact_qualification_id is not null');
        }

        Test.stopTest();
    }

    @isTest
    /**
     * @author      vishal gupta
     * @description Tests updating contact qualifications for Graduate Research
     *
     * GIVEN student has already inserted the contact qualifications for Graduate Research
     * WHEN the any information on qualification is updated
     * THEN system should update the contact qualifications for Graduate Research
     */
    public static void testUpdateContactQualification()
    {
        // create community user
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        Test.startTest();
        System.runAs(applicant) {
            List<RecordType> recTypes = [SELECT Id, Name, sObjectType
            FROM        RecordType
            WHERE       sObjectType = 'Contact_Qualification__c'
            AND Name = 'Tertiary Education'
            ];

            RecordType rt = recTypes[0];
            
            Application__c app = StudFirst_TestHelper.createApplication(c.Id);
            app.Type_Of_Study__c = 'Graduate Research';
            insert app;

            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = applicant.ContactId;
            cq.RecordTypeId = rt.Id;
            insert cq;

            Map<String, Object> objResults = MyGRAppAddQualificationController.upsertQualificationToContact(c.Id, app.Id, cq, 'Tertiary_Education');
            Assert.areEqual(NULL, objResults.get('app_qualification_id'), 'updated the contact qualification and didnt insert application qualification');
        }

        Test.stopTest();
    }

    @isTest
    /**
     * @author      vishal gupta
     * @description Tests deleting the contact qualifications for Graduate Research
     *
     * GIVEN student has already inserted the contact qualifications for Graduate Research
     * WHEN the students click on delete button on contact qualification
     * THEN system should delete the particualr contact qualification
     */
    public static void testDeleteContactQualification()
    {
        // create community user
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        Test.startTest();
        System.runAs(applicant) {
            List<RecordType> recTypes = [SELECT Id, Name, sObjectType
            FROM        RecordType
            WHERE       sObjectType = 'Contact_Qualification__c'
            AND Name = 'Tertiary Education'
            ];

            RecordType rt = recTypes[0];
            
            Application__c app = StudFirst_TestHelper.createApplication(c.Id);
            app.Type_Of_Study__c = 'Graduate Research';
            insert app;

            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = applicant.ContactId;
            cq.RecordTypeId = rt.Id;
            insert cq;

            Contact_Document__c contactDocu = new Contact_Document__c();
            contactDocu = StudFirst_TestHelper.createContactDocument(applicant.ContactId);
            contactDocu.Document_Type__c = 'PARENT_GUARDIAN';
            contactDocu.Contact_Qualification__c = cq.Id;
            contactDocu.Application__c = app.Id;
            contactDocu.Submitted__c = true;
            insert contactDocu;

            Map<String, Object> objResults = MyGRAppAddQualificationController.deleteContactQualification(cq.Id, app.Id);
            Assert.areNotEqual(NULL, objResults.get('result'), 'deleted result is not null');

            List<Contact_Document__c> lstDocuments = [SELECT Id from Contact_Document__c WHERE Contact_Qualification__c = :cq.Id];  
            Assert.areEqual(true, lstDocuments.isEmpty(), 'deleted the documents');          
        }

        Test.stopTest();
    }

    @isTest
    /**
     * @author      sethu venna
     * @description validate fetchDeclarationOptions method on MyGRAppAddQualificationController
     * GIVEN        the declaration options are stored in Declaration_Text__c field on MyGRAppSetting__mdt
     * WHEN         the applicant is on my.app review and submit page
     * THEN         fetchDeclarationOptions should return the declaration options as a string with | as separator 
     */
    public static void testFetchDeclarationOptions()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Test.startTest();
        System.runAs(applicant) {
            List<MyGRAppSetting__mdt>  declarationOptions = MyGRAppAddQualificationController.fetchDeclarationOptions();
            Assert.areNotEqual(NULL, declarationOptions, 'return value of the method is not null');
        }
        Test.stopTest();
    }
}