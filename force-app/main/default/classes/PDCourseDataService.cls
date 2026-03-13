/**
 * @author                      Kristian Vegerano
 * @created                     10/10/2021
 * @description                 Rest Service that retrieves PD Courses
 */
@RestResource(urlMapping='/PDCourseDataService')
global with sharing class PDCourseDataService {

    /**
     * @author                      Kristian Vegerano
     * @created                     10/10/2021
     * @description                 Method that runs when a GET request has been sent to PDCourseDataService
     * @return                      returns customer and public articles in JSON format attached to the response body
     */
    @HttpGet
    global static void doGet() {
        //retrieve service parameters
        String courseCodes = RestContext.request.params.get('CourseCodes');
        String statuses = RestContext.request.params.get('Status'); 

        //assign parameter filters
        List<String> l_courseCodes = new List<String>();
        List<String> l_statuses = new List<String>();
        if(!String.isEmpty(courseCodes)){
            l_courseCodes = courseCodes.split(',');
        }
        if(!String.isEmpty(statuses)){
            l_statuses = statuses.split(',');
        }

        //Set return type to JSON
        RestContext.response.addHeader('Content-Type', 'application/json');

        //Return FAQ data
        PDCourseData pdCourseService = new PDCourseData();
        String responseJSON = JSON.serialize(pdCourseService.retrieveProfessionalDevelopmentCourses(l_courseCodes, l_statuses), false).replace('null', '""');
        
        //Set return type to JSON
        RestContext.response.responseBody = Blob.valueOf(responseJSON);
    }

    /**
     * @author                      Kristian Vegerano
     * @created                     10/10/2021
     * @description                 Class that would contain the logic for PDCourseDataService. Retrieves all published articles and formats it on JSON
     */
    @TestVisible
    private with sharing class PDCourseData {
        /**
         * @author                      Kristian Vegerano
         * @created                     10/10/2021
         * @description                 Updates the case Email_To__c field with the ToAddress field of EmailMessage
         * @return                      List<CourseData> - list of published FAQ articles
         */
        public List<CourseData> retrieveProfessionalDevelopmentCourses(List<String> l_courseCodes, List<String> l_statuses){
            //Initialize variables
            Map<Id, CourseData> courseMap = new Map<Id, CourseData>();
            Map<String, List<CourseOfferingPricingData>> courseOfferingPricingMap = new Map<String, List<CourseOfferingPricingData>>();   
            
            //Query Course / Course Offering / Course Offering pricing and build the structure
            String queryString = '';
                //main query's select clause
                queryString += 'SELECT Id, Name, Course__c, Course_Code__c, Faculty_Code__c, Course_Title_F__c, Status__c, Course_Type__c, Campus__c, ';
                    queryString += 'Start_Date__c, End_Date__c, Registration_Close_Date__c, Active__c, ';
                    //Parent Course Record
                    queryString += 'Course__r.Name, Course__r.Course_Code__c, Course__r.Status__c, Course__r.Title__c, Course__r.Course_Description__c, Course__r.Course_Full_Description__c, Course__r.Type__c, ';
                    queryString += 'Course__r.Level__c, Course__r.Course_Level__c, Course__r.Points__c, Course__r.Start_Date__c, Course__r.End_Date__c, Course__r.Expiry_Date__c,  ';
                    queryString += 'Course__r.pw_Course_Duration__c, Course__r.Managing_Faculty__c, Course__r.Faculty_Description__c, Course__r.Faculty_Code__c, ';
                    //Child Course Offering Pricing records
                    queryString += '(SELECT Id, Name, Course_Offering__c, Active__c, Pricing_Name__c, StartDate__c, EndDate__c, Pricing_Type__c, ';
                    queryString += 'Fee__c, DiscountEvidenceType__c ';
                    queryString += 'FROM Course_Offering_Pricings__r ';
                    queryString += 'WHERE Active__c = true) ';
                //main query's from clause
                queryString += 'FROM Course_Offering__c ';
                //main query's from clause
                queryString += 'WHERE Course__r.Type__c = \'Short_Course\' ';

                //dynamic course codes filter
                if(!l_courseCodes.isEmpty()){
                    queryString += 'AND Course__r.Name IN :l_courseCodes ';
                }
                //dynamic status filter
                if(!l_statuses.isEmpty()){
                    queryString += 'AND Status__c IN :l_statuses ';
                }

                //main query's order by clause
                queryString += 'ORDER BY LastModifiedDate DESC';

            //query course offerings, courses and course offering prices
            for(Course_Offering__c loopOffering : Database.query(queryString)){
                //collect course offering price records and map it to course offerings
                List<CourseOfferingPricingData> courseOfferingPricingList = new List<CourseOfferingPricingData>();
                if(loopOffering.Course_Offering_Pricings__r != null && !loopOffering.Course_Offering_Pricings__r.isEmpty()){
                    for(Course_Offering_Pricing__c loopCourseOfferingPricing : loopOffering.Course_Offering_Pricings__r){
                        courseOfferingPricingList.add(new CourseOfferingPricingData(loopCourseOfferingPricing));
                    }
                }
                courseOfferingPricingMap.put(loopOffering.Id, courseOfferingPricingList);

                //add course record and assign child course offering data
                if(!courseMap.containsKey(loopOffering.Course__c)){
                    courseMap.put(loopOffering.Course__c, new CourseData(loopOffering.Course__r));
                }
                courseMap.get(loopOffering.Course__c).courseOfferings.add(new CourseOfferingData(loopOffering, courseOfferingPricingMap.get(loopOffering.Id)));
            }

            return courseMap.values();
        }
    }

    /**
     * @author                      Kristian Vegerano
     * @created                     10/10/2021
     * @description                 Wrapper class for the JSON format of the course data
     */
    public class CourseData {
        public String courseTitle {get; set;} //Title__c
        public String courseDescription {get; set;} //Course_Description__c
        public String courseCode {get; set;} //Course_Code__c
        public List<CourseOfferingData> courseOfferings {get; set;}

        /**
         * @author                      Kristian Vegerano
         * @created                     10/10/2021
         * @description                 Constructor
         */
        public CourseData(Course__c course){
            this.courseTitle = course.Course_Description__c;
            this.courseDescription = course.Course_Full_Description__c;
            this.courseCode = course.Name;
            this.courseOfferings = new List<CourseOfferingData>();
        }
    }

    /**
     * @author                      Kristian Vegerano
     * @created                     10/10/2021
     * @description                 Wrapper class for the JSON format of the course offering data
     */
    public class CourseOfferingData {
        public String courseOfferingId {get; set;} //Name
        public String location {get; set;} //Campus__c
        public String startDate {get; set;} //Start_Date__c
        public String endDate {get; set;} //End_Date__c
        public String status {get; set;} //Status__c
        public Boolean active {get; set;} //Active__c
        public List<CourseOfferingPricingData> fees {get; set;}

        /**
         * @author                      Kristian Vegerano
         * @created                     10/10/2021
         * @description                 Constructor
         */
        public CourseOfferingData(Course_Offering__c courseOffering, List<CourseOfferingPricingData> courseOfferingPricingDataList){
            this.courseOfferingId = courseOffering.Name;
            this.location = courseOffering.Campus__c;
            this.startDate = courseOffering.Start_Date__c != null ? DateTime.newInstance(courseOffering.Start_Date__c.year(), courseOffering.Start_Date__c.month(), courseOffering.Start_Date__c.day()).format('dd/MM/YYYY') : null;
            this.endDate = courseOffering.End_Date__c != null ? DateTime.newInstance(courseOffering.End_Date__c.year(), courseOffering.End_Date__c.month(), courseOffering.End_Date__c.day()).format('dd/MM/YYYY') : null;
            this.status = courseOffering.Status__c;
            this.active = courseOffering.Active__c;
            this.fees = courseOfferingPricingDataList;
        }
    }

    /**
     * @author                      Kristian Vegerano
     * @created                     10/10/2021
     * @description                 Wrapper class for the JSON format of the course offering data
     */
    public class CourseOfferingPricingData {
        public Boolean active {get; set;} //Active__c
        public String description {get; set;} //Pricing_Name__c
        public String amount {get; set;} //Fee__c
        public String feeName {get; set;} //Pricing_Type__c

        /**
         * @author                      Kristian Vegerano
         * @created                     10/10/2021
         * @description                 Constructor
         */
        public CourseOfferingPricingData(Course_Offering_Pricing__c courseOfferingPricing){  
            this.active = courseOfferingPricing.Active__c;      
            this.feeName = courseOfferingPricing.Pricing_Type__c;   
            this.description = courseOfferingPricing.Pricing_Name__c;  
            if(courseOfferingPricing.Fee__c != null){
                this.amount = courseOfferingPricing.Fee__c.format();
            }
        }
    }
}