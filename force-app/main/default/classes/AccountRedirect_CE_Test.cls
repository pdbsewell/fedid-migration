/**
 * Test coverage written for the AccountRedirect Controller Extension
 * 
 * @param   NIL	collection of static methods
 * @return  NIL
 * @see		AccountRedirect_CE
 */
@isTest(isParallel=true)
private class AccountRedirect_CE_Test {

    static testMethod void testRedirectOfAccountTypes() {
        
        List<contact> contacts  = TestHelper.createOrphanContactRecords(1);
        
        insert contacts;
        
        // test with Organisation
        
        Account organisation = new Account(name = 'test organisation',
        								   RecordTypeId = CommonServices.recordTypeId('Account',AccountServices.ACCOUNT_ORGANISATION_TYPE));
        
        insert organisation;

        ApexPages.StandardController stdAccount = new ApexPages.StandardController(organisation);
        
        AccountRedirect_CE con = new AccountRedirect_CE(stdAccount);
        PageReference result = con.IndividualRedirect();
        
        system.assert(result.getUrl().startsWith('/001')); // expect will direct to org record
        
        // now test with Individual
        
        Id accountId = [select id,accountId from contact where id =:contacts[0].id limit 1].accountId ; // the id resulting from Individual creation
        					
        stdAccount = new ApexPages.StandardController([select id from Account where id =:accountId limit 1]);
        
        con = new AccountRedirect_CE(stdAccount);
        
        result = con.IndividualRedirect();
        
        system.assert(result.getUrl().startsWith('/001')); // it will redirect to actual account
        
        system.debug(result);
    }
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         23.Feb.2017         
    * @description  test for Base Profile users
    *******************************************************************************/
    static testMethod void testRedirectOfAccountTypes_Ran_by_Base_Profile() {
        
        User baseProfileUser = TestHelper.createTestUsers('Base Profile', 1)[0];
        //run as a base profile user to test the redirect
        system.runAs(baseProfileUser) {
            List<contact> contacts  = TestHelper.createOrphanContactRecords(1);
        
            insert contacts;
            
            // test with Organisation
            
            Account organisation = new Account(name = 'test organisation',
                                               RecordTypeId = CommonServices.recordTypeId('Account',AccountServices.ACCOUNT_ORGANISATION_TYPE));
            
            insert organisation;
            ApexPages.StandardController stdAccount = new ApexPages.StandardController(organisation);
            
            AccountRedirect_CE con = new AccountRedirect_CE(stdAccount);
            PageReference result = con.IndividualRedirect();
            
            system.assert(result.getUrl().startsWith('/001')); // expect will direct to org record
            
            // now test with Individual
            
            Id accountId = [select id,accountId from contact where id =:contacts[0].id limit 1].accountId ; // the id resulting from Individual creation
                                
            stdAccount = new ApexPages.StandardController([select id from Account where id =:accountId limit 1]);
            
            con = new AccountRedirect_CE(stdAccount);
            
            result = con.IndividualRedirect();
            
            system.assert(result.getUrl().startsWith('/003')); // expect will direct to contact record
            system.debug(result);
        }
    }
    
    /*******************************************************************************
    * @author       Kristian Vegerano   
    * @description  test redirection for lightning experience
    *******************************************************************************/
    static testMethod void testDetermineRedirect_As_NonAdmin() {
        User nonAdminUser = [SELECT Id, Profile.Name
                            FROM User
                            WHERE ProfileId != null
                                AND Profile.Name != :Label.Profile_SystemAdministrator
                                AND IsActive = true
                            LIMIT 1]; 
        Account testAccount = new Account(Name = 'TestAccount', 
                                          RecordTypeId = CommonServices.recordTypeId('Account', AccountServices.ACCOUNT_INDIVIDUAL_TYPE));
        insert testAccount;
            
        Contact testContact = new Contact(LastName = 'TestLastName', 
                                  AccountId = testAccount.Id,
                                  RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Not known to Monash systems').getRecordTypeId());                    
        insert testContact;
                                              
        Id returnedId; 
        System.runAs(nonAdminUser){  
            Test.startTest();
                returnedId = AccountRedirect_CE.determineRedirect(testAccount.Id);
            Test.stopTest();
        }
    }
}