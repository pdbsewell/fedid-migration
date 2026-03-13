/**
 * @description       : Selector class for Exploding Leads Process
 * @author            : Nick Guia
 * @date              : 24-09-2020
 * @group             : Lead Management
 * @last modified on  : 04-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *  27-09-2022    Nick Guia   - Moved queries from BulkSPSDAO to run in without sharing for V1
 *                            - Updated dynamic query to use DynamicSoqlBuilder
 *  04-07-2023    Nick Guia   - Removed query for CPA records
**/
public without sharing class ExplodingLeadsSelector {

    @TestVisible
    private DynamicSoqlBuilder soqlBuilder;

    public ExplodingLeadsSelector() {
        //no need to validate fields as it will come from schema
        //shouldn't enforce FLS (by design)
        this.soqlBuilder = DynamicSoqlBuilder.getInstance();
    }

    /**
     * @description retrieve existing Contact information
     * @return List<Contact> retrieved Prospective Student Contact records
     */
    public List<Contact> selectExistingContacts(Set<Id> contactIds) {
        List<Contact> retList = new List<Contact>();
        if(contactIds == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!contactIds.isEmpty()) {
            retList = [SELECT Id, FirstName, LastName, Email, Monash_Email_Address__c, Nationality__c,
                                Personal_Email__c, Birthdate, AccountId, Gender__c, Country_of_Residence__c, 
                                LastModifiedDate, CreatedDate, Birth_year__c
                                FROM Contact
                                WHERE Id IN :contactIds];
        }
        return retList;
    }

    /**
     * @description queries all Prospective Student related Roles and Channels
     *  if query finds multiple 'current' roles: latest, greatest.
     *  TODO: this is to be deprecated once migrating to P360 (V2) is completed
     * @return List<Roles__c>
     */
    public List<Roles__c> selectContactRolesByContactId(Set<Id> contactIds) {
        List<Roles__c> retList = new List<Roles__c>();
        if(contactIds == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!contactIds.isEmpty()) {
            retList = [SELECT Id, Contact__c, Status__c, Role__c
                        FROM Roles__c
                        WHERE Contact__c IN :contactIds
                        AND Role__c = :Label.Roles_Role_ProspectiveStudent
                        AND Status__c = :Label.Roles_Status_Current
                        ORDER BY CreatedDate ASC];
        }
        return retList;
    }

    /**
     * @description Retrieve all Channels related to contact. We need to use a dynamic query 
     *  since getting all fields is required for the 'Do not Overwrite' feature to know if 
     *  there are current values.
     * 
     *  TODO: this is to be deprecated once migrating to P360 (V2) is completed
     * @return void
     */
    public List<Channel__c> selectContactChannelByRoleId(Set<Id> roleIds) {
        List<Channel__c> retList = new List<Channel__c>();
        if(roleIds == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!roleIds.isEmpty()) {
            //build query String
            Set<String> fieldSet = Schema.describeSObjects(new List<String> { 'Channel__c' })[0].fields
                                    .getMap()
                                    .keySet();
            String whereClause = ' Role__c IN :roleIds';

            //no need to validate fields as it will come from schema and shouldn't enforce FLS (by design)
            String queryString = this.soqlBuilder.validateFields(false)
                                    .setEnforced(false)
                                    .querySObject('Channel__c')
                                    .queryFields(fieldSet)
                                    .getQuery(whereClause);
            retList = Database.query(queryString);
        }
        return retList;
    }

    /**
     * @description for retrieving existing Cases linked to the SPS. 
     *  This is for updating blank Lead lookup in Enquiry
     * 
     * TODO: this is to be deprecated once migrating to P360 (V2) is completed
     * @return void
     */
    public List<Case> selectCases(Set<Id> conIds, Set<Id> caseIds) {
        List<Case> retList = new List<Case>();
        if(conIds == null || caseIds == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!conIds.isEmpty() && !caseIds.isEmpty()) {
            retList = [SELECT Id, Lead__c, ContactId
                        FROM Case 
                        WHERE Id IN :caseIds
                        AND ContactId IN :conIds];
        }
        return retList;
    }

    /**
     * @description retrieve existing Prospective Student Affiliation
     * for each Contact record
     * @return List<Affiliation__c> retrieved Prospective Student Affiliation records
     */
    public List<Affiliation__c> selectProspectAffiliation(Set<Id> contactIds) {
        List<Affiliation__c> retList = new List<Affiliation__c>();

        if(contactIds == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!contactIds.isEmpty()) {
            Id psRecTypeId = Schema.SObjectType.Affiliation__c
                        .getRecordTypeInfosByDeveloperName()
                        .get('Prospective_Student')
                        .getRecordTypeId();

            retList =  [SELECT Id, Account__c, Contact__c, Is_Active__c
                    FROM Affiliation__c
                    WHERE Contact__c IN :contactIds
                    AND Is_Active__c = TRUE
                    AND RecordTypeId = :psRecTypeId];
        }
        return retList;   
    }

    /**
     * @description retrieve all Leads related to contact
     * @return List<Lead> retrieved Prospective Student Lead records
     */
    public List<Lead> selectExistingLeads(Set<Id> conIds) {
        List<Lead> retList = new List<Lead>();
        if(conIds == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!conIds.isEmpty()) {
            Set<String> fieldSet = Schema.describeSObjects(new List<String> { 'Lead' })[0].fields
                                    .getMap()
                                    .keySet();
            String whereClause = ' RecordTypeId = \'' + StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT + '\'' +
                                 ' AND Active_Lead_Contact_Id__c IN :conIds' +
                                 ' ORDER BY LastModifiedDate ASC';
                                 
            //no need to validate fields as it will come from schema and shouldn't enforce FLS (by design)
            String queryString = this.soqlBuilder.validateFields(false)
                                    .setEnforced(false)
                                    .querySObject('Lead')
                                    .queryFields(fieldSet)
                                    .getQuery(whereClause);
            retList = Database.query(queryString);
        }
        return retList;   
    }

    /**
     * @description for retrieving existing Lead Course Associations 
     * based on the collected Course Codes / Course master ID + Lead IDs
     * @return List<Lead_Course_Association__c> retrieved Lead Course Association records
     */
    public List<Lead_Course_Association__c> selectExistingLCA(Set<Id> existingLeadIdSet, Set<String> interestedCourseSet) {
        List<Lead_Course_Association__c> retList = new List<Lead_Course_Association__c>();

        if(existingLeadIdSet == null || interestedCourseSet == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!existingLeadIdSet.isEmpty()) {
            retList = [SELECT Id, Course_Master__c, Course_Code__c, Associated_Date__c, 
                        Last_Associated_Rank__c, Lead__c, Lead__r.Active_Lead_Contact_Id__c
                    FROM Lead_Course_Association__c
                    WHERE Lead__c IN :existingLeadIdSet
                    AND (
                        Course_Master__c IN :interestedCourseSet
                        OR Course_Code__c IN :interestedCourseSet
                    )];
        }
        return retList;
    }

    /**
     * @description retrieve all Contact Qualifications related to contact
     * @return List<Contact_Qualification__c> retrieved Contact Qualification records
     */
    public List<Contact_Qualification__c> selectExistingContactQualifications(Set<Id> conIds, Set<String> qualNames, Set<String> insNames) {
        List<Contact_Qualification__c> retList = new List<Contact_Qualification__c>();
        if(conIds == null || qualNames == null || insNames == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!conIds.isEmpty()) {
            retList =  [SELECT Id, Contact__c, Other_Qualification__c, Institution_Name__c
                        FROM Contact_Qualification__c
                        WHERE (
                            Contact__c IN :conIds
                            AND Other_Qualification__c IN :qualNames
                            AND Institution_Name__c IN :insNames
                        )];
        }
        return retList;
    }

    /**
     * @description retrieve all existing Courses and map by course code and ID
     * @return List<Course_Master__c> retrieved Contact Master records
     */
    public List<Course_Master__c> selectCourseMasters(Set<String> interestedCourseSet) {
        List<Course_Master__c> retList = new List<Course_Master__c>();
        if(interestedCourseSet == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!interestedCourseSet.isEmpty()) {
            retList = [SELECT Id, Course_Code__c 
                    FROM Course_Master__c
                    WHERE Course_Code__c IN :interestedCourseSet
                    OR Id IN :interestedCourseSet];
        }
        return retList;
    }

    /**
     * @description retrieve all existing campaign members for contacts
     * @return List<Campaign> retrieved Campaign and Campaign Member records
     */
    public List<Campaign> selectExistingCampaignMember(Set<Id> conIds, Set<Id> campaignIds) {
        List<Campaign> retList = new List<Campaign>();
        if(conIds == null || campaignIds == null) {
            throw new ExplodingLeadsSelectorException('Invalid null argument');
        } else if(!campaignIds.isEmpty()) {
            retList = [SELECT Id, Channel_Type__c,
                            (SELECT Id, ContactId, CampaignId, Active__c, ChannelEmail__c, ChannelSMS__c
                            FROM CampaignMembers
                            WHERE ContactId IN :conIds)
                        FROM Campaign 
                        WHERE Id IN :campaignIds];
        }
        return retList;
    }

    /**
     * @description query all "unprocessed" SPS records. This is mainly used for Asynchronous Exploding Leads
     * @return List<Staged_Prospective_Student__c> unprocessed SPS records
     */
    public List<Staged_Prospective_Student__c> getUnprocessedRecords(Integer batchSize) {
        List<Staged_Prospective_Student__c> spsList = new List<Staged_Prospective_Student__c>();
        List<String> statuses = new List<String> { 'New', 'Re-process' };

        try {
            /**
             * split the the SPS query into two because using FOR UPDATE does not allow ORDER BY
             * ORDER BY is required to ensure that we process the latest SPS records first
             */
            Map<Id, Staged_Prospective_Student__c> spsMap = new Map<Id, Staged_Prospective_Student__c>(
                [SELECT Id
                FROM Staged_Prospective_Student__c
                WHERE Is_Synchronous__c = FALSE
                AND Status__c IN: statuses
                ORDER BY Exploding_Leads_V2__c, CreatedDate ASC
                LIMIT: batchSize]
            );

            //query the same set of SPS records, with FOR UPDATE
            spsList = [SELECT Id, 
                       Acquisition_Source_Campaign__c,
                       Birthdate__c,
                       Birth_year__c,
                       Broad_area_s_of_interest__c,
                       Broad_Area_of_Interest_Update_Mode__c,
                       Company__c,
                       Considering_Asian_universities_Text__c,
                       Contact_Qualification_JSON__c,
                       Country_of_Residence__c,
                       Current_Studies__c,
                       Desired_Start_Period__c,
                       Desired_Start_Year__c,
                       Dietary_Requirements__c,
                       Do_Not_Create_Acquisition_Camp_Member__c,
                       Do_Not_Overwrite__c,
                       Email__c,
                       English_Proficiency_Level__c,
                       Enquiry_Description__c,
                       Enquiry_Subject__c,
                       Event_Campaigns__c,
                       Event_Member_Status__c,
                       Exploded_Target__c,
                       Exploded_Enquiry__c,
                       Exploded_Lead__c,
                       Exploding_Leads_V2__c,
                       Extension_Enrolment__c,
                       First_Name__c,
                       Study_Funded_By__c,
                       GACLIENTID__c,
                       GATRACKID__c,
                       GAUSERID__c,
                       Gender__c,
                       Interested_Course_List__c,
                       Interested_in_Monash_College_Text__c,
                       is_Synchronous__c,
                       Last_Name__c,
                       Lead_Source__c,
                       Mailing_City__c,
                       Mailing_Country__c,
                       Mailing_Postcode__c,
                       Mailing_State__c,
                       Mailing_Street__c,
                       Migrated_Lead__c,
                       Mobile__c,
                       is_Monash_Scholars_Text__c,
                       Nationality__c,
                       Number_of_Attendees__c,
                       Parent_Guardian_Email__c,
                       Parent_Guardian_First_Name__c,
                       Parent_Guardian_Last_Name__c,
                       Parent_Guardian_Mobile__c,
                       Phone__c,
                       Preferred_Course_Unknown__c,
                       Salutation__c,
                       Secondary_School__c,
                       Seeking_information_for__c,
                       Session__c,
                       Specific_Study_Area__c,
                       Status__c,
                       is_Student_Extension_Text__c,
                       Student_type__c,
                       Study_Level__c,
                       Subscription_Lists__c,
                       Web_Lead_Source__c,
                       Complete_Secondary_School__c,
                       Preferred_Country_of_Study__c,
                       Monash_Visitor_ID__c,
                       Attended_By__c,
                       CreatedDate,
                       LastModifiedDate
                       FROM Staged_Prospective_Student__c
                       WHERE Id IN :spsMap.keySet()
                       FOR UPDATE];
        } catch(QueryException e) {
            //in case of locking...
            System.debug(LoggingLevel.INFO, e.getMessage());
            System.debug(LoggingLevel.INFO, e.getStackTraceString());
        }
        return spsList;
    }

    public class ExplodingLeadsSelectorException extends Exception {}
}