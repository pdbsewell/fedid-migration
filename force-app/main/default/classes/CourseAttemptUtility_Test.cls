/**
 * @description       : Test class for CourseAttemptUtility
 * @author            : Inderpal Dhanoa
 * @group             : Test
 * @last modified on  : 2024-08-02
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2024-08-02   Inderpal Dhanoa - Auto close linked OCR MCT-440
 */
@isTest(isParallel=true)
public class CourseAttemptUtility_Test {
    @TestSetup
    public static void setup() {
		//Course Data
        Course__c course1 = (Course__c)TestDataFactory.createSObject(new Course__c(Name = 'Z9999', Course_Code__c = 'Z9999_1', Version__c = '1', Type__c = 'Course-All'), true);

		// Contact
        triggerCommon.disableTrigger('Contact');
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(firstname='John', lastname='Summers', Person_ID_unique__c='11223346', SAP_STAFF_ID__c = 'NoDupChk'), true);
        triggerCommon.enableTrigger('Contact');

        Course_Attempt__c ca1 = (Course_Attempt__c)TestDataFactory.createSObject(new Course_Attempt__c(Name = 'Test CA Trigger', Contact__c = contact.Id, course__c = course1.Id,  
        Course_Attempt_Status__c = 'Inactive'), true);

        TestDataFactory.createSObject(new Outbound_Call_Result__c(Contact__c = contact.Id, Engagement_Type__c = 'Conversion',  
        Course_Attempt__c = ca1.Id, Additional_Detail__c = 'Test Camp',
        RecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId()), true);
        
    }

    /**
     * @description : Test the "closeLinkedOCRS" method if the OCR gets autoclosed
     */
	@IsTest    
    static void closeLinkedOCRS_Test() {  
        
        //GIVEN: The Course Attempt should have a linked OCR
        List<Contact> con2 = [SELECT Id FROM Contact WHERE Person_ID_unique__c = '11223346' LIMIT 1];
        
        test.startTest();
        //WHEN: The Course Attempt is updated
        CourseAttemptUtility.closeLinkedOCRS(new Set<Id>{con2[0].Id});
        test.stopTest();
        
        //THEN: The linked OCR is updated
        Outbound_Call_Result__c ocr = [SELECT Id, Call_Status__c
                                        FROM Outbound_Call_Result__c 
                                        WHERE Contact__c = :con2[0].Id ];
        Assert.areEqual('Closed', ocr.Call_Status__c, 'closeLinkedOCRS Linked OCR did not close');
    }
}