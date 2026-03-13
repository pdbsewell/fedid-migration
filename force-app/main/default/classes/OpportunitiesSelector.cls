/**
 * @author      David Browaeys
 * @description Selector class for opportunity object process selector
 * @group       Selectors
 * @revision    14/10/2019 - David Browaeys - Created
 */
public inherited sharing class OpportunitiesSelector extends BaseSelector {
    /**
     * Constructors
     */
    public OpportunitiesSelector() {
        super(false);
    }
    
    public OpportunitiesSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
    
    /**
     * @author      David Browaeys
     * @description Returns the object type
     * @revision    14/10/2019 - David Browaeys - Created
     */
    public Schema.SObjectType getSObjectType() {
        return Opportunity.sObjectType;
    }
    /**
     * @author      David Browaeys
     * @description Query opportunity by ids
     * @revision    14/10/2019 - David Browaeys - Created
     */
    public List<Opportunity> selectById(Set<Id> idSet) {
        return (List<Opportunity>) selectSObjectsById(idSet);
    }
    
    /**
     * @author      Jasmin Joy Rudio
     * @description Query opportunity by ids with opportunity line items ORDER BY the most recent record
     * @revision    27/05/2020 - Jasmin Joy Rudio - Created
     * 06/09/2021   Vinothraja  Added Offer_Template__c and Template_Type__c Fields 
     */
    public List<Opportunity> selectLatesByContactIdWithOpportunityLines(Set<String> idSet, Set<String> statuses) {
        String queryString = String.format('SELECT {0}, {1}, {2}, {3} FROM {4} WHERE PrimaryContact__c in :idSet AND StageName IN :statuses ORDER BY {5} LIMIT {6}', 
                                new List<String>{
                                    'Name, StageName, PrimaryContact__c, Template_Type__c, Offer_Template__c',
                                    'PrimaryContact__r.Name, Agent_Account__r.Email__c',
                                    '(SELECT Id, ACP__c, ACP__r.Course_Code__c, Clause__c, Mirror_Clause__c, Clause__r.APXT_Redlining__Latest_Revision__c, Clause__r.APXT_Redlining__Text__c, Clause__r.Object_Level__c, Clause__r.Clause_Review_Required__c FROM Associated_Clauses__r)',
                                    '(SELECT id, Application_Course_Preference__c, Override_Start_Date__c, Override_End_Date__c, Override_Duration__c, PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id, OpportunityId, PricebookEntryId, PricebookEntry.Product2.Product_Bundle__c, Expiry_Date__c, ProductCode, '
                                    + 'Application_Course_Preference__r.Course_Code__c, Application_Course_Preference__r.Location_Code__c, Application_Course_Preference__r.Attendance_Type__c, Application_Course_Preference__r.Attendance_Mode__c, '
                                    + 'Application_Course_Preference__r.Admission_Category__c, Application_Course_Preference__r.Unit_Set_Code__c, Application_Course_Preference__r.Course_Offering__r.Citizenship_Type__c, Application_Course_Preference__r.Admission_Calendar_Type__c, '
                                    + 'Application_Course_Preference__r.Academic_CI_Sequence_Number__c, Application_Course_Preference__r.Admission_CI_Sequence_Number__c, Application_Course_Preference__r.Course_Version_Number__c, Application_Course_Preference__r.Unit_Set_Version__c, '
                                    + 'Application_Course_Preference__r.ACP_ID__c, Application_Course_Preference__r.Course_Title__c, Application_Course_Preference__r.Commencement_Period__c, Application_Course_Preference__r.Course_Offering__r.Campus__c, Application_Course_Preference__r.Name, '
                                    + 'Application_Course_Preference__r.Course_Start_Date_Updated__c, Application_Course_Preference__r.Course_End_Date_Updated__c, Application_Course_Preference__r.Approved_Credit_Points__c, Application_Course_Preference__r.Application__r.Submission_Location_Country__c, '
                                    + 'Application_Course_Preference__r.Application__r.Submission_Location_Country__r.Name, Application_Course_Preference__r.Application__r.Agent__c, Application_Course_Preference__r.Outcome_Status_LOV__r.System_Code__c, Application_Course_Preference__r.Offer_Response_Date__c, '
                                    + 'Application_Course_Preference__r.Course_Product_Id__c, Application_Course_Preference__r.ACP_Url__c, Product2.Family, '+
                                    + 'Application_Course_Preference__r.Credit_Adjusted_Course_Duration_Type__c, '+
									+ 'Application_Course_Preference__r.Course_Offering__r.Admission_CI_Sequence_Number__c, '+
                                    + 'Application_Course_Preference__r.Course_Offering__r.Start_Date__c, '+
                                    + 'Application_Course_Preference__r.Course_Offering__r.End_Date__c, '+
                                    + 'Application_Course_Preference__r.Course_Offering__r.Commencement_Period__c, '+
                                    + 'Application_Course_Preference__r.Course_Offering__r.Academic_Year__c, '+
                                    + 'Application_Course_Preference__r.Course_Offering__r.Admission_Calendar_Type__c, '+
                                    + 'Application_Course_Preference__r.Course_Offering__r.Course_Duration__c,  '+ 
                                    + 'Application_Course_Preference__r.Course_Offering__r.Override_Duration__c, '+
                                    + 'Application_Course_Preference__r.Course_Offering__r.Admission_Category__c,' + 
                                    + 'Application_Course_Preference__r.Course_Offering__r.Attendance_Mode__c,' + 
                                    + 'Application_Course_Preference__r.Course_Offering__r.Attendance_Type__c, ' + 
                                    + 'Application_Course_Preference__r.Course_Offering__r.Location_Code__c, ' + 
                                    + 'Application_Course_Preference__r.Course_Offering__r.Override_Duration_Unit__c, ' +
                                    + 'Application_Course_Preference__r.Outcome_Status_LOV__r.Value__c, ' +
                                    + 'Application_Course_Preference__r.Conditional_Offer_Status_LOV__r.Value__c, ' +
                                    + 'Application_Course_Preference__r.Application__r.Agent__r.Name ' +
                                    + 'FROM OpportunityLineItems WHERE (Expiry_Date__c > TODAY OR Expiry_Date__c = null) ORDER BY Application_Course_Preference__r.Course_Start_Date_Updated__c ASC,  Application_Course_Preference__r.Course_End_Date_Updated__c ASC NULLS LAST)',
                                    getSObjectName(),
                                    'CloseDate DESC',
                                    '3'    
                                }
                            );
        
        return (List<Opportunity>) Database.query(queryString);
    }
    
    /**
     * @author      David Browaeys
     * @description Query opportunity by ids with opportunity line items
     * @revision    14/10/2019 - David Browaeys - Created
     * 07/05/2021   Vinothraja - Added Type_of_Study__c to the SELECT fields list of OpportunityLineItems
     */
    public List<Opportunity> selectByIdForOfferUpdate(Set<Id> idSet) {
        return (List<Opportunity>) Database.query(String.format(
            'SELECT {0}, {1}, {2}, {3} FROM {4} WHERE id in :idSet', 
            new List<String>{
                    getFieldListString(),
                    'Agent_Account__r.Email__c',
                    '(SELECT Id, ACP__c, ACP__r.Course_Code__c, Clause__c, Mirror_Clause__c, Clause__r.APXT_Redlining__Latest_Revision__c, Clause__r.APXT_Redlining__Text__c, Clause__r.Object_Level__c, Clause__r.Clause_Review_Required__c FROM Associated_Clauses__r)',
                    '(SELECT Id, Application_Course_Preference__r.Application__r.Type_of_study__c, Application_Course_Preference__r.Credit_Adjusted_Course_Duration_Type__c, Application_Course_Preference__r.Course_Offering__r.Course_Duration__c,  Application_Course_Preference__r.Course_Offering__r.Override_Duration__c, Application_Course_Preference__r.Deferred_Course_Offering__c, Application_Course_Preference__r.Deferment_Status_LoV__r.Unique_Key__c, Additional_Clause_Notes__c, Additional_Bahasa_Clause_Notes__c,Application_Course_Preference__c, Override_Duration_With_RPL__c, Override_Start_Date__c, Override_End_Date__c, Override_Duration__c, PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id, OpportunityId, PricebookEntryId, PricebookEntry.Product2.Product_Bundle__c, PricebookEntry.Product2.Expiry_days__c, Expiry_Date__c, PricebookEntry.Product2.Family FROM OpportunityLineItems)',
                    getSObjectName()
            }
        ));
    }
    
    /**
     * @author      David Browaeys
     * @description Query opportunity by ids with opportunity line items
     * @revision    14/10/2019 - David Browaeys - Created
     */
    public List<Opportunity> selectByIdWithOpportunityLines(Set<Id> idSet) {
        return (List<Opportunity>) Database.query(String.format(
            'SELECT {0}, {1}, {2}, {3} FROM {4} WHERE id in :idSet', 
            new List<String>{
                    getFieldListString(),
                    'Agent_Account__r.Email__c',
                    '(SELECT Id, ACP__c, Clause__c, Mirror_Clause__c, Clause__r.APXT_Redlining__Latest_Revision__c, Clause__r.APXT_Redlining__Text__c, Clause__r.Object_Level__c, Clause__r.Clause_Review_Required__c FROM Associated_Clauses__r)',
                    '(SELECT Id, Application_Course_Preference__r.Credit_Adjusted_Course_Duration_Type__c, Application_Course_Preference__r.Course_Offering__r.Course_Duration__c,  Application_Course_Preference__r.Course_Offering__r.Override_Duration__c, Application_Course_Preference__r.Deferred_Course_Offering__c, Application_Course_Preference__r.Deferment_Status_LoV__r.Unique_Key__c, Additional_Clause_Notes__c, Additional_Bahasa_Clause_Notes__c,Application_Course_Preference__c, Override_Duration_With_RPL__c, Override_Start_Date__c, Override_End_Date__c, Override_Duration__c, PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id, OpportunityId, PricebookEntryId, PricebookEntry.Product2.Product_Bundle__c, PricebookEntry.Product2.Expiry_days__c, Expiry_Date__c FROM OpportunityLineItems WHERE (Expiry_Date__c > TODAY OR Expiry_Date__c = null) ORDER BY Application_Course_Preference__r.Course_Start_Date_Updated__c ASC NULLS LAST)',
                    getSObjectName()
            }
        ));
    }


    /**
     * @author      Kristian Vegerano
     * @description Query opportunity by ids with offer acceptance checklist necessary details
     * @revision    20/06/2020 - Kristian Vegerano - Created
     */
    public List<Opportunity> selectByIdWithFullOfferAcceptanceDetails(Set<Id> idSet) {
        assertIsAccessible();

        String queryString = String.format('SELECT {0}, PrimaryContact__r.Under_18__c, PrimaryContact__r.BirthDate, (SELECT Id, Application_Course_Preference__r.Offer_Condition__c FROM OpportunityLineItems WHERE Application_Course_Preference__c != null) FROM {1} WHERE Id IN :idSet ORDER BY {2}', 
            new List<String>{
                getFieldListString(),
                getSObjectName(),
                getOrderBy()
        });

        return (List<Opportunity>) Database.query(queryString);
    }

    /**
     * @author      Vishal Gupta
     * @description Query opportunity by ACP and get the related quote
     * @revision    13/01/2025 - Vishal Gupta - Created
     */
    public List<Opportunity> selectScholarshipOpportunityByACPId(Set<Id> idSet) {
        assertIsAccessible();
        String queryString = String.format('SELECT {0}, (SELECT Id, SBQQ__Status__c, SBQQ__ExpirationDate__c FROM SBQQ__Quotes2__r) FROM {1} WHERE Research_Offer_Type__c = \'Scholarship Offer\' AND Application_Course_Preference__c != null AND Application_Course_Preference__c IN :idSet ORDER BY {2}', 
            new List<String>{
                getFieldListString(),
                getSObjectName(),
                getOrderBy()
        });

        return (List<Opportunity>) Database.query(queryString);
    }
}