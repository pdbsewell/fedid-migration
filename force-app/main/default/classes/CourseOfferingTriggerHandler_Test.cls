@IsTest(isParallel=true) 
public class CourseOfferingTriggerHandler_Test {
	@testSetup
   	static void setup() {
		Calendar__c c = new Calendar__c(name = 'Test 666', calendar_code__c = '666_666', Start_Date__c = Date.today());
        insert c;
        
        Calendar_Dates__c cd = new Calendar_Dates__c(Name = 'CRS-START', Calendar_Code__c = '11050_11078', Calendar_Date_Unique_Key__c = '11050_11078CRS-START1', CalendarId__c = c.Id, Date_Sequence_Nbr__c = 1, Date_Type_Description__c = 'COURSE START DATE FOR ADMISSION PERIODS', Date_Value__c = Date.today() );
        insert cd;
        
        TestDataFactory.createSObject(new Course__c(), true);
    }

    @isTest private static void test_calendaroverride_main(){
        Course_Offering__c co = (Course_Offering__c) TestDataFactory.createSObject(new Course_Offering__c(),true);
        co.Override_Start_Date__c = Date.today();
        co.Override_Duration__c = 6;
        co.Override_Duration_Unit__c = 'Month';
        update co;
        
        Course_Offering__c result1 = [SELECT Id, Calendar__c, End_Date__c FROM Course_Offering__c WHERE id =: co.Id];
        System.assert(result1.Calendar__c != null, 'Calendar should be populated base on Academic_CI_Sequence_Number__c and Admission_CI_Sequence_Number__c');
        System.assert(result1.End_Date__c == Date.today().addMonths(6),'End Date should be overriden by calendar start date + 6 months');
        
        co.Override_Duration_Unit__c = null;
        co.Override_Duration__c = null;
        co.Override_End_Date__c = Date.today().addMonths(12);
        update co;
        
        result1 = [SELECT Id, End_Date__c FROM Course_Offering__c WHERE id =: co.Id];
        System.assert(result1.End_Date__c == Date.today().addMonths(12),'End Date should be overriden by today + 12 months');
    }

    @isTest private static void test_calendaroverride_week(){
        Course_Offering__c co = (Course_Offering__c) TestDataFactory.createSObject(new Course_Offering__c(),true);
        co.Override_Duration__c = 6;
        co.Override_Duration_Unit__c = 'Week';
        update co;

        Course_Offering__c result1 = [SELECT Id, Calendar__c, End_Date__c FROM Course_Offering__c WHERE id =: co.Id];
        System.assert(result1.End_Date__c == Date.today().addDays(7 * 6),'End Date should be overriden by calendar start date + 6 weeks');
    }

     @isTest private static void test_calendaroverride_year(){
        Course_Offering__c co = (Course_Offering__c) TestDataFactory.createSObject(new Course_Offering__c(),true);
        co.Override_Duration__c = 2;
        co.Override_Duration_Unit__c = 'Year';
        update co;

        Course_Offering__c result1 = [SELECT Id, Calendar__c, End_Date__c FROM Course_Offering__c WHERE id =: co.Id];
        System.assert(result1.End_Date__c == Date.today().addYears(2),'End Date should be overriden by calendar start date + 2 years');

        Boolean inError = false;
        try{
            co = (Course_Offering__c) TestDataFactory.createSObject(new Course_Offering__c(),true);
            co.Override_Duration__c = 2;
            co.Override_Duration_Unit__c = null;
            update co;
        }catch(Exception e){
            inError = true;
        }
        System.assert(inError == true,'Duration Unit not found');
    }

    @isTest private static void test_calendaroverride_withoutcalendar(){
        Test.startTest();
        Course_Offering__c co = (Course_Offering__c) TestDataFactory.createSObject(new Course_Offering__c(Academic_CI_Sequence_Number__c = 76543),true);
        Test.stopTest();
    }

    @isTest private static void test_calendaroverride_withoutcrsstart(){
        Test.startTest();
        delete [select id from Calendar_Dates__c where Name = 'CRS-START'];
        Course_Offering__c co = (Course_Offering__c) TestDataFactory.createSObject(new Course_Offering__c(),true);
        Test.stopTest();
    }
}