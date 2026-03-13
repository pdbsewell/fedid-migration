/**
* @author   APRivera
* @date     21-02-2019
*
* @description  Trigger for Enquiry Interest Object
* @revision     21-02-2019 - APRivera - Added class UpdateCaseRecordCourseFields
*/

trigger EnquiryInterestTrigger on Enquiry_Interest__c (before insert, before delete, after insert) {

    if (TriggerCommon.doNotRunTrigger('Enquiry_Interest__c')) { return; }
    new Triggers()
            .bind(Triggers.Evnt.beforeInsert, new EnquiryInterestTriggerHandler.linkInterestsToPerson())
            .bind(Triggers.Evnt.beforeDelete, new EnquiryInterestTriggerHandler.preventDeletionOnClosedCases())
            .bind(Triggers.Evnt.afterinsert, new EnquiryInterestTriggerHandler.UpdateCaseRecordCourseFields())
            .execute();

}