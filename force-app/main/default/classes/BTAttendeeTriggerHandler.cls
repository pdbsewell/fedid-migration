/**
 * @author Nick Guia
 * @date 11-08-2020
 * @group Event Management
 * @description Trigger handler for conference360__Attendee__c object (Blackthorn)
 * @revision
 *   04.11.2020  Ibrahim Rumi    - EPBBS-1375 added method cancelRegistrationRelatedAttendee to handle cancellation of event registration by attendees
 *   12.04.2021  Ibrahim Rumi    - EPBBS-1856 added method AutoRegisterWaitlistedAttendee to auto change the status from pending to registered
 *   30.05.2021  Ibrahim Rumi    - EPBBS-1888 Deleting CancelRegistrationRelatedAttendee and AutoRegisterWaitlistedAttendee classes from handler.
 *   30.05.2021  Ibrahim Rumi    - EPBBS-1888 added method registrationStatusHandler to handle Attendee registration Status change
 *   25.06.2021  Ibrahim Rumi    - EPBBS-2019 updated execute method of registrationStatusHandler to call BTAttendeeRegistrationStatusManager only when the attendee maps are not empty
 *   17.08.2021  Aref Samad      - EPBBS-2087 Number Reg - Check In - Check in Guest Attendees in attendee group when Primary attendee checked in
 *   18.10.2021  Ibrahim Rumi    - EPBBS-2183 Share newly inserted Attendee with existing event Staff
 *   21.10.2021  Ibrahim Rumi    - EPBBS-2183 Update ShareAttendeeToEventStaff to only include Attendee with a contact
 *   17.01.2022  Ibrahim Rumi    - EPBBS-2379 validateRegistration method to Validate capacity and duplicates during attendee registration
 **/
