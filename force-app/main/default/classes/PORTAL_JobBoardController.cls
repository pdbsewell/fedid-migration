/*
 * Copyright (c) 2019, UC Innovation, Inc.  All Rights Reserved.
 *                     http://www.ucinnovation.com
 *
 * This source code is licensed, not sold, and is subject to a written
 * license agreement.  Among other things, no portion of this source
 * code may be copied, transmitted, disclosed, displayed, distributed,
 * translated, used as the basis for a derivative work, or used, in
 * whole or in part, for any program or purpose other than its intended
 * use in compliance with the license agreement as part of UC Innovation's
 * software.  This source code and certain of the algorithms contained
 * within it are confidential trade secrets of UC Innovation, Inc.
 * and may not be used as the basis for any other
 * software, hardware, product or service.
 */
 
 /**
 * Handles methods related to job board.
 *
 * @author:  Jiabin Chen
 * @version: 1.0
 * @since:   1.0
 */

public with sharing class PORTAL_JobBoardController {

    /**
     * Delete a job record.
     *
     * @param: jobRecId     Record ID of job to delete.
     * @return: 			Success.
     * @since: 				1.0
     */
    
    @AuraEnabled
    public static string SERVER_deleteJobRecord(Id jobRecId){
    
        delete [SELECT Id From Job__c Where Id = :jobRecId];

        return 'Success';
    }

    /**
     * Create a job record.
     *
     * @param: jobRecord	Job record to create.
     * @return: 			success.
     * @since: 				1.0
     */
    
    @AuraEnabled
    public static string SERVER_createJobRecord (Job__c jobRecord) {
        
        System.debug('job record: ' + jobRecord);
        insert jobRecord;

        return 'success';
    }

    /**
     * Query for all open jobs that have not expired.
     *
     * @return:	All open jobs that have not expired.
     * @since: 	1.0
     */
    
    @AuraEnabled
    public static List<Job__c> SERVER_queryOpenJobs() {

        Date today = Date.Today();

        return [SELECT Approximate_Salary__c, 
                       Recruiting_Company__c,
                       Name, 
                       CreatedDate,
                       Description__c, 
                       Location__c,
                       Qualification__c,
                       Desired_Skills__c,
                       Desired_Majors__c,
                       Position_Type__c,
                       Work_Hours_Per_Week__c,
                       Require_Work_Authorization__c
                FROM Job__c
                WHERE Expiration_Date__c > today
                ORDER BY CreatedDate DESC];
    }
 
    /**
     * Query for all posted jobs by the logged in user.
     *
     * @return:	All posted jobs by the logged in user.
     * @since: 	1.0
     */
    
    @AuraEnabled
    public static List<Job__c> SERVER_queryPostedJobs() {

        Id userId = UserInfo.getUserId();

        return [SELECT Approximate_Salary__c, 
                       Recruiting_Company__c,
                       Name, 
                       CreatedDate,
                       Description__c, 
                       Location__c,
                       Qualification__c,
                       Desired_Skills__c,
                       Desired_Majors__c,
                       Position_Type__c,
                       Work_Hours_Per_Week__c,
                       Require_Work_Authorization__c,
                       (SELECT ContentDocument.Title, ContentDocument.Owner.Name, ContentDocument.Owner.Email, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks)
                FROM Job__c
                WHERE CreatedById = :userId
                ORDER BY CreatedDate DESC];
    }

    /**
     * Query for all posted jobs by the logged in user based on the filter criteria.
     *
     * @param: filterCriteria	Filter criteria to used to filter for posted jobs.
     * @return:					All posted jobs by the logged in user based on the filter criteria.
     * @since: 					1.0
     */
    
    @AuraEnabled
    public static List<Job__c> SERVER_queryPostedJobsWithFilter(Map<string, object> filterCriteria) {
       
        System.debug('filterCriteria: ' + filterCriteria);
        
        string keyWord = (string)filterCriteria.get('keyWord');
        
        if (!String.isEmpty(keyWord)) {
            keyWord = '%' + keyWord + '%';
        }
        
        string locationKeyWord = (string)filterCriteria.get('locationKeyWord');
        
        if (!String.isEmpty(locationKeyWord)) {
            locationKeyWord = '%' + locationKeyWord + '%';
        }
        
        decimal salaryLowerBound = (decimal)filterCriteria.get('salaryLowerBound');
        decimal salaryUpperBound = (decimal)filterCriteria.get('salaryUpperBound');
        string positionType = (string)filterCriteria.get('positionType');
        string classDegreeLevel = (string)filterCriteria.get('classDegreeLevel');
        
        System.debug('salaryLowerBound: ' + salaryLowerBound);
        System.debug('salaryUpperBound: ' + salaryUpperBound);

        string keyWordCondition = string.isEmpty(keyWord) ? '' : ' (Name LIKE :keyWord OR Recruiting_Company__c LIKE :keyWord) ';
        string locationCondition = string.isEmpty(locationKeyWord) ? '' : ' Location__c LIKE :locationKeyWord ';
        string moneyLowerCondition = salaryLowerBound == null ? '' : ' Approximate_Salary__c >= ' + salaryLowerBound; 
        string moneyUpperCondition = salaryUpperBound == null ? '' : ' Approximate_Salary__c <= ' + salaryUpperBound;
        string positionTypeCondition = positionType.startsWith('All') ? '' : ' Position_Type__c = :positionType ';
        string levelCondition = classDegreeLevel.startsWith('All') ? '' : ' Class_Level_Degree_Level__c = :classDegreeLevel ';

        string fields = ' Approximate_Salary__c, Recruiting_Company__c, Name, Description__c, Location__c, Qualification__c, Desired_Skills__c, Desired_Majors__c, Position_Type__c, Work_Hours_Per_Week__c, Require_Work_Authorization__c';

        List<String> conditions = new List<String>{keyWordCondition, locationCondition, moneyLowerCondition, moneyUpperCondition, positionTypeCondition, levelCondition};

        String whereClause = '';
        Boolean hasWhere = false;
        for (Integer i = 0; i < conditions.size(); i++) {

            if (String.isEmpty(conditions[i]) == false) {
                if (hasWhere == false) {
                    hasWhere = true;
                    whereClause = ' WHERE ' + conditions[i];
                } else {
                    whereClause = whereClause + ' AND ' + conditions[i];
                }
            }
        }

        System.debug('query: ' + 'Select ' + fields + ' From Job__c ' + whereClause + ' LIMIT 200');
        // Limit 200, if we need more then we do pagination and search
        return Database.query('SELECT ' + fields + ' FROM Job__c ' + whereClause + ' LIMIT 200');
    }
    
    /**
     * Query for all applied jobs by the logged in user.
     *
     * @return:	All applied jobs by the logged in user.
     * @since: 	1.0
     */
    
    @AuraEnabled
    public static List<Job__c> SERVER_queryAppliedJobs() {
    
        // Query could be optimized later
        Id userId = UserInfo.getUserId();
        List<ContentDocument> resumes = [SELECT Id, CreatedDate
                                         FROM ContentDocument
                                         WHERE OwnerId = :userId];
        
        Set<Id> resumeIDs = getIdTypeValuesByField(resumes, ContentDocument.Id);

        // Need to check to make sure it's not empty.  Otherwise, will get the following error:
        // Implementation restriction: ContentDocumentLink requires a filter by a single Id on ContentDocumentId or LinkedEntityId using the equals operator or multiple Id's using the IN operator.
        if (!resumeIDs.isEmpty()) {
            List<ContentDocumentLink> resumeLinks = [SELECT ContentDocumentId, LinkedEntityId, ContentDocument.CreatedDate
                                                     FROM ContentDocumentLink
                                                     WHERE ContentDocumentId in :resumeIDs];
            
            Set<Id> appliedJobIDs = getIdTypeValuesByField(resumeLinks, ContentDocumentLink.LinkedEntityId);
            
            Map<Id, Date> jobIdToCreateDate = new Map<Id, Date>();
            
            for (ContentDocumentLink link : resumeLinks) {
                jobIdToCreateDate.put(link.LinkedEntityId, link.ContentDocument.CreatedDate.Date());
            }
    
            List<Job__c> appliedJobs = [SELECT Recruiting_Company__c, Name
                                        FROM Job__c
                                        WHERE Id in :appliedJobIDs];
            
            for (Job__c job : appliedJobs) {
                job.Submission_Date__c = jobIdToCreateDate.get(job.Id);
            }
    
            // appliedJobs.get(0).Submission_Date__c = Date.Today();
    
            System.debug('appliedJobs: ' + appliedJobs);
    
            return appliedJobs;
        }
        else {
            return new List<Job__c>();
        }
    }

    /**
     * Query for job applications for a given job.
     *
     * @param: jobRecId		Job to find applicants for.
     * @return:				All job applications associated with the given job.
     * @since: 				1.0
     */    
    @AuraEnabled
    public static List<ContentDocumentLink> SERVER_queryJobApplicants(Id jobRecId){

        System.debug('jobRecId: ' + jobRecId);

        List<ContentDocumentLink> resumeLinks = [SELECT ContentDocument.Title, ContentDocument.Owner.Name, ContentDocument.Owner.Email, ContentDocumentId, LinkedEntityId
                                                 FROM ContentDocumentLink
                                                 WHERE LinkedEntityId = :jobRecId];
        

        return resumeLinks;
    }

    /**
     * Query for job applications for a given job.
     *
     * @param: records	Record to get the ID field value from.
     * @param: field	ID field.
     * @return:			Set of ID values of the ID field from the records.
     * @since: 			1.0
     */    
    public static Set<Id> getIdTypeValuesByField(List<sObject> records, Schema.SObjectField field) {

        Set<Id> idSet = new Set<Id>();

        String fieldName = field.getDescribe().getName();

        for (sObject sobj : records) {
            if (sobj.get(fieldName) != null) {
                idSet.add( (Id)sobj.get(fieldName) );
            }
        }

        return idSet;
    }
}