/**
* @author Angelo Rivera
* @date 17.06.2020
* @group TriggerHandlers
* @description EventTrigger Handler
* @revision 17.06.2020 - Initial Create
*/
public with sharing class EventTriggerHandler {

    /**
    @author Angelo Rivera
    @date 17 June 2020
    @description - Inner class to link Event to Outbound_Call_Result__c
    @revision Initial version - 17 June 2020
    **/
    public class LinkEventToOutboundCall extends TriggerAbstract {
        public Set<Id> setContactIds = new Set<Id>();
        public override void process(SObject record) {
            Event eventRecord = (Event)record;
            // Only process events with Calendly_Event record type
            if (eventRecord.RecordTypeId == EventServices.CALENDLY_RECTYPEID && eventRecord.WhoId != null) {
                System.debug('!@# process - eventRecord: ' + eventRecord);
                records.add(eventRecord);
                setContactIds.add(eventRecord.WhoId);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if (!records.isEmpty()) {
                Map<Id, Outbound_Call_Result__c> tempMapOutboundCallByContactId = new Map<Id, Outbound_Call_Result__c>();
                Map<Id, Outbound_Call_Result__c> mapOutboundCallByContactId = new Map<Id, Outbound_Call_Result__c>();
                EventServices.retrieveOutboundCalls(tempMapOutboundCallByContactId, 'Pending', setContactIds);
                System.debug('!@# tempMapOutboundCallByContactId: '+ tempMapOutboundCallByContactId.size());
                if(!tempMapOutboundCallByContactId.isEmpty()){
                    mapOutboundCallByContactId.putAll(tempMapOutboundCallByContactId);
                }else{
                    EventServices.retrieveOutboundCalls(mapOutboundCallByContactId, 'Cancelled', setContactIds);
                }
                System.debug('!@# mapOutboundCallByContactId: '+ mapOutboundCallByContactId.size());
                if(!mapOutboundCallByContactId.isEmpty()) {
                    for(Event e : (List<Event>)records){
                        System.debug('!@# event: '+ e);
                        if(mapOutboundCallByContactId.get(e.WhoId) != null){
                            e.WhatId = mapOutboundCallByContactId.get(e.WhoId).Id;
                            e.Event_Status__c = 'Assigned';
                            System.debug('!@# e.WhatIde.WhatId: '+ e.WhatId);
                        }
                    }
                }
            }
            LogUtilityException.getLimits();
        }
    }

    /**
    @author Angelo Rivera
    @date 17 June 2020
    @description - Inner class to update Outbound_Call_Result__c after event is generated and linked
    @revision Initial version - 17 June 2020
    **/
    public class UpdateOutboundCallOnEventInsert extends TriggerAbstract {
        public Map<Id,Event> mapEventByOCRIds = new Map<Id, Event>();
        public override void process(SObject record) {
            Event eventRecord = (Event)record;
            // Only process events with Calendly_Event record type
            if (eventRecord.RecordTypeId == EventServices.CALENDLY_RECTYPEID && eventRecord.WhoId != null  && eventRecord.WhatId != null) {
                mapEventByOCRIds.put(eventRecord.WhatId, eventRecord);
            }
            System.debug('!@# process - mapEventByOCRIds: ' + mapEventByOCRIds.size());
        }

        public override void execute() {
            System.debug('!@# execute mapEventByOCRIds: ' + mapEventByOCRIds.size());
            //Checks if there are records to be processed
            if (!mapEventByOCRIds.isEmpty()) {
                List<Outbound_Call_Result__c> lstOutboundCallResults = new List<Outbound_Call_Result__c>();
                List<Outbound_Call_Result__c> tempLstOutboundCallResults = new List<Outbound_Call_Result__c>();
                EventServices.getOCRs(tempLstOutboundCallResults,'Pending', mapEventByOCRIds.keySet());
                System.debug('!@# Pending - tempLstOutboundCallResults: ' + tempLstOutboundCallResults);
                if(!tempLstOutboundCallResults.isEmpty()){
                    lstOutboundCallResults.addAll(tempLstOutboundCallResults);
                }else{
                    EventServices.getOCRs(lstOutboundCallResults, 'Cancelled', mapEventByOCRIds.keySet());
                }
                System.debug('!@# lstOutboundCallResults: ' + lstOutboundCallResults);
                if(!lstOutboundCallResults.isEmpty()){
                    for(Outbound_Call_Result__c ocr : lstOutboundCallResults){
                        ocr.Event_Link_Status__c = 'Session Booked';
                        ocr.Event_Id__c = mapEventByOCRIds.get(ocr.Id).Id;
                    }
                    try {
                        if(!lstOutboundCallResults.isEmpty()) Database.update(lstOutboundCallResults);
                    } catch (Exception e) {
                        ExLog.add('EventTrigger - EventTriggerHandler', 'Event', 'UpdateOutboundCallOnEventInsert', e.getMessage());
                    }
                }
            }
            LogUtilityException.getLimits();
        }
    }

    /**
    @author Angelo Rivera
    @date 17 June 2020
    @description - Inner class to update Outbound_Call_Result__c after event is generated and linked
    @revision Initial version - 17 June 2020
    **/
    public class UpdateOutboundCallOnEventUpdate extends TriggerAbstract {
        public Map<Id, Event> mapEventByOCRIds = new Map<Id, Event>();
        public override void process(SObject record, SObject oldRecord) {
            Event newEventRecord = (Event) record;
            Event oldEventRecord = (Event) oldRecord;
            // Only process events with Calendly_Event record type
            if (newEventRecord.RecordTypeId == EventServices.CALENDLY_RECTYPEID && newEventRecord.WhoId != null && newEventRecord.WhatId != null) {
                if (newEventRecord.Event_Status__c != oldEventRecord.Event_Status__c) {
                    if (newEventRecord.Event_Status__c == 'Cancelled') {
                        mapEventByOCRIds.put(newEventRecord.WhatId, newEventRecord);
                    }
                }
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if (!mapEventByOCRIds.isEmpty()) {
                List<Outbound_Call_Result__c> lstOutboundCallResults = new List<Outbound_Call_Result__c>();
                EventServices.getOCRs(lstOutboundCallResults, 'Session Booked', mapEventByOCRIds.keySet());
                if (!lstOutboundCallResults.isEmpty()) {
                    for (Outbound_Call_Result__c ocr : lstOutboundCallResults) {
                        ocr.Event_Link_Status__c = 'Cancelled';
                    }
                    try {
                        if (!lstOutboundCallResults.isEmpty()) Database.update(lstOutboundCallResults);
                    } catch (Exception e) {
                        ExLog.add('EventTrigger - EventTriggerHandler', 'Event', 'UpdateOutboundCallOnEventUpdate', e.getMessage());
                    }
                }
            }
            LogUtilityException.getLimits();
        }
    }
}