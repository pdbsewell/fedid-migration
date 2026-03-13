/**
 * @description       : Test class for IterateGenericSObject
 * @author            : Mac Domingo
 * @group             : Platforms
 * @last modified on  : 2023-18-08
 * @last modified by  : Mac Domingo
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2023-18-08 - Mac Domingo - Added test for IterateGenericSObject
**/
@IsTest(IsParallel=true) 
public class IterateGenericSObject_Test { 
    /*******************************************************************************
     * @author       Mac Domingo
     * @date         2023-18-08
     * @description  Tests the Iterator 
    *******************************************************************************/ 
    static testMethod void testIterator() { 
         // Get the record type developer name 
         String enquiryRecordTypeDevName = 'Monash_Connect_Enquiry'; 
 
         // Get the record type ID using the Schema class 
         Id enquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(enquiryRecordTypeDevName).getRecordTypeId(); 
         //GIVEN: Test Case Values
         // Create a test case 
         Case testCase = new Case(); 
         testCase.RecordTypeId = enquiryRecordTypeId; 
         testCase.Subject = 'Test Case'; 
         testCase.Description = 'This is a test case'; 
         insert testCase; 
 
         //WHEN: The Iterator class is called
         Test.startTest();
        // Create a new IterateGenericSobject instance 
        IterateGenericSobject iterateObject = new IterateGenericSobject(); 

        // Get the iterator from the IterateGenericSobject instance 
        Iterator<IterableWrapper> iterator = iterateObject.Iterator();

        // Create a separate collection to store modified items
        List<IterableWrapper> modifiedItems = new List<IterableWrapper>();
 
        // Iterate through the iterator and modify the items
        while (iterator.hasNext()) {
            IterableWrapper wrapper = iterator.next();

            // Modify the wrapper object and add it to the separate collection
            IterableWrapper modifiedWrapper = new IterableWrapper();
            modifiedWrapper.objRecord = wrapper.objRecord;
            modifiedWrapper.objectName = 'Modified ' + wrapper.objectName;
            modifiedItems.add(modifiedWrapper);
        }       
        Test.stopTest();

        //THEN: Wrapper Class is populated correctly and it contains the expected value
        // Assert the modified values in the collection
        for (IterableWrapper wrapper : modifiedItems) {
            System.assertEquals('Modified Case', wrapper.objectName);
        }
    } 
}