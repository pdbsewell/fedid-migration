/**
 * @File Name          : IProspectiveStudentLead.cls
 * @Description        : interface for ProspectiveStudentLeadDAO
 * @Author             : Nick Guia
 * @Group              : Lead Management
 * TO BE DEPRECATED AFTER MOVING TO V2
**/
public interface IProspectiveStudentLead {
    /**
    * @description retrieve the Lead record related with this Prospective Student
    * @return Lead
    */
    Lead getLead();
    /**
    * @description retrieves all Lead Course Association records related with this Prospective Student 
    * @return List<Lead_Course_Association__c>
    */
    List<Lead_Course_Association__c> getCourseInterests();
    /**
    * @description retrieves all Lead Course Association records related 
    *   with this Prospective Student in a map format
    * @return Map<Id, Lead_Course_Association__c>
    */
    Map<Id, Lead_Course_Association__c> getCourseInterestsMap();
    /**
    * @description assign a Lead record for this Prospective Student
    * @param Lead leadRec
    * @return void
    */
    void setLead(Lead leadRec);
    /**
    * @description adds a Lead Course Association record for this Prospective Student 
    * @param Lead_Course_Association__c lca : Lead Course Association record to be added
    * @return void
    */
    void addCourseInterest(Lead_Course_Association__c lca);
    /**
    * @description replaces the existing List of Lead Course Association 
    *   records related witht this Prospective Student
    * @param List<Lead_Course_Association__c> listLca : new List of Lead Course Association records
    * @return void
    */
    void setCourseInterest(List<Lead_Course_Association__c> listLca);
    /**
    * @description resolves dependencies and object relationships of all associated
    *   records within the Data Access Object
    * @param BaseClass bc : an instance of BaseClass with a defined commit order
    * @param Contact con : parent Contact of Prospective Student Lead record
    * @return void
    */
    void resolveDependencies(BaseClass bc, Contact con);
}