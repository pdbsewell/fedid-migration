/**
 * @description Interface for applying data transformation to Course Offering 
 * records
 * @group Course Offering
 */
public interface CourseOfferingTransform {

    /**
     * @description Tranforms course offering data with pass by reference
     * @param courseOffering List of Course Offering records to be transformed
     */
    void transform(List<Course_Offering__c> courseOfferings);

}