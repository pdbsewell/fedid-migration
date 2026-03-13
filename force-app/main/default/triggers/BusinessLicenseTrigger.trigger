/**
 * @author			Russell Cadapan
 * @description		Trigger for Business License object
 * @revision		10/06/2019 - Russell Cadapan - Created
 */
trigger BusinessLicenseTrigger on Business_License__c (after insert) {
	if (TriggerCommon.doNotRunTrigger('Business_License__c')) { return; }
    
    new Triggers()
    /*** INSERT **/
    .bind(Triggers.Evnt.afterinsert, new BusinessLicenseTriggerHandler.ShareRecordManually())
    .execute(); 
}