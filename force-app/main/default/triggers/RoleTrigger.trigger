trigger RoleTrigger on Roles__c (after insert, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Role')) { return; }

    new Triggers()
        //Handle aggregate calculation of the Is COO Flag on Account based upon Role RecordType
        .bind(Triggers.Evnt.afterInsert, new RoleServices.updateAccCOOFlag())
        .bind(Triggers.Evnt.afterUpdate, new RoleServices.updateAccCOOFlag())
        .bind(Triggers.Evnt.afterDelete, new RoleServices.updateAccCOOFlag()) 
        .bind(Triggers.Evnt.afterunDelete, new RoleServices.updateAccCOOFlag()) 

        //Handle aggregate calculation of the Is COO Flag on Contact based upon Role RecordType
        .bind(Triggers.Evnt.afterInsert, new RoleServices.updateCntCOOFlag())
        .bind(Triggers.Evnt.afterUpdate, new RoleServices.updateCntCOOFlag())
        .bind(Triggers.Evnt.afterDelete, new RoleServices.updateCntCOOFlag()) 
        .bind(Triggers.Evnt.afterunDelete, new RoleServices.updateCntCOOFlag()) 

       //Other binds go here
 
    .execute();
}