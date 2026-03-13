/**
 * @description       : Course Offerings Response Wrapper
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 23-02-2024
 * @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class CourseOfferingsResponseWrapper {
	public String success;
	public String description;
    public String error;
	public List<Course_Offering__c> courses;
	public String pageSize;
    public String pageOffset;
    public Integer noOfRecords;
    
    /**
    * @description Parse Json Method
    * @author rajesh.punjabi@monash.edu | 06-02-2024 
    **/
	public static CourseOfferingsResponseWrapper parse(String json) {
		return (CourseOfferingsResponseWrapper) System.JSON.deserialize(json, CourseOfferingsResponseWrapper.class);
	}
}