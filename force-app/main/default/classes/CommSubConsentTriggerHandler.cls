/**
 * @author       : Ibrahim Rumi
 * @date         : 15-02-2023
 * @group        : Consent Management
 * @description Trigger handler for CommSubscriptionConsent object
 * @revision
 *   15-02-2023  Ibrahim Rumi    - EPBBS-0000 added GenerateUuidIfMissing to Generate UUID if they don't already have it on record creation
**/


public class CommSubConsentTriggerHandler {
    /*
	 * @author:			Ibrahim Rumi
	 * @date: 15-02-2023
	 * @description:	Generate UUID for all records if they don't already have it on record creation.
	 */
	public class GenerateUuidIfMissing extends TriggerAbstract {
		public override void process(SObject record) {
			CommSubscriptionConsent c = (CommSubscriptionConsent)record;
			if(String.isEmpty(c.UUID__c)) {
                c.UUID__c = new Uuid().getValue();
			}
		}
    }
    
    
}