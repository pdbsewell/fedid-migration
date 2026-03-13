/**
 * @author Nick Guia
 * @date MAR.20.2018
 * @description Trigger for Lead Course Association object
 * @revision
 * 	AUG.28.2018 	Nick Guia 	- added CrossPopulateCourses as an interim process for populating Course Master
 *	OCT.08.2018 	Nick Guia 	- removed CrossPopulateCourses.
 */
trigger LeadCourseAssociationTrigger on Lead_Course_Association__c (before insert, after insert, after update, after delete) {
	if (TriggerCommon.doNotRunTrigger('Lead_Course_Association__c')) { return; }

	new Triggers()
		.bind(Triggers.Evnt.afterInsert, new LeadCourseAssociationTriggerHandler.ValidateIsLatestPrimaryProcess())
		.bind(Triggers.Evnt.afterUpdate, new LeadCourseAssociationTriggerHandler.ValidateIsLatestPrimaryProcess())
		.bind(Triggers.Evnt.afterDelete, new LeadCourseAssociationTriggerHandler.ValidateIsLatestPrimaryProcess())
	.execute();
}