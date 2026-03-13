/**
 * @description       : Test Data Factory for the Person 360 structure
 * @author            : Nick Guia
 * @last modified on  : 18-07-2023
 * @last modified by  : Nick Guia
**/
@isTest
public without sharing class Person360TestDataFactory {

    private Boolean isMock = false;
    
    public Person360TestDataFactory(Boolean shouldMock) {
        this.isMock = shouldMock;
    }

    /**
    * @description generate a Person 360 instance. Will insert an affiliation account
    * @author Nick Guia | 17-07-2023 
    * @param Contact con : try to use unique names on your contact; should have FN and LN
    * @return Person360 
    **/
    public Person360 createPerson360(Contact con) {
        return createPerson360(con, createAgencyAccount());
    }

    /**
    * @description create an Agency type account
    * @author Nick Guia | 17-07-2023 
    * @return Account 
    **/
    public Account createAgencyAccount() {
        return new Account(
            Id = isMock ? fflib_IDGenerator.generate(Account.SObjectType) : null,
            Name = 'Person 360 Pty Ltd',
            Phone = '987654',
            Email__c = 'p360.australia@test.org',
            Website = 'www.p360-australia.com',
            Street__c = 'Collins St',
            City__c = 'Melbourne',
            State__c = 'VIC',
            Post_Code__c = '3000',
            ShippingStreet = 'Collins St',
            ShippingCity = 'Melbourne',
            ShippingState = 'VIC',
            ShippingPostalCode = '3000',
            ShippingCountry = 'Australia',
            Monash_AM_Web_Status__c = true,
            Callista_Org_Unit_Code__c = 'CRM-AGENT',
            Monash_AM_Campus__c = 'Australia',
            RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE,
            Status__c = 'Appointed'
        );
    }

    /**
    * @description generate a Person 360 instance
    * @author Nick Guia | 17-07-2023 
    * @param Contact con : try to use unique names on your contact; should have FN and LN
    * @param Account affiliationAccount : Account to be linked to Affiliation (required)
    * @return Person360 
    **/
    public Person360 createPerson360(Contact con, Account affiliationAccount) {

        Person360.Person360Builder builder = new Person360.Person360Builder(con);

        // affiliation
        builder.withAffiliation(affiliationAccount?.Id, 'Applicant');

        // address
        builder.buildAddress()
                .withClassification('Private')
                .withStreetName('Collins St')
                .withCity('Melbourne')
                .withState('VIC')
                .withPostCode('3000')
                .withCountry('Australia')
                .withType('Mailing')
                .withSource('Contact supplied');
        // phone
        builder.buildPhone()
                .withClassification('Private')
                .withPhoneNumber('+61 497000000')
                .withType('Mobile')
                .withSource('Contact supplied');
        // email
        builder.buildEmail()
                .withClassification('Private')
                .withEmailId('person360.testdatafactory@test.org')
                .withSource('Contact supplied');
        // name
        builder.buildName()
                .withSalutation('Mr')
                .withName(con.FirstName, 'MiddleName', con.LastName)
                .withSuffix('Jr')
                .withType('Common')
                .withSource('Contact supplied');

        if(this.isMock) {
            mockFields(builder);
        } else {
            // bypass the builder and set default start dates on each contact points
            // this is so that we can keep the triggers muted since start date is required
            // TODO : add withStartDate() on ContactPointBuilderFactory
            for(String cpKey : builder.contactPointMap.keySet()) {
                List<SObject> cpList = builder.contactPointMap.get(cpKey);
                
                for(SObject cpRec : cpList) {
                    // assume all api names are the same
                    cpRec.put('Start_Date__c', Date.today());
                }
            }
        }

        return builder.build();
    }

    /**
    * @description mocks the IDs and read-only fields
    * @author Nick Guia | 17-07-2023 
    * @param Person360.Person360Builder builder 
    **/
    private void mockFields(Person360.Person360Builder builder) {

        builder.conRec.Id = (builder.conRec.Id == null) ? fflib_IDGenerator.generate(Contact.SObjectType) : builder.conRec.Id;
        builder.accRec.Id = fflib_IDGenerator.generate(Account.SObjectType);
        builder.affRec.Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType);

        Map<String, String> cpaTypeMap = new Map<String, String>{
            'Phone__c' => 'Phone',
            'Email__c' => 'Email',
            'Address__c' => 'Address'
        };

        // generate mock Ids for contact points and CPAs
        for(String cpType : builder.contactPointMap.keySet()) {

            List<SObject> lstSObj = builder.contactPointMap.get(cpType);

            // ignore the CPAs in the builder - create a new one
            List<Contact_Point_Affiliation__c> lstCPA = new List<Contact_Point_Affiliation__c>();

            for(SObject iCp : lstSObj) {
                iCp.put('Id', fflib_IDGenerator.generate(iCp.getSObjectType()));
                // link CP to Contact
                iCp.put('Contact__c', builder.conRec.Id);
                iCp.put('Start_Date__c', Date.today());

                if(cpType != 'Name__c') { // Do not create CPA for Names
                    Contact_Point_Affiliation__c cpa = new Contact_Point_Affiliation__c();
                    // link CPA to contact
                    cpa.put('Contact__c', builder.conRec.Id);
                    // link CPA to affiliation
                    cpa.put('Affiliation__c', builder.affRec.Id);
                    // link CPA to CP; assumption is that SObjectType = Lookup field API
                    cpa.put(cpType, iCp.Id); 
                    // populate the rest of the mocks
                    cpa = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
                        cpa,
                        Contact_Point_Affiliation__c.class,
                        new Map<SObjectField, Object> {
                            Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                            Contact_Point_Affiliation__c.Type__c => cpaTypeMap.get(cpType)
                        }
                    );
                    lstCPA.add(cpa);
                }
            }

            builder.cpaMap.put(cpType, lstCPA);
        }
    }
}