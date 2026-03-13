/**
* @author Angelo Rivera
* @date 05.09.19
* @group Monash Connect
* @description Trigger for Chat 365 Log
* @revision 05.09.19 - Initial Create
            17 March 2020 - Cartick Sub - Link Contacts
*/

trigger Chat365LogTrigger on Chat_365_Log__c (after update, before insert, before update) {
    if (TriggerCommon.doNotRunTrigger('Chat_365_Log__c')) { return; }

    new Triggers()
            // Before Insert events
            .bindExtended(Triggers.Evnt.beforeinsert, new Chat365LogTriggerHandler.LinkContact())

            // Before Update events
            .bindExtended(Triggers.Evnt.beforeupdate, new Chat365LogTriggerHandler.LinkContact())
            
            //After Update Events
            .bindExtended(Triggers.Evnt.afterupdate, new Chat365LogTriggerHandler.InsertChatBotSurvey())

            .execute();

    LogUtilityException.getLimits();
}