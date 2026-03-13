/**
 * @description       : Trigger Handler to manage all DML and events on EnquiryOrganisations test Classes
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
**/
@Istest(isParallel=true)
public class EnquiryOrganisationsHandler_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         11.May.2021
    * @description  Test setup
    *******************************************************************************/
    @testSetup static void setup() {

       Test.startTest();
        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'External_Organisation' LIMIT 1][0];
        Account acct0 = new Account(Name='Acct0', RecordTypeId = recType.Id);
        insert acct0;

        Account acct1 = new Account(Name='Acct1', RecordTypeId = recType.Id);
        insert acct1;

        Account acct2 = new Account(Name='Acct2', RecordTypeId = recType.Id);
        insert acct2;

        String admissionsRecType = CommonServices.recordTypeId('Case', 'Enterprise');
        Case caseRec = new  Case(SuppliedName = 'testName',
								SuppliedPhone = '0400000000',
								SuppliedEmail = 'testformEmail@monash.edu',
								AccountId = acct0.Id,
								RecordTypeId = admissionsRecType );
		insert caseRec;
    }

    /* Method Name: getMyRelatedOpportunities
     * Description: method to extract recent Opportunities
     * returns a List of Wrapper with Opportunity Details and Account Details
    */
    @isTest
    public static void validateDuplicateOrganisationsTest(){
        
        Test.startTest();
        List<Case> existEnquiry = [SELECT Id FROM Case];
        List<Account> existOrgs = [SELECT Id FROM Account ORDER BY createdDate ASC];

        // Insert Scenario
        Enquiry_Organisations__c newOrg1 = new Enquiry_Organisations__c(Account__c = existOrgs[1].Id, Enquiry__c = existEnquiry[0].Id);
        Enquiry_Organisations__c newOrg2 = new Enquiry_Organisations__c(Account__c = existOrgs[1].Id, Enquiry__c = existEnquiry[0].Id);
        List<Enquiry_Organisations__c> l_newOrgs = new List<Enquiry_Organisations__c>();
        l_newOrgs.add(newOrg1);
        l_newOrgs.add(newOrg2);
        try{
            insert l_newOrgs;
        }catch(Exception ex){
            String validationError = Label.EnquiryOrganisation_ValidationError;
            Boolean expectedExceptionThrown =  ex.getMessage().contains(validationError) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);    
        }
        newOrg2 = new Enquiry_Organisations__c(Account__c = existOrgs[2].Id, Enquiry__c = existEnquiry[0].Id);
        l_newOrgs.clear();
        l_newOrgs.add(newOrg1);
        l_newOrgs.add(newOrg2);
        insert l_newOrgs;
        
        List<Enquiry_Organisations__c> result = [SELECT Id, Account__c, Enquiry__c FROM Enquiry_Organisations__c];
        system.assertEquals(result.size(),2);
        for(Enquiry_Organisations__c existOrgEnqs : result){
            existOrgEnqs.Account__c = existOrgs[1].Id;
        }
        try{
            update result;
        }catch(Exception ex){
            String validationError = Label.EnquiryOrganisation_ValidationError;
            Boolean expectedExceptionThrown =  ex.getMessage().contains(validationError) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);    
        }
        Test.stopTest();
    }
}