/*
* @description  Contains the triggers for Application_Course_Preference__c
* @revision     25-Jan-2019 Martin Cadman - Removed call to onlinecredit
* @revision     Ayush Agrawal (ayush.agrawal@monash.edu) - EPBBS-984
* @revision     Ayush Agrawal (ayush.agrawal@monash.edu) - EPBBS-1011
* @revision     Ayush Agrawal (ayush.agrawal@monash.edu) - EPBBS-1011
* @revision     Martin Cadman - SFTLG-846
* @revision     22 April 2021 - Cartick Sub - PRODEV-678 - Convert the Process Builder, "PD Update ACP [Partitioning for Short Courses]", into a before trigger
* @revision     2 June 2021   - Cartick Sub - PRODEV-690 - Convert the Process Builder and Flow, both named PD Update Faculty Student Email CC, into a before trigger            
* @revision     01 May 2023   - Martin Cadman - Moved calculateName to the trigger framework
*                                             - Introduced populateOwner
* @revision     25 Feb 2024   - Martin Cadman - Moved ACPLookups to the extended trigger framework
* @revision     27 APR 2025   - Davey Yu      - SMSTA-517 call createTimestampLogs in after insert and after update to log timestamp if ACP workflow status field is updated
* @revision     27 APR 2025   - Davey Yu      - SMSTA-590 call updateReleaseFlag in before insert operation 
*/
trigger ApplicationCoursePreferenceTrigger on Application_Course_Preference__c (before insert, before update, after update, after insert, after delete, after undelete) {
    if(TriggerCommon.doNotRunTrigger('Application_Course_Preference__c')) {
        return;
    }
    
    new Triggers()
        //Before Update
        .bind(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.copyCourseOfferings())
        .bindExtended(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.ACPLookups())
        .bind(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.generateCourseAdmissionStatus())
        .bindExtended(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.calculateName())
        .bind(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.SetPDFaculty())
        .bindExtended(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.SetPDFacultyCCEmail())
        .bindExtended(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.populateOwner())
        .bindExtended(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.RunACPQueueRouting())
        .bindExtended(Triggers.Evnt.beforeUpdate, new ApplicationCoursePreferenceServices.UpdateReleaseFlag())
        
        //Beforec Insert
        .bind(Triggers.Evnt.beforeInsert, new ApplicationCoursePreferenceServices.copyCourseOfferings())
        .bindExtended(Triggers.Evnt.beforeInsert, new ApplicationCoursePreferenceServices.ACPLookups())
        .bind(Triggers.Evnt.beforeInsert, new ApplicationCoursePreferenceServices.generateCourseAdmissionStatus())
        .bindExtended(Triggers.Evnt.beforeInsert, new ApplicationCoursePreferenceServices.calculateName())
        .bind(Triggers.Evnt.beforeInsert, new ApplicationCoursePreferenceServices.SetPDFaculty())
        .bindExtended(Triggers.Evnt.beforeInsert, new ApplicationCoursePreferenceServices.SetPDFacultyCCEmail())
        .bindExtended(Triggers.Evnt.beforeInsert, new ApplicationCoursePreferenceServices.populateOwner())
        .bindExtended(Triggers.Evnt.beforeInsert, new ApplicationCoursePreferenceServices.UpdateReleaseFlag())
        
        //After Update
        .bind(Triggers.Evnt.afterUpdate, new ApplicationCoursePreferenceServices.submitApprovalProcess())
        .bind(Triggers.Evnt.afterUpdate, new ApplicationCoursePreferenceServices.assignApplicationResidencyStatus())
        .bind(Triggers.Evnt.afterUpdate, new ApplicationCoursePreferenceServices.createPlatformEventForEnglishTestScore())
        .bind(Triggers.Evnt.afterUpdate, new ApplicationCoursePreferenceServices.fireCallistaOutbound())
        .bindExtended(Triggers.Evnt.afterUpdate, new ApplicationCoursePreferenceServices.createTimestampLogs())
        .bind(Triggers.Evnt.afterUpdate, new ApplicationCoursePreferenceServices.createPlatformEventForGRSubmission())
        .bind(Triggers.Evnt.afterUpdate, new ApplicationCoursePreferenceServices.RetryHDRIntegration())
        .bindExtended(Triggers.Evnt.afterUpdate, new DlrsDelegateTriggerHandler(Application_Course_Preference__c.SObjectType))

        //After Insert
        .bind(Triggers.Evnt.afterInsert, new ApplicationCoursePreferenceServices.assignApplicationResidencyStatus())
        .bindExtended(Triggers.Evnt.afterInsert, new DlrsDelegateTriggerHandler(Application_Course_Preference__c.SObjectType))
        .bindExtended(Triggers.Evnt.afterInsert, new ApplicationCoursePreferenceServices.createTimestampLogs())

        //Delete
        .bindExtended(Triggers.Evnt.afterDelete, new DlrsDelegateTriggerHandler(Application_Course_Preference__c.SObjectType))
        .bindExtended(Triggers.Evnt.afterUndelete, new DlrsDelegateTriggerHandler(Application_Course_Preference__c.SObjectType))
        .execute();
   
}