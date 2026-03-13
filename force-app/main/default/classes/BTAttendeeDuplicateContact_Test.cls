/**
 * @author Nick Guia
 * @date 15-10-2020
 * @group Event Management
 * @description test class for BTAttendeeDuplicateContact 
 **/
@isTest(isParallel=true)
private class BTAttendeeDuplicateContact_Test {

    @TestSetup
    static void makeData(){
        //create blackthorn event
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        insert btEvent;
        System.assert(btEvent.Id != null, 'Unable to setup Blackthorn Event');
    }

    /**
     * @description build contact record for a single attendee record
     */
    @isTest
    static void shouldBuildContactRecordForSingleAttendee() {
        //given
        conference360__Event__c btEvent = [SELECT Id 
                                        FROM conference360__Event__c
                                        LIMIT 1];
        conference360__Attendee__c att = TestHelper.createBlackthornAttendee(btEvent.Id, 1)[0];
        att.conference360__First_Name2__c = 'BTAttendeeDuplicateContact_Test';
        att.conference360__Last_Name2__c = 'BTAttendeeDuplicateContact_Test';
        att.conference360__Email2__c = 'Test@test.org';
        BTAttendeeDuplicateContact dup;

        Test.startTest();

        //when
        dup = new BTAttendeeDuplicateContact(att);

        Test.stopTest();

        //then
        System.assert(dup.con != null, 'Unable to build a Contact record for attendee');
    }

    /**
     * @description build contact record for multiple attendee records
     */
    @isTest
    static void shouldBuildContactRecordForMultipleAttendees() {
        //given
        conference360__Event__c btEvent = [SELECT Id 
                                        FROM conference360__Event__c
                                        LIMIT 1];
        List<conference360__Attendee__c> attList = TestHelper.createBlackthornAttendee(btEvent.Id, 2);
        for(conference360__Attendee__c iAtt : attList) {
            iAtt.conference360__First_Name2__c = 'BTAttendeeContactMatcher_Test';
            iAtt.conference360__Last_Name2__c = 'BTAttendeeContactMatcher_Test';
            iAtt.conference360__Email2__c = 'Test@test.org';
        }
        BTAttendeeDuplicateContact dup;

        Test.startTest();

        //when
        dup = new BTAttendeeDuplicateContact(attList);

        Test.stopTest();

        //then
        System.assert(dup.con != null, 'Unable to build a Contact record for attendees');
    }

    @isTest
    static void shouldSetContactIdOnAttendee() {
        //given
        conference360__Event__c btEvent = [SELECT Id 
                                        FROM conference360__Event__c
                                        LIMIT 1];
        conference360__Attendee__c att = TestHelper.createBlackthornAttendee(btEvent.Id, 1)[0];
        att.conference360__First_Name2__c = 'BTAttendeeDuplicateContact_Test';
        att.conference360__Last_Name2__c = 'BTAttendeeDuplicateContact_Test';
        att.conference360__Email2__c = 'Test@test.org';

        BTAttendeeDuplicateContact dup  = new BTAttendeeDuplicateContact(att);
        System.assert(dup.con != null, 'Unable to build a Contact record for attendee');
        Contact con = dup.con;
        insert con;

        Test.startTest();

        //when
        dup.propagateContactIds();

        Test.stopTest();

        //then
        System.assertEquals(con.Id, att.conference360__Contact__c, 'Unable to set contact Id to attendee');
    }
}