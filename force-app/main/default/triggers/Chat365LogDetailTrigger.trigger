/**
* @author Angelo Rivera
* @date 05.09.19
* @group Monash Connect
* @description Trigger for Chat 365 Log Detail
* @revision 05.09.19 - Initial Create <br/>
*/

trigger Chat365LogDetailTrigger on Chat_365_Log_Detail__c (before insert, after insert) {

    if (TriggerCommon.doNotRunTrigger('Chat_365_Log_Detail__c')) { return; }

    new Triggers()
            //After Insert Events
            .bindExtended(Triggers.Evnt.afterinsert, new Chat365LogDetailTriggerHandler.InsertEnquiry())

            .execute();

    LogUtilityException.getLimits();
}