/**
* @author Ibrahim Rumi
* @date 01.02.2021
* @group Event Management
* @description Test class for BTFormSubmissionTriggerHandler
*/
@isTest(isParallel=true)
public class BTFormSubmissionTriggerHandler_Test {

    @TestSetup
    static void makeData(){

        //create a Contact
        Contact con = new Contact(
            FirstName = 'BTFormSubmissionTriggerHandler_Test', 
            LastName = 'Test', 
            Email = 'test@test.org');
        insert con;

        //create an event
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        insert btEvent;

        //create an attendee
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(btEvent.id, 1)[0];
        insert attendee;
    }

    /**
	 * @description test whether Person360 record is created for the Contact that
	 * was linked to the Attendee when Form Elements are present
	 */
    @isTest
    static void shouldCreateP360WhenFormElementsPresent() {

        //given
        Contact con = [SELECT Id, FirstName, LastName, Email
                    FROM Contact WHERE FirstName = 'BTFormSubmissionTriggerHandler_Test'
                    LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Attendee__c attendee = [SELECT Id FROM conference360__Attendee__c LIMIT 1];

        conference360__Form_Submission__c btForm = TestHelper.createBTFormSubmission(1, con.id, btEvent.id, attendee.id, true)[0];
        insert btForm;
        
        Test.startTest();
        //when
        btForm.conference360__Status__c = BTFormSubmissionTriggerHandler.STATUS_SUBMITTED;
        btForm.conference360__Processed__c = true;
        
        update btForm;
        
        Test.stopTest();
        
        //then
        List<Staged_Prospective_Student__c> spsList = [SELECT Id FROM Staged_Prospective_Student__c 
                                                    WHERE Lead_Source__c = 'Event'];
        System.assert(!spsList.isEmpty(), 'Unable to create SPS record for Attendee');
    }

    /**
	 * @description test whether Person360 record is created for the Contact that
	 * was linked to the Attendee
	 */
    @isTest
    static void shouldCreateP360WhenFormElementsNotPresent() {
        //given
        Contact con = [SELECT Id, FirstName, LastName, Email
                    FROM Contact WHERE FirstName = 'BTFormSubmissionTriggerHandler_Test'
                    LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Attendee__c attendee = [SELECT Id FROM conference360__Attendee__c LIMIT 1];

        conference360__Form_Submission__c btForm = TestHelper.createBTFormSubmission(1, con.id, btEvent.id, attendee.id, false)[0];
        insert btForm;
        
        Test.startTest();

        //when
        btForm.conference360__Status__c = BTFormSubmissionTriggerHandler.STATUS_SUBMITTED;
        btForm.conference360__Processed__c = true;
        
        update btForm;
        
        Test.stopTest();
        
        //then
        List<Staged_Prospective_Student__c> spsList = [SELECT id FROM Staged_Prospective_Student__c 
                                             WHERE Lead_Source__c = 'Event'];
        System.assert(!spsList.isEmpty(), 'Unable to create SPS record for Attendee');
    }
}