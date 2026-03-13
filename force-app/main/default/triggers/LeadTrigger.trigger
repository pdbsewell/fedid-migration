/**
 * @description       : Trigger class for Lead object
 * @author            : Nick Guia
 * @group             : Commons
 * @last modified on  : 10-10-2022
 * @last modified by  : NG
 * rev 
 * Added new after update method :
 * 1. CascadeUpdatesOnContact - Checks for update in Email or Mobile field and cascade the value to Contact
 * 2. ManageLCAOnCourseChange - Check for update in Primary Course Master Associated field and create/update LCAs accordingly.
**/
trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    
    if (TriggerCommon.doNotRunTrigger('Lead')) { return; }
    
    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new LeadTriggerHandler.PopulateLeadNurturingFields())
        .bindExtended(Triggers.Evnt.beforeUpdate, new LeadTriggerHandler.PopulateLeadNurturingFields())
        .bindExtended(Triggers.Evnt.afterUpdate, new LeadTriggerHandler.CascadeUpdatesOnContact())
        .bindExtended(Triggers.Evnt.afterUpdate, new LeadTriggerHandler.ManageLCAOnCourseChange())
    .execute();
}