/**
 * @description       : Course Offerings Request Wrapper
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 16-02-2024
 * @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class CourseOfferingsWSRequest {
    public class Courserequest {
        public String courseYear;
        public String courseCode;
        public String locationCode;
        public String courseName;
        public String campusCountry;
        public String pageSize;
        public String pageOffset;
        public String citizenshipTypeCodes;
    }
    
    /**
    * @description Get Offered Course
    * @author rajesh.punjabi@monash.edu | 06-02-2024 
    **/
    public static Courserequest parse(String json) {
        return (Courserequest) System.JSON.deserialize(json, Courserequest.class);
    }
}