/****************************************************************************
@Name: GOEDCardController_Test
@Author: Kevin Evasco (GrowthOps)
********************************************************************************/
@isTest(isParallel=true)
public class GOEDCardController_Test {

    
    static testmethod void positiveTest(){
        // setup so that half of cases to be inserted have existing contact, and half dont
        // some will use monash email address, and some the personal email address
        
        List<Contact> testContacts = TestHelper.createStudentContacts(1, null);
        List<Case> webToCaseForms = TestHelper.webToCaseForms(1);
        
        TriggerCommon.disableTrigger('Contact'); // have set up own alternate email addresses etc, so wont
        insert testContacts;
        TriggerCommon.enableTrigger('Contact');
        
        Set<Id> testContactIds = new Map<Id, Contact>(testContacts).keySet();
        
        webToCaseForms[0].SuppliedEmail = testContacts[0].Monash_Email_Address__c;
        insert webToCaseForms;
        
        Test.startTest();
        
        Case caseRec = [SELECT Id,SuppliedEmail FROM Case LIMIT 1];
        Map<String, String> parameterMap = new Map<String, String>();
        parameterMap.put('recId',caseRec.Id);
        parameterMap.put('outcomeField','Prediction_Outcome__c');
        parameterMap.put('explanationField','Prediction_Explanation__c');
        parameterMap.put('recommendationField','Prediction_Recommendation__c');
        
        GOEDCardController.getEDInfo(JSON.serialize(parameterMap));
        
        Test.stopTest();
        
        system.assertEquals(caseRec.SuppliedEmail,webToCaseForms[0].SuppliedEmail);
        
    }
    
    static testmethod void negativeTest(){
    // setup so that half of cases to be inserted have existing contact, and half dont
        // some will use monash email address, and some the personal email address
        
        List<Contact> testContacts = TestHelper.createStudentContacts(1, null);
        List<Case> webToCaseForms = TestHelper.webToCaseForms(1);
        
        TriggerCommon.disableTrigger('Contact'); // have set up own alternate email addresses etc, so wont
        insert testContacts;
        TriggerCommon.enableTrigger('Contact');
        
        Set<Id> testContactIds = new Map<Id, Contact>(testContacts).keySet();
        
        webToCaseForms[0].SuppliedEmail = testContacts[0].Monash_Email_Address__c;
        insert webToCaseForms;
        
        Test.startTest();
        
        Case caseRec = [SELECT Id,SuppliedEmail FROM Case LIMIT 1];
        
        Map<String, String> parameterMap = new Map<String, String>();
        parameterMap.put('recId',caseRec.Id);
        parameterMap.put('outcomeField','Non_existent_1__c');
        parameterMap.put('explanationField','Non_existent_2__c');
        parameterMap.put('recommendationField','Non_existent_3__c');
        
        GOEDCardController.getEDInfo(JSON.serialize(parameterMap));
        
        Test.stopTest();        
        
        system.assertEquals(caseRec.SuppliedEmail,webToCaseForms[0].SuppliedEmail);        
    }
    
}