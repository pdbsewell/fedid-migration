trigger EmergencyContactTrigger on Emergency_Contact__c (before insert, before update) {

	if (TriggerCommon.doNotRunTrigger('Emergency_Contact__c')) {
		return;
	}
	//Run Trigger
	new Triggers()
	.bindExtended(Triggers.Evnt.beforeinsert, new EmergencyContactServices.managePhoneFields())
	.bindExtended(Triggers.Evnt.beforeinsert, new EmergencyContactServices.manageNameFields())
	.bindExtended(Triggers.Evnt.beforeinsert, new EmergencyContactServices.manageEmailFields())
	.bindExtended(Triggers.Evnt.beforeinsert, new EmergencyContactServices.populateHash())

    .bindExtended(Triggers.Evnt.beforeupdate, new EmergencyContactServices.managePhoneFields())
    .bindExtended(Triggers.Evnt.beforeupdate, new EmergencyContactServices.manageNameFields())
    .bindExtended(Triggers.Evnt.beforeupdate, new EmergencyContactServices.manageEmailFields())
	.bindExtended(Triggers.Evnt.beforeupdate, new EmergencyContactServices.populateHash())
	.execute();

}