trigger UnitSetAttemptTrigger on Unit_Set_Attempt__c (before insert, before update) {
	if (TriggerCommon.doNotRunTrigger('Unit_Set_Attempt__c')) { return; }
	
    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new UnitSetAttemptServices.PopulateUnitSetAttemptName())
        .bindExtended(Triggers.Evnt.beforeUpdate, new UnitSetAttemptServices.PopulateUnitSetAttemptName())
        
        .execute();
}