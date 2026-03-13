/**
 * @File Name          : IMyAppApplicantChecker.cls
 * @Description        : Interface for My.App authentication if the record is related to logged in user
 * @Author             : Vishal Gupta
 * @Group              : My.App
 * @date               : 28/3/2025
 **/
public interface IMyAppApplicantChecker {
    /**
    * @description get the applicant id 
    * @return Id
    **/
    Id getApplicantId();

    /**
    * @description check if the record is related to the current logged in user 
    * @return boolean
    **/
    Boolean isRecordRelatedToCurrentUser();
}