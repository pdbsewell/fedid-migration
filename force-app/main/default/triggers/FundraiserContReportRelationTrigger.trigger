/**
 * @description       : Trigger for ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c
 * @author            : Inderpal Dhanoa
 * @group             : Engage Enterprise 
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   2021-10-18 - Inderpal Dhanoa -   Added a functionality to handle Insert, Update and Delete for the Funders
**/
trigger FundraiserContReportRelationTrigger on ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c (before insert, after insert, before update, 
                                                                                            after update, before delete, after delete, after undelete) {
    if (TriggerCommon.doNotRunTrigger('ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c')) {
        return;
    }

    new Triggers()
    /** INSERT */
    .bindExtended(Triggers.Evnt.afterInsert, new FundraiserContReportRelationHandler.SyncUpdateTasks())

    /** UPDATE */
    .bindExtended(Triggers.Evnt.afterupdate, new FundraiserContReportRelationHandler.SyncUpdateTasks()) 

    /** DELETE */ 
    .bindExtended(Triggers.Evnt.afterDelete, new FundraiserContReportRelationHandler.SyncUpdateTasks())  

    /** UNDELETE */
    .execute();
}