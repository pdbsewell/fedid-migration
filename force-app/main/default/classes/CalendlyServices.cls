/**
 * @author      tom.gangemi@monash.edu
 * @description Services for Calendly event data
 * @revision    20/06/2022 - Tom Gangemi - SA-1481 Created
 */
public without sharing class CalendlyServices {
    // without sharing used so that integration user doesn't require access to Case and Contact

    public static final String EVENT_CREATED = 'invitee.created';
    public static final String EVENT_CANCELED = 'invitee.canceled';
    public static final Id BOOKING_RECORD_TYPE = SObjectType.Event_Booking__c.getRecordTypeInfosByDeveloperName().get('Calendly').getRecordTypeId();
    private static final Boolean DELETE_ACTIONS = true;

    /**
     * - Take incoming CalendlyAction records and convert them into Event_Booking__c
     * - Update Event Bookings with cancellation info
     * - Link Event Bookings to relevant Case and Contact
     */
    public class processActions extends TriggerAbstract {

        // incoming actions by event ID and action
        Map<String,Map<String,Calendly__CalendlyAction__c>> eventsByActionAndUUID = new Map<String,Map<String,Calendly__CalendlyAction__c>>();
        Calendly__CalendlyAction__c[] allRecords = new Calendly__CalendlyAction__c[0];

        public override void process(SObject record) {
            Calendly__CalendlyAction__c ca = (Calendly__CalendlyAction__c)record;
            allRecords.add(ca);
            if(String.isNotBlank(ca.Calendly__EventUuid__c)) {
                Map<String,Calendly__CalendlyAction__c> eventsByAction = eventsByActionAndUUID.get(ca.Calendly__EventUuid__c);
                if(eventsByAction == null) {
                    eventsByAction = new Map<String,Calendly__CalendlyAction__c>();
                    eventsByActionAndUUID.put(ca.Calendly__EventUuid__c + ca.Calendly__InviteeUuid__c, eventsByAction);
                }
                eventsByAction.put(ca.Name, ca);
            }
        }

        public override void execute() {

            // retrieve existing bookings
            Map<String,Event_Booking__c> existingBookingsByUUID = new Map<String,Event_Booking__c>();
            for(Event_Booking__c eb :[
                SELECT UUID__c, Contact__c FROM Event_Booking__c
                WHERE UUID__c IN :eventsByActionAndUUID.keySet() AND RecordType.DeveloperName = 'Calendly'
            ]){
                existingBookingsByUUID.put(eb.UUID__c, eb);
            }

            Event_Booking__c[] bookingsToUpsert = new Event_Booking__c[0];

            Set<Id> caseIds = new Set<Id>();

            for(String uuid :eventsByActionAndUUID.keySet()) {
                // for each incoming event
                Map<String, Calendly__CalendlyAction__c> eventsByAction = eventsByActionAndUUID.get(uuid);
                for(String action :eventsByAction.keySet()) {
                    // for each event's actions
                    Calendly__CalendlyAction__c ca = eventsByAction.get(action);

                    Event_Booking__c eventBooking = existingBookingsByUUID.get(uuid);

                    if(action == EVENT_CREATED && eventBooking == null) {
                        // new event received
                        String rawId = ca.Calendly__ObjectId__c;
                        if(String.isNotBlank(rawId) && rawId instanceof Id) {
                            // new event has a valid SFID, create it
                            Event_Booking__c newBooking = createBooking(ca);

                            Id sfId = Id.valueOf(rawId);
                            if(sfId.getSobjectType() == Case.SObjectType) {
                                caseIds.add(sfId);
                            }
                            if(newBooking != null) {
                                bookingsToUpsert.add(newBooking);
                            }
                        }
                    }

                    if(action == EVENT_CANCELED && eventBooking != null) {
                        // received cancellation for existing event
                        eventBooking.Cancelled_Reason__c = ca.Calendly__EventCancelReason__c;
                        eventBooking.Cancelled_Date_Time__c = ca.Calendly__InviteeCanceledAt__c;
                        eventBooking.Is_Rescheduled__c = ca.Calendly__IsRescheduled__c;
                        bookingsToUpsert.add(eventBooking);
                    }
                }
            }

            if(caseIds.size() > 0) {
                // for incoming actions with a Case Id, get the Case's Contact and link it to the new event
                Map<Id,Id> contactIdsByCaseId = new Map<Id,Id>();
                for(Case c :[SELECT ContactId FROM Case WHERE Id IN :caseIds]) {
                    contactIdsByCaseId.put(c.Id, c.ContactId);
                }
                for(Event_Booking__c eb :bookingsToUpsert) {
                    if(eb.Contact__c == null && contactIdsByCaseId.containsKey(eb.Case__c)) {
                        eb.Contact__c = contactIdsByCaseId.get(eb.Case__c);
                    }
                }
            }

            upsert bookingsToUpsert;

            if(DELETE_ACTIONS) {
                // delete actions after processing
                delete [SELECT Id FROM Calendly__CalendlyAction__c WHERE Id IN :allRecords];
            }
        }
    }

    /**
     * Create Event_Booking__c object from incoming Calendly action
     */
    public static Event_Booking__c createBooking(Calendly__CalendlyAction__c ca) {
        Event_Booking__c eb = new Event_Booking__c();

        Id sfId = Id.valueOf(ca.Calendly__ObjectId__c);
        if(sfId.getSobjectType() == Case.SObjectType) {
            eb.Case__c = sfId;
        } else {
            return null;
        }

        eb.RecordTypeId = BOOKING_RECORD_TYPE;
        eb.Start_Date_Time__c = ca.Calendly__EventStartTime__c;
        eb.Duration_In_Minutes__c = Integer.valueOf(ca.Calendly__EventTypeDuration__c);
        eb.End_Date_Time__c = eb.Start_Date_Time__c.addMinutes(Integer.valueOf(eb.Duration_In_Minutes__c));
        eb.UUID__c = ca.Calendly__EventUuid__c + ca.Calendly__InviteeUuid__c;
        eb.Name = (ca.Calendly__InviteeName__c + ' - ' + ca.Calendly__EventTypeName__c).abbreviate(80);
        eb.Is_Rescheduled__c = ca.Calendly__IsRescheduled__c;
        eb.Booking_Form_Response__c = createResponsesText(ca);
        eb.Location__c = ca.Calendly__Location__c;

        if(ca.Calendly__UtmSource__c == 'SalesforceWidget') {
            // there isn't a proper way to map extra metadata - so it's fed into the UTM fields
            // UtmTerm__c = Calendar Name
            // UtmMedium__c = Calendly_Event_Type__c
            // UtmContent__c = UserId

            eb.Calendar_Name__c = ca.Calendly__UtmTerm__c;
            if(String.isNotBlank(ca.Calendly__UtmMedium__c) && ca.Calendly__UtmMedium__c instanceof Id) {
                Id eventTypeId = Id.valueOf(ca.Calendly__UtmMedium__c);
                if(eventTypeId.getSobjectType() == Calendly_Event_Type__c.getSObjectType()) {
                    eb.Calendly_Event_Type__c = ca.Calendly__UtmMedium__c;
                }
            }
            if(String.isNotBlank(ca.Calendly__UtmContent__c) && ca.Calendly__UtmContent__c instanceof  Id) {
                Id userId = Id.valueOf(ca.Calendly__UtmContent__c);
                if(userId.getSobjectType() == User.getSObjectType()) {
                    eb.Booked_By__c = userId;
                }
            }
        }

        return eb;
    }

    public static String createResponsesText(Calendly__CalendlyAction__c ca) {
        String questionFieldPrefix = 'Calendly__CustomQuestion';
        String responseFieldPrefix = 'Calendly__CustomResponse';
        Integer numQuestions = 10;

        String[] results = new String[0];
        for(Integer i = 1; i <= numQuestions; i++) {
            String question = (String)ca.get(questionFieldPrefix + i + '__c');
            if(String.isNotBlank(question)) {
                String answer = (String)ca.get(responseFieldPrefix + i + '__c');
                results.add('Q' + i + ') ' + question + '\nA' + i + ') ' + answer);
            }
        }
        return String.join(results,'\n-------------------\n');
    }

}