trigger UnitOfferingTrigger on Unit_Offering__c (before insert, before Update) {
    
    if (TriggerCommon.doNotRunTrigger('Unit_Offering__c')) { return; }

    new Triggers()
        // Insert
        .bindExtended(Triggers.Evnt.beforeInsert, new UnitOfferingServices.PopulateUnitOfferingName())
        // Update
        .bindExtended(Triggers.Evnt.beforeUpdate, new UnitOfferingServices.PopulateUnitOfferingName())
    .execute();
}