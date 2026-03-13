/**
 * @description       : Trigger for Affiliation__c object
 * @author            : Peter Sewell
 * @group             : Trigger
 * @last modified on  : 2023-03-08
 * @last modified by  : Peter Sewell
 * Modifications Log 
 * Date         Author          Modification
 * 2023-03-08 - Peter Sewell - Initial Version
 * 2023-24-11 - Mac Domingo - Added logic for assigning CompositeKey
 **/
trigger AffiliationTrigger on Affiliation__c (before insert, after insert, before update, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Affiliation__c')) {
        return;
    }

    //Run Triggers
    new Triggers()
    
    // Before Insert
    .bindExtended(Triggers.Evnt.beforeinsert, new AffiliationTriggerHandler.UpdateSharingCompositeKey())    
    .bindExtended(Triggers.Evnt.beforeinsert, new AffiliationTriggerHandler.SetDefaultValues())
    // Before Update
    .bindExtended(Triggers.Evnt.beforeupdate, new AffiliationTriggerHandler.UpdateSharingCompositeKey())
    .bindExtended(Triggers.Evnt.beforeupdate, new AffiliationTriggerHandler.RegenerateCompositeKey())

    // After Insert
    .bindExtended(Triggers.Evnt.afterinsert, new AffiliationTriggerHandler.CreateContactShares())
    .bindExtended(Triggers.Evnt.afterinsert, new AffiliationTriggerHandler.updateOwnerToSystemDataOwner())
    .bindExtended(Triggers.Evnt.afterinsert, new AffiliationTriggerHandler.CreateCPAs())

    // After Update
    .bindExtended(Triggers.Evnt.afterupdate, new AffiliationTriggerHandler.UpdateContactShares())

    // After Delete
    .bindExtended(Triggers.Evnt.afterdelete, new AffiliationTriggerHandler.DeleteContactShares())
    
    //Execute
    .execute();
}