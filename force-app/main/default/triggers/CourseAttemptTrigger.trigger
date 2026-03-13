/**
 * @author          Gabriel Ludik
 * @description     Trigger on Course Attempt Object
 * @history         26/04/2018 - Gabriel Ludik - Initial version
 * 					20/05/2018 - Stefan Scheit - Added UpdateFieldsHandler for before events
 * 					02/04/2019 - Nick Guia     - Added PopulateCourseAttemptName
 * 					22/02/2020 - Martin Cadman - Moved trigger logic to CDC
 *                  02/08/2024 - Inderpal Dhanoa - Auto close linked OCR MCT-440
 * frame work
 * removed ACPlookup
 *                  
 */
trigger CourseAttemptTrigger on Course_Attempt__c (before insert, after insert, before update, after update, after delete) {
    
    if (TriggerCommon.doNotRunTrigger('Course_Attempt__c')) {
        return;
    }

    try{
        new Triggers()
            // Insert
            .bindExtended(Triggers.Evnt.beforeInsert, new CourseAttemptServices.PopulateCourseAttemptName())
            .bindExtended(Triggers.Evnt.beforeInsert, new CourseAttemptServices.UpdateFieldsHandler())

            // Update
            .bindExtended(Triggers.Evnt.beforeUpdate, new CourseAttemptServices.PopulateCourseAttemptName())
            .bindExtended(Triggers.Evnt.beforeUpdate, new CourseAttemptServices.UpdateFieldsHandler())
            .bindExtended(Triggers.Evnt.afterUpdate, new CourseAttemptServices.AutoCloseLinkedMonConOCR())

        .execute();

    } Catch (Exception e){
        LogUtilityException.logException(e, 'CourseAttemptTrigger');
    }
}