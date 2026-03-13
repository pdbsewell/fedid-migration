/**
 * Test class for SuggestedCourseOfferingHandler
 * @author David Browaeys
 * @group Bulk Data Processing
 */
@isTest(isParallel=true)
public with sharing class SuggestedCourseOfferingHandler_Test {
    @isTest
    private static void testTrigger(){
        TriggerCommon.disableTrigger('Bulk_Data_Processing__c');
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(Person_ID__c = '123456', Transfer_Course_Campus__c = 'CLAYTON'), 'TestDataFactorySettings.BulkDataProcessingDefaults', true);

        TriggerCommon.disableTrigger('Course_Offering__c');
        Course_Offering__c co = (Course_Offering__c)TestDataFactory.createSObject(new Course_Offering__c(), true);

        
        Test.startTest();
        Suggested_Course_Offering__c sco = new Suggested_Course_Offering__c(Bulk_Data_Processing__c = bdp.Id,Course_Offering__c = co.id);
        insert sco;
        System.assert(sco != null, 'Suggested Course Offering created successfully.');

        TriggerCommon.disableTrigger('Course_Offering__c');
        update sco;
        System.assert(sco != null, 'Suggested Course Offering update successfully.');
        Test.stopTest();
    }
    @isTest
    private static void shouldCreateACPSuccessfully(){
        Suggested_Course_Offering__c sco = new Suggested_Course_Offering__c(
            Primary__c = true,
            Bulk_Data_Processing__c = 'a1z4Y0000001cKgQAI',
            Course_Offering__c = 'a2B4Y0000000huPUAQ'
        );
        SuggestedCourseOfferingHandler handler = new SuggestedCourseOfferingHandler();
        handler.bdpSelector = (BulkDataProcessingSelector) Test.createStub(BulkDataProcessingSelector.class, new SelectorMocks());
        handler.coSelector = (CourseOfferingSelector) Test.createStub(CourseOfferingSelector.class, new SelectorMocks());
        handler.sobjectDao = (SObjectDao) Test.createStub(SObjectDao.class, new SObjectDaoMocks());
        Test.startTest();
        handler.process(sco);
        handler.execute();
        Test.stopTest();
        System.assert(handler.courseOfferings.isEmpty() == false);
    }
    @isTest
    private static void shouldNotProcessAnything(){
        Suggested_Course_Offering__c sco = new Suggested_Course_Offering__c(
            Primary__c = false,
            Bulk_Data_Processing__c = 'a1z4Y0000001cKgQAI',
            Course_Offering__c = 'a2B4Y0000000huPUAQ'
        );
        SuggestedCourseOfferingHandler handler = new SuggestedCourseOfferingHandler();
        Test.startTest();
        handler.process(sco);
        handler.execute();
        Test.stopTest();
        System.assert(handler.courseOfferings.isEmpty() == true);
    }
    @isTest
    private static void whenCreditDurationIsTrimester(){
        SuggestedCourseOfferingHandler handler = new SuggestedCourseOfferingHandler();
        Application_Course_Preference__c acp = new Application_Course_Preference__c(Agreed_Start_Date__c = Date.today());
        Test.startTest();
        handler.setDurationBaseCredit(acp, new Bulk_Data_Processing__c(Credit_Duration_Value__c = 3, Credit_Duration_Unit__c = 'Trimesters'));
        Test.stopTest();
        System.assert(acp.Revised_End_Date__c == Date.today().addMonths(12));
    }
    @isTest
    private static void whenCreditDurationIsSemester(){
        SuggestedCourseOfferingHandler handler = new SuggestedCourseOfferingHandler();
        Application_Course_Preference__c acp = new Application_Course_Preference__c(Agreed_Start_Date__c = Date.today());
        Test.startTest();
        handler.setDurationBaseCredit(acp, new Bulk_Data_Processing__c(Credit_Duration_Value__c = 3, Credit_Duration_Unit__c = 'Semesters'));
        Test.stopTest();
        System.assert(acp.Revised_End_Date__c == Date.today().addMonths(18));
    }
    private class SelectorMocks implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
                
            if ('selectByIdWithACPDetails'.equals(stubbedMethodName)) {
                return (Bulk_Data_Processing__c[]) JSON.deserialize('[{"attributes":{"type":"Bulk_Data_Processing__c","url":"/services/data/v49.0/sobjects/Bulk_Data_Processing__c/a1z4Y0000001cKgQAI"},"Id":"a1z4Y0000001cKgQAI","Person_ID__c":"28115120","Status__c":"Ready for Offer","Transfer_From__c":"a204Y0000009RoNQAU","Current_Course_Campus__c":"MALAYSIA","Transfer_Course_Campus__c":"CLAYTON","Transfer_To_Application__c":"a244Y0000001jGLQAY","Transfer_To__c":"a204Y000000A4GTQA0","Offer_Lapsed_Date__c":"2020-07-31","Applicant__c":"0034Y00000310h3QAA","Transfer_Course_Code__c":"C2000","Credit_Duration_Unit__c":"Years","Credit_Duration_Value__c":0.50,"Credit_Points__c":48,"Preference__c":"1","Type__c":"Campus Transfer","Student_Notes__c":"You have been given an offer for your highest eligible course preference.","RecordTypeId":"0124Y0000004t87QAA","Transfer_From__r":{"attributes":{"type":"Application_Course_Preference__c","url":"/services/data/v49.0/sobjects/Application_Course_Preference__c/a204Y0000009RoNQAU"},"Id":"a204Y0000009RoNQAU","Application__c":"a244Y000000108YQAQ","Application__r":{"attributes":{"type":"Application__c","url":"/services/data/v49.0/sobjects/Application__c/a244Y000000108YQAQ"},"Id":"a244Y000000108YQAQ","Citizenship_Country__c":"a3p4Y00000008WgQAI"}}}]', List<Bulk_Data_Processing__c>.class);
            }else if ('selectMapById'.equals(stubbedMethodName)) {
                return (Map<ID,Course_Offering__c>) JSON.deserialize('{"a2B4Y0000000huPUAQ":{"attributes":{"type":"Course_Offering__c"},"Id":"a2B4Y0000000huPUAQ","OwnerId":"0054Y000000WKwoQAG","Name":"CrOf-188451","Academic_CI_Sequence_Number__c":9708,"Academic_Calendar_Type__c":"ACAD-YR","Academic_Year__c":2021,"Active__c":true,"Admission_CI_Sequence_Number__c":9729,"Admission_Calendar_Description__c":"2021 Semester 1 (February - March start)","Admission_Calendar_Type__c":"ADM-1","Admission_Category__c":"UG-IS","Attendance_Mode_Description__c":"On-campus Education","Attendance_Mode__c":"IN","Attendance_Type_Description__c":"Full time","Attendance_Type__c":"FT","Citizenship_Type__c":"INTRNTNL","Commencement_Period__c":"Semester 1 (February start)","Course_Code__c":"C2000","Course_Title__c":"Bachelor of Information Technology","Course_Type_Group__c":"UG","Course_Type__c":"10","Course_Version_Number__c":3,"Course__c":"a0B4Y000000BQwyUAG","Faculty__c":"Faculty of Information Technology","Location_Code__c":"CLAYTON","Location_Description__c":"CLAYTON","System_Citizenship_Type__c":"INTRNTNL","Derived_Closing_Date__c":"2021-03-07","Pay_by_Invoice__c":false,"Admission_Alternate_Code__c":"1","Course_Title_F__c":"Bachelor of Information Technology","Customised_course_offering__c":false,"End_Date__c":"2023-12-31","Legacy_Cancellation__c":false,"Max_Capacity__c":0,"Number_of_Remaining_Places__c":-6,"Payment_Total__c":0.00,"Registration_Count__c":6,"Start_Date__c":"2021-03-01","Status__c":"Full","Waitlist_Count__c":6,"Waitlisted__c":false,"Is_Selective__c":false,"Admission_Category_Desc__c":"UNDERGRADUATE INTERNATIONAL","Correspondence_Category__c":"STANDARD","Course_Abbreviation__c":"BInfoTech","Default_Admission_Category_Ind__c":true,"Enrolment_Category__c":"ALL-STEPS","Fee_Category__c":"AU_INT","Hecs_Payment_Option__c":"310","Portal_Available__c":true,"Student_Status__c":"310","Admission_Calendar_F__c":"2021 ADM-1","Calendar__c":"a3Y4Y0000000a9fUAA","Course_Duration__c":3,"Cricos_Code__c":"085120M","Faculty_Code__c":"50000566","Override_Reviewed__c":true,"Calendar_Key__c":"9708_9729","Course_Key__c":"C2000_3"}}', Map<ID, Course_Offering__c>.class);
            }
            return null;
        }
    }
    private class SObjectDaoMocks implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            System.debug(stubbedObject);
            System.debug(stubbedMethodName);
            System.debug(returnType);
            System.debug(listOfParamTypes);
            System.debug(listOfParamNames);
            System.debug(listOfArgs);
            return null;
        }
    }
}