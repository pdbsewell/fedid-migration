/**
 * @author Nick Guia
 * @description Trigger for Unit Attempt object
 * @history
 * 	NOV.26.2018 	Nick Guia 	- Created initial version
 *  APR.02.2019     Nick Guia   - Added PopulateUnitAttemptExt()
 *  MAY.08.2024     Martin Cadman - Added assignUnitOffering()
 */
trigger UnitAttemptTrigger on Unit_Attempt__c (before insert, before update) {
	if (TriggerCommon.doNotRunTrigger('Unit_Attempt__c')) { return; }
	
    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new UnitAttemptServices.PopulateUnitAttemptName())
        .bindExtended(Triggers.Evnt.beforeInsert, new UnitAttemptServices.PopulateUnitAttemptExt())
        .bindExtended(Triggers.Evnt.beforeInsert, new UnitAttemptServices.PublishedDate())

        // Update the name but not the UK on update
        .bindExtended(Triggers.Evnt.beforeUpdate, new UnitAttemptServices.PopulateUnitAttemptName())
        .bindExtended(Triggers.Evnt.beforeUpdate, new UnitAttemptServices.PublishedDate())
        // Not executed on insert as ibdUnitAttempt deals with the UO
        .bindExtended(Triggers.Evnt.beforeUpdate, new UnitAttemptServices.assignUnitOffering())
        
        .execute();
}