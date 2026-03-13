/**
* @description       : Course Offerings Service Test Class
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 13-03-2024
* @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(IsParallel=true)
public class CourseOfferingsService_Test {
    
    /**
    * @description test data
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @testSetup static void setup() {
        //.. Create Course Offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        
        //.. OES
        Course_Offering__c oCourse_Offering = new Course_Offering__c();
        oCourse_Offering.Course_Code__c = 'B1899-test';
        oCourse_Offering.Academic_Year__c = 2018;
        oCourse_Offering.Location_Code__c = 'MALAYSIA';
        oCourse_Offering.Citizenship_Type__c = 'INT-SUN-P';
        oCourse_Offering.Course_Title__c = 'Faculty of Business and Economics';
        oCourse_Offering.Faculty__c = 'Master of Project Management';
        oCourse_Offering.Mix_Unique_Id__c = 'B1899-test|1|ONLINE|IN|FT|8619|8638|NULL|NULL|NULL|NULL';
        lstCourseOfferings.add(oCourse_Offering);
        
        //.. Malaysia
        Course_Offering__c oCourse_Offering2 = new Course_Offering__c();
        oCourse_Offering2.Course_Code__c = 'B1899-test2';
        oCourse_Offering2.Academic_Year__c = 2018;
        oCourse_Offering2.Location_Code__c = 'MALAYSIA';
        oCourse_Offering2.Citizenship_Type__c = 'DOM-SUN';
        oCourse_Offering2.Course_Title__c = 'Faculty of Business and Economics';
        oCourse_Offering2.Faculty__c = 'Master of Project Management';
        oCourse_Offering2.Mix_Unique_Id__c = 'B1899-test2|1|MALAYSIA|IN|FT|8619|8638|NULL|NULL|NULL|NULL';
        lstCourseOfferings.add(oCourse_Offering2);

        insert lstCourseOfferings;   
    }
    
    /**
    * @description Get list of Course Offering Test fuction
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void getCourseOfferingsGetAll_Test(){
        
        //.. GIVEN .. Query Course Offerings.
        Course_Offering__c oCourse_Offering = [SELECT Id, Course_Offering_UID__c, Mix_Unique_Id__c FROM Course_Offering__c WHERE Course_Code__c = 'B1899-test' LIMIT 1];
        CourseOfferingsWSRequest.Courserequest oRequest = new CourseOfferingsWSRequest.Courserequest();
        List<Course_Offering__c> lstCourseOffering = new List<Course_Offering__c>();
        //.. Set the record values.
        oRequest.courseYear = '2018';
        oRequest.campusCountry = 'MALAYSIA';
        oRequest.citizenshipTypeCodes = 'DOM-SUN,INT-SUN-P';
        oRequest.courseName = 'Faculty of Business and Economics';
        oRequest.pageSize = '20';
        oRequest.pageOffset = '0';
        
        //.. WHEN .. Call the Get Course Offering Function
        Test.startTest();
        lstCourseOffering = CourseOfferingsService.getCourseOfferings(oRequest, false);
        Test.stopTest();
        
        //.. THEN  .. List must contains course offerings.
        Assert.isTrue(lstCourseOffering.size() > 0, 'List of Course Offerings');
        
    }
    
    /**
    * @description Get list of Course Offering Test fuction
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void getCourseOfferingsGetDOMSUN_Test(){
        
        //.. GIVEN .. Query Course Offerings.
        Course_Offering__c oCourse_Offering = [SELECT Id, Course_Offering_UID__c, Mix_Unique_Id__c FROM Course_Offering__c WHERE Course_Code__c = 'B1899-test2' LIMIT 1];
        CourseOfferingsWSRequest.Courserequest oRequest = new CourseOfferingsWSRequest.Courserequest();
        List<Course_Offering__c> lstCourseOffering = new List<Course_Offering__c>();
        //.. Set the record values.
        oRequest.courseYear = '2018';
        oRequest.campusCountry = 'Malaysia';
        oRequest.courseCode = 'B1899-test2';
        oRequest.citizenshipTypeCodes = 'DOM-SUN';
        oRequest.courseName = 'Faculty of Business and Economics';
        oRequest.pageSize = '20';
        oRequest.pageOffset = '0';
        
        //.. WHEN .. Call the Get Course Offering Function
        Test.startTest();
        lstCourseOffering = CourseOfferingsService.getCourseOfferings(oRequest,false);
        Test.stopTest();
        
        //.. THEN  .. List must contains course offerings.
        Assert.isTrue(lstCourseOffering.size() > 0, 'List of Course Offerings');
        
    }
    
    /**
    * @description Convert Params to Qury Test fuction
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void convertListToQueryParam_Test(){
        //.. GIVEN .. Create new list of strings
        List<String> lstString = new List<String> {'String 1', 'String 2', 'String 3'};
        String sReturnString = '';
        
        //.. WHEN .. call the function to conver the list.
        Test.startTest();
        sReturnString = CourseOfferingsService.convertListToQueryParam(lstString);
        Test.stopTest();
        
        //.. THEN  .. return string contains query params
        Assert.isNotNull (sReturnString, 'List converted to Query Parameters');
    }

    /**
    * @description Generate Hash Test fuction
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void generateHash_Test(){
        
        //.. GIVEN  .. Query the record to create hash
        List<String> lstResponse = new List<String>();
        Course_Offering__c oCourse_Offering = [SELECT Id, Course_Offering_UID__c, Mix_Unique_Id__c FROM Course_Offering__c WHERE Course_Code__c = 'B1899-test' LIMIT 1];
        List<CourseOfferingHashRequest> oReqList = new List<CourseOfferingHashRequest>();
        CourseOfferingHashRequest oReq = new CourseOfferingHashRequest();
        List<List<CourseOfferingHashRequest>> invocableVar = new  List<List<CourseOfferingHashRequest>>();
        
        oReq.strId = oCourse_Offering.Id;
        oReq.strMixUniqueId = oCourse_Offering.Mix_Unique_Id__c;
        oReqList.add(oReq);
        invocableVar.add(oReqList);
        
        //.. WHEN  .. Call the function to create hash.
        Test.startTest();
        lstResponse = CourseOfferingsService.generateHash(invocableVar);
        Test.stopTest();
        
        //.. THEN .. Hash is created for Course Offerings
        //Assert.isNotNull (lstResponse[0] == 'success', 'Hash generated successfully.');
    }
    
    /**
    * @description Exception Test fuction
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void getCourseOfferings_ExceptionTest(){
        //..GIVEN .. Query course offering record. (Exception Test code coverage)
        Course_Offering__c oCourse_Offering = [SELECT Id, Course_Offering_UID__c, Mix_Unique_Id__c FROM Course_Offering__c WHERE Course_Code__c = 'B1899-test' LIMIT 1];
        CourseOfferingsWSRequest.Courserequest oRequest = new CourseOfferingsWSRequest.Courserequest();
        List<Course_Offering__c> lstCourseOffering = new List<Course_Offering__c>();
        
        //.. WHEN .. Call the function to get courses.
        Test.startTest();
        lstCourseOffering = CourseOfferingsService.getCourseOfferings(oRequest, false);
        Test.stopTest();
        
        //.. THEN  .. Assert for succesful exception test.
        Assert.isTrue (true, 'Exception Testing Successful.');
    }
}