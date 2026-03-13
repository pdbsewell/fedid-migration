/**
 * @description       : Trigger Helper to manage all DML and events on Contact Report
 * @author            : Inderpal Dhanoa
 * @group             : Engage Enterprise 
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   2021-10-18 - Inderpal Dhanoa -   Added a functionality to handle Insert and Delete for Contact Reports
**/
public without sharing class ContactReportTriggerHelper {
    /*
    * Method Name:  syncTask
     * @param       Task to be synced
     * @param       contactReport record from the Contact Report Object
     * @return      Boolean 
     * Description: Sync data from Contact Report to Task 
    */
    public static Task syncTask(Task syncedTask, ucinn_ascendv2__Contact_Report__c contactReport){
        syncedTask.ActivityDate = contactReport.ucinn_ascendv2__Date__c;
        syncedTask.Task_Start_Date__c = contactReport.ucinn_ascendv2__Date__c; 
        syncedTask.Completed_Date_Time__c = contactReport.ucinn_ascendv2__Date__c; 
        syncedTask.Status='Completed';
        syncedTask.Type = contactReport.ucinn_ascendv2__Contact_Method__c;
        syncedTask.Contact_Report__c = contactReport.Id;
        if(String.isNotBlank((String)contactReport.ucinn_ascendv2__Proposal__c)){
            syncedTask.WhatId = contactReport.ucinn_ascendv2__Proposal__c;
        }else{
            syncedTask.WhatId = contactReport.ucinn_ascendv2__Account__c;
        }
        syncedTask.Subject = 'Contact Report ' + contactReport.ucinn_ascendv2__Description__c;
        syncedTask.WhoId = contactReport.ucinn_ascendv2__Contact__c;
        return syncedTask;
    }
}