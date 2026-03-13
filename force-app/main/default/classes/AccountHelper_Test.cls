/**
 * @description       : Test class for Account Trigger Helper
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
 * @last modified on  : 2021-04-08
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2021-11-09 - Inderpal Dhanoa - Added test for SyncHierarchyLevel from Account to Account
**/
@isTest(isParallel=true)
public class AccountHelper_Test {

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         8.Nov.2021
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        // Unable to insert the parent and child accounts in a single DM as Parent and child records do not get linked 
        //https://salesforce.stackexchange.com/questions/156181/invalid-field-foreign-key-external-id-not-found-inserting-related-records-via
        //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_dml_foreign_keys.htm

        Id recType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();

        List<Account> l_accntList = new List<Account>();
        Account accLevel1 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 1', NumberOfEmployees = 1, RecordTypeId = recType), false);
        l_accntList.add(accLevel1);
        Account accLevel2 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 2', NumberOfEmployees = 2, RecordTypeId = recType), false);
        l_accntList.add(accLevel2);
        Account accLevel3 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 3', NumberOfEmployees = 3, RecordTypeId = recType), false);
        l_accntList.add(accLevel3);
        Account accLevel4 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 4', NumberOfEmployees = 4, RecordTypeId = recType), false);
        l_accntList.add(accLevel4);
        Account accLevel5 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 5', NumberOfEmployees = 5, RecordTypeId = recType), false);
        l_accntList.add(accLevel5);
        Account accLevel6 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 6', NumberOfEmployees = 6, RecordTypeId = recType), false);
        l_accntList.add(accLevel6);
        Account accLevel7 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 7', NumberOfEmployees = 7, RecordTypeId = recType), false);
        l_accntList.add(accLevel7);
        Account accLevel8 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 8', NumberOfEmployees = 8, RecordTypeId = recType), false);
        l_accntList.add(accLevel8);
        Account accLevel9 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 9', NumberOfEmployees = 9, RecordTypeId = recType), false);
        l_accntList.add(accLevel9);
        Account accLevel10 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 10', NumberOfEmployees = 10, RecordTypeId = recType), false);
        l_accntList.add(accLevel10);
        Account accLevel11 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 11', NumberOfEmployees = 11, RecordTypeId = recType), false);
        l_accntList.add(accLevel11);
        insert l_accntList;
        
        List<Account> l_relAccount = [SELECT Id, Name, ParentId FROM Account WHERE Name like 'Level%' order by NumberOfEmployees];
        for(Integer i = 1; i < l_relAccount.size() ; i++){
            l_relAccount[i].ParentId = l_relAccount[i-1].Id;
        }
        update l_relAccount;
        
        Test.getEventBus().deliver();
    }
    
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         8.Nov.2021
     * @description  Tests regarding to capturing the Hierarchy
    *******************************************************************************/ 
	@isTest 
    static void testUpdateHierarchy_Update() {
        
        Id recType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();

        //GIVEN
        // The Label exists for the minimum Level 
        String sMinLevel = 'Level ' + String.valueOf(Label.MinimumHierarchyLevel);
        
        //WHEN - Accounts are updated in the hierarchy
        //Start test
        Test.startTest();
        
        Account accLevel7 = [SELECT Id, ParentId FROM Account WHERE Name = 'Level 7'];
        Account accLevel2 = [SELECT Id, Name, Hierarchy_Level__c,Parent.Name, Monash_Faculty_Area_Name__c FROM Account WHERE Name = 'Level 2'];
        accLevel7.ParentId = accLevel2.Id;
        update accLevel7;
        
        Test.stopTest();
          
        //THEN - Accounts are populated with the revised hierarchy level, Level 8 is now the revised Level 4, Level 9 is now the revised Level 5
        Account accLevel8 = [SELECT Id, Name, Hierarchy_Level__c, Monash_Faculty_Area_Name__c FROM Account WHERE Name = 'Level 8'];
        Account accLevel9 = [SELECT Id, Name, Hierarchy_Level__c, Monash_Faculty_Area_Name__c FROM Account WHERE Name = 'Level 9'];
        
        System.assertEquals(accLevel8.Monash_Faculty_Area_Name__c, accLevel8.Name);
        System.assertEquals(accLevel9.Monash_Faculty_Area_Name__c, accLevel8.Name);        
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         8.Nov.2021
     * @description  Tests regarding to capturing the Hierarchy
    *******************************************************************************/ 
	@isTest 
    static void testUpdateHierarchy_Insert() {
        
        Id recType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();

        //GIVEN
        // The Label exists for the minimum Level 
        String sMinLevel = 'Level ' + String.valueOf(Label.MinimumHierarchyLevel);
        
        //WHEN - Accounts are updated in the hierarchy
        //Start test
        Test.startTest();
            Account accLevel10 = [SELECT Id, Name, Hierarchy_Level__c,Parent.Name, Monash_Faculty_Area_Name__c FROM Account WHERE Name = 'Level 10'];

            Account accLevel12 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 12', ParentId=accLevel10.Id, NumberOfEmployees = 12, RecordTypeId = recType), false);
            insert accLevel12;
        Test.stopTest();
          
        //THEN - Accounts are populated with the correct hierarchy level

        accLevel12 = [SELECT Id, Name, Hierarchy_Level__c,Parent.Name, Monash_Faculty_Area_Name__c FROM Account WHERE Name = 'Level 12'];
        Account accMinLevel = [SELECT Id, name FROM Account WHERE Name = :sMinLevel];
        
        System.assertEquals(accLevel12.Monash_Faculty_Area_Name__c, accMinLevel.Name);        
    }
}