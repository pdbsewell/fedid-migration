/**
 * @description       : Contact Service Class - ERDA only - Test Class
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 03-05-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=true)
public with sharing class ContactServiceERDA_Test {
    @testSetup
    static void setup() {
        TestDataFactoryERDA.createContactRelationship('Spouse', true);
        TestDataFactoryERDA.createContactRelationship('Partner', true);
    }
    
	@isTest
    public static void updateContactDeceasedTrueTest1(){
        Contact_Relationship__c oContactRelation = [SELECT Id, Contact__c FROM Contact_Relationship__c WHERE Type__c ='Spouse' LIMIT 1];
        Contact oContact = [SELECT Id, Deceased_Date__c, Deceased__c FROM Contact WHERE Id =:oContactRelation.Contact__c LIMIT 1];
        Test.startTest();
        //.. Set deceased flag to true.
        oContact.Deceased__c = true;
        update oContact;
        Test.stopTest();
        oContactRelation = [SELECT Id, End_Date__c FROM Contact_Relationship__c WHERE Contact__c =:oContact.Id LIMIT 1];
        System.assert(oContactRelation.End_Date__c != null, 'Contact Relationship market as deceased.');
    }
    
    @isTest
    public static void updateContactDeceasedTrueTest2(){
        Contact_Relationship__c oContactRelation = [SELECT Id, Contact__c FROM Contact_Relationship__c WHERE Type__c ='Partner' LIMIT 1];
        Contact oContact = [SELECT Id, Deceased_Date__c, Deceased__c FROM Contact WHERE Id =:oContactRelation.Contact__c LIMIT 1];
        Test.startTest();
        //.. Set deceased flag to true.
        oContact.Deceased__c = true;
        update oContact;
        Test.stopTest();
		oContactRelation = [SELECT Id, End_Date__c FROM Contact_Relationship__c WHERE Contact__c =:oContact.Id LIMIT 1];
        System.assert(oContactRelation.End_Date__c != null, 'Contact Relationship market as deceased.');
    }
    
    @isTest
    public static void updateContactDeceasedTrueTest3(){
        Contact_Relationship__c oContactRelation = [SELECT Id, Contact__c FROM Contact_Relationship__c WHERE Type__c ='Spouse' LIMIT 1];
        Contact oContact = [SELECT Id, Deceased_Date__c, Deceased__c FROM Contact WHERE Id =:oContactRelation.Contact__c LIMIT 1];
        oContact.Deceased_Date__c = System.today() - 2;
        Test.startTest();
        //.. Set deceased flag to true.
        oContact.Deceased__c = true;
        update oContact;
        Test.stopTest();
        oContactRelation = [SELECT Id, End_Date__c FROM Contact_Relationship__c WHERE Contact__c =:oContact.Id LIMIT 1];
        System.assert(oContactRelation.End_Date__c != null, 'Contact Relationship market as deceased.');
    }
    
    @isTest
    public static void updateContactDeceasedTrueNegativeTest(){
        Contact_Relationship__c oContactRelation = [SELECT Id, Contact__c FROM Contact_Relationship__c WHERE Type__c ='Spouse' LIMIT 1];
        Contact oContact = [SELECT Id, Deceased_Date__c, Deceased__c FROM Contact WHERE Id =:oContactRelation.Contact__c LIMIT 1];
        Test.startTest();
        //.. Set deceased flag to false.
        oContact.Deceased__c = false;
        update oContact;
        Test.stopTest();
		oContactRelation = [SELECT Id, End_Date__c FROM Contact_Relationship__c WHERE Contact__c =:oContact.Id LIMIT 1];
        System.assert(oContactRelation.End_Date__c == null, 'Contact Relationship still active.');
    }
}