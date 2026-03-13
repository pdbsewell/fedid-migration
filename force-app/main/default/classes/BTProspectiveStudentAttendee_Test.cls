/**
* @author Nick Guia
* @date 18-02-2021
* @description Sibling test class for BTProspectiveStudentAttendee
**/
@isTest(isParallel=true)
private class BTProspectiveStudentAttendee_Test {

    /**
     * @description should initialise an SPS based on
     * Attendee and Event details
     */
    @isTest
    static void shouldCreateAttendePerson360() {

        //given
        Contact con = new Contact(
            FirstName = 'shouldCreateAttendePerson360', 
            LastName = 'Test', 
            Email = 'test@test.org');

        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        //EPBBS-3452 - Populate Broad_Area_of_Interest_Update_Mode__c from Event on SPS
        btEvent.Broad_Area_of_Interest_Update_Mode__c = 'Append';
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;

        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(btEvent.id, 1)[0];

        BTProspectiveStudentAttendee ps;

        Test.startTest();

        //when
        ps = new BTProspectiveStudentAttendee(con, btEvent, attendee);
        ps.createAttendeePerson360();

        Test.stopTest();

        //then
        //EPBBS-3452 - Populate Broad_Area_of_Interest_Update_Mode__c from Event on SPS
        Assert.isTrue(ps.sps.Broad_Area_of_Interest_Update_Mode__c == 'Append', 'Unable to update Broad Area of interest Update mode');
        Assert.isTrue(ps.sps != null, 'Unable to create an SPS record for Prospective Student Attendee');
    }

    /**
     * @description should blank out SPS address values when SPS
     * Mailing Address details only contains a country ISO Code 
     */
    @isTest
    static void shouldCleanupCountryISOCode() {

        Contact con = new Contact(
            FirstName = 'shouldCreateAttendePerson360', 
            LastName = 'Test', 
            Email = 'test@test.org');

        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;

        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(btEvent.id, 1)[0];

        BTProspectiveStudentAttendee ps;

        Staged_Prospective_Student__c sps = new Staged_Prospective_Student__c(Mailing_Country__c = 'AU');

        //given

        Test.startTest();

        //when
        ps = new BTProspectiveStudentAttendee(con, btEvent, attendee);
        ps.sps = sps; //inject test sps
        ps.cleanupCountryISOCode();

        Test.stopTest();

        //then
        Assert.isTrue(ps.sps.Mailing_Country__c == null, 'Unable to remove ISO Country code value in Mailing Country');
    }

    /**
     * @description test push SPS record into Base Class
     */
    @isTest
    static void shouldPushRecords() {

        //given
        Contact con = new Contact(
            FirstName = 'shouldCreateAttendePerson360', 
            LastName = 'Test', 
            Email = 'test@test.org');

        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;

        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(btEvent.id, 1)[0];

        BTAttendeeServices attendeeService = new BTAttendeeServices();
        BaseClass bc = new BaseClass(attendeeService.getP360CommitOrder());

        BTProspectiveStudentAttendee ps;

        Test.startTest();

        //when
        ps = new BTProspectiveStudentAttendee(con, btEvent, attendee);
        ps.createAttendeePerson360();

        Test.stopTest();

        //then
        Assert.isTrue(bc.lCommitOrder != null, 'Unable to push sps to Base Class');
    }
}