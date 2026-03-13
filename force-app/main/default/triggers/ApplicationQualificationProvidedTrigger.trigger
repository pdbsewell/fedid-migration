/**
* @author various
* @date 18.07.2025
*
* @group Application_Qualification_Provided__c
*/
trigger ApplicationQualificationProvidedTrigger on Application_Qualification_Provided__c (before insert) {
	// moved to the start ensure all actions are disabled
    if (TriggerCommon.doNotRunTrigger('Application_Qualification_Provided__c')) {
        return;
    } 
    
    //Initialize Triggers
    new Triggers()

        /** BEFORE INSERT */
        .bindExtended(Triggers.Evnt.beforeinsert, new ApplicationQualificationProvidedHandler.PopulateApplicationStatus())
        
        //Calls the run method on each class
        .execute();

}