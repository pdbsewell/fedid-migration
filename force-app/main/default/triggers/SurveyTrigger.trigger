/**
* @author Inderpal Dhanoa
* @date 11.12.23
* @group Monash Connect
* @description Trigger for Survey
* @revision 11.12.23 - Initial Create <br/>
*/
trigger SurveyTrigger on Survey__c (before insert, before update, after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('Survey__c')) {
        return;
    }
    new Triggers() 
        // INSERT
        
        //UPDATE
        .bindExtended(Triggers.Evnt.afterUpdate, new SurveyTriggerHandler.SyncSurveyDetails())
    .execute();
}