/**
 * @author Nick Guia
 * @group Event Management
 * @description runs the Attendee Contact matching in asynchronous context.
 * Given the hard limit of matching (50 records at a time), the initial input number of records
 * is broken down into batches (Custom_Attende_Matching_Threshold__c) and chains the remainder
 * into a new Queueable job
 **/
public with sharing class BTQueueAttendeeContactMatcher implements Queueable {

    @TestVisible
    private List<conference360__Attendee__c> attendeeList;
    @TestVisible
    private List<conference360__Attendee__c> chainAttendeList;
    
    public BTQueueAttendeeContactMatcher(List<conference360__Attendee__c> attList) {
        this.attendeeList = new List<conference360__Attendee__c>();
        this.chainAttendeList = new List<conference360__Attendee__c>();

        conference360__Blackthorn_Events_Settings__c settings = conference360__Blackthorn_Events_Settings__c.getOrgDefaults();
        Integer max = (Integer) settings.Custom_Attende_Matching_Threshold__c;

        //break it into batches and chain the remainder
        for(Integer i = 0; i < attList.size(); i++) {
            if(this.attendeeList.size() != max) {
                //create a new instance to prevent read-only errors
                conference360__Attendee__c listAttendee = attList[i];
                conference360__Attendee__c instAttendee = new conference360__Attendee__c(
                    Id = listAttendee.Id,
                    conference360__First_Name2__c = listAttendee.conference360__First_Name2__c,
                    conference360__Last_Name2__c = listAttendee.conference360__Last_Name2__c,
                    conference360__Email2__c = listAttendee.conference360__Email2__c,
                    conference360__Event__c = listAttendee.conference360__Event__c
                );
                this.attendeeList.add(instAttendee);
            } else {
                this.chainAttendeList.add(attList[i]);
            }
        }
    }

    public void execute(QueueableContext context) {
		if(!this.attendeeList.isEmpty()) {
            BTAttendeeContactMatcher matcher = new BTAttendeeContactMatcher(this.attendeeList);
            matcher.findAllEmailFields();
            matcher.run();
            
            List<Database.SaveResult> srList = Database.update(this.attendeeList, false);
            for(Database.SaveResult iRes : srList) {
                for(Database.Error iError : iRes.getErrors()) {
                    LogUtilityException.addLogEvent(
                        'Blackthorn',
                        iRes.getId(),
                        iError,
                        'BTQueueAttendeeContactMatcher'
                    );
                }
            }
            LogUtilityException.publishAll();
        }
        
        if(!this.chainAttendeList.isEmpty()) {
            BTQueueAttendeeContactMatcher chain = new BTQueueAttendeeContactMatcher(this.chainAttendeList);
            System.enqueueJob(chain);
        }
	}
}