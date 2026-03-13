@isTest
public with sharing class ContactPointAffiliationServices_Test {

    @testSetup
    static void setup() {
		// Agency accounts require countries
        Country_Attribute__c country = new Country_Attribute__c(Name = 'AUSTRALIA',
                                           Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                           Country__c = 'Australia');
        insert country;  
        
		// Create an agency account
		// Nothing about the tests require that the account is promoted to a partner
		Account agency = new Account();
        agency.Name = 'Kangaroo Education';
        agency.Callista_Org_Unit_Code__c = 'KANGA-ED';
        agency.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId();
        agency.Monash_AM_Campus__c = 'Australia';
		agency.City__c = 'Bangalore';
        agency.Post_Code__c = '400028';
        agency.Email__c = 'Kangaroo@Education.com';
        agency.Status__c = 'Appointed';
        agency.Country_Lookup__c = country.id;
        insert agency;
        
        // Our identifiable test contact
		Contact con = StudFirst_TestHelper.createApplicant();
        con.AssistantName = 'CPA Test Contact';
        insert con;

		// Contact Point
        Phone__c ph = new Phone__c(name='+61 401555555',type__c='Mobile', classification__c = 'Private', start_date__c = date.today(), contact__c=con.id);
        insert ph;

		// Contact Point
        Email__c em = new Email__c(name='egarapplication@home.co.xx',classification__c = 'Private', start_date__c = date.today(), contact__c=con.id);
        insert em;

		// Contact Point
        Address__c ad = new Address__c(Street_name__c = '1 The Ridge', classification__c = 'Private', start_date__c = date.today(), contact__c=con.id);
        insert ad;
        
        // Affiliate the test contact with the agency
        Affiliation__c aff = new Affiliation__c (start_date__c = date.today(), Contact__c=con.id, account__c=agency.id, RecordTypeId=Schema.SObjectType.Affiliation__c.getRecordTypeInfosByName().get('Applicant').getRecordTypeId());
        insert aff;
    }

    /*
     * 1. Check that the unique composite key is generated and formed of the required two ids
     *    Requires the feature switch to be enabled (see setup)
     * 2. Check that the name field is built correctly with fields from the Contact, Affiliation and Phone contact point 
	 */
    @isTest
    static void testTheFirst() {

        // Enable the feature switch to generate the CPA unique key and enable the polymorphic validation rule
		Feature_Switch__c fs = new Feature_Switch__c();
        fs.Generate_UK_for_CPA__c = true;
        insert fs;
        
        Contact ct = [select id, (select id from Affiliations__r), (select id from phones__r) from contact where AssistantName = 'CPA Test Contact' limit 1];
		Phone__c ph = ct.phones__r[0];
		Affiliation__c af = ct.Affiliations__r[0];
        
        test.starttest();
        // Create a CPA record for the phone contact point
        contact_point_affiliation__c cpa = new contact_point_affiliation__c(affiliation__c=af.id, contact__c=ct.id, phone__c=ph.id, start_date__c = date.today());
        insert cpa;
        test.stoptest();

		cpa = [select name, type__c, Affiliation__c, phone__c, Composite_Key__c
                    , contact__r.crm_id__c
                    , affiliation__r.account__r.callista_org_unit_code__c, affiliation__r.recordtype.name
               from contact_point_affiliation__c where id = :cpa.id];

        // Is the name field correct?
        system.assertEquals(cpa.contact__r.crm_id__c + '/' 
                          + cpa.affiliation__r.account__r.callista_org_unit_code__c + '/'
                          + cpa.affiliation__r.recordtype.name +'/'
                          + cpa.type__c, cpa.name, 'The name format does not meet expectations');
        
        // Has the composite key been generated?
		system.assertEquals(String.valueOf(cpa.Affiliation__c) + cpa.phone__c, cpa.Composite_Key__c, 'The composite key should be a combination of affiliation and contact ids');
    }
    
    /*
     * 1. Check that the feature switch does disable the generation of a unique composite key
	 */
    @isTest
    static void testTheSecond() {

        // Disable the feature switch to generate the CPA unique key
		Feature_Switch__c fs = new Feature_Switch__c();
        fs.Generate_UK_for_CPA__c = false;
        insert fs;
        
        Contact ct = [select id, (select id from Affiliations__r), (select id from emails__r) from contact where AssistantName = 'CPA Test Contact' limit 1];
		Email__c em = ct.emails__r[0];
		Affiliation__c af = ct.Affiliations__r[0];

        test.starttest();
        // Create a CPA record for the phone contact point
        contact_point_affiliation__c cpa = new contact_point_affiliation__c(affiliation__c=af.id, contact__c=ct.id, email__c=em.id, start_date__c = date.today());
        insert cpa;
        test.stoptest();

		cpa = [select name, type__c, Affiliation__c, email__c, Composite_Key__c
                    , contact__r.crm_id__c
                    , affiliation__r.account__r.callista_org_unit_code__c, affiliation__r.recordtype.name
               from contact_point_affiliation__c where id = :cpa.id];

        // Has the composite key generation been skipped?
		system.assertEquals(null, cpa.Composite_Key__c, 'The composite key should not be populated');
    }
    
    /*
     * 1. Verifiy that the type of CPA is correct
     *    Insert and Update are done (not a real world scenario)
	 */
    @isTest
    static void testTheThird() {
		Feature_Switch__c fs = new Feature_Switch__c();
        fs.Generate_UK_for_CPA__c = true;
        insert fs;
        
        Contact ct = [select id, (select id from Affiliations__r), (select id from addresses__r), (select id from phones__r) from contact where AssistantName = 'CPA Test Contact' limit 1];
		address__c ad = ct.addresses__r[0];
        phone__c ph = ct.phones__r[0];
		Affiliation__c af = ct.Affiliations__r[0];

        test.starttest();
        // Create a CPA record for the address contact point
        contact_point_affiliation__c cpa = new contact_point_affiliation__c(affiliation__c=af.id, contact__c=ct.id, address__c=ad.id, start_date__c = date.today());
        insert cpa;
		cpa = [select name, type__c
               from contact_point_affiliation__c where id = :cpa.id];

        // Has the type been correctly indicated?
		system.assertEquals('Address', cpa.type__c, 'The CPA type is incorrect');

        // Update the CPA to an address (which also helps with code coverage)
        cpa.Address__c = null;
        cpa.Phone__c = ph.id;
		update cpa;
        
        test.stoptest();

		cpa = [select name, type__c
               from contact_point_affiliation__c where id = :cpa.id];

        // Has the type changed?
		system.assertEquals('Phone', cpa.type__c, 'The CPA type is incorrect');
    }
}