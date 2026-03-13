/**
 * @File Name          : MyAppApplicationAuthenticator.cls
 * @Description        : My.App authentication if the record is related to logged in user
 * @Author             : Vishal Gupta
 * @Group              : My.App
 * @date               : 28/3/2025
 **/
public with sharing class MyAppApplicationAuthenticator implements IMyAppApplicantChecker {
    private Application__c app;
    public MyAppApplicationAuthenticator(Application__c application) {
        this.app = application;
    }

    /**
     * @author      Vishal Gupta
     * @description  Implement the getApplicantId method
     * @revision    28/3/2025 - Initial Version
    */
    public Id getApplicantId() {
        return app.Applicant__c;
    }

    /**
     * @author      Vishal Gupta
     * @description Implement the isRecordRelatedToCurrentUser method
     * @revision    28/3/2025 - Initial Version
    */
    public Boolean isRecordRelatedToCurrentUser() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
        return getApplicantId() == currentUser.ContactId;
    }
}