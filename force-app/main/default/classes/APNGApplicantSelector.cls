/**
 * @description       : Selector class for  APNGApplicant
 * @author            : Ben Greenland
 * @group             : Admissions
 * @last modified on  : 2024-10-21
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-08-20   Ben Greenland   Initial Version
**/
public virtual inherited sharing class APNGApplicantSelector {
    /**
    * @description Gets count of records for searchApplicants as the original implemention in AgentPortalServices.searchApplicants
    *               doesn't correctly support pagination (rafactored from AgentPortalServices.searchApplicants)
    * @author Ben Greenland | 2024-08-15 
    * @param applicantName 
    * @return Integer 
    **/
    public static Integer searchApplicantsCountForPagination(String applicantName) {
        // Query for Applicants 
        String clause = '(full_name__c LIKE  \'%' + String.escapeSingleQuotes(applicantName) + '%\' OR Previous_Surname__c  LIKE  \'%' + String.escapeSingleQuotes(applicantName) + '%\' OR First_name__c  LIKE  \'%' + String.escapeSingleQuotes(applicantName) + '%\' )';
        clause += ' AND RecordType.DeveloperName NOT IN (\'Agency_Contact\', \'Partner\')';
        String query = 'SELECT COUNT() ';
        query += ' FROM Contact WHERE {0}';
        query = String.format(query, new List<String> {clause});
        return Database.countQuery(query,AccessLevel.USER_MODE);
    }
}