public with sharing class BTAttendeeTriggerHandler {

    /**
     * @description use custom matching rules to link Attendee to a Contact
     */
    public class LinkContactToAttendee extends TriggerAbstract {

        private List<conference360__Attendee__c> attendeesBI = new List<conference360__Attendee__c>();
        private List<conference360__Attendee__c> attendeesAI = new List<conference360__Attendee__c>();
        private conference360__Blackthorn_Events_Settings__c settings =
            conference360__Blackthorn_Events_Settings__c.getOrgDefaults();

        public override void process(SObject sobj) {
            if(!settings.Disable_Custom_Matching_Rules__c) {

                conference360__Attendee__c newObj = (conference360__Attendee__c) sobj;

                //PROCESS IF: Contact lookup is null
                if(newObj.conference360__Contact__c == null &&
                    String.isNotBlank(newObj.conference360__First_Name2__c) &&
                    String.isNotBlank(newObj.conference360__Last_Name2__c) &&
                    String.isNotBlank(newObj.conference360__Email2__c ))
                {
                    if(newObj.Id == null) {
                        //ON BEFORE INSERT
                        this.attendeesBI.add(newObj);
                    } else {
                        //ON AFTER INSERT
                        this.attendeesAI.add(newObj);
                    }
                }
            }
        }

        public override void execute() {
            /**
             * if the number of attendees that needs to be matched to a contact
             * is less than the ideal threshold, do the match synchronously.
             * Otherwise, run it async on after insert
             */
            if(!this.attendeesBI.isEmpty() && this.attendeesBI.size() <= settings.Custom_Attende_Matching_Threshold__c) {
                BTAttendeeContactMatcher matcher = new BTAttendeeContactMatcher(attendeesBI);
                matcher.findAllEmailFields();
				matcher.run();
            }

            if(!this.attendeesAI.isEmpty()) {
                //run contact matching async
                BTQueueAttendeeContactMatcher asyncMatcher = new BTQueueAttendeeContactMatcher(this.attendeesAI);
                System.enqueueJob(asyncMatcher);
            }
        }
    }

    /**
     * @description Subscribes the Contact linked to the Attendee if consent was provided.
     *  This is only a means to subscribe, but never to unsubscribe.
     */
    public class SubscribeToMarketing extends TriggerAbstract {

        private List<conference360__Attendee__c> attendees = new List<conference360__Attendee__c>();
        private Set<Id> events = new Set<Id>();

        public override void process(SObject sobj) {
            conference360__Attendee__c newObj = (conference360__Attendee__c) sobj;

            /**
             * PROCESS IF:
             * - linked contact AND EVENT not null AND
             * - Marketing_Subscription_Opt_in__c is true
             */
            if(newObj.conference360__Contact__c != null &&
               newObj.Marketing_Subscription_Opt_in__c &&
               newObj.conference360__Event__c != null)
            {
                this.attendees.add(newObj);
                this.events.add(newObj.conference360__Event__c);
            }
        }

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Attendee__c newObj = (conference360__Attendee__c) sobj;
            conference360__Attendee__c oldObj = (conference360__Attendee__c) oldRec;

            /**
             * PROCESS IF:
             * - Marketing_Subscription_Opt_in__c is true AND
             * - linked contact changed OR Marketing_Subscription_Opt_in__c changed AND
             * - linked contact AND linked event not null
             */
            if(newObj.Marketing_Subscription_Opt_in__c) {
                if((newObj.conference360__Contact__c != oldObj.conference360__Contact__c ||
                    newObj.Marketing_Subscription_Opt_in__c != oldObj.Marketing_Subscription_Opt_in__c) &&
                   newObj.conference360__Contact__c != null &&
                   newObj.conference360__Event__c != null)
                {
                    this.attendees.add(newObj);
                    this.events.add(newObj.conference360__Event__c);
                }
            }
        }

        public override void execute() {
            try {
                if(!this.attendees.isEmpty()) {
                    //query parent events to get subscription source campaign
                    Map<Id, conference360__Event__c> events = new Map<Id, conference360__Event__c>(
                        [SELECT Id, conference360__Campaign__c
                        FROM conference360__Event__c
                        WHERE Id IN :this.events]
                    );

                    Map<Id, String> campaignSourceByContactId = new Map<Id, String>();

                    for(conference360__Attendee__c iAtt : this.attendees) {
                        //group contacts by source campaign
                        conference360__Event__c event = events.get(iAtt.conference360__Event__c);
                        if(event != null) {
                            campaignSourceByContactId.put(iAtt.conference360__Contact__c, event.conference360__Campaign__c);
                        }
                    }

                    //get monash info and events from custom setting
                    Marketing_Subscription_List__c listSetting = Marketing_Subscription_List__c.getOrgDefaults();
                    Id mie = (Id) listSetting.MIE__c;

                    //dispatch event to create campaign members asynchronously
                    CampaignSubscriptionService service = new CampaignSubscriptionService(new Set<Id> { mie });
                    service.setMembersWithSource(campaignSourceByContactId);
                    service.runAsync();
                    service.execute();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

     /**
     * @description handles registration status change on before update context
     */
    public class RegistrationStatusHandler extends TriggerAbstract {

        Map<Id, conference360__Attendee__c> oldAttendeeMap = new Map<Id, conference360__Attendee__c>();
        Map<Id, conference360__Attendee__c> newAttendeeMap = new Map<Id, conference360__Attendee__c>();

        public override void process(SObject sobj, SObject oldRec) {

            conference360__Attendee__c newObj = (conference360__Attendee__c) sobj;
            conference360__Attendee__c oldObj = (conference360__Attendee__c) oldRec;

            /**
             * PROCESS IF:
             * - conference360__Registration_Status__c is changed
             */
            if(oldObj.conference360__Registration_Status__c !=
               newObj.conference360__Registration_Status__c)
                {
                    oldAttendeeMap.put(oldObj.Id,oldObj);
                    newAttendeeMap.put(newObj.Id,newObj);
                }
        }

        public override void execute() {
            try {
                if(!oldAttendeeMap.isEmpty() && !newAttendeeMap.isEmpty()) {
                	new BTAttendeeRegistrationStatusManager(oldAttendeeMap,newAttendeeMap).run();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * @description EPBBS-2087 Number Reg - Check In - Check in Guest Attendees in attendee group when Primary attendee checked in
     */
    public class CheckinGroupAttendee extends TriggerAbstract {

        public override void process(SObject sobj, SObject oldRec) {

            conference360__Attendee__c newObj = (conference360__Attendee__c) sobj;
            conference360__Attendee__c oldObj = (conference360__Attendee__c) oldRec;

            if(oldObj.conference360__Attendance_Status__c != newObj.conference360__Attendance_Status__c
            && newObj.conference360__Attendance_Status__c==BTAttendeeServices.ATTN_STATUS_ATTENDED &&
               newObj.is_Primary_Registrant__c==true && newObj.conference360__Attendee_Group__c != NULL)
                {
                  records.add(newObj);
                }
        }

        public override void execute() {
            try {

                if(!records.isEmpty()) {
                	new BTCheckinService(records).checkInAttendeeGroup();
                }

            } catch(Exception e) {

                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());

            } finally {

                LogUtilityException.getLimits();

            }
        }
    }

    /**
     * @description EPBBS-2183 Share newly inserted Attendee with existing event Staff
     */
    public class ShareAttendeeToEventStaff extends TriggerAbstract {
		
        private Set<Id>eventIdSet = new Set<Id>();
        private List<conference360__Attendee__c> attendeeList = new List<conference360__Attendee__c>();
        
        public override void process(SObject sobj) {
			
            conference360__Attendee__c newObj = (conference360__Attendee__c) sobj;

            if(newObj.conference360__Contact__c != null ||(newObj.conference360__Contact__c == null && newObj.is_Primary_Registrant__c))
                {
                  attendeeList.add(newObj);
                  eventIdSet.add(newObj.conference360__Event__c);
                }
        }

        public override void execute() {
            
                if(!attendeeList.isEmpty()) {
                	new BTAttendeeServices().shareAttendeeToEventStaff(attendeeList,eventidSet);
                }

        }
    }

    public class ValidateRegistration extends TriggerAbstract {
        List<conference360__Attendee__c> attendeeList = new List<conference360__Attendee__c>();
        
        public override void process(SObject sobj) {
            conference360__Attendee__c newObj = (conference360__Attendee__c) sobj;
            if(newObj.conference360__Contact__c != null && newObj.conference360__Event__c != null 
               && string.isNotBlank(newObj.conference360__Registration_Status__c) && 
               newObj.conference360__Registration_Status__c == BTAttendeeServices.REG_STATUS_REGISTERED){
                this.attendeeList.add(newObj);
            }
        }

        public override void execute() {
            try {
                new BTAttendeeServices().validateRegistration(this.attendeeList);
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }
}