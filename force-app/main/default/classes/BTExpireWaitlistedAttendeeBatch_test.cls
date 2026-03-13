/**
* @author Ibrahim Rumi
* @date 12-07-2021
* @description Sibling test class for BTBatchExpireWaitlistedAttendee
**/
@isTest(isParallel=true)
public class BTExpireWaitlistedAttendeeBatch_test {
    /**
     * @description Inserts records required for test methods
     */
    @testSetup
    static void setup(){
    
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        insert btEventList;
        
         list<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendeeWithMatchingContacts(btEventList[0].Id, 10);
        
        for(conference360__Attendee__c att: attendeeList){
            att.Registration_status_reason__c = BTAttendeeServices.REG_STATUS_REASON_PENDING_WL_REG;
            att.conference360__Registration_Status__c = BTAttendeeServices.REG_STATUS_PENDING;
            att.Waitlist_Registration_Expiry_1hr__c = Date.today().addDays(-1);
        }
        insert attendeeList;
    }
    /**
     * @description test the batch job to check if the registration status for attendees is canceled
     */
    @isTest 
    static void testExpireWaitlistedAttendee() {
        
        Test.startTest();
        BTExpireWaitlistedAttendeeBatch bwaexpirebatch = new BTExpireWaitlistedAttendeeBatch();
        Id batchId = Database.executeBatch(bwaexpirebatch);
        Test.stopTest();
        // after the testing stops, assert records were updated properly
        System.assertEquals(10, [select count() from conference360__Attendee__c where conference360__Registration_Status__c =: BTAttendeeServices.REG_STATUS_CANCELLED]);
    }
    
}