/**
* @description       : Course Offerings Request Wrapper Test Class
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 12-03-2024
* @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(IsParallel=true)
public class CourseOfferingsWSRequest_Test {
    
    /**
    * @description Request Wrapper Test
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void createRequest(){
        //.. GIVEN .. Create Wrapper
        CourseOfferingsWSRequest.Courserequest oCourseRequest = new CourseOfferingsWSRequest.Courserequest();
        oCourseRequest.courseYear = '2019';
        oCourseRequest.courseCode = 'B6019';
        oCourseRequest.courseName = 'Master';
        oCourseRequest.campusCountry = 'Caufield';
        oCourseRequest.pageSize = '1';
        oCourseRequest.pageOffset = '5';
        oCourseRequest.citizenshipTypeCodes = 'DOM-SUN,INT-SUN-P';
        
        String requestJSON = JSON.serializePretty (oCourseRequest);
        
        //.. WHEN  .. Parse JSON to Wrapper
        Test.startTest();
        oCourseRequest = CourseOfferingsWSRequest.parse(requestJSON);
        Test.stopTest();
        
        //.. THEN .. Check wrapper is updated.
        Assert.isTrue (!String.isBlank(oCourseRequest.courseName), 'Request created succesfully.');
    }
}