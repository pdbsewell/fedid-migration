/**
 * @author      tom.gangemi@monash.edu
 * @description Controller for CalendlyWidget and CalendlyConfigWidget
 * @revision    20/06/2022 - Tom Gangemi - SA-1481 Created
 */
@IsTest
public with sharing class CalendlyController_Test {

    private static final String MONCON_RECTYPE = 'Monash_Connect_Enquiry';
    private static final Id MONCON_RECTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(MONCON_RECTYPE).getRecordTypeId();
    private static final String COMPLAINT_RECTYPE = 'Complaint';
    private static final Id COMPLAINT_RECTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(COMPLAINT_RECTYPE).getRecordTypeId();
    private static final String STUDENT_RECTYPE = 'Student';
    private static final Id STUDENT_RECTYPEID = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(STUDENT_RECTYPE).getRecordTypeId();

    @TestSetup static void setup() {
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('Case');
    }

    @IsTest static void groupIsVisibleForRecordType() {
        // Arrange
        Calendly_Event_Group__c noTypeGroup = new Calendly_Event_Group__c();
        Calendly_Event_Group__c monConGroup = new Calendly_Event_Group__c(Case_Record_Types__c=MONCON_RECTYPE);
        Calendly_Event_Group__c bothGroups = new Calendly_Event_Group__c(Case_Record_Types__c=MONCON_RECTYPE+','+COMPLAINT_RECTYPE);
        Calendly_Event_Group__c studentGroup = new Calendly_Event_Group__c(Contact_Record_Types__c=STUDENT_RECTYPE);
        SObjectType caseType = Case.SObjectType;
        SObjectType contactType = Contact.SObjectType;

        Test.startTest();
        // Act / Assert
        // cases
        System.assertEquals(true, CalendlyController.groupIsVisibleForRecordType(noTypeGroup, caseType, MONCON_RECTYPE));
        System.assertEquals(true, CalendlyController.groupIsVisibleForRecordType(noTypeGroup, caseType, COMPLAINT_RECTYPE));
        System.assertEquals(true, CalendlyController.groupIsVisibleForRecordType(monConGroup, caseType, MONCON_RECTYPE));
        System.assertEquals(false, CalendlyController.groupIsVisibleForRecordType(monConGroup, caseType, COMPLAINT_RECTYPE));
        System.assertEquals(true, CalendlyController.groupIsVisibleForRecordType(bothGroups, caseType, MONCON_RECTYPE));
        System.assertEquals(true, CalendlyController.groupIsVisibleForRecordType(studentGroup, caseType, MONCON_RECTYPE));
        // contacts
        System.assertEquals(true, CalendlyController.groupIsVisibleForRecordType(studentGroup, contactType, STUDENT_RECTYPE));
        System.assertEquals(false, CalendlyController.groupIsVisibleForRecordType(studentGroup, contactType, MONCON_RECTYPE));
        Test.stopTest();
    }

    @IsTest static void testGetObjectData() {
        Contact cont = new Contact(LastName='Personson', RecordTypeId=STUDENT_RECTYPEID, Email='person@example.com');
        insert cont;
        Case cse = new Case(RecordTypeId = MONCON_RECTYPEID, ContactId = cont.Id);
        insert cse;

        // Act
        Test.startTest();
        CalendlyController.ObjectData od = CalendlyController.getObjectData(cse.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(cont.Email, od.contact.Email);
        System.assertEquals(MONCON_RECTYPE, od.recordTypeDevName);
    }

    @IsTest static void groupIsVisibleForPublicGroups() {
        Calendly_Event_Group__c noPublicGroup = new Calendly_Event_Group__c();
        Calendly_Event_Group__c publicGroupFoo = new Calendly_Event_Group__c(Public_Groups__c = 'foo');
        Calendly_Event_Group__c publicGroupBar = new Calendly_Event_Group__c(Public_Groups__c = 'bar');
        Calendly_Event_Group__c publicGroupFooBar = new Calendly_Event_Group__c(Public_Groups__c = 'foo, bar');

        // Act / Assert
        Test.startTest();
        System.assertEquals(true, CalendlyController.groupIsVisibleForPublicGroups(noPublicGroup, new Set<String>()));
        System.assertEquals(true, CalendlyController.groupIsVisibleForPublicGroups(noPublicGroup, new Set<String>{'Foo'}));
        System.assertEquals(true, CalendlyController.groupIsVisibleForPublicGroups(publicGroupFoo, new Set<String>{'Foo'}));
        System.assertEquals(true, CalendlyController.groupIsVisibleForPublicGroups(publicGroupBar, new Set<String>{'Foo','Bar'}));
        System.assertEquals(true, CalendlyController.groupIsVisibleForPublicGroups(publicGroupFooBar, new Set<String>{'XXX','Bar'}));
        System.assertEquals(true, CalendlyController.groupIsVisibleForPublicGroups(publicGroupFooBar, new Set<String>{'Foo','Bar'}));

        System.assertEquals(false, CalendlyController.groupIsVisibleForPublicGroups(publicGroupFoo, new Set<String>()));
        System.assertEquals(false, CalendlyController.groupIsVisibleForPublicGroups(publicGroupBar, new Set<String>{'Foo','XXX'}));
        System.assertEquals(false, CalendlyController.groupIsVisibleForPublicGroups(publicGroupFooBar, new Set<String>()));
        Test.stopTest();
    }

    @IsTest static void getEventsByObjectType() {
        Case cse = new Case(RecordTypeId = MONCON_RECTYPEID);
        insert cse;
        Contact cont = new Contact(LastName='Personson', RecordTypeId=STUDENT_RECTYPEID);
        insert cont;

        // create groups
        Calendly_Event_Group__c caseGroup = new Calendly_Event_Group__c(SObject_Types__c = 'Case');
        Calendly_Event_Group__c contactGroup = new Calendly_Event_Group__c(SObject_Types__c = 'Contact');
        Calendly_Event_Group__c bothGroup = new Calendly_Event_Group__c(SObject_Types__c = 'Contact;Case');
        Calendly_Event_Group__c noneGroup = new Calendly_Event_Group__c(SObject_Types__c = '');
        insert new Calendly_Event_Group__c[]{caseGroup, contactGroup, bothGroup, noneGroup};

        // create events
        Calendly_Event_Type__c cet01 = new Calendly_Event_Type__c(Name = '01');
        Calendly_Event_Type__c cet02 = new Calendly_Event_Type__c(Name = '02');
        Calendly_Event_Type__c cet03 = new Calendly_Event_Type__c(Name = '03');
        Calendly_Event_Type__c cet04 = new Calendly_Event_Type__c(Name = '04');
        Calendly_Event_Type__c cet05 = new Calendly_Event_Type__c(Name = '05');
        insert new Calendly_Event_Type__c[]{cet01, cet02, cet03, cet04, cet05};

        // create links between events and groups
        Calendly_Event_Type_Group__c cetg01 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = caseGroup.Id, Calendly_Event_Type__c = cet01.Id
        );
        Calendly_Event_Type_Group__c cetg02 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = contactGroup.Id, Calendly_Event_Type__c = cet02.Id
        );
        Calendly_Event_Type_Group__c cetg03 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = bothGroup.Id, Calendly_Event_Type__c = cet03.Id
        );
        Calendly_Event_Type_Group__c cetg04 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = noneGroup.Id, Calendly_Event_Type__c = cet04.Id
        );
        Calendly_Event_Type_Group__c cetg05 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = noneGroup.Id, Calendly_Event_Type__c = cet05.Id
        );
        insert new Calendly_Event_Type_Group__c[]{cetg01, cetg02, cetg03, cetg04, cetg05};

        // validate Case
        Test.startTest();
        validateRecordsEvents(cse.Id, new String[]{cet01.Name, cet03.Name, cet04.Name, cet05.Name});

        // validate Contact
        validateRecordsEvents(cont.Id, new String[]{cet02.Name, cet03.Name, cet04.Name, cet05.Name});
        Test.stopTest();
    }

    @IsTest static void getEventsMixed() {
        // create users and groups
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User user1 = (User)TestDataFactory.createSObject(new User());
        user1.ProfileId = profileId;
        user1.Username = 'calendly_getEventsMixed_test01@example.com';
        User user2 = (User)TestDataFactory.createSObject(new User());
        user2.ProfileId = profileId;
        user2.Username = 'calendly_getEventsMixed_test02@example.com';
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new User[]{user1, user2};
            // create and assign public group
            Group pGroup = new Group(Name = 'Faculty', DeveloperName = 'Faculty', Type = 'Regular');
            insert pGroup;
            GroupMember member = new GroupMember(GroupId = pGroup.Id, UserOrGroupId = user2.Id);
            insert member;
        }

        Case caseMonCon = new Case(RecordTypeId = MONCON_RECTYPEID);
        Case caseComplaint = new Case(RecordTypeId = COMPLAINT_RECTYPEID);
        insert new Case[]{caseMonCon, caseComplaint};

        // create groups
        Calendly_Event_Group__c caseMonConGroup = new Calendly_Event_Group__c(
            SObject_Types__c = 'case', Case_Record_Types__c = MONCON_RECTYPE);
        Calendly_Event_Group__c caseMonConFacultyGroup = new Calendly_Event_Group__c(
            SObject_Types__c = 'Case', Case_Record_Types__c = MONCON_RECTYPE, Public_Groups__c = 'Faculty');
        Calendly_Event_Group__c caseComplaintFacultyGroup = new Calendly_Event_Group__c(
            SObject_Types__c = 'Case', Case_Record_Types__c = COMPLAINT_RECTYPE, Public_Groups__c = 'Faculty');
        Calendly_Event_Group__c caseSupportGroup = new Calendly_Event_Group__c(
            SObject_Types__c = 'Case', Public_Groups__c = 'Support');
        Calendly_Event_Group__c contactGroup = new Calendly_Event_Group__c(
            SObject_Types__c = 'Contact');
        insert new Calendly_Event_Group__c[]{
            caseMonConGroup, caseMonConFacultyGroup, caseComplaintFacultyGroup, caseSupportGroup, contactGroup
        };

        // create events
        Calendly_Event_Type__c cet01 = new Calendly_Event_Type__c(Name = '01');
        Calendly_Event_Type__c cet02 = new Calendly_Event_Type__c(Name = '02');
        Calendly_Event_Type__c cet03 = new Calendly_Event_Type__c(Name = '03');
        Calendly_Event_Type__c cet04 = new Calendly_Event_Type__c(Name = '04');
        Calendly_Event_Type__c cet05 = new Calendly_Event_Type__c(Name = '05');
        insert new Calendly_Event_Type__c[]{cet01, cet02, cet03, cet04, cet05};

        // create links between events and groups
        Calendly_Event_Type_Group__c cetg01 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = caseMonConGroup.Id, Calendly_Event_Type__c = cet01.Id
        );
        Calendly_Event_Type_Group__c cetg02 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = caseMonConFacultyGroup.Id, Calendly_Event_Type__c = cet02.Id
        );
        Calendly_Event_Type_Group__c cetg03 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = caseComplaintFacultyGroup.Id, Calendly_Event_Type__c = cet03.Id
        );
        Calendly_Event_Type_Group__c cetg04 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = caseSupportGroup.Id, Calendly_Event_Type__c = cet04.Id
        );
        Calendly_Event_Type_Group__c cetg05 = new Calendly_Event_Type_Group__c(
            Calendly_Event_Group__c = contactGroup.Id, Calendly_Event_Type__c = cet05.Id
        );
        insert new Calendly_Event_Type_Group__c[]{cetg01, cetg02, cetg03, cetg04, cetg05};

        Test.startTest();
        System.runAs(user1) {
            // validate without public group
            validateRecordsEvents(caseMonCon.Id, new String[]{cet01.Name});
            validateRecordsEvents(caseComplaint.Id, new String[0]);
        }
        System.runAs(user2) {
            // validate with public group
            validateRecordsEvents(caseMonCon.Id, new String[]{cet01.Name, cet02.Name});
            validateRecordsEvents(caseComplaint.Id, new String[]{cet03.Name});
        }
        Test.stopTest();
    }

    private static void validateRecordsEvents(Id recordId, String[] eventNames) {
        CalendlyController.WidgetData result = CalendlyController.getWidgetData(recordId);
        System.assertEquals(eventNames.size(), result.events.size());
        if(eventNames.isEmpty()) return;
        Set<String> caseEventNames = new Set<String>();
        for(CalendlyController.CalendlyEvent ce :result.events) {
            caseEventNames.add(ce.name);
        }
        System.assert(caseEventNames.containsAll(eventNames), caseEventNames);
    }

    @isTest static void testConfig() {
        // Setup
        Calendly_Event_Group__c group01 = new Calendly_Event_Group__c(Name='Group 01');
        Calendly_Event_Group__c group02 = new Calendly_Event_Group__c(Name='Group 02');
        Calendly_Event_Group__c group03 = new Calendly_Event_Group__c(Name='Group 03');
        insert new Calendly_Event_Group__c[]{group01, group02, group03};
        Calendly_Event_Type__c t01 = new Calendly_Event_Type__c(Name = '01');
        Calendly_Event_Type__c t02 = new Calendly_Event_Type__c(Name = '02');
        Calendly_Event_Type__c t03 = new Calendly_Event_Type__c(Name = '03');
        insert new Calendly_Event_Type__c[]{t01, t02, t03};

        // Verify return no linked events correctly
        Test.startTest();
        System.assertEquals(0, CalendlyController.getEventTypesInGroup(group01.Id).size());
        System.assertEquals(3, CalendlyController.getEventTypesNotInGroup(group01.Id).size());

        // Link some events
        CalendlyController.addEventsToGroup(group01.Id, new Id[]{t01.Id, t02.Id});
        CalendlyController.addEventsToGroup(group02.Id, new Id[]{t01.Id});

        // Verify events got linked
        Calendly_Event_Type_Group__c[] links = [
            SELECT Calendly_Event_Group__c, Calendly_Event_Type__c FROM Calendly_Event_Type_Group__c
            ORDER BY Calendly_Event_Group__r.Name ASC, Calendly_Event_Type__r.Name ASC
        ];
        System.assertEquals(3, links.size());
        System.assert(links[0].Calendly_Event_Group__c == group01.Id && links[0].Calendly_Event_Type__c == t01.Id);
        System.assert(links[1].Calendly_Event_Group__c == group01.Id && links[1].Calendly_Event_Type__c == t02.Id);
        System.assert(links[2].Calendly_Event_Group__c == group02.Id && links[2].Calendly_Event_Type__c == t01.Id);

        // Verify linked events are returned
        System.assertEquals(2, CalendlyController.getEventTypesInGroup(group01.Id).size());
        System.assertEquals(1, CalendlyController.getEventTypesNotInGroup(group01.Id).size());

        Calendly_Event_Type__c[] inGroup02 = CalendlyController.getEventTypesInGroup(group02.Id);
        System.assertEquals(1, inGroup02.size());
        System.assertEquals(t01.Id, inGroup02[0].Id);
        System.assertEquals(2, CalendlyController.getEventTypesNotInGroup(group02.Id).size());

        System.assertEquals(3, CalendlyController.getEventTypesNotInGroup(group03.Id).size());
        Test.stopTest();
    }


}