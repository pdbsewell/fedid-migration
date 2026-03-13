@isTest(isParallel=true)
public with sharing class BDPCourseOfferingResetService_Test {
    @isTest static void whenSuggestedCourseOfferingDeleteSuccessfully(){
        Bulk_Data_Processing__c[] records = (Bulk_Data_Processing__c[]) JSON.deserialize('[{"attributes":{"type":"Bulk_Data_Processing__c","url":"/services/data/v49.0/sobjects/Bulk_Data_Processing__c/a1z4Y0000001cKgQAI"},"Id":"a1z4Y0000001cKgQAI","Person_ID__c":"28115120","Status__c":"Ready for Offer","Transfer_From__c":"a204Y0000009RoNQAU","Current_Course_Campus__c":"MALAYSIA","Transfer_Course_Campus__c":"CLAYTON","Transfer_To_Application__c":"a244Y0000001jGLQAY","Transfer_To__c":"a204Y000000A4GTQA0","Offer_Lapsed_Date__c":"2020-07-31","Applicant__c":"0034Y00000310h3QAA","Transfer_Course_Code__c":"C2000","Credit_Duration_Unit__c":"Years","Credit_Duration_Value__c":0.50,"Credit_Points__c":48,"Preference__c":"1","Type__c":"Campus Transfer","Student_Notes__c":"You have been given an offer for your highest eligible course preference.","RecordTypeId":"0124Y0000004t87QAA","Transfer_From__r":{"attributes":{"type":"Application_Course_Preference__c","url":"/services/data/v49.0/sobjects/Application_Course_Preference__c/a204Y0000009RoNQAU"},"Id":"a204Y0000009RoNQAU","Application__c":"a244Y000000108YQAQ","Application__r":{"attributes":{"type":"Application__c","url":"/services/data/v49.0/sobjects/Application__c/a244Y000000108YQAQ"},"Id":"a244Y000000108YQAQ","Citizenship_Country__c":"a3p4Y00000008WgQAI"}}}]', List<Bulk_Data_Processing__c>.class);
        Test.startTest();
        BDPCourseOfferingResetService service = new BDPCourseOfferingResetService();
        service.init();
        service.execute(records);
        Test.stopTest();
        System.assert(service.suggestedCourseOfferings != null, 'Suggested Course Offering must be deleted');
    }
}