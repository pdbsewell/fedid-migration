/**
 * @description: Trigger on copado__Result__c Object
 **/
trigger CopadoResultTrigger on copado__Result__c (before update) {
    if(Trigger.isBefore){
        CopadoResultTriggerService.beforeUpdate(Trigger.new,Trigger.oldMap);
        system.debug('******* Result trigger *********');
    }
}