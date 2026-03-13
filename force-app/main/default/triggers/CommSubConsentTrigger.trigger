/**
 * @author       : Ibrahim Rumi
 * @date         : 15-02-2023
 * @group        : Consent Management
 * @description  : Trigger for CommSubscriptionConsent object 
 * @revision
 *   15-02-2023  Ibrahim Rumi    - EPBBS-0000 added GenerateUuidIfMissing to Generate UUID if they don't already have it on record creation
**/
trigger CommSubConsentTrigger on CommSubscriptionConsent (before insert) {

    if (TriggerCommon.doNotRunTrigger('CommSubscriptionConsent')) { return; }

    new Triggers()
        //Before Insert Events
        .bindExtended(Triggers.Evnt.beforeInsert, new CommSubConsentTriggerHandler.GenerateUuidIfMissing())
    .execute();
}