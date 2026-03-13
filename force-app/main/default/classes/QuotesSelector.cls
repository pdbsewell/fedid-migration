/**
 * @author      Jasmin Joy Rudio
 * @description Selector class for CPQ Quote object processes
 * @group       Selectors
 * @revision    11/12/2019 - Jasmin - Created
 */
public inherited sharing class QuotesSelector extends BaseSelector {
    /**
     * Constructors
     */
    public QuotesSelector() {
        super(false);
    }
    
    public QuotesSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
    
    /**
     * @author      Jasmin Joy Rudio
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return SBQQ__Quote__c.sObjectType;
    }
    /**
     * @author      Jasmin Joy Rudio
     * @description Query Quote by ids
     * @return      List of Quote records
     */
    public List<SBQQ__Quote__c> selectById(Set<Id> idSet) {
        return (List<SBQQ__Quote__c>) selectSObjectsById(idSet);
    }
    
    /**
     * @author      Mathew Jose
     * @description Return quote map
     * @revision    11/11/2019 - Mathew Jose - Created
     */
    public Map<Id, SBQQ__Quote__c> selectByIdMap(Set<String> quoteIdSet) {  
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>(selectQuoteById(quoteIdSet));
        return quoteMap;
    }    

    /**
     * @author      Jasmin Joy Rudio
     * @description Query Quote by id with related lookup fields 
     * @return      List of Quote records
     */
    public List<SBQQ__Quote__c> selectQuoteById(Set<String> idSet) { 
        String queryString = String.format(
            'SELECT {0}, {1} FROM {2} WHERE Id in :idSet ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),
                    'SBQQ__Opportunity2__r.Id,'+                  
                    'SBQQ__Opportunity2__r.StageName,'+  
                    'SBQQ__PrimaryContact__r.FirstName,'+
                    'SBQQ__PrimaryContact__r.LastName,'+
                    'SBQQ__PrimaryContact__r.First_Name__c,'+
                    'SBQQ__PrimaryContact__r.Last_Name__c,'+
                    'SBQQ__PrimaryContact__r.Is_Mononymous_Name__c,'+
                    'SBQQ__PrimaryContact__r.Name,'+
                    'Application_Course_Preference__r.Callista_Application_Id__c,'+
                    'Application_Course_Preference__r.Course_Code__c,'+
                    'SBQQ__PrimaryContact__r.Under_18__c',                    
                    getSObjectName(),
                    getOrderBy()
            }
        );
        return (List<SBQQ__Quote__c>) Database.query(queryString);
    }

    /**
     * @author      Jasmin Joy Rudio
     * @description Query Quote by primary contact id or Owner Id
     * @return      List of Quote records
     */
    public List<SBQQ__Quote__c> selectQuoteByContactOwner(String contactId, String ownerId) { 
        String queryString = String.format(
            'SELECT {0}, {1} FROM {2} WHERE SBQQ__PrimaryContact__c =:contactId OR OwnerId =: ownerId OR CreatedById =: ownerId ORDER BY {3}',
            new List<String>{
                    getFieldListString(),
                    'Application_Course_Preference__r.Callista_Application_Id__c,SBQQ__PrimaryContact__r.Under_18__c,'+
                    'Application_Course_Preference__r.Course_Code__c,' + 
                    'SBQQ__Opportunity2__r.Name, SBQQ__PriceBook__r.Name, ' +
                    '(SELECT Id, Name, Location__c, SBQQ__ProductFamily__c, SBQQ__ProductName__c, SBQQ__Product__c, '+
                    'Total_Grant_Scholarship_Value__c, Expiry_Date__c FROM SBQQ__LineItems__r ORDER BY Course_Start_Date__c desc)',
                    getSObjectName(),
                    'CreatedDate desc'
                    //getOrderBy()
            }
        );
        return (List<SBQQ__Quote__c>) Database.query(queryString);
    }

    /**
     * @author      Jasmin Joy Rudio
     * @description Query Quote by primary contact id or Owner Id for pagination
     * @return      List of Quote records
     */
    public List<SBQQ__Quote__c> selectQuoteByWithPagination(String contactId, String ownerId, Integer limitNum, Integer offset) { 
        String offsetString = (offset > 0 ? ' OFFSET ' + offset : '');
        String queryString = String.format(
            'SELECT {0}, {1} FROM {2} WHERE (Contact_Access__c =:contactId OR OwnerId =: ownerId OR CreatedById =: ownerId) AND Manual_ISCA_Edit_Required__c = false ORDER BY {3}'+
            ' LIMIT ' + limitNum + offsetString, 
            new List<String>{
                    getFieldListString(),
                    'Application_Course_Preference__r.Callista_Application_Id__c,SBQQ__PrimaryContact__r.Under_18__c,'+
                    'Application_Course_Preference__r.Course_Code__c,' + 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Location_Description__c,' + 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Location_Code__c,' + 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Course_Title__c,' + 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Proposed_Commencement_Date__c,' + 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Attendance_Mode_Description__c,' + 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Attendance_Type_Description__c,' + 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Attendance_Type__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Attendance_Mode__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Course__r.Managing_Faculty__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.AOU_Name__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Scholarship_Round_Closing__c,'+
                    'SBQQ__Opportunity2__r.Name, SBQQ__PriceBook__r.Name, ' +
                    '(SELECT Id, Name, Location__c, SBQQ__ProductFamily__c, SBQQ__ProductName__c, SBQQ__Product__c, '+
                    'Total_Grant_Scholarship_Value__c, Expiry_Date__c FROM SBQQ__LineItems__r ORDER BY Course_Start_Date__c DESC NULLS LAST)',
                    getSObjectName(),
                    'CreatedDate desc'
                    //getOrderBy()
            }
        );
        return (List<SBQQ__Quote__c>) Database.query(queryString);
    }

   /**
    * @author Richard Cook
    * @description retrieve OSHC related information for quote selection on community portal
    * @param quoteId Id - record which is requested
    * @param lock Boolean - request to lock record
    * @return QuoteOSHCView
    */     
    public SBQQ__Quote__c getHealthOptions(Id quoteId, Boolean lock)           
    {
        string type  = lock ? 'UPDATE' : 'VIEW';
        string soqlStatement = 'select Id, SBQQ__Status__c, Sub_Status__c, Health_Cover_Provider_Type__c, Health_Cover_Provider_Name__c, Acknowledged_by_applicant__c, (select Id, SBQQ__ProductName__c, Health_Cover_Duration__c, Health_Cover_Type__c, SBQQ__NetTotal__c, SBQQ__ProductFamily__c,SBQQ__RequiredBy__c,SBQQ__Product__r.Sub_Family__c,SBQQ__Product__r.Description from SBQQ__LineItems__r WHERE SBQQ__ProductFamily__c = \'OSHC\') from SBQQ__Quote__c  WHERE Id = :quoteId LIMIT 1 FOR ' + type;
        return (SBQQ__Quote__c)Database.Query(soqlStatement);
    }    

    /**
     * @description Retrieves a list of quotes where there is a matching 
     * primary DocuSign envelop Id
     * @param envelopId The DocuSign envelop Id for querying
     * @return Returns a list of quotes matching the envelop Id
     */
    public List<SBQQ__Quote__c> selectQuotesByPrimaryDocuSignEnvelopId(String envelopId) {
        String queryString = String.format(
            'SELECT {0} FROM {1} WHERE Primary_DocuSign_Envelop_Id__c = :envelopId ORDER BY {2}', 
            new List<String>{
                    getFieldListString(),                  
                    getSObjectName(),
                    getOrderBy()
            }
        );
        return (List<SBQQ__Quote__c>) Database.query(queryString);
    }

    /**
     * @description Retrieves a list of quotes where there is a matching 
     * primary DocuSign envelop Id
     * @param envelopIds A Set of DocuSign envelop Id for querying
     * @return Returns a list of quotes matching the envelop Id
     */
    public List<SBQQ__Quote__c> selectQuotesByPrimaryDocuSignEnvelopId(Set<String> envelopIds) {
        String queryString = String.format(
            'SELECT {0} FROM {1} WHERE Primary_DocuSign_Envelop_Id__c IN :envelopIds ORDER BY {2}', 
            new List<String>{
                    getFieldListString(),                  
                    getSObjectName(),
                    getOrderBy()
            }
        );
        return (List<SBQQ__Quote__c>) Database.query(queryString);
    }
    
    /**
     * @description Returns a map of envelop Ids with match quotes
     * @param envelopIds A Set of DocuSign envelop Id for querying
     * @return Returns a map of quotes matching the envelop Id
     * E.g. <envelop id (string), quote>
     */
    public Map<String, SBQQ__Quote__c> selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId(
            Set<String> envelopIds) {
        
        Map<String, SBQQ__Quote__c> quotesByEnvelopId = 
            new Map<String, SBQQ__Quote__c>();

        List<SBQQ__Quote__c> associatedQuotes = 
            this.selectQuotesByPrimaryDocuSignEnvelopId(envelopIds);

        for (SBQQ__Quote__c quote : associatedQuotes) {
            quotesByEnvelopId.put(quote.Primary_DocuSign_Envelop_Id__c, quote);
        }

        return quotesByEnvelopId;
    }

    /**
     * @author      Jasmin Joy Rudio
     * @description Query Quote by id with related lookup fields 
     * @return      List of Quote records
     */
    public List<SBQQ__Quote__c> selectQuoteAndLineItemsById(Set<String> idSet) { 
        String queryString = String.format(
            'SELECT {0}, {1}, {2} FROM {3} WHERE Id in :idSet ORDER BY {4}', 
            new List<String>{
                    getFieldListString(),
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Calendar_Code__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Graduate_Research_Application_Type__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Scholarship_Calendar__r.Published_Date_for_Domes_ScholarRound__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Scholarship_Calendar__r.Published_Date_for_Inter_ScholarRound__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Course__r.Sub_Level__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Academic_Org_Unit_Name__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Course_Title__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Course_Code__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Attendance_Type__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Attendance_Mode__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Attendance_Mode_Description__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Attendance_Type_Description__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Managing_Faculty__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Status__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.GradRes_Callista_Id__c,'+
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Callista_Applicant_Id__c,'+
                    'SBQQ__Opportunity2__r.Offer_published_date__c,'+
                    'Contact_Access__r.Person_ID__c,'+
                    'Contact_Access__r.First_Name__c,'+
                    'Contact_Access__r.Full_Name__c,'+
                    'Contact_Access__r.MailingCity,'+
                    'Contact_Access__r.MailingCountry,'+
                    'Contact_Access__r.MailingPostalCode,'+
                    'Contact_Access__r.MailingState,'+
                    'Contact_Access__r.MailingStreet,'+
                    'SBQQ__Opportunity2__r.Offer_Type__c,'+  
                    'SBQQ__Opportunity2__r.Faculty_Scholarship_Awarded__c,'+  
                    'SBQQ__Opportunity2__r.Faculty_Sponsorship_Awarded__c,'+  
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Applicant__r.Person_ID_unique__c,'+ 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__c,'+ 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__r.Parent_Application__c,'+ 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__r.Proceed_without_scholarship__c,'+ 
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Outcome_Status_LOV__r.System_Code__c,'+    
                    'SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__r.Citizenship_Classification__c',
                    '(SELECT Id, Additional_Clause_Notes__c, Scholarship_Name__c, Scholarship_Type__c, Scholarship_Value__c, Scholarship_Previous_Value__c, Scholarship_Value_Year__c, Scholarship_Previous_Value_Year__c, Scholarship_Value_Range__c, Scholarship_Previous_Value_Range__c FROM SBQQ__LineItems__r WHERE Scholarship_Deactivated__c = false)',                                
                    getSObjectName(),
                    getOrderBy()
            }
        );
        return (List<SBQQ__Quote__c>) Database.query(queryString);
    }
}