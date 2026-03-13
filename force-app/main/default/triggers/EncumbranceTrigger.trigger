trigger EncumbranceTrigger on Encumbrance__c (before insert, before update, after undelete) {
    if (TriggerCommon.doNotRunTrigger('Encumbrance__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new EncumbranceServices.PopulateEncumbranceName())
        .bindExtended(Triggers.Evnt.beforeInsert, new EncumbranceServices.updateFields())

        .bindExtended(Triggers.Evnt.beforeUpdate, new EncumbranceServices.PopulateEncumbranceName())
        .bindExtended(Triggers.Evnt.beforeUpdate, new EncumbranceServices.updateFields())

        .bindExtended(Triggers.Evnt.afterUndelete, new EncumbranceServices.updateFields())
    .execute();
}