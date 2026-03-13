/**
 * @description       : Trigger class specific to Contact Report (ucinn_ascendv2__Contact_Report__c)
 * @author            : Inderpal Dhanoa
 * @group             : Engage Enterprise 
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   2021-10-18 - Inderpal Dhanoa -   Added a functionality to handle Insert and Delete for Contact Reports
**/
trigger ContactReportTrigger on ucinn_ascendv2__Contact_Report__c (before insert, after insert, before update, after update, 
                                                                    before delete, after delete, after undelete) {
    if (TriggerCommon.doNotRunTrigger('ucinn_ascendv2__Contact_Report__c')) {
        return;
    }

    new Triggers()
    /** INSERT */
    .bindExtended(Triggers.Evnt.afterInsert, new ContactReportTriggerHandler.SyncInsertTasks())
	
	/** UPDATE */
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactReportTriggerHandler.SyncUpdateTasks())  

    /** DELETE */
    .bindExtended(Triggers.Evnt.beforeDelete, new ContactReportTriggerHandler.SyncDeleteTasks())

    /** UNDELETE */
    .execute();
}