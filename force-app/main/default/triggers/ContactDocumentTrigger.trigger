/**
 * @author      J.Mapanao
 * @description Trigger for Contact Document SObject (API NAME: Contact_Document__c)
 * @revision    J.Mapanao, 08.Aug.2019 - created
 * Vinothraja   18/01/2022  SFTG-2167 :: Removed calls to ContactDocumentTriggerHandler, as it is removed as part of WR Decommission 
 */
trigger ContactDocumentTrigger on Contact_Document__c (after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('Contact_Document__c')) {
        return;
    }

    //Run Trigger
    new Triggers()
        //BEFORE INSERT
        //BEFORE UPDATE
        //BEFORE DELETE
        //AFTER INSERT
        //AFTER UPDATE
        .bindExtended(Triggers.Evnt.afterUpdate, new ContactDocumentTriggerHandler.RetryGRDocumentSyncToCallista())
        //After Delete
        .execute();
}