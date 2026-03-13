/**
 * @description       : Trigger for EnquiryOrganisations object
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
*/
trigger EnquiryOrganisationsTrigger on Enquiry_Organisations__c(before insert, after insert, before update, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Enquiry_Organisations__c')) {
        return;
    }

    //Initialize Triggers
    new Triggers()
    //Bind Classes that implement Triggers.Handler
    /** INSERT */
    .bindExtended(Triggers.Evnt.beforeInsert, new EnquiryOrganisationsHandler.ValidateDuplicateOrganisations())
    //after insert
    
    /** UPDATE */
    .bindExtended(Triggers.Evnt.beforeUpdate, new EnquiryOrganisationsHandler.ValidateDuplicateOrganisations())
    
    //Calls the run method on each class
    .execute();
}