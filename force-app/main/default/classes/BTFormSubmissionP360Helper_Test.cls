/**
* @author Nick Guia
* @date 18-02-2021
* @description Sibling test class for BTFormSubmissionP360Helper
**/
@isTest(isParallel=true)
private class BTFormSubmissionP360Helper_Test {
    
    @TestSetup
    static void makeData(){

        //create a Contact
        Contact con = new Contact(
            FirstName = 'BTFormSubmissionP360Helper_Test', 
            LastName = 'Test', 
            Email = 'test@test.org');
        insert con;

        //create an event
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        insert btEvent;

        //create an attendee
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(btEvent.id, 1)[0];
        attendee.conference360__Contact__c = con.Id;
        insert attendee;
    }

    /**
	 * @description collect form submission details and
     * store withing the helper class
	 */
    @isTest
    static void shouldCollectFormSubmissionDetails() {

        //given
        Contact con = [SELECT Id, FirstName, LastName, Email
                    FROM Contact WHERE FirstName = 'BTFormSubmissionP360Helper_Test'
                    LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Attendee__c attendee = [SELECT Id FROM conference360__Attendee__c LIMIT 1];

        conference360__Form_Submission__c fs = TestHelper.createBTFormSubmission(1, con.id, btEvent.id, attendee.id, true)[0];
        BTFormSubmissionP360Helper helper;
        
        Test.startTest();

        //when
        helper =  new BTFormSubmissionP360Helper();
        helper.collectFormSubmissionDetails(fs);
        
        Test.stopTest();
        
        //then
        System.assert(!helper.attendeeIdsByEventId.isEmpty(), 'Unable to collect form submission details');
        System.assert(!helper.allAttendeeIds.isEmpty(), 'Unable to collect form submission details');
    }

    /**
	 * @description collect form submission details and
     * store withing the helper class even if Form Submission record
     * does not have any form element details in the payload
	 */
    @isTest
    static void shouldCollectFormSubmissionDetailsIfNoFormElement() {

        //given
        Contact con = [SELECT Id, FirstName, LastName, Email
                    FROM Contact WHERE FirstName = 'BTFormSubmissionP360Helper_Test'
                    LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Attendee__c attendee = [SELECT Id FROM conference360__Attendee__c LIMIT 1];

        conference360__Form_Submission__c fs = TestHelper.createBTFormSubmission(1, con.id, btEvent.id, attendee.id, false)[0];
        BTFormSubmissionP360Helper helper;
        
        Test.startTest();

        //when
        helper =  new BTFormSubmissionP360Helper();
        helper.collectNoCustomFormElement(fs);
        
        Test.stopTest();
        
        //then
        System.assert(!helper.attendeeIdsByEventId.isEmpty(), 'Unable to collect form submission details');
        System.assert(!helper.allAttendeeIds.isEmpty(), 'Unable to collect form submission details');
    }

    /**
     * @description invoke create person360 process based on form submission details.
     * This test should create an SPS record in return given that Event Audience Type
     * is Prospective Student
     */
    @isTest
    static void shouldCreatePerson360() {
        //given
        Contact con = [SELECT Id, FirstName, LastName, Email
                    FROM Contact WHERE FirstName = 'BTFormSubmissionP360Helper_Test'
                    LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Attendee__c attendee = [SELECT Id FROM conference360__Attendee__c LIMIT 1];

        conference360__Form_Submission__c fs = TestHelper.createBTFormSubmission(1, con.id, btEvent.id, attendee.id, false)[0];
        BTFormSubmissionP360Helper helper;

        Test.startTest();

        //when
        helper =  new BTFormSubmissionP360Helper();
        helper.collectNoCustomFormElement(fs);
        helper.createPerson360();

        Test.stopTest();

        //then
        List<Staged_Prospective_Student__c> spsList = [SELECT Id FROM Staged_Prospective_Student__c 
                                                    WHERE Lead_Source__c = 'Event'];
        System.assert(!spsList.isEmpty(), 'Unable to create SPS record for Attendee');
    }

    /**
     * @description test query attendee records and build
     *  Contact map based on result set
     */
    @isTest
    static void shouldSelectAttendees() {

        //given
        conference360__Attendee__c attendee = [SELECT Id FROM conference360__Attendee__c LIMIT 1];
        BTFormSubmissionP360Helper helper = new BTFormSubmissionP360Helper();
        helper.allAttendeeIds.add(attendee.Id);

        Test.startTest();

        //when
        helper.selectAttendees().buildContactMap();

        Test.stopTest();

        //then
        System.assert(!helper.attendeeMap.isEmpty(), 'Unable to query Attendee records');
        System.assert(!helper.attendeeIdsByContactId.isEmpty(), 'Unable to build Contact and Attendees map');
    }

    /**
     * @description test query event records
     */
    @isTest
    static void shouldSelectEvents() {

        //given
        conference360__Attendee__c attendee = [SELECT Id FROM conference360__Attendee__c LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        BTFormSubmissionP360Helper helper = new BTFormSubmissionP360Helper();
        helper.attendeeIdsByEventId.put(btEvent.Id, new Set<Id>{ attendee.Id });

        Test.startTest();

        //when
        helper.selectEvents();

        Test.stopTest();

        //then
        System.assert(!helper.eventMap.isEmpty(), 'Unable to query Event records');
    }

    /**
     * @description test query contact records
     */
    @isTest
    static void shouldSelectContacts() {

        //given
        conference360__Attendee__c attendee = [SELECT Id, conference360__Contact__c 
                                            FROM conference360__Attendee__c 
                                            LIMIT 1];
        BTFormSubmissionP360Helper helper = new BTFormSubmissionP360Helper();
        helper.attendeeIdsByContactId.put(attendee.conference360__Contact__c, new Set<Id>{ attendee.Id });

        Test.startTest();

        //when
        helper.selectContacts();

        Test.stopTest();

        //then
        System.assert(!helper.conMap.isEmpty(), 'Unable to query Contact records');
    }

	/**
     * @description invoke create person360 process based on form submission details.
     * This test should create an SPS record in return given that Event Audience Type
     * is Prospective Student
     */
    @isTest
    static void shouldCheckBroadInterestfromEvent() {
        //given
        Contact con = [SELECT Id, FirstName, LastName, Email
                    FROM Contact WHERE FirstName = 'BTFormSubmissionP360Helper_Test'
                    LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        //EPBBS-3452 - Populate Broad_Area_of_Interest_Update_Mode__c from Event on SPS
        btEvent.Broad_Area_of_Interest_Update_Mode__c = 'Append';
        conference360__Attendee__c attendee = [SELECT Id FROM conference360__Attendee__c LIMIT 1];

        conference360__Form_Submission__c fs = TestHelper.createBTFormSubmission(1, con.id, btEvent.id, attendee.id, false)[0];
        BTFormSubmissionP360Helper helper;

        Test.startTest();

        //when
        helper =  new BTFormSubmissionP360Helper();
        helper.collectNoCustomFormElement(fs);
        helper.createPerson360();

        Test.stopTest();

        //then
        List<Staged_Prospective_Student__c> spsList = [SELECT Id,Broad_Area_of_Interest_Update_Mode__c FROM Staged_Prospective_Student__c 
                                                    WHERE Lead_Source__c = 'Event'];
        System.assert(!spsList.isEmpty(), 'Unable to create SPS record for Attendee');
        Assert.isTrue(spsList[0].Broad_Area_of_Interest_Update_Mode__c =='Append','Unable to update Broad Area of interest Update mode');
    }    
}