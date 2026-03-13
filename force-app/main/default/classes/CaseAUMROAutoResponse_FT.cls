/**
 * @description       : Test class for Case : AU : MRO Enquiry Defaults & Auto Responses flow
 * @author            : Matthew Maramot
 * @created date      : 11/06/2024
 * @group             : Monash Research Office (MRO)
**/
@isTest (isParallel=true)
public with sharing class CaseAUMROAutoResponse_FT {
    //Different types of MRO enquiries to be tested
    static List<String> toAddressList = new List<String>{'mrff@monash.edu',
    'mro.researchdevelopment@monash.edu',
    'mro.pivotrp@monash.edu',
    'mro-awards@monash.edu',
    'mro-majorawards@monash.edu',
    'mro-applications@monash.edu'};
    
    //Set up test data that will be used across all test methods
	@testSetup
	static void setup(){
		//Populate custom settings
        RecordTypes_Allowed_on_CaseTrigger__c rec = new RecordTypes_Allowed_on_CaseTrigger__c(Name='Monash Research Office', API_Name__c ='Monash Research Office');
        insert rec;

        //Create MRO Enquiries
        List<Case> caseList = new List<Case>();
        for(String toAddress : toAddressList){
            Case testCase = new Case();
            testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
            testCase.Origin = 'Email';
            testCase.suppliedEmail = 'testmonash.addressonly@monash.edu';
            caseList.add(testCase);
        }
        insert caseList;
	}

    @isTest
    private static void EnquiryDefaults_Test() {      
        //Mock Email Routing Addresses
        Map<Id, EmailRoutingAddress> routingAddressMap = new Map<Id, EmailRoutingAddress>();
        for(String toAddress : toAddressList){
            EmailRoutingAddress testRoutingAddress = new EmailRoutingAddress(Id = fflib_IDGenerator.generate(EmailRoutingAddress.SObjectType),
            Address = toAddress);
            routingAddressMap.put(testRoutingAddress.Id, testRoutingAddress);
        }
        EmailMessageUtility.testEmailRoutingAddressMap = routingAddressMap;
        List<Id> routingAddressIds = new List<Id>(routingAddressMap.keySet());

        // GIVEN : Create Enquiries with Record Type Monash Research Office
        List<Case> mroCases = [SELECT Id FROM Case WHERE suppliedEmail = 'testmonash.addressonly@monash.edu'];

        // WHEN : Enquiry is updated due to email message
        Test.startTest();
        List<EmailMessage> emailList = new List<EmailMessage>();
        Integer i = 0;
        for(String toAddress : toAddressList){
            emailList.add(new EmailMessage( ParentId = mroCases[i].Id,
                FromAddress = 'testfrom@testmonash.edu',
                FromName = 'testSender',
                Subject = 'testSubject',
                TextBody = 'test body',
                HTMLBody = 'HTML body',
                ToAddress = toAddress,
                Incoming = true,
                EmailRoutingAddressId = routingAddressIds[i]
			));
            i++;
        }
		insert emailList;

        // THEN : Verify Enquiry Default Assignment
        Test.stopTest();
        Assert.areEqual(1, [SELECT Id  FROM Case WHERE Enquiry_Type__c LIKE 'Research Development' AND Group__c LIKE 'MRFF' AND Category_Level_1__c LIKE 'General'].size(), 'MRFF enquiry defaults not assigned correctly');
        Assert.areEqual(1, [SELECT Id  FROM Case WHERE Enquiry_Type__c LIKE 'Research Development' AND Group__c LIKE 'Major Initiative' AND Category_Level_1__c LIKE 'General'].size(), 'Major Initiative enquiry defaults not assigned correctly'); 
        Assert.areEqual(1, [SELECT Id  FROM Case WHERE Enquiry_Type__c LIKE 'Research Development' AND Group__c LIKE 'Pivot-RP' AND Category_Level_1__c LIKE 'General'].size(), 'Research Professional enquiry defaults not assigned correctly'); 
        Assert.areEqual(1, [SELECT Id  FROM Case WHERE Enquiry_Type__c LIKE 'Award' AND Category_Level_1__c LIKE 'General'].size(), 'Award enquiry defaults not assigned correctly'); 
        Assert.areEqual(1, [SELECT Id  FROM Case WHERE Enquiry_Type__c LIKE 'Major Award' AND Category_Level_1__c LIKE 'General'].size(), 'Major Award enquiry defaults not assigned correctly'); 
        Assert.areEqual(1, [SELECT Id  FROM Case WHERE Enquiry_Type__c LIKE 'Application' AND Category_Level_1__c LIKE 'General'].size(), 'Application enquiry defaults not assigned correctly'); 
    }
}