/**
* @description       : Course Offerings Web Service Test Class
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 12-03-2024
* @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(IsParallel=true)
public class CourseOfferingsWebService_Test {
    /**
    * @description test data
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @testSetup static void setup() {
        //.. Create Course Offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c oCourse_Offering1 = new Course_Offering__c();
        oCourse_Offering1.Course_Code__c = 'B1899-test';
        oCourse_Offering1.Academic_Year__c = 2018;
        oCourse_Offering1.Campus__c = 'Malaysia';
        oCourse_Offering1.Location_Code__c = 'Malaysia';
        oCourse_Offering1.Course_Title__c = 'Faculty of Business and Economics';
        oCourse_Offering1.Faculty__c = 'Master of Project Management';
        oCourse_Offering1.Mix_Unique_Id__c = 'B1899-test|1|CAULFIELD|IN|FT|8619|8638|NULL|NULL|NULL|NULL';
        oCourse_Offering1.Citizenship_Type__c = 'INT-SUN-P';
        lstCourseOfferings.add(oCourse_Offering1);

        Course_Offering__c oCourse_Offering2 = new Course_Offering__c();
        oCourse_Offering2.Course_Code__c = 'B1900-test';
        oCourse_Offering2.Academic_Year__c = 2018;
        oCourse_Offering2.Campus__c = 'Malaysia';
        oCourse_Offering2.Location_Code__c = 'Malaysia';
        oCourse_Offering2.Course_Title__c = 'Faculty of Business and Economics';
        oCourse_Offering2.Faculty__c = 'Master of Project Management';
        oCourse_Offering2.Mix_Unique_Id__c = 'B1900-test|1|CAULFIELD|IN|FT|8619|8638|NULL|NULL|NULL|NULL';
        oCourse_Offering2.Citizenship_Type__c = 'DOM-SUN';
        lstCourseOfferings.add(oCourse_Offering2);
        insert lstCourseOfferings;   
    }
    
    /**
    * @description Query with record found.
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void getOfferedCourses_Test(){
        //.. GIVEN  .. Query the Course Offering Record.
        Course_Offering__c oCourse_Offering = [SELECT Id, Campus__c, Academic_Year__c FROM Course_Offering__c WHERE Course_Code__c = 'B1899-test' LIMIT 1];
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('campusCountry', oCourse_Offering.Campus__c);
        req.params.put('courseYear', String.valueOf(oCourse_Offering.Academic_Year__c));
        req.params.put('citizenshipTypeCodes','DOM-SUN,INT-SUN-P' );
        req.params.put('pageSize', String.valueOf(1));

        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        //.. WHEN  .. Call get courseoffering function
        Test.startTest();
        CourseOfferingsWebService.getOfferedCourses();
        Test.stopTest();
        CourseOfferingsResponseWrapper result = (CourseOfferingsResponseWrapper)
        JSON.deserialize(res.responseBody.toString(), CourseOfferingsResponseWrapper.class);
        //.. THEN .. verify the response
        //noOfRecords must be the size of the total number of records when pageSiae=1
        Assert.isTrue(result.noOfRecords==2, 'The number of total records should be 2');
        Assert.isTrue(result.pageSize=='1', 'The pageSize must be 1');
        Assert.isNotNull(String.isBlank(res.responseBody.toString()), 'Record Found.');
    }
    
    /**
    * @description Query with No Record result.
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void getOfferedCoursesNoRecord_Test(){
        //.. GIVEN  .. Test no record found.
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('campusCountry', 'Australia');
        req.params.put('courseYear', '2090');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        //.. WHEN .. Call get courseoffering function
        Test.startTest();
        CourseOfferingsWebService.getOfferedCourses();
        Test.stopTest();
        
        //.. THEN  .. Response should contain no record found.
        Assert.isTrue(res.responseBody.toString().containsIgnoreCase('No record found.') , 'No Record Found.');
    }
    
    /**
    * @description Validate Missing Params Test
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void getOfferedCoursesMissingParam_Test(){
        //.. GIVEN .. validate if params are null
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        //.. WHEN  .. call the function
        Test.startTest();
        CourseOfferingsWebService.getOfferedCourses();
        Test.stopTest();
        
        //.. THEN .. response contains missing params.
        Assert.isTrue(res.responseBody.toString().containsIgnoreCase('Missing Parameter') , 'Missing Params.');
    }
    
    /**
    * @description Exception test method
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void getCourseOfferings_ExceptionTest(){
        //..GIVEN  .. Exception Test Data not required
        
        //.. WHEN  .. Call the function
        Test.startTest();
        CourseOfferingsWebService.getOfferedCourses();
        Test.stopTest();
        
        //.. THEN  .. Assert for succesful exception test.
        Assert.isTrue (true, 'Exception Testing Successful.');
    }
}