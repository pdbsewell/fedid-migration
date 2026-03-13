/**
 * @author      tom.gangemi@monash.edu
 * @description Services for Calendly event data
 * @revision    20/06/2022 - Tom Gangemi - SA-1481 Created
 */
@IsTest
public class CalendlyServices_Test {

    private static Case createCase(Id contactId) {
        TriggerCommon.disableTrigger('Case');
        Case cse = new Case(ContactId = contactId);
        insert cse;
        return cse;
    }

    private static Contact createContact() {
        TriggerCommon.disableTrigger('Contact');
        Contact cont = new Contact(FirstName = 'Bob', LastName = 'Loblaw');
        insert cont;
        return cont;
    }

    private static Integer reqId = 1;
    private static String nextReqId() {
        return String.valueOf(++reqId);
    }

    private static Calendly__CalendlyAction__c createAction() {
        Calendly__CalendlyAction__c action = new Calendly__CalendlyAction__c(
            Calendly__EventCreatedAt__c = Datetime.now(),
            Calendly__EventEndTime__c = Datetime.now(),
            Calendly__EventPrimaryPublisherEmail__c = 'publisher@example.com',
            Calendly__EventPrimaryPublisherName__c = 'Publisher Name',
            Calendly__EventSubject__c = 'Subject',
            Calendly__EventTypeKind__c = 'EventTypeKind',
            Calendly__EventTypeName__c = 'EventTypeName',
            Calendly__EventTypeSlug__c = 'EventTypeSlug',
            Calendly__InviteeCreatedAt__c = Datetime.now(),
            Calendly__InviteeEmail__c = 'invitee@example.com',
            Calendly__InviteeUuid__c = '777',
            Calendly__RequestId__c = nextReqId(),
            Calendly__UtmSource__c = 'SalesforceWidget'
        );
        return action;
    }

    @IsTest static void createEventThenCancel() {
        // Arrange

        Calendly_Event_Type__c cet = new Calendly_Event_Type__c();
        cet.Name = 'Support Sesh';
        cet.Calendar_Name__c = 'Monash Connect';
        insert cet;

        Contact cont = createContact();
        Case cse = createCase(cont.Id);

        Calendly__CalendlyAction__c createAction1 = createAction();
        createAction1.Calendly__EventUuid__c = 'EVUUID_001';
        createAction1.Name = CalendlyServices.EVENT_CREATED;
        createAction1.Calendly__ObjectId__c = cse.Id;
        createAction1.Calendly__EventStartTime__c = Datetime.now().addHours(3);
        createAction1.Calendly__EventTypeDuration__c = 20;
        createAction1.Calendly__UtmMedium__c = cet.Id;
        createAction1.Calendly__UtmTerm__c = cet.Calendar_Name__c;
        Calendly__CalendlyAction__c createAction2 = createAction();
        createAction2.Calendly__EventUuid__c = 'EVUUID_002';
        createAction2.Name = CalendlyServices.EVENT_CREATED;
        createAction2.Calendly__ObjectId__c = cse.Id;
        createAction2.Calendly__EventStartTime__c = Datetime.now().addDays(1);
        createAction2.Calendly__EventTypeDuration__c = 15;

        // Act
        Test.startTest();
        // create two events
        insert new Calendly__CalendlyAction__c[]{createAction1, createAction2};
        Event_Booking__c[] results01 = [
            SELECT Case__c, Contact__c, UUID__c, Start_Date_Time__c, Duration_In_Minutes__c,
                Calendly_Event_Type__c, Calendar_Name__c
            FROM Event_Booking__c WHERE RecordType.DeveloperName = 'Calendly'
        ];

        // cancel one of them
        Calendly__CalendlyAction__c cancelAction1 = createAction1.clone();
        cancelAction1.Name = CalendlyServices.EVENT_CANCELED;
        cancelAction1.Calendly__EventCancelReason__c = 'No longer required';
        cancelAction1.Calendly__InviteeCanceledAt__c = Datetime.now().addMinutes(-2);
        cancelAction1.Calendly__RequestId__c = nextReqId();
        insert cancelAction1;
        Test.stopTest();

        Event_Booking__c[] results02 = [
            SELECT UUID__c, Cancelled_Reason__c, Cancelled_Date_Time__c
            FROM Event_Booking__c WHERE RecordType.DeveloperName = 'Calendly'
        ];

        // Assert
        System.assertEquals(2, results01.size());
        for(Event_Booking__c e :results01) {
            // verify that both events created
            System.assertEquals(cse.Id, e.Case__c);
            System.assertEquals(cont.Id, e.Contact__c);
            if(e.UUID__c == (createAction1.Calendly__EventUuid__c + createAction1.Calendly__InviteeUuid__c)) {
                System.assertEquals(createAction1.Calendly__EventStartTime__c, e.Start_Date_Time__c);
                System.assertEquals(createAction1.Calendly__EventTypeDuration__c, e.Duration_In_Minutes__c);
                System.assertEquals(cet.Id, e.Calendly_Event_Type__c);
                System.assertEquals(cet.Calendar_Name__c, e.Calendar_Name__c);
            } else if(e.UUID__c == (createAction2.Calendly__EventUuid__c + createAction2.Calendly__InviteeUuid__c)) {
                System.assertEquals(createAction2.Calendly__EventStartTime__c, e.Start_Date_Time__c);
                System.assertEquals(createAction2.Calendly__EventTypeDuration__c, e.Duration_In_Minutes__c);
            } else {
                System.assert(false, 'Invalid UUID found: ' + e.UUID__c);
            }
        }

        System.assertEquals(2, results02.size());
        for(Event_Booking__c e :results02) {
            // verify that only one event cancelled
            if(e.UUID__c == (createAction1.Calendly__EventUuid__c + createAction1.Calendly__InviteeUuid__c)) {
                System.assertEquals(cancelAction1.Calendly__InviteeCanceledAt__c, e.Cancelled_Date_Time__c);
                System.assertEquals(cancelAction1.Calendly__EventCancelReason__c, e.Cancelled_Reason__c);
            } else if(e.UUID__c == (createAction2.Calendly__EventUuid__c + createAction2.Calendly__InviteeUuid__c)) {
                System.assertEquals(null, e.Cancelled_Date_Time__c);
                System.assertEquals(null, e.Cancelled_Reason__c);
            } else {
                System.assert(false, 'Invalid UUID found: ' + e.UUID__c);
            }
        }
    }

