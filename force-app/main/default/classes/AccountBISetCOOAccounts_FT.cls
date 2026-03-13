/**
 * @description       : 
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 21-02-2025
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=false) //.. using runAs function.
public with sharing class AccountBISetCOOAccounts_FT {    
    
    @isTest
    private static void updateCOOAccountFlag(){
        
        // GIVEN : Create new Account with RT Type = Organization
        Account oAccount = new Account();
        oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
        oAccount.Name = 'Flow Testing COO Account FT-1';
        
        //.. Create standard user with Office_of_the_Chief_Operating_Officer Role.
        User oStandardUser = createUser();

        //WHEN :  Insert new account with Standard User.
        System.runAs(oStandardUser) {
            Test.startTest();
            insert oAccount;
            Test.stopTest();
        }

        //THEN : COO flag is set to true.
        Account oAccountUpdated = [SELECT Id, Is_COO_Account__c FROM Account WHERE Id=: oAccount.Id LIMIT 1];
        Assert.areEqual (true, oAccountUpdated.Is_COO_Account__c); 
    }

    //.. Create Standard User
    static User createUser(){
        Integer iRandoomNumber = Integer.valueOf(Math.random()*9999);
        User oUser = new User();
        oUser.Alias = 'User' + iRandoomNumber;
        oUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
        oUser.Email = String.valueOf(iRandoomNumber) +'testuser@mutesting.edu';
        oUser.EmailEncodingKey='UTF-8';
        oUser.LastName='TestingUser';
        oUser.LanguageLocaleKey='en_US';
        oUser.LocaleSidKey='en_GB';
        oUser.TimeZoneSidKey='Australia/Sydney';
        oUser.UserName= String.valueOf(iRandoomNumber) +'testuser@mutesting.edu';
        oUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Office_of_the_Chief_Operating_Officer' LIMIT 1].Id;
        insert oUser;
        return oUser;
    }
}