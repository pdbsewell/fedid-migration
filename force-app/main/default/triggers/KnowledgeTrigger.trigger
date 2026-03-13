/**
 * @description       : Trigger for Knowledge object
 * @author            : Inderpal Dhanoa
 * @group             : Trigger
 * Modifications Log 
 * Date         Author          Modification
 * 2024-04-30 - Inderpal Dhanoa - Author
 **/
trigger KnowledgeTrigger on Knowledge_Article__kav (before insert, after insert, before update, after update, after delete, after undelete) {
   if (TriggerCommon.doNotRunTrigger('Knowledge_Article__kav')) {
        return;
    }
    
    //Initialize Triggers
    new Triggers('Knowledge_Article__kav')
    /** INSERT */
    .bindExtended(Triggers.Evnt.afterInsert, new KnowledgeTriggerHandler.MapDataCategories())
    //Calls the run method on each class
    .execute();
}