    @IsTest static void createEventWithQuestions() {
        // Arrange
        Contact con = createContact();
        Case cse = createCase(con.Id);

        Calendly__CalendlyAction__c createAction1 = createAction();
        createAction1.Calendly__EventUuid__c = '2b30f0a5-dee8-4295-8a15-a15a168fc5c3';
        createAction1.Calendly__InviteeUuid__c = 'ca5b3aa8-3b7f-4d03-9935-53b6113bab7d';
        createAction1.Name = CalendlyServices.EVENT_CREATED;
        createAction1.Calendly__ObjectId__c = cse.Id;
        createAction1.Calendly__EventStartTime__c = Datetime.now().addDays(3);
        createAction1.Calendly__EventTypeDuration__c = 45;
        createAction1.Calendly__UtmSource__c = 'SalesforceWidget';
        createAction1.Calendly__UtmTerm__c = 'MC/CA';
        createAction1.Calendly__CustomQuestion1__c = 'What is your favourite colour?';
        createAction1.Calendly__CustomResponse1__c = 'Blue! ...No!';
        createAction1.Calendly__CustomQuestion2__c = 'What is the airspeed velocity of an unladen swallow?';
        createAction1.Calendly__CustomResponse2__c = 'African or European?';
        createAction1.Calendly__CustomQuestion3__c = 'What is your quest?';
        createAction1.Calendly__CustomResponse3__c = 'To seek the Holy Grail';

        // Act
        Test.startTest();
        insert createAction1;
        Test.stopTest();

        // Assert
        Event_Booking__c[] results = [
            SELECT Case__c, Contact__c, Start_Date_Time__c, Duration_In_Minutes__c, Booking_Form_Response__c
            FROM Event_Booking__c
        ];
        System.assertEquals(1, results.size());
        Event_Booking__c result = results[0];
        System.assertEquals(cse.Id, result.Case__c);
        System.assertEquals(con.Id, result.Contact__c);
        System.assertEquals(createAction1.Calendly__EventStartTime__c, result.Start_Date_Time__c);
        System.assertEquals(createAction1.Calendly__EventTypeDuration__c, result.Duration_In_Minutes__c);

        System.assert(result.Booking_Form_Response__c.contains('Q1) ' + createAction1.Calendly__CustomQuestion1__c), result.Booking_Form_Response__c);
        System.assert(result.Booking_Form_Response__c.contains('A1) ' + createAction1.Calendly__CustomResponse1__c), result.Booking_Form_Response__c);
        System.assert(result.Booking_Form_Response__c.contains('Q3) ' + createAction1.Calendly__CustomQuestion3__c), result.Booking_Form_Response__c);
        System.assert(result.Booking_Form_Response__c.contains('A3) ' + createAction1.Calendly__CustomResponse3__c), result.Booking_Form_Response__c);
    }

}