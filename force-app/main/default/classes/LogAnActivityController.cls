/**
 * @author          Kristian Vegerano
 * @description     Apex controller class for AddLogaCall lightning component
 * @history         25/08/2018
 */
public class LogAnActivityController {

    @AuraEnabled 
    public static Task commitTask(String activityType, String activitySubject, String activityDescription, String parentId, String relatedWhoId) {
        Task commitTask = new Task(WhatId = (Id)parentId,
                                   Type = activityType,
                                   Subject = activitySubject,
                                   Description = activityDescription,
                                   Status = 'Completed',
                                   WhoId = relatedWhoId,
                                   ActivityDate = System.TODAY());
        insert commitTask;
        
        //Return to page the inserted task
        return commitTask;
    }
    
}