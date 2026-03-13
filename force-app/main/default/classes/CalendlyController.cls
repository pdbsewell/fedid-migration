/**
 * @author      tom.gangemi@monash.edu
 * @description Controller for CalendlyWidget and CalendlyConfigWidget
 * @revision    20/06/2022 - Tom Gangemi - SA-1481 Created
 */
public with sharing class CalendlyController {

    /**
     * Data used to construct booking widget
     */
    public class WidgetData {
        @AuraEnabled public ContactData contact; // information of contact being booked against
        @AuraEnabled public CalendlyEvent[] events; // list of events available to user for booking
    }

    public class ContactData {
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String personId;
    }

    /**
     * Represents a bookable Calendly Event Type
     */
    public class CalendlyEvent {
        public CalendlyEvent(String name, String url, String personIdAnswerKey) {
            this.name = name;
            this.url = url;
            this.personIdAnswerKey = personIdAnswerKey;
        }
        @AuraEnabled public String name; // name of event type
        @AuraEnabled public String calendarName;
        @AuraEnabled public String url; // event type booking URL
        @AuraEnabled public String personIdAnswerKey; // key passed to custom answers for personId
        @AuraEnabled public Id eventTypeId; // Salesforce Calendly_Event_Type__c.Id
    }

    /**
     * Wraps target sobject so that widget can be invoked from Contact or Case
     */
    public class ObjectData {
        public Contact contact;
        public String recordTypeDevName;
        public SObjectType objectType;
    }

    // returns True if the group is visible for the given object and record type
    public static Boolean groupIsVisibleForRecordType(Calendly_Event_Group__c eventGroup, SObjectType objType, String recordType) {
        String recordTypes = null;
        if(objType == Contact.SObjectType) {
            recordTypes = eventGroup.Contact_Record_Types__c;
        } else if(objType == Case.SObjectType) {
            recordTypes = eventGroup.Case_Record_Types__c;
        }
        if(String.isNotBlank(recordTypes)) {
            // check if group contains the given recordType
            Set<String> rtSet = new Set<String>(recordTypes.toLowerCase().deleteWhitespace().split(','));
            return rtSet.contains(recordType.toLowerCase());
        } else {
            // there is no recordType restriction on this group
            return true;
        }
    }

    // return True if the group is visible for the given set of public groups
    public static Boolean groupIsVisibleForPublicGroups(Calendly_Event_Group__c eventGroup, Set<String> publicGroups) {
        if(String.isNotBlank(eventGroup.Public_Groups__c)) {
            // if the event group has public groups defined, the user must be a member of at least one of them
            Set<String> pbSet = new Set<String>();
            for(String pg :eventGroup.Public_Groups__c.toLowerCase().split(',')) {
                pbSet.add(pg.trim());
            }
            for(String pg :publicGroups) {
                if(pbSet.contains(pg.toLowerCase().trim())) {
                    // found matching group
                    return true;
                }
            }
            // no group found
            return false;
        } else {
            return true;
        }
    }

    /**
     * Given a supported sobject Id, return related Contact info
     */
    public static ObjectData getObjectData(Id recordId) {
        ObjectData od = new ObjectData();
        od.objectType = recordId.getSobjectType();

        // get the given record's record type
        if(od.objectType == Contact.SObjectType) {
            od.contact = [
                SELECT RecordType.DeveloperName, Name, Email, Person_ID__c
                FROM Contact WHERE Id = :recordId
            ];
            od.recordTypeDevName = od.contact.RecordType.DeveloperName;
        }
        else if(od.objectType == Case.SObjectType) {
            Case cse = [
                SELECT RecordType.DeveloperName, Contact.Name, Contact.Email, Contact.Person_ID__c
                FROM Case WHERE Id = :recordId
            ];
            od.contact = cse.Contact;
            od.recordTypeDevName = cse.RecordType.DeveloperName;
        } else {
            throw new IllegalArgumentException('Unsupported SObject Type');
        }

        return od;
    }

    /**
     * Return all necessary data to construct widget for a given record Id
     */
    @AuraEnabled
    public static WidgetData getWidgetData(Id recordId) {
        ObjectData od = getObjectData(recordId);

        Set<String> usersGroups = new Set<String>();
        for(GroupMember membership :[
            SELECT Group.DeveloperName FROM GroupMember
            WHERE Group.Type = 'Regular' AND UserOrGroupId = :UserInfo.getUserId()
        ]) {
            usersGroups.add(membership.Group.DeveloperName);
        }

        Map<Id,Calendly_Event_Group__c> eventGroupsById = new Map<Id,Calendly_Event_Group__c>();

        for(Calendly_Event_Group__c eventGroup :[
            SELECT Contact_Record_Types__c, Case_Record_Types__c, Public_Groups__c
            FROM Calendly_Event_Group__c
            WHERE Active__c = TRUE AND SObject_Types__c INCLUDES (:String.valueOf(od.objectType),'')
        ]) {
            // for each active Event Group, filtered by object type

            Boolean validRecordType = groupIsVisibleForRecordType(eventGroup, od.objectType, od.recordTypeDevName);

            Boolean validPublicGroup = groupIsVisibleForPublicGroups(eventGroup, usersGroups);

            if(validRecordType && validPublicGroup) {
                eventGroupsById.put(eventGroup.Id, eventGroup);
            }
        }

        // create the return data
        Set<Id> eventIds = new Set<Id>();
        CalendlyEvent[] events = new CalendlyEvent[0];
        for(Calendly_Event_Type_Group__c evtg :[
            SELECT Calendly_Event_Group__c, Calendly_Event_Type__r.Name, Calendly_Event_Type__r.Event_URL__c,
                Calendly_Event_Type__r.Calendar_Name__c, Calendly_Event_Type__r.Person_ID_Answer_Key__c
            FROM Calendly_Event_Type_Group__c
            WHERE Calendly_Event_Group__c IN :eventGroupsById.keySet()
            ORDER BY Calendly_Event_Type__r.Calendar_Name__c ASC, Calendly_Event_Type__r.Name ASC
        ]) {
            // for each Event Type that belongs to relevant Event Groups

            Calendly_Event_Type__c evt = evtg.Calendly_Event_Type__r;
            if(eventIds.add(evt.Id)) {
                // event type not already added
                CalendlyEvent ce = new CalendlyEvent(evt.Name, evt.Event_URL__c, evt.Person_ID_Answer_Key__c);
                ce.calendarName = evt.Calendar_Name__c;
                ce.eventTypeId = evt.Id;
                events.add(ce);
            }
        }

        WidgetData wd = new WidgetData();
        wd.contact = new ContactData();
        wd.contact.name = od.contact.Name;
        wd.contact.email = od.contact.Email;
        wd.contact.personId = od.contact.Person_ID__c;
        wd.events = events;
        return wd;
    }

    @AuraEnabled
    public static Calendly_Event_Type__c[] getEventTypesInGroup(Id groupId) {
        return [
            SELECT Name, Event_URL__c, Calendar_Name__c FROM Calendly_Event_Type__c
            WHERE Id IN (SELECT Calendly_Event_Type__c FROM Calendly_Event_Type_Group__c WHERE Calendly_Event_Group__c = :groupId)
            ORDER BY Calendar_Name__c ASC, Name ASC
        ];
    }

    @AuraEnabled
    public static Calendly_Event_Type__c[] getEventTypesNotInGroup(Id groupId) {
        return [
            SELECT Name, Event_URL__c, Calendar_Name__c FROM Calendly_Event_Type__c
            WHERE Id NOT IN (SELECT Calendly_Event_Type__c FROM Calendly_Event_Type_Group__c WHERE Calendly_Event_Group__c = :groupId)
            ORDER BY Calendar_Name__c ASC, Name ASC
        ];
    }

    @AuraEnabled
    public static void addEventsToGroup(Id groupId, Id[] eventIds) {
        Calendly_Event_Type_Group__c[] links = new Calendly_Event_Type_Group__c[0];
        for(Id eventId :eventIds) {
            links.add(new Calendly_Event_Type_Group__c(Calendly_Event_Group__c=groupId, Calendly_Event_Type__c=eventId));
        }
        insert links;
    }

    @AuraEnabled
    public static void removeEventsFromGroup(Id groupId, Id[] eventIds) {
        delete [
            SELECT Id FROM Calendly_Event_Type_Group__c
            WHERE Calendly_Event_Type__c IN :eventIds AND Calendly_Event_Group__c = :groupId
        ];
    }
}