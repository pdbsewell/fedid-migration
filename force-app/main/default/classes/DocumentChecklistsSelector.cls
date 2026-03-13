/**
 * @author      Kristian Vegerano
 * @description Selector class for document checklist object processes
 * @group       Selectors
 * @revision    31/05/2019 - Kristian Vegerano - Created
 */
public with sharing class DocumentChecklistsSelector extends BaseSelector {
    /**
     * Constructors
     */
    public DocumentChecklistsSelector() {
        super(false);
    }
    
    public DocumentChecklistsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
    
    /**
     * @author      Kristian Vegerano
     * @date        31/05/2019
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return Document_Checklist__c.sObjectType;
    }
    
    /**
     * @author      Kristian Vegerano
     * @description Return ORDER BY clause for the query
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public override String getOrderBy() {
        return 'Sort_Order__c ASC';
    }

    /**
     * @author      Kristian Vegerano
     * @date        31/05/2019
     * @description Query document checklists by ids
     */
    public List<Document_Checklist__c> selectById(Set<Id> idSet) {
        return (List<Document_Checklist__c>) selectSObjectsById(idSet);
    }
    
    /**
     * @author      Kristian Vegerano
     * @date        31/05/2019
     * @description Query document checklists by parent application's ids
     */
    public List<Document_Checklist__c> selectApplicationAssessmentByApplicationIds(Set<Id> applicationIdSet) {
        assertIsAccessible();

        ApplicationsSelector applicationSelector = new ApplicationsSelector(overrideObjectPermissions);
        applicationSelector.assertIsAccessible();
        ContactQualificationsSelector contactQualificationsSelector = new ContactQualificationsSelector(overrideObjectPermissions);
        contactQualificationsSelector.assertIsAccessible();

        Id applicationAssessmentRecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId();
        String queryString = String.format('SELECT {0}, {1}, {2}, {3} FROM {4} WHERE Application__c IN :applicationIdSet AND RecordTypeId = :applicationAssessmentRecordTypeId ORDER BY {5}',
                                           new List<String>{getFieldListString(),
                                                            applicationSelector.getRelatedFieldListString('Application__r'),
                                                            'Contact_Qualification__r.Qualification_Type__c,Contact_Qualification__r.Name, Contact_Qualification__r.Qualification_Country__r.ISO_Alpha_2__c',
                                                            '(SELECT Id, CreatedDate, Document_Checklist__c, Content__c, NotesSeen__c FROM Document_Checklist_Comments__r ORDER BY CreatedDate DESC)',
                                                            getSObjectName(),
                                                            getOrderBy()});
        return Database.query(queryString);
    }

    /**
     * @author      Kristian Vegerano
     * @date        31/05/2019
     * @description Query document checklists by parent application's ids
     */
    public List<Document_Checklist__c> selectByIdWithApplicationDetails(Set<Id> applicationChecklistIds) {
        assertIsAccessible();

        ApplicationsSelector applicationSelector = new ApplicationsSelector(overrideObjectPermissions);
        applicationSelector.assertIsAccessible();

        String queryString = String.format('SELECT {0}, {1} FROM {2} WHERE Id IN :applicationChecklistIds ORDER BY {3}', 
                                           new List<String>{getFieldListString(),
                                                            applicationSelector.getRelatedFieldListString('Application__r'),
                                                            getSObjectName(),
                                                            getOrderBy()});
        return Database.query(queryString);
    }
    
    /**
     * @author      Kristian Vegerano
     * @description Query document checklists by parent sbqq quote's ids
     * @revision    13/02/2020 - Kristian Vegerano - Created
     */
    public List<Document_Checklist__c> selectOfferAcceptanceByQuoteIds(Set<Id> opportunityIdSet) {
        assertIsAccessible();

        OpportunitiesSelector opportunitySelector = new OpportunitiesSelector(overrideObjectPermissions);
        opportunitySelector.assertIsAccessible();

        Id offerAcceptanceRecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Offer_Acceptance').getRecordTypeId();
        String queryString = String.format('SELECT {0}, {1}, {2} FROM {3} WHERE Opportunity__c IN :opportunityIdSet AND RecordTypeId = :offerAcceptanceRecordTypeId ORDER BY {4}', 
                                           new List<String>{getFieldListString(),
                                                            opportunitySelector.getRelatedFieldListString('Opportunity__r'),
                                                            '(SELECT Id, CreatedDate, Document_Checklist__c, Content__c, NotesSeen__c FROM Document_Checklist_Comments__r ORDER BY CreatedDate DESC)',
                                                            getSObjectName(),
                                                            getOrderBy()});        
        return Database.query(queryString);
    }

    /**
     * @author      Vishal Gupta
     * @date        22/10/2024
     * @param applicationId
     * @param docRequestType
     * @param sequenceNumber
     * @return List<Document_Checklist__c>
     * @description Query document checklists by application id, doc request type and Sequence Number if given
     */
    public List<Document_Checklist__c> selectApplicationAssessmentByApplicationIdAndSequenceNumber(Id applicationId, String docRequestType, Integer sequenceNumber) {
        assertIsAccessible();
        String applicationQualQuery = '';
        Set<String> status = new Set<String>{'Requested', 'Submitted', 'Insufficient'};
        String docCommentsQuery = '(SELECT Id, Content__c, Cancelled__c, Cancelled_Date__c, Request_Date__c FROM Document_Checklist_Comments__r ORDER BY CreatedDate DESC)';
        if(sequenceNumber != null) {
            applicationQualQuery = ' AND Contact_Qualification__c IN (SELECT Contact_Qualification__c FROM Application_Qualification_Provided__c WHERE Application__c = :applicationId and Sequence_Number__c = :sequenceNumber) ';
        }
        Id applicationAssessmentRecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId();
        String queryString = String.format('SELECT {0}, {1} FROM {2} WHERE Application__c = :applicationId AND Document_Request_Type__c = :docRequestType AND Status__c in :status {3} ORDER BY {4}',
                                           new List<String>{getFieldListString(),
                                                            docCommentsQuery,
                                                            getSObjectName(),
                                                            applicationQualQuery,
                                                            getOrderBy()});
        return Database.query(queryString);
    }
}