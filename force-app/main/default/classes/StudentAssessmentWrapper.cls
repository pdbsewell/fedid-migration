/**
 * @description       : Wrapper Class for Student Assessments
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @last modified on  : 04-10-2021
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   04-10-2021 - Angelo Rivera - Initial Creation
 * 2.0	 17-08-2025	- Sachin Shetty	- Added a default constructor
**/

public class StudentAssessmentWrapper {
    @AuraEnabled public String id;
    @AuraEnabled public String cmid;
    @AuraEnabled public String unitOfferingId;
    @AuraEnabled public String type;
    @AuraEnabled public String name;
    @AuraEnabled public String dueDate;
    @AuraEnabled public String cutoffDate;
    @AuraEnabled public String description;
    @AuraEnabled public String submissionStartDate;
    
    // Default constructor
    public StudentAssessmentWrapper() {} //NOPMD
}