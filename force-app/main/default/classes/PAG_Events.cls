public with sharing class PAG_Events {
    @TestVisible public static PAG_MoID_Minted__e lastPublished;

    public static Boolean publishMoIDMinted(String sor, String sorPersonId, String moid, Id contactId, String personaKey){
        PAG_MoID_Minted__e evt = new PAG_MoID_Minted__e(
            PAG_SoR__c = sor,
            PAG_SoRPersonId__c = sorPersonId,
            PAG_MoID__c = moid,
            PAG_ContactId__c = (contactId == null ? null : String.valueOf(contactId)),
            PAG_PersonaKey__c = personaKey,
            PAG_OccurredAt__c = System.now()
        );
        Database.SaveResult sr = EventBus.publish(evt);
        lastPublished = evt;
        return sr != null && sr.isSuccess();
    }
}