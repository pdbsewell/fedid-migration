/**
@author Cartick Sub
@date 17 September 2020
@group Monash Connect
@description Trigger for Student Letter Logs
@revision Initial version - 17 September 2020
**/

trigger StudentLetterLogTrigger on Student_Letter_Log__c (before insert) {
    
    if (TriggerCommon.doNotRunTrigger('Student_Letter_Log__c')){
        return;
    }

    new Triggers()
            // Before insert events
            .bindExtended(Triggers.Evnt.beforeinsert, new StudentLetterLogTriggerHandler.LinkContact())
            .bindExtended(Triggers.Evnt.beforeinsert, new StudentLetterLogTriggerHandler.LinkEnquiry())
            
            .execute();

    LogUtilityException.getLimits();
}