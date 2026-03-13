/**
 * @author       : Ibrahim Rumi
 * @date         : 15-02-2023
 * @group        : Consent Management
 * @description Trigger handler for AuthorizationFormConsent object
 * @revision
 *   15-02-2023  Ibrahim Rumi    - EPBBS-0000 added GenerateUuidIfMissing to Generate UUID if they don't already have it on record creation
**/


public class AuthFormConsentTriggerHandler {
    /*
	 * @author:			Ibrahim Rumi
	 * @date: 15-02-2023
	 * @description:	Generate UUID for all records if they don't already have it on record creation.
	 */
	public class GenerateUuidIfMissing extends TriggerAbstract {
		public override void process(SObject record) {
			AuthorizationFormConsent authFormConsent = (AuthorizationFormConsent)record;
			if(String.isEmpty(authFormConsent.UUID__c)) {
                authFormConsent.UUID__c = new Uuid().getValue();
			}
		}
    }
    
    
}