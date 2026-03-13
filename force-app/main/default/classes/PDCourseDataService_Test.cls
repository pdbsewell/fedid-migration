/**
 * @author                      Kristian Vegerano
 * @created                     05/08/2021
 * @description                 Test class for PDCourseDataService.CourseDataService class
 */
@isTest (SeeAllData=false)
private class PDCourseDataService_Test {
    
    /**
     * @author                      Kristian Vegerano
     * @created                     05/08/2021
     * @description                 Method that sets up data to be used on all test methods in this class
     */
    @testSetup 
    static void setup() {
        // Create records for Professional Development related test methods
        Course__c course = PDTestHelper.createCourse();
        PDTestHelper.createCourseOfferingForCourse(course);
        Course_Offering__c cof = [SELECT Id, Name FROM Course_Offering__c LIMIT 1];
        PDTestHelper.createCourseOfferingPricing(cof.Id, 'Normal Rate' );
    }
    
    /**
     * @author                      Kristian Vegerano
     * @created                     05/08/2021
     * @description                 Test for retrieving customer and public articles using the rest service. Tests if the method returns the correct JSON format
     */
    @isTest
    private static void testGetCallout() {
        //Initialize Variables
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        //Setup endpoint
        req.requestURI = '/services/apexrest/PDCourseDataService';
        
        //Setup action
        req.httpMethod = 'GET';
        
        //Setup callout
        RestContext.request = req;
        RestContext.response = res;
        
        //Start Test
        Test.startTest();
        PDCourseDataService.doGet();
        Test.stopTest();
        
        Map<Id, PDCourseDataService.CourseData> courseMap = new Map<Id, PDCourseDataService.CourseData>();
        Map<String, List<PDCourseDataService.CourseOfferingPricingData>> courseOfferingPricingMap = new Map<String, List<PDCourseDataService.CourseOfferingPricingData>>();   
        
        //Query Course / Course Offering / Course Offering pricing and build the structure
        for(Course_Offering__c loopOffering : [SELECT Id, Name, Course__c, Course_Code__c, Faculty_Code__c, Course_Title_F__c, Status__c, Course_Type__c, Campus__c,
                                                        Start_Date__c, End_Date__c, Registration_Close_Date__c, Active__c,
                                                        //Parent Course Record
                                                        Course__r.Name, Course__r.Course_Code__c, Course__r.Status__c, Course__r.Title__c, Course__r.Course_Description__c, Course__r.Course_Full_Description__c, Course__r.Type__c,
                                                        Course__r.Level__c, Course__r.Course_Level__c, Course__r.Points__c, Course__r.Start_Date__c, Course__r.End_Date__c, Course__r.Expiry_Date__c, 
                                                        Course__r.pw_Course_Duration__c, Course__r.Managing_Faculty__c, Course__r.Faculty_Description__c, Course__r.Faculty_Code__c,
                                                        //Child Course Offering Pricing records
                                                        (SELECT Id, Name, Course_Offering__c, Active__c, Pricing_Name__c, StartDate__c, EndDate__c, Pricing_Type__c,
                                                                Fee__c, DiscountEvidenceType__c
                                                        FROM Course_Offering_Pricings__r
                                                        WHERE Active__c = true)
                                                FROM Course_Offering__c 
                                                WHERE Course__r.Type__c = 'Short_Course'
                                                ORDER BY LastModifiedDate DESC]){
            //collect course offering price records and map it to course offerings
            List<PDCourseDataService.CourseOfferingPricingData> courseOfferingPricingList = new List<PDCourseDataService.CourseOfferingPricingData>();
            if(loopOffering.Course_Offering_Pricings__r != null && !loopOffering.Course_Offering_Pricings__r.isEmpty()){
                for(Course_Offering_Pricing__c loopCourseOfferingPricing : loopOffering.Course_Offering_Pricings__r){
                    courseOfferingPricingList.add(new PDCourseDataService.CourseOfferingPricingData(loopCourseOfferingPricing));
                }
            }
            courseOfferingPricingMap.put(loopOffering.Id, courseOfferingPricingList);

            //add course record and assign child course offering data
            if(!courseMap.containsKey(loopOffering.Course__c)){
                courseMap.put(loopOffering.Course__c, new PDCourseDataService.CourseData(loopOffering.Course__r));
            }
            courseMap.get(loopOffering.Course__c).courseOfferings.add(new PDCourseDataService.CourseOfferingData(loopOffering, courseOfferingPricingMap.get(loopOffering.Id)));
        }
        
        //Set response for assertion
        Blob responseJSON = res.responseBody;
        
        //Test response
        Integer i_firstItem = 0;
        Course__c testCourse = [SELECT Id, Course_Description__c FROM Course__c LIMIT 1];
        System.assertEquals(JSON.serialize(courseMap.values(), false).replace('null', '""'), 
                            responseJSON.toString());
        System.assertEquals(testCourse.Course_Description__c, 
                            (String)(((List<PDCourseDataService.CourseData>)JSON.deserialize(responseJSON.toString(), List<PDCourseDataService.CourseData>.class))[i_firstItem].courseTitle));
    }

}