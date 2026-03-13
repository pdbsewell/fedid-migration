/**
 * @description Test class for CricosCodeSelector
 */
@isTest(isParallel=true)
public class CricosCodeSelector_Test {

    @testSetup
    static void makeData(){
        List<CRICOS_Code__c> cricosCodeTestData = new List<CRICOS_Code__c>();

        CRICOS_Code__c cricosRecord1 = new CRICOS_Code__c();
        cricosRecord1.Name = '041042F';
        cricosRecord1.Course_Version_Key__c = '2602_4';
        cricosRecord1.Type__c = 'CRICOS';
        cricosCodeTestData.add(cricosRecord1);

        CRICOS_Code__c cricosRecord2 = new CRICOS_Code__c();
        cricosRecord2.Name = '041042F';
        cricosRecord2.Course_Version_Key__c = '2602_5';
        cricosRecord2.Type__c = 'CRICOS';
        cricosCodeTestData.add(cricosRecord2);

        CRICOS_Code__c cricosRecord3 = new CRICOS_Code__c();
        cricosRecord3.Name = '043635J';
        cricosRecord3.Course_Version_Key__c = '2609_7';
        cricosRecord3.Type__c = 'CRICOS';
        cricosCodeTestData.add(cricosRecord3);

        CRICOS_Code__c cricosRecord4 = new CRICOS_Code__c();
        cricosRecord4.Name = '034865C';
        cricosRecord4.Course_Version_Key__c = '2476_2';
        cricosRecord4.Type__c = 'CRICOS Exchange';
        cricosCodeTestData.add(cricosRecord4);

        CRICOS_Code__c cricosRecord5 = new CRICOS_Code__c();
        cricosRecord5.Name = '018367K';
        cricosRecord5.Course_Version_Key__c = '2476_2';
        cricosRecord5.Type__c = 'CRICOS';
        cricosCodeTestData.add(cricosRecord5);

        TriggerCommon.disableTrigger('CRICOS_Code__c');
        insert cricosCodeTestData;

    }

    @isTest
    static void shouldReturnSObjectType() {
        CricosCodeSelector cricosCodeSelector = new CricosCodeSelector();
        System.assertNotEquals(null, cricosCodeSelector.getSObjectType(), 
            'Expected SObject type to be returned.'
        );
    }

    @isTest
    static void shouldReturnNoCricosCodeWhenCourseVersionRecordDoesNotExistForTypeCricos() {
        CricosCodeSelector cricosCodeSelector = new CricosCodeSelector();
        List<CRICOS_Code__c> results = 
            cricosCodeSelector.selectByCourseVersionKeyAndType(
                new Set<String>{'DOESNOTEXIST1'}, 'CRICOS'
            );
        System.assertEquals(true, results.isEmpty(), 'Expected no results found');
    }

    @isTest
    static void shouldReturnOneCricosCodeWhenCourseVersionRecordExistsForTypeCricos() {
        CricosCodeSelector cricosCodeSelector = new CricosCodeSelector();
        List<CRICOS_Code__c> results = 
            cricosCodeSelector.selectByCourseVersionKeyAndType(
                new Set<String>{'2476_2'}, 'CRICOS'
            );
        System.assertEquals('018367K', results[0].Name, 'Expecting the correct matching CRICOS code');
        System.assertEquals(1, results.size(), 'Expected only 1 CRICOS code match');
    }
}