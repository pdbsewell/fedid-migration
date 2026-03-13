/**
 * @author       : Ibrahim Rumi
 * @date         : 30-06-2023
 * @group        : SFMC
 * @description  : trigger on individual email results
**/
trigger SFMC_IERTrigger on et4ae5__IndividualEmailResult__c (before insert) {

    //Run Triggers
    new Triggers()

    //BEFORE INSERT
    .bindExtended(Triggers.Evnt.beforeinsert, new SFMC_IERTriggerHandler.encryptViewURL())
    
    .execute();
}