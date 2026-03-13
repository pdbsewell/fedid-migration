/**
* @author Inderpal Dhanoa
* @date 11.12.23
* @group Monash Connect
* @description Trigger for Coaching Opportunities
* @revision 11.12.23 - Initial Create <br/>
*/
trigger CoachingOpportunitiesTrigger on Coaching_Opportunities__c (before insert, before update, after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('Coaching_Opportunities__c')) {
        return;
    }
    new Triggers() 
        // INSERT
		.bindExtended(Triggers.Evnt.beforeInsert, new CoachngOpptyTriggerHandler.LinkSurveyDetails())
        .bindExtended(Triggers.Evnt.afterInsert, new CoachngOpptyTriggerHandler.NotifyOwner())
        
        //UPDATE
        .bindExtended(Triggers.Evnt.beforeUpdate, new CoachngOpptyTriggerHandler.LinkSurveyDetails())
        .bindExtended(Triggers.Evnt.afterUpdate, new CoachngOpptyTriggerHandler.NotifyOwner())
	.execute();
}