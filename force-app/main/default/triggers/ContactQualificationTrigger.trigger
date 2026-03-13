/*******************************************************************************
* @author		Sethu Venna
* @date         12/03/2025 
* @description  Trigger for Contact Qualification Object
* @revision     17/03/2025  - Initial Version
*******************************************************************************/
trigger ContactQualificationTrigger on Contact_Qualification__c (
    after insert, 
    before insert, 
    before update, 
    after update, 
    after delete
) 
{
    if (TriggerCommon.doNotRunTrigger('Contact_Qualification__c')) { return; }
    
    new Triggers()
    .bind(Triggers.Evnt.afterUpdate, new ContactQualificationServices.ATARCalloutFromTrigger())
    .bind(Triggers.Evnt.afterInsert, new ContactQualificationServices.ATARCalloutFromTrigger())
    .execute();
}