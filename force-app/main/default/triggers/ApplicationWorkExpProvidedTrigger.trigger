/**
* @author various
* @date 30.07.2025
*
* @group Application_Work_Experience_Provided__c 
*/
trigger ApplicationWorkExpProvidedTrigger on Application_Work_Experience_Provided__c (before insert) {
	// moved to the start ensure all actions are disabled
    if (TriggerCommon.doNotRunTrigger('Application_Work_Experience_Provided__c')) {
        return;
    } 
    
    //Initialize Triggers
    new Triggers()

        /** BEFORE INSERT */
        .bindExtended(Triggers.Evnt.beforeinsert, new ApplicationWorkExpProvidedHandler.PopulateApplicationStatus())
        
        //Calls the run method on each class
        .execute();

}