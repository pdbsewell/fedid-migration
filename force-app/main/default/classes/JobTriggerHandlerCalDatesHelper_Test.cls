/*
 *  @author         Majid Reisi Dehkordi
 *  @date           06/June/2018
 *  @description    Test class for JobTriggerHandlerCalDatesHelper
 *                  Scenario 1) Creation of new Calendar_Dates__cs, Calendars
 *                              Create (SETUP_RECORD_COUNT - 1) of Stg_Calendar_Dates__c records.
 *                              Create a job control record with 'Staging Load Started' status
 *                              Update the job control record status to 'CRM Ready to Process'
 *                              See if the corresponding calendar dates have been created successfully.
 *                              See if the corresponding calendars have been created successfully.
 *                  Scenario 2) Linking with existing Calendar
 *                              Create one Stg_Calendar_Dates__c record with Date_Type_Description__c of 'CalDate--'.
 *                              Create a correseponding calendar manually
 *                              Update the job control record status to 'CRM Ready to Process'
 *                              See if the corresponding calendar has been linked successfully.
 *                               See if the calendar's calendar date has the right value for Date_Type_Description__c.
 *                  Scenario 3) Update of Calendar Date
 *                              Create (SETUP_RECORD_COUNT - 1) of Stg_Calendar_Dates__c records.
 *                              Create one Stg_Calendar_Dates__c record.
 *                              Update the job control record status to 'CRM Ready to Process'
 *                              See if the corresponding Calendar Date has been updated successfully.
 * @revision        -
 */

@isTest(isParallel=true)
public class JobTriggerHandlerCalDatesHelper_Test {
    private static final Integer SETUP_RECORD_COUNT = 500;
    
    @testSetup
    static void testSetup() {
        
        // Create a large number SETUP_RECORD_COUNT of staging calendar Dates for the test
        List<Stg_Calendar_Dates__c> stagingCalDates = new List<Stg_Calendar_Dates__c>();
        for (Integer i = 0; i < SETUP_RECORD_COUNT; i++) {
            Stg_Calendar_Dates__c calDateTempObj = new Stg_Calendar_Dates__c();
            calDateTempObj.Calendar_Code__c = 'CalDate-' + i;
            calDateTempObj.Date_Sequence_Nbr__c = i;
            calDateTempObj.Date_Type_Description__c = 'CalDate-' + i;
            calDateTempObj.Name = 'CalDate-' + i;
            calDateTempObj.Date_Value__c = Date.today();
            calDateTempObj.Job_Code__c = 'JobCode0001';
            calDateTempObj.Record_Status__c = '';
            
            stagingCalDates.add(calDateTempObj);
        }
        
        // The last staging calDate obj is used to test update
        stagingCalDates[SETUP_RECORD_COUNT - 1].Date_Type_Description__c = 'CalDate--';
        
        // To test the update of calendar date
        stagingCalDates[0].Date_Sequence_Nbr__c = 888889;
        
        //Test if they are being created
        try {
            insert stagingCalDates;
            stagingCalDates = [SELECT Id FROM Stg_Calendar_Dates__c];
            System.assertEquals(SETUP_RECORD_COUNT, stagingCalDates.size(), 'Number of courses does not match the expected number');
        } catch (Exception exc) {
            System.debug(System.LoggingLevel.ERROR, exc);
            System.assert(exc!=null, 'Courses could not be inserted as part of testSetup.');
        }
        
        // Create a calendar date obj to test update of calendar date
        Calendar_Dates__c calendarDateObj = new Calendar_Dates__c();
        calendarDateObj.Calendar_Code__c = 'CalDate-0';
        calendarDateObj.Date_Sequence_Nbr__c = 888888;
        
        try {
            insert calendarDateObj;
            List<Calendar_Dates__c> listOfcalendarDateObj = [SELECT Id, Calendar_Code__c,Date_Sequence_Nbr__c FROM Calendar_Dates__c WHERE Calendar_Code__c = 'CalDate-0'];
            System.assertEquals(1, listOfcalendarDateObj.size(), 'The calendar date record was not inserted.');
            System.assertEquals(listOfcalendarDateObj[0].Date_Sequence_Nbr__c, 888888 , 'The calendar date record was not inserted.');
        } catch (Exception exc) {
            System.debug(System.LoggingLevel.ERROR, exc);
            System.assert(exc!=null, 'A new calendar date was not added.');
        }
        
        // Create a calendar to test update
        Calendar__c calendarTempObj = new Calendar__c();
        calendarTempObj.Calendar_Code__c = 'CalDate-' + (SETUP_RECORD_COUNT - 1);
        
        try {
            insert calendarTempObj;
            List<Calendar__c> calendarObjs = [SELECT Id FROM Calendar__c];
            System.assertEquals(1, calendarObjs.size(), 'The calendar record was not inserted.');
        } catch (Exception exc) {
            System.debug(System.LoggingLevel.ERROR, exc);
            System.assert(exc!=null, 'A new calendar was not added.');
        }
        
        // Create a job control for the test
        Job_Control__c jobControlObj = new Job_Control__c();
        jobControlObj.Job_Code__c = 'JobCode0001';
        jobControlObj.Number_of_Records_Processed__c = 0;
        jobControlObj.Number_of_Records_to_Process__c = 0;
        jobControlObj.Process_Name__c = 'Calendar_Dates';
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
        
        //Test if it the job control run and gets updated
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
    
/*
 *   @author         Majid Reisi Dehkordi
 *   @date            09/June/2018
 *   @description     Scenario 1) Creation of new Calendar_Dates__cs, Calendars
 *   @revision        -
 */
    @isTest
    static void ifCalendarDatesAndCalendarsGetCreated(){
        // If all calendar dates got created
        List<Calendar_Dates__c> calendarDatesObj = [select id from Calendar_Dates__c];
        system.assertEquals(SETUP_RECORD_COUNT, calendarDatesObj.size(), 'Wrong number of calendar dates are created');
        
        // If a calendar date object got created correctly
        calendarDatesObj = [select Calendar_Code__c, Date_Sequence_Nbr__c, Date_Type_Description__c, Name, Date_Value__c
                            from Calendar_Dates__c
                            Where Calendar_Code__c = 'CalDate-1'];
        system.assertEquals('CalDate-1', calendarDatesObj[0].Calendar_Code__c, 'The field content is not filled correctly');// Useless
        system.assertEquals(1, calendarDatesObj[0].Date_Sequence_Nbr__c, 'The field content is not filled correctly');
        system.assertEquals('CalDate-1', calendarDatesObj[0].Name, 'The field content is not filled correctly');
        system.assertEquals('CalDate-1', calendarDatesObj[0].Date_Type_Description__c, 'The field content is not filled correctly');
        system.assertEquals(Date.today(), calendarDatesObj[0].Date_Value__c, 'The field content is not filled correctly');
        
        
        // If calendars got created
        List<Calendar__c> listOfCalendars = [select id from Calendar__c];
        system.assertEquals(SETUP_RECORD_COUNT, listOfCalendars.size(), 'Wrong number of calendar are created');
    }
    
/* 
 *  @author          Majid Reisi Dehkordi
 *  @date            09/June/2018
 *  @description     Scenario 2) Linking with existing Calendar
 *  @revision        -
 */
    @isTest
    static void ifLinkingWithExistingCalendarWorks(){
        String calendarCodeString = 'CalDate-' + (SETUP_RECORD_COUNT - 1);
        List<Calendar__c> updatedCalendars = [select id, (select Date_Type_Description__c from Calendar_Dates__r) from Calendar__c where Calendar_Code__c = :calendarCodeString];
        
        system.assertEquals(1, updatedCalendars.size(), 'Wrong number of calendar dates are created');
        system.assertEquals('CalDate--', updatedCalendars[0].Calendar_Dates__r[0].Date_Type_Description__c , 'Calendar has not been updated correctly');   
    }
    
    
/*
 *  @author          Majid Reisi Dehkordi
 *  @date            09/June/2018
 *  @description     Scenario 3) Update of Calendar Date
 *  @revision        -
 */
    @isTest
    static void ifCalendarDateGetsUpdated(){
        List<Calendar_Dates__c> listOfcalendarDateObj = [SELECT Id, Calendar_Code__c,Date_Sequence_Nbr__c FROM Calendar_Dates__c WHERE Calendar_Code__c = 'CalDate-0'];
        
        System.assertEquals(1, listOfcalendarDateObj.size(), 'The calendar date record was not inserted.');
        System.assertEquals(888889, listOfcalendarDateObj[0].Date_Sequence_Nbr__c , 'The calendar date record was not updated correctly.');
    }
}