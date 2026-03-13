/**
 * @author          Ajitabh
 * @description     Trigger for Course_Attempt__ChangeEvent sObject
 * @revision        
 * 					21/05/2020 J.Mapanao		- Added CourseAttemptChangeEventService.ToggleIsStudentContact()
 */
trigger CourseAttemptChangeEventTrigger on Course_Attempt__ChangeEvent (after insert) {
	
    if (TriggerCommon.doNotRunTrigger('Course_Attempt__ChangeEvent')) {
        return;
    }
    new Triggers() 
		.bindExtended(Triggers.Evnt.afterInsert, new CourseAttemptChangeEventService.cdcSCAHandler())
	.execute();
}