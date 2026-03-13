trigger ContactPointAffiliationTrigger on Contact_Point_Affiliation__c (before insert, before update, after insert, after update) {

if (TriggerCommon.doNotRunTrigger('Contact_Point_Affiliation__c')) {
        return;
    }

    new Triggers() 
        .bindExtended(Triggers.Evnt.beforeupdate, new ContactPointAffiliationServices.buildName())
	    .bindExtended(Triggers.Evnt.beforeupdate, new ContactPointAffiliationServices.buildUniqueId())

        .bindExtended(Triggers.Evnt.beforeinsert, new ContactPointAffiliationServices.buildName())
        .bindExtended(Triggers.Evnt.beforeinsert, new ContactPointAffiliationServices.buildUniqueId())
        .execute();
}