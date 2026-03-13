/**
 * @author          Jackie Ho
 * @group           Test Class
 * @description     Unit test for ContactQualificationChangeEventTrigger
 * @last modified on  : 05-08-2025
 * @last modified by  : Jackie Ho
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   05-08-2025   Jackie Ho       Initial Version
 */
@isTest(isParallel=true)
public class ContactQualificationEventTrigger_Test {
    
    // Test method to verify the trigger calls the handler when a qualification change event occurs
    @isTest 
    static void testTriggerCallsHandler() {
        // GIVEN: Disable the trigger first to test the trigger bypass logic
        Test.enableChangeDataCapture();
        
        // GIVEN: Create test data
        string testname = 'name ' + String.valueOf(System.now());
        id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        Account testaccount = new Account(name=testname, recordtypeid=recordtypeids);
        insert testaccount;

        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(Firstname='Test', Lastname=testLastname, contact_profile__c='');
        insert testContact;
       
        // GIVEN: Create a course attempt
        Course_Attempt__c ca = new Course_Attempt__c(
            Course__c = createCourse(testaccount.id), 
            Contact__c = testContact.Id
        );
        insert ca;

        Test.startTest();
        
        // WHEN: Create a qualification change event
        id recordTypeConQual = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert new Contact_Qualification__C(
            contact__c = testContact.id,
            Obtained_status__c = ContactQualificationChangeEvent.OBTAINED_STATUS_MONASH,
            faculty__c = testaccount.id,
            Date_Achieved__c = system.today()-5,
            Course_Attempt__c = ca.id,
            Institution_Name__c = ContactQualificationChangeEvent.INSTITUTION_MONASH,
            RecordTypeId = recordTypeConQual
        );
        
        // WHEN: Deliver the change event
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // THEN: Verify the contact was updated
        Contact updatedContact = [SELECT Id, contact_profile__c, Study_at_Monash__c FROM Contact WHERE Id = :testContact.Id];
        Assert.areEqual('Alumni', updatedContact.contact_profile__c, 'The contact profile should be updated to Alumni');
        Assert.areEqual(true, updatedContact.Study_at_Monash__c, 'The Study at Monash flag should be set to true');
    }
    
    // Test method to verify trigger bypass logic
    @isTest 
    static void testTriggerBypass() {
        // GIVEN: Get System Admin user for testing
        User adminUser = [SELECT Id, Username FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        // GIVEN: Create a trigger mute request for the admin user
        TriggerMuteRequest__c muteRequest = new TriggerMuteRequest__c(
            Name = adminUser.Username,
            TriggersList__c = 'Contact_Qualification__ChangeEvent'
        );
        insert muteRequest;
        
        // WHEN: Run test as admin user
        System.runAs(adminUser) {
            Test.startTest();
            // The trigger should be bypassed for this user
            Test.enableChangeDataCapture();
            
            // Create minimal test data
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            
            Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
            insert testContact;
            
            // Create a course
            Id courseId = createCourse(testAccount.Id);
            
            // Create a course attempt
            Course_Attempt__c ca = new Course_Attempt__c(
                Course__c = courseId,
                Contact__c = testContact.Id
            );
            insert ca;
            
            // Create a qualification change event
            id recordTypeConQual = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
            insert new Contact_Qualification__C(
                contact__c = testContact.id,
                Obtained_status__c = 'Test Status',
                faculty__c = testAccount.id,
                Date_Achieved__c = system.today(),
                Course_Attempt__c = ca.id,
                Institution_Name__c = 'Test Institution',
                RecordTypeId = recordTypeConQual
            );
            
            // WHEN: Deliver the change event
            Test.getEventBus().deliver();
            Test.stopTest();
            
            // THEN: Verify the contact was not updated (trigger was bypassed)
            Contact updatedContact = [SELECT Id, contact_profile__c FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual(null, updatedContact.contact_profile__c, 'The contact profile should not be updated when trigger is bypassed');
        }
    }
    
    
    // Helper method to create a test course
    private static id createCourse(Id accountId) {
        Course__c course = new Course__c();
        course.Name = 'CrsNme';
        course.Course_Description__c = 'CourseDescription-1';
        course.Course_Code__c = 'CourseCode-1';
        course.Version__c = '1';
        course.Faculty_Description__c = 'FacultyDescription-1';
        course.Sub_Level__c = '41'; //DOCTORATE BY RESEARCH';
        course.Title__c = 'Course Title';
        course.Managing_Faculty__c = 'Faculty of Engineering';
        course.Faculty_Code__c = 'FacCode';
        course.Type__c = 'Course-All';
        course.Faculty__c = accountId;
        insert course;  
        return course.id;
    }
}