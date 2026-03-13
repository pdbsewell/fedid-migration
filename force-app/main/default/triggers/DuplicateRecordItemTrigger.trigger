/**
 * @description       : Trigger for Duplicate Record Item object
 * @author            : Sachin Shetty
 * @group             : Trigger
 **/
trigger DuplicateRecordItemTrigger on DuplicateRecordItem (after delete) {

    if (TriggerCommon.doNotRunTrigger('DuplicateRecordItem')) {
        return;
    }

    //Run Triggers
    new Triggers()
    //After DELETE
    .bindExtended(Triggers.Evnt.afterdelete, new DuplicateRecordItemTriggerHandler.UpdateDuplicateRecordSet())
    .execute();

}