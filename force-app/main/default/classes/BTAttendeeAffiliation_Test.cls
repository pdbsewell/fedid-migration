/**
* @author Nick Guia
* @date 18-02-2021
* @description Sibling test class for BTAttendeeAffiliation
**/
@isTest(isParallel=true)
private class BTAttendeeAffiliation_Test {

    /**
     * @description just a place holder test coverage as this
     * class doesn't have any functions yet until the next iteration
     */
    @istest
    static void shouldInitialiseClass() {

        //given
        Contact con = TestHelper.createProspectiveStudentContact(1)[0];
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(null, 1)[0];
        BaseClass bc = new BaseClass();

        BTAttendeeAffiliation aff;

        Test.startTest();

        //when
        aff = new BTAttendeeAffiliation(con, attendee);
        aff.createAttendeePerson360();
        aff.pushRecords(bc);

        Test.stopTest();

        //then
        System.assert(aff != null, 'Unable to initialise BTAttendeeAffiliation');
    }
}