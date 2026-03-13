/**
 * @author       : Ibrahim Rumi
 * @date         : 15-02-2023
 * @group        : Consent Management
 * @description Trigger handler for AuthorizationFormConsent object
 * @revision
 *   15-02-2023  Ibrahim Rumi    - EPBBS-0000 added GenerateUuidIfMissing to Generate UUID if they don't already have it on record creation
**/

@isTest
private class AuthFormConsentTriggerHandler_Test {

    @testSetup
    static void setup() {
        AuthorizationForm af = new AuthorizationForm();
        af.Name = 'test Authorization Form';
        af.EffectiveFromDate = System.today();

        insert af;

        AuthorizationFormText aft = new AuthorizationFormText();
        aft.name = 'test Authorization Form Text';
        aft.AuthorizationFormId = af.Id;

        insert aft;

        Contact testContact = new Contact(LastName = 'TestContact');
		insert testContact;

    }

    /*
	 * @author:			Ibrahim Rumi
	 * @description:	Test Generate UUID if they don't already have it on record creation.
	 */
	@isTest
    static void testGenerateUuidIfMissing() {
        List<AuthorizationFormConsent> authorizationFormConsentList = new List<AuthorizationFormConsent>();
        
        List<AuthorizationFormText> aftList = new List<AuthorizationFormText>();
        List<Contact> conList = new List<Contact>();

        aftList = [SELECT id,name from AuthorizationFormText LIMIT 1];
		conList = [SELECT id FROM contact LIMIT 1];

        AuthorizationFormConsent afc = new AuthorizationFormConsent();

        afc.AuthorizationFormTextId= aftList[0].Id;
        afc.name = 'Test AuthorizationFormConsent';
        afc.ConsentCapturedSourceType = 'Email';
        afc.ConsentCapturedDateTime = system.now();
        afc.ConsentCapturedSource = 'Monash sites';
        afc.ConsentGiverId = conList[0].id;

        authorizationFormConsentList.add(afc);
        
        insert authorizationFormConsentList;
        
        Test.startTest();
        
        afc = [SELECT Id, UUID__c FROM authorizationFormConsent LIMIT 1];
        
        Test.stopTest();
        
        Assert.isNotNull(afc.UUID__c, 'GenerateUuidIfMissing is not working.');
    }
    
}