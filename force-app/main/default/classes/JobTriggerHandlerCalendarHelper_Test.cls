@isTest(isParallel=true)
public class JobTriggerHandlerCalendarHelper_Test {
/**
 * @author          Majid Reisi Dehkordi
 * @date            06/June/2018
 * @description     Test class for JobTriggerHandlerCalendarHelper
 *                  Scenario 1) Creation of new Calendars
 *                              Create SETUP_RECORD_COUNT of Calendar__c records.
 *                              Create a job control record with 'Staging Load Started' status
 *                              Update the job control record status to 'CRM Ready to Process'
 *                              Seare if the corresponding calendars have been created successfully.
 *                 Scenario 2) Update of a exsisting Calendar
 *                              Create one Calendar record with Description__c of 'InitialDescriptoin(BeforeUpdate)'.
 *                              Create a correseponding calendar manually
 *                              Update the job control record status to 'CRM Ready to Process'
 *                              See if the corresponding calendar has been linked successfully.
 *                              See if the calendar's Description__c has been updated with 'Description 0'.
 * @revision        -
 */
    private static final Integer SETUP_RECORD_COUNT = 500;
    
	@testSetup
    static void testSetup() {
        
        // Create a large number (SETUP_RECORD_COUNT -1 ) of staging calendar Dates for the test
        List<Stg_Calendar__c> listOfStgCalendars = new List<Stg_Calendar__c>();
        for (Integer i = 0; i < SETUP_RECORD_COUNT; i++) {
            Stg_Calendar__c calendarTempObj = new Stg_Calendar__c();
            calendarTempObj.Category__c = 'ADMISSION';
            calendarTempObj.Description__c = 'Description ' + i;
            calendarTempObj.Type__c = 'ADM-1';
            calendarTempObj.Type_Alt__c = '1';
            calendarTempObj.Type_Description__c = 'ADMISSION PERIOD 1';
            calendarTempObj.Year__c = '2018';
            calendarTempObj.Closed__c = false;
            calendarTempObj.End_Date__c = Date.today();
            calendarTempObj.Job_Code__c = 'JobCode0001';
            calendarTempObj.Record_Status__c = '';
            calendarTempObj.Sequence_Number__c = i;
            calendarTempObj.Sequence_Number_Year__c = i;
            calendarTempObj.Start_Date__c = Date.today();
            calendarTempObj.Status__c = 'PLANNED';
            listOfStgCalendars.add(calendarTempObj);
        }

        //Test if they are being created
        try {
        	insert listOfStgCalendars;
            listOfStgCalendars = [SELECT Id FROM Stg_Calendar__c];
            System.assertEquals(SETUP_RECORD_COUNT, listOfStgCalendars.size(), 'Number of calendars does not match the expected number');
        } catch (Exception exc) {
            System.debug(System.LoggingLevel.ERROR, exc);
            System.assert(exc!=null, 'calendars could not be inserted as part of testSetup.');
        }

        // Create a calendar  obj to test update of calendar
        Calendar__c calendarObj = new Calendar__c();
        calendarObj.Sequence_Number_Year__c = 0;
        calendarObj.Sequence_Number__c = 0;
        calendarObj.Calendar_Code__c = '0_0';
        calendarObj.Description__c = 'InitialDescriptoin(BeforeUpdate)';

        try {
        	insert calendarObj;
            List<Calendar__c> listOfcalendarDateObj = [SELECT Id, Description__c, Calendar_Code__c FROM Calendar__c WHERE Calendar_Code__c = '0_0'];
            System.assertEquals(1, listOfcalendarDateObj.size(), 'The calendar date record was not inserted.');
            System.assertEquals(listOfcalendarDateObj[0].Description__c, 'InitialDescriptoin(BeforeUpdate)' , 'The calendar date record was not inserted.');
        } catch (Exception exc) {
            System.debug(System.LoggingLevel.ERROR, exc);
            System.assert(exc!=null, 'A new calendar date was not added.');
        }

        // Create a job control for the test
        Job_Control__c jobControlObj = new Job_Control__c();
        jobControlObj.Job_Code__c = 'JobCode0001';
        jobControlObj.Number_of_Records_Processed__c = 0;
        jobControlObj.Number_of_Records_to_Process__c = 0;
        jobControlObj.Process_Name__c = 'Calendar';
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

/* @author          Majid Reisi Dehkordi
 * @date            09/June/2018
 * @description     Scenario 1) Creation of new Calendars
 * @revision        -
 */
    @isTest
    static void ifCalendarsAreCreated(){
        // If all calendars got created
        List<Calendar__c> listOfCalendars = [select id from Calendar__c];
        system.assertEquals(SETUP_RECORD_COUNT, listOfCalendars.size(), 'Wrong number of calendar are created');

        // If a calendar object got created correctly
        listOfCalendars = [select   Category__c, Calendar_Code__c, Description__c, 
                                    Calendar_Name_Alternate__c, Type__c, Type_Alt__c, Type_Description__c, 
                                    Year__c, Closed__c, End_Date__c, Sequence_Number__c, Sequence_Number_Year__c, 
                                    Start_Date__c, Status__c 
                                    from Calendar__c
                                    Where Calendar_Code__c = '1_1'];
        System.debug(listOfCalendars[0]);
        system.assertEquals('ADMISSION', listOfCalendars[0].Category__c, 'The field content is not filled correctly');
        system.assertEquals('1_1', listOfCalendars[0].Calendar_Code__c, 'The field content is not filled correctly'); // Useless
        system.assertEquals('Description 1', listOfCalendars[0].Description__c, 'The field content is not filled correctly');
        system.assertEquals('2018/1', listOfCalendars[0].Calendar_Name_Alternate__c, 'The field content is not filled correctly');
        system.assertEquals('ADM-1', listOfCalendars[0].Type__c, 'The field content is not filled correctly');
        system.assertEquals('1', listOfCalendars[0].Type_Alt__c, 'The field content is not filled correctly');
        system.assertEquals('ADMISSION PERIOD 1', listOfCalendars[0].Type_Description__c, 'The field content is not filled correctly');
        system.assertEquals('2018', listOfCalendars[0].Year__c, 'The field content is not filled correctly');
        system.assertEquals(false, listOfCalendars[0].Closed__c, 'The field content is not filled correctly');
        system.assertEquals(Date.today(), listOfCalendars[0].End_Date__c, 'The field content is not filled correctly');
        system.assertEquals(1, listOfCalendars[0].Sequence_Number__c, 'The field content is not filled correctly');
        system.assertEquals(1, listOfCalendars[0].Sequence_Number_Year__c, 'The field content is not filled correctly');
        system.assertEquals(Date.today(), listOfCalendars[0].Start_Date__c, 'The field content is not filled correctly');
        system.assertEquals('PLANNED', listOfCalendars[0].Status__c, 'The field content is not filled correctly');
    }

/* @author          Majid Reisi Dehkordi
 * @date            09/June/2018
 * @description     Scenario 2) Update of existing Calendar
 * @revision        -
 */
    @isTest
    static void ifCalendarGetsUpdated(){
        List<Calendar__c> updatedCalendarObj = [SELECT Id, Calendar_Code__c, Description__c FROM Calendar__c WHERE Calendar_Code__c = '0_0'];
        System.assertEquals(1, updatedCalendarObj.size(), 'The calendar record was not updated.');
        System.assertEquals('Description 0', updatedCalendarObj[0].Description__c, 'The calendar record was not updated correctly.');
    }
}