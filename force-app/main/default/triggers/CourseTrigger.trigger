/**
 * @author          Stefan Scheit
 * @description     Trigger class to delegate trigger logic to services class
 * @revision        25/04/2018 - Stefan Scheit - Initial version (SF-1034)
 * 					01/08/2018 - Nick Guia - Added handler logic for Master Course creation
 *  				23 Nov 2020 Martin Cadman
 */
trigger CourseTrigger on Course__c (after insert, before insert, before update, after update) {
    
    if (TriggerCommon.doNotRunTrigger(String.valueOf(Course__c.class))) {
        return;
    }
    
    new Triggers()
        .bind(Triggers.Evnt.beforeInsert, new CourseServices.UpdateFieldsHandler())
        .bind(Triggers.Evnt.beforeInsert, new CourseServices.LinkCourseMaster())

		.bind(Triggers.Evnt.afterInsert, new CourseServices.RollupLatestCourse())

        .bind(Triggers.Evnt.beforeUpdate, new CourseServices.UpdateFieldsHandler())
        .bind(Triggers.Evnt.beforeUpdate, new CourseServices.LinkCourseMaster())

        .bind(Triggers.Evnt.afterUpdate, new CourseServices.RollupLatestCourse())
        .execute();
}