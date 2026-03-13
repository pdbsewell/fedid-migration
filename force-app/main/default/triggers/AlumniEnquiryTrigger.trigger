/*
 * @description : Trigger for Alumni Enquiry Object
 * @group : Advancement
 * @revision
 */
trigger AlumniEnquiryTrigger on Alumni_Enquiry__c (before insert, before update, after insert, after update, before delete) {
    /**
     * trigger muting.
     */
    if(TriggerCommon.doNotRunTrigger('Alumni_Enquiry__c')) { return; }
    new Triggers()
    //Before Insert Events
    
    //Before Update Events
    
    //After Insert Events
    .bindExtended(Triggers.Evnt.afterInsert, new AlumniEnquiryHandler.syncAlumniEnquiryToEnquiry())
    //After Update Events
    
    // Delete

.execute();

LogUtilityException.getLimits();
}