/**
* @author Nick Guia
* @date 01.02.2021
* @group Event Management
* @description Test class for BTContactAttendeeDAO
*/
@isTest(isParallel=true)
private class BTContactAttendeeDAO_Test {
    
    /**
     * @description test adding a new event-attendee to DAO class
     */
    @isTest
    static void shouldAddEventATtendee() {
        
        //given
        Contact con = new Contact(
            FirstName = 'shouldAddEventATtendee', 
            LastName = 'Test', 
            Email = 'test@test.org');
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(null, 1)[0];
        BTContactAttendeeDAO dao;

        Test.startTest();

        //when
        dao = new BTContactAttendeeDAO(con);
        dao.addEventAttendee(btEvent, attendee);

        Test.stopTest();

        //then
        System.assert(!dao.eventAttendeeDAO.isEmpty(), 'Unable to add new instance of Event in DAO class');
    }

    /**
     * @description test identifying whether or not an affiliation of the same type
     * has already been created in memory 
     */
    @isTest
    static void shouldCreateNewAffiliation() {
        
        //given
        Contact con = new Contact(
            FirstName = 'shouldAddEventATtendee', 
            LastName = 'Test', 
            Email = 'test@test.org');

        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(2);
        btEventList[0].Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        btEventList[1].Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(null, 2);
        BTContactAttendeeDAO dao;
        Boolean firstCheck = false;
        Boolean secondCheck = false;

        Test.startTest();

        //when
        dao = new BTContactAttendeeDAO(con);
        //add prospective student event
        dao.addEventAttendee(btEventList[0], attendeeList[0]);
        //should be true
        firstCheck = dao.shouldCreateNewAffiliation(dao.eventAttendeeDAO[0]);
        //add another prospective student event
        dao.addEventAttendee(btEventList[1], attendeeList[1]);
        //should be false since prospective student has already been added for the same contact
        secondCheck = dao.shouldCreateNewAffiliation(dao.eventAttendeeDAO[1]);

        Test.stopTest();

        //then
        System.assert(firstCheck, 'Unable to indentify affiliation creation properly');
        System.assert(!secondCheck, 'Unable to indentify affiliation creation properly');
    }

    /**
     * @description test Contact getter
     */
    @isTest
    static void shouldReturnContactRecord() {
        
        //given
        Contact con = new Contact(
            FirstName = 'shouldAddEventATtendee', 
            LastName = 'Test', 
            Email = 'test@test.org');
        BTContactAttendeeDAO dao;

        Test.startTest();

        //when
        dao = new BTContactAttendeeDAO(con);

        Test.stopTest();

        //then
        System.assert(dao.getContact() != null, 'Unable to get Contact from DAO class');
    }
}