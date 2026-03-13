/**
* @description       : Course Offerings Response Wrapper Test Class
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 12-03-2024
* @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(IsParallel=true)
public class CourseOfferingsResponseWrapper_Test {
    /**
    * @description Course Offering Wrapper Test method.
    * @author rajesh.punjabi@monash.edu | 08-03-2024 
    **/
    @isTest
    public static void createRequest(){
        //.. GIVEN .. Create Wrapper
        CourseOfferingsResponseWrapper oCourseResponse = new CourseOfferingsResponseWrapper();
        oCourseResponse.success = 'true';
        oCourseResponse.description = 'Request is succesfful.';
        oCourseResponse.error = '';
        
        String requestJSON = JSON.serializePretty (oCourseResponse);
        
        //.. WHEN .. Parse Json to wrapper.
        Test.startTest();
        oCourseResponse = CourseOfferingsResponseWrapper.parse(requestJSON);
        Test.stopTest();
        
        //.. THEN .. Check for succcess response in body.
        Assert.isTrue (oCourseResponse.success == 'true', 'Response created succesfully..');
    }
}