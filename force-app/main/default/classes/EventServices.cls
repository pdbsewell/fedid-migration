/**
* @author Angelo Rivera
* @date 17.06.2020
* @group TriggerHandlers
* @description EventTrigger Handler Service Clas
* @revision 17.06.2020 - Initial Create
*/

public with sharing class EventServices {

    public static Id CALENDLY_RECTYPEID {
        get {
            if(CALENDLY_RECTYPEID == null) CALENDLY_RECTYPEID = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Calendly_Event').getRecordTypeId();
            return CALENDLY_RECTYPEID;
        }
        set;
    }

    /**
   @description retrieves Outbound call results
   @return List<Outbound_Call_Result__c>
   @revision Initial version - 17 March 2020
   **/
    public static void getOCRs(List<Outbound_Call_Result__c> lstOutboundCallResults, String strEventStatus, Set<Id> setOCRIds){
        for(Outbound_Call_Result__c ocr : [SELECT Id, Contact__c, Event_Link_Status__c, Event_Id__c FROM Outbound_Call_Result__c
                                            WHERE Event_Link_Status__c =: strEventStatus
                                            AND Id IN: setOCRIds
                                            ORDER BY LastModifiedDate DESC]) {
            if(strEventStatus == 'Cancelled'){
                if(ocr.Event_Id__c != null) lstOutboundCallResults.add(ocr);
            }else{
                lstOutboundCallResults.add(ocr);
            }
        }
    }

    /**
    @description A helper method which retrieves from Outbound Call related to the contact from the Event.
    @return A map where the key is the Contact Id and the value is the Outbound_Call_Result__c.
    @revision Initial version - 17 March 2020
    **/
    public static void retrieveOutboundCalls(Map<Id, Outbound_Call_Result__c> mapOutboundCallByContactId, String strEventStatus, Set<Id> setContactIds) {
        for (Outbound_Call_Result__c ocr : [SELECT Id, Contact__c, Event_Link_Status__c, Event_Id__c FROM Outbound_Call_Result__c
                                            WHERE (Event_Link_Status__c =: strEventStatus)
                                            AND Contact__c IN :setContactIds
                                            ORDER BY LastModifiedDate DESC]) {
            if(strEventStatus == 'Cancelled'){
                if(ocr.Event_Id__c != null) mapOutboundCallByContactId.put(ocr.Contact__c, ocr);
            }else{
                mapOutboundCallByContactId.put(ocr.Contact__c, ocr);
            }
            System.debug('!@# retrieveOutboundCalls-mapOutboundCallByContactId: '+ mapOutboundCallByContactId.size());
        }
    }
}