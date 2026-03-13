/**
 * @author      Jasmin Joy Rudio
 * @description Test class for calendar__c object selector class
 * @group       
 * @revision    02/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest(isParallel=true)
public with sharing class CalendarSelector_Test {
    @isTest static void selectById() {
        List<Calendar__c> calendars = new CalendarSelector().selectById(new Set<Id>());
        System.assertEquals(new List<Calendar__c>(), calendars,
                            'Expected empty list of calendars as Id list is empty');
    }
    @isTest static void selectByAlternateNameCategory() { 
        List<Calendar__c> calendars = new CalendarSelector(false).selectByAlternateNameCategory(new Set<String>(), '');
        System.assertEquals(new List<Calendar__c>(), calendars,
                            'Expected empty list of calendars as Id list is empty');
    }
}