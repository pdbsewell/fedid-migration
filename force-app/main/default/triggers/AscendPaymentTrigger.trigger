/**
 * @author Charlie Park UC - Innovation
 * @revision
 */
trigger AscendPaymentTrigger on ucinn_ascendv2__Payment__c (before insert, after insert, after update, before update, before delete, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('ucinn_ascendv2__Payment__c')) { 
    	return; 
    }

    new Triggers()
        	.bind(Triggers.Evnt.beforeInsert, new EngagePaymentService.setAuthorizeAndCharge())
			.bind(Triggers.Evnt.beforeUpdate, new EngagePaymentService.setAuthorizeAndCharge())
            .execute();
}