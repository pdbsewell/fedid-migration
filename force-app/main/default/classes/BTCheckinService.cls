/**
 * @author Aref Samad
 * @date 17-08-2021
 * @group Event Management
 * @description class to handle Group attendee Registration check in
 *   17-08-2021  Aref Samad    - EPBBS-2087 added method checkInAttendeeGroup to Check in Guest Attendees in attendee group when Primary attendee checked in
 **/

public without sharing class BTCheckinService {

    List<conference360__Attendee__c> l_PrimaryAttendees=new List<conference360__Attendee__c>();

    public BTCheckinService(List<conference360__Attendee__c> primaryAttendees)
    {
        if(primaryAttendees != null && !primaryAttendees.isEmpty()) {
            l_PrimaryAttendees=primaryAttendees;
        }
    }

     /**
     * @description EPBBS-2087 Number Reg - Check In - Check in Guest Attendees in attendee group when Primary attendee checked in
     */
    public void checkInAttendeeGroup()
    {
        Set<Id> attendeeGroupIdSet=new Set<id>();

        for(conference360__Attendee__c attendee:l_PrimaryAttendees)
        {
            attendeeGroupIdSet.add(attendee.conference360__Attendee_Group__c);
        }

        List<conference360__Attendee__c> guestAttendeeList=[SELECT Id,conference360__Attendance_Status__c,conference360__Registration_Status__c
        From conference360__Attendee__c WHERE conference360__Attendee_Group__c in:attendeeGroupIdSet AND is_Primary_Registrant__c!= TRUE
        AND conference360__Attendance_Status__c!=:BTAttendeeServices.ATTN_STATUS_ATTENDED];

        for(conference360__Attendee__c guestAttendee: guestAttendeeList)
        {
            guestAttendee.conference360__Attendance_Status__c=BTAttendeeServices.ATTN_STATUS_ATTENDED;
        }

        update guestAttendeeList;
    }



}