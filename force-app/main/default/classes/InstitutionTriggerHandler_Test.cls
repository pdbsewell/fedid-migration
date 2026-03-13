@isTest(isParallel=true)
public class InstitutionTriggerHandler_Test {

	@TestSetup
    static void testSetup() {
		Country_Attribute__c ca = new Country_Attribute__c (Active_Ind__c=true, Country__c='New Zealand', Callista_Country__c= 'New Zealand', Name='Aotearoa');
        insert ca;

		// institution for update test
        Institution__c inst = new Institution__c(Institution_Name__c = 'Burnside High School', Institution_Code__c = 'BSIDE1');
	    insert inst;    

		// institution for insert test
        inst = new Institution__c(Institution_Name__c = 'Canterbury University', Institution_Code__c = 'CU1', country__c = 'New Zealand');
	    insert inst;    
    }

	@isTest
    static void checkCountryLookup() {
        Institution__c inst;
        
		// Check lookup is assigned on insert
        inst = [select Institution_Name__c, country__c, Institution_Country__c from institution__c where Institution_Code__c = 'CU1' limit 1];
		system.assert.IsNotNull(inst.Institution_Country__c,'A country lookup is expected');    

        // Check lookup is assigned on update
        inst = [select Institution_Name__c, country__c, Institution_Country__c from institution__c where Institution_Code__c = 'BSIDE1' limit 1];
		system.assert.IsNull(inst.Institution_Country__c,'No country lookup is expected');    
		
        test.startTest();
        inst.country__c = 'New Zealand'; 
        update inst;
        test.stopTest();
        
        inst = [select Institution_Name__c, Institution_Country__c, Institution_Country__r.name, ISO_Country_API_Name__c from institution__c where Institution_Code__c = 'BSIDE1' limit 1];
		system.assert.isNotNull(inst.Institution_Country__c, 'Country lookup missing');
		system.assertEquals('Aotearoa', inst.Institution_Country__r.name, 'Country lookup incorrect');
		system.assertEquals('New Zealand', inst.ISO_Country_API_Name__c, 'Formula field incorrect');
        
    }
}