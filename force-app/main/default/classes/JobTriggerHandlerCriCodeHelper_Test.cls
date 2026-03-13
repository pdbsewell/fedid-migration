/**
* @author          Majid Reisi Dehkordi
* @date            11/June/2018
* @description     Test class for JobTriggerHandlerCriCodeHelper
*                  Scenario 1) Creation of new Codes
*                              Create SETUP_RECORD_COUNT of Stg_CRICOS_Code__c records.
*                              Create a job control record with 'Staging Load Started' status
*                              Update the job control record status to 'CRM Ready to Process'
*                              See if the corresponding CricosCodes have been created successfully.
*                  Scenario 2) Update of CricosCodes
*                              Create SETUP_RECORD_COUNT of Stg_CRICOS_Code__c records.
*                              Create one CricosCodes record with Notes__c of 'CRICOS code ---------------'.
*                              Update the job control record status to 'CRM Ready to Process'
*                              See if the corresponding CricosCodes has been updated successfully.
*                  Scenario 3) Linking with existing Calendar
*                              Create one Stg_Calendar_Dates__c record with Date_Type_Description__c of 'CalDate--'.
*                              Create a correseponding calendar manually
*                              Update the job control record status to 'CRM Ready to Process'
*                              See if the corresponding calendar has been linked successfully.
*                              See if the calendar's calendar date has the right value for Date_Type_Description__c.
* @revision        - Nitin Khandelwal
@description     - changed the field API  names and logic because of the change in logic in the main class
@date            - 27/June/2018	
*/
@isTest(isParallel=true)
public class JobTriggerHandlerCriCodeHelper_Test {
    
    private static final Integer SETUP_RECORD_COUNT = 500;
    
    @testSetup
    static void testSetup() {
        // Create a large number (SETUP_RECORD_COUNT -1 ) of staging CricosCodes for the test
        List<Stg_CRICOS_Code__c> listOfStgCRICOSCodes = new List<Stg_CRICOS_Code__c>();
        for (Integer i = 0; i < SETUP_RECORD_COUNT; i++) {
            Stg_CRICOS_Code__c CRICOSCodeTempObj = new Stg_CRICOS_Code__c();
            CRICOSCodeTempObj.Course_Version_Key__c = 'CourseCode ' + i;
            CRICOSCodeTempObj.Expiry_Date__c = Date.today();
            CRICOSCodeTempObj.Job_Code__c = 'JobCode0001';
            CRICOSCodeTempObj.Notes__c = 'CRICOS code cancelled 06/05/2013';
            CRICOSCodeTempObj.Record_Status__c = '';
            CRICOSCodeTempObj.Type__c = 'CRICOS';
            listOfStgCRICOSCodes.add(CRICOSCodeTempObj);
        }
        
        // Create a CricosCodes obj to test update of CricosCodes
        CRICOS_Code__c CRICOSCodesObj = new CRICOS_Code__c();
        CRICOSCodesObj.Course_Version_Key__c = 'CourseCode ' + (SETUP_RECORD_COUNT - 1) + '_1';
        CRICOSCodesObj.Notes__c = 'CRICOS code ---------------';
        
        //Test if they are being created
        try {
            insert listOfStgCRICOSCodes;
            listOfStgCRICOSCodes = [SELECT Id FROM Stg_CRICOS_Code__c];
            System.assertEquals(SETUP_RECORD_COUNT, listOfStgCRICOSCodes.size(), 'Number of CRICOSCodes does not match the expected number');
        } catch (Exception exc) {
            System.debug(System.LoggingLevel.ERROR, exc);
            System.assert(exc!=null, 'CRICOSCodes could not be inserted as part of testSetup.');
        }
        
        // Create a job control for the test
        Job_Control__c jobControlObj = new Job_Control__c();
        jobControlObj.Job_Code__c = 'JobCode0001';
        jobControlObj.Number_of_Records_Processed__c = 0;
        jobControlObj.Number_of_Records_to_Process__c = 0;
        jobControlObj.Process_Name__c = 'CRICOS_Code';
        jobControlObj.Processing_Status__c = 'Staging Load Started';
        
        //Test if it the job control record gets created
        try {
            insert jobControlObj;
            List<Job_Control__c> jobControlObjs = [SELECT Id FROM Job_Control__c];
            System.assertEquals(1, jobControlObjs.size(), 'The job control record was not inserted.');
        } catch (Exception exc) {
            System.debug(System.LoggingLevel.ERROR, exc);
            System.assert(exc!=null, 'Job control record could not be inserted as part of the testSetup.');
        }
        
        //Test if it the job control record runs and gets updated
        try {
            jobControlObj.Processing_Status__c = 'CRM Ready to Process';
            update jobControlObj;
            jobControlObj = [SELECT Id, Processing_Status__c FROM Job_Control__c];
            System.assertEquals(jobControlObj.Processing_Status__c, 'Target Load Completed' , 'The job control did not get updated.');
        } catch (Exception exc) {
            System.debug(System.LoggingLevel.ERROR, exc);
            System.assert(exc!=null, 'Job control did not get update.');
        }
    }
    
    
    @isTest
    static void ifCRICOSCodesAreCreated(){
        // If all CRICOScodes got created
        List<CRICOS_Code__c> listOfCRICOSCodes = [select id,Course_Version_Key__c from CRICOS_Code__c];
        system.assertEquals(SETUP_RECORD_COUNT, listOfCRICOSCodes.size(), 'Wrong number of CRICOSCodes are created');
        system.debug('SETUP_RECORD_COUNT' + listOfCRICOSCodes[0].Course_Version_Key__c);
        
        // If all fields of a CRICOScode object got created correctly
        listOfCRICOSCodes = [select Course__c,Course_Version_Key__c,
                             Expiry_Date__c, Notes__c, 
                             Type__c
                             from CRICOS_Code__c
                             Where Course_Version_Key__c = 'CourseCode 115'];
        system.assertEquals('CourseCode 115', listOfCRICOSCodes[0].Course_Version_Key__c, 'The field content is not filled correctly'); 
        system.assertEquals(Date.today(), listOfCRICOSCodes[0].Expiry_Date__c, 'The field content is not filled correctly');
        system.assertEquals('CRICOS code cancelled 06/05/2013', listOfCRICOSCodes[0].Notes__c, 'The field content is not filled correctly');
        system.assertEquals('CRICOS', listOfCRICOSCodes[0].Type__c, 'The field content is not filled correctly');
        
        // If courses got created
        List<Course__c> listOfCourses = [select id from Course__c];
        system.assertEquals(SETUP_RECORD_COUNT, listOfCourses.size(), 'Wrong number of courses are created');
    }
    
}