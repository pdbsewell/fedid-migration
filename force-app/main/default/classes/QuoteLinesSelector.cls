/**
 * @author      Mathew Jose
 * @description Selector class for CPQ Quote line object processes
 * @group       Selectors
 * @revision    11/11/2019 - Mathew Jose - Created
 */
public inherited sharing class QuoteLinesSelector extends BaseSelector {
    /**
     * Constructors
     */
    public QuoteLinesSelector() {
        super(false);
    }
    
    /**
     * @author      Mathew Jose
     * @description Returns the object type
     * @revision    11/11/2019 - Mathew Jose - Created
     */
    public Schema.SObjectType getSObjectType() {
        return SBQQ__QuoteLine__c.sObjectType;
    }
    /**
     * @author      Mathew Jose
     * @description Query Quote by ids
     * @revision    11/11/2019 - Mathew Jose - Created
     */
    public List<SBQQ__QuoteLine__c> selectById(Set<Id> idSet) {
        return (List<SBQQ__QuoteLine__c>) selectSObjectsById(idSet);
    }

    /**
     * @author      Mathew Jose
     * @description Query Quote line items with quote records 
     * @revision    11/11/2019 - Mathew Jose - Created
     */
    public List<SBQQ__QuoteLine__c> selectByQuoteIdAndProductFamily(Set<Id> quoteIdSet, List<string> prodFamilyList) {  
        return (List<SBQQ__QuoteLine__c>) Database.query(String.format(
            'SELECT {0}, {1} FROM {2} WHERE SBQQ__Quote__c in :quoteIdSet and  SBQQ__ProductFamily__c in: prodFamilyList ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),
                    'Application_Course_Preference__r.Managing_Faculty__c,' + 
                    'SBQQ__Product__r.Expiry_days__c,'+
                    'SBQQ__Product__r.Family,'+
                    'SBQQ__Quote__r.SBQQ__ExpirationDate__c,'+ 
                    'SBQQ__Quote__r.Calculated_Expiry_Date__c',                                        
                    getSObjectName(),
                    getOrderBy()
            }
        ));
    }

    /**
     * @author      Mathew Jose
     * @description Query Quote by ids with Quote line items
     * @revision    11/11/2019 - Mathew Jose - Created
     */
    public List<SBQQ__QuoteLine__c> selectByIdWithQuoteLines(Set<Id> idSet) {
        return (List<SBQQ__QuoteLine__c>) Database.query(String.format(
            'SELECT {0}, {1} FROM {2} WHERE SBQQ__Quote__c in :idSet ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),
                    'SBQQ__Quote__r.SBQQ__PrimaryContact__r.Country_of_Citizenship__c,'+
                    'Application_Course_Preference__r.Course_Start_Date_Updated__c,' + 
                    'Application_Course_Preference__r.Recruitment_Reference_Code__c,' + 
                    'Application_Course_Preference__r.Unit_Set_Code__c,' + 
                    'Application_Course_Preference__r.Admission_Calendar_Type__c,' + 
                    'Application_Course_Preference__r.Course_Offering__r.Location__c,'+
                    'Application_Course_Preference__r.Location_Code__c,'+
                    'Application_Course_Preference__r.Calendar_Start_Date__c,'+
                    'Application_Course_Preference__r.Course_Code__c,'+
                    'Application_Course_Preference__r.Admission_Category__c,'+
                    'Application_Course_Preference__r.Managing_Faculty__c,'+
                    'Application_Course_Preference__r.Course_Level__c,'+
                    'Application_Course_Preference__r.Credit_Assessment_Flag__c,'+
                    'SBQQ__Quote__r.SBQQ__PrimaryContact__r.Country_of_Residence__c,'+
                    'Application_Course_Preference__r.Credit_Assessment_Decision__c,'+
                    'SBQQ__Quote__r.SBQQ__PrimaryContact__r.HasDisabilities__c,'+
                    'SBQQ__Quote__r.SBQQ__PrimaryContact__r.Under_18__c,'+
                    'Offer_Primary_Quote_Line__r.Course_Title__c,'+
                    'Offer_Primary_Quote_Line__r.Course_Code__c,'+
                    'SBQQ__Quote__r.Net_Deposit__c,'+
                    'SBQQ__Product__r.Name,'+
                    'SBQQ__Product__r.Description,'+
                    'SBQQ__Product__r.Quota_Accepted__c,'+
                    'SBQQ__Product__r.Quota_Assigned__c,' +
                    'SBQQ__Product__r.Clause__r.Name,'+
                    'SBQQ__Product__r.Quote_Document_Group__c,' +
                    'SBQQ__Product__r.Face_Value__c,' +
                    'SBQQ__Product__r.Type__c',
                    getSObjectName(),
                    getOrderBy()
            }
        ));
    }
    /**
     * @author      Jasmin Joy Rudio
     * @description This method returns a list of bundle quote lines for a quote
     * @param offerId parent quote record id
     * @return return List of Quote Line Bundles with primary quote line items
     */
    public List<SBQQ__QuoteLine__c> selectBundleByQuoteId(Set<String> idSet) {
        String bundle = 'Bundle';
        String query = String.format(
            'SELECT {0}, {1} FROM {2} WHERE SBQQ__Quote__c in :idSet AND SBQQ__ProductFamily__c =: bundle ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),
                    'Offer_Primary_Quote_Line__r.Course_Title__c,'+
                    'Offer_Primary_Quote_Line__r.Course_Start_Date__c,'+
                    'Offer_Primary_Quote_Line__r.Course_End_Date__c,'+
                    'Offer_Primary_Quote_Line__r.Course_Code__c,'+
                    'Offer_Primary_Quote_Line__r.Location__c,'+
                    'Offer_Primary_Quote_Line__r.Standard_Course_Point_Annual_Load__c,'+
                    'Offer_Primary_Quote_Line__r.Mode_of_Study__c,'+
                    'Offer_Primary_Quote_Line__r.Total_Tuition_Fee__c,'+
                    'Offer_Primary_Quote_Line__r.Annual_Tuition_Fee__c,'+
                    'Offer_Primary_Quote_Line__r.Credit_Points_Required_Updated__c,'+
                    'Offer_Primary_Quote_Line__r.SBQQ__ProductFamily__c,'+
                    'Offer_Primary_Quote_Line__r.Net_Total_Tuition_Fee__c,'+
                    'Offer_Primary_Quote_Line__r.Duration_FT__c,'+
                    'Offer_Primary_Quote_Line__r.Course_Fee_Year__c,'+
                    'Offer_Primary_Quote_Line__r.Credit_Points_Required__c,'+
                    'Offer_Primary_Quote_Line__r.SBQQ__ListTotal__c,'+
                    'Offer_Primary_Quote_Line__r.Course_Duration__c,'+
                    'Offer_Primary_Quote_Line__r.Course_Duration_Updated__c,'+
                    'Offer_Primary_Quote_Line__r.Additional_Clause_Notes__c,'+
                    'Offer_Primary_Quote_Line__r.Additional_Bahasa_Clause_Notes__c,'+
                    'Offer_Primary_Quote_Line__r.SBQQ__Product__r.Sub_Family__c,'+
                    'Offer_Option_Quote_Line__r.SBQQ__Product__r.Sub_Family__c,'+
                    'Offer_Option_Quote_Line__r.Course_Title__c,'+
                    'Offer_Option_Quote_Line__r.Course_Fee_Year__c,'+
                    'Offer_Option_Quote_Line__r.Annual_Tuition_Fee__c,'+
                    'Application_Course_Preference__r.Credit_Assessment_Decision__c,'+
                    'Application_Course_Preference__r.Credit_Assessment_Flag__c,'+
                    'Application_Course_Preference__r.Approved_Credit_Points__c,'+  
                    'Application_Course_Preference__r.Offer_Condition__c,'+     
                    'Application_Course_Preference__r.Bahasa_Offer_Condition__c,'+               
                    'Application_Course_Preference__r.Name,' +
                    'Application_Course_Preference__r.Unit_Set_Description__c,' + 
                    'SBQQ__Product__r.Face_Value__c,' +
                    'SBQQ__Product__r.Description',
                    getSObjectName(),
                    getOrderBy()
            }
        );
        return (List<SBQQ__QuoteLine__c>) Database.query(query);

    }

    /**
     * @author      Jasmin Joy Rudio
     * @description Query Quote line items exclude hidden quotelines for pricing  
     * @revision    02/10/2020 - Jasmin Joy Rudio - Created
     */
    public List<SBQQ__QuoteLine__c> selectByIdHiddenPricing(Set<Id> quoteIdSet) {  
        return (List<SBQQ__QuoteLine__c>) Database.query(String.format(
            'SELECT {0}, {1} FROM {2} WHERE SBQQ__Quote__c in :quoteIdSet and SBQQ__Hidden__c = false ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),
                    'SBQQ__Quote__r.SBQQ__NetAmount__c,' +
                    'SBQQ__Quote__r.Net_Deposit__c,' +
                    'Application_Course_Preference__r.Approved_Credit_Points__c,'+
                    'SBQQ__Product__r.Clause__r.APXT_Redlining__Text__c,' +
                    'SBQQ__Product__r.Description,' +
                    'SBQQ__Product__r.Quote_Document_Group__c,' +
                    'SBQQ__Product__r.Expiry_days__c,'+
                    'SBQQ__Product__r.Sub_Family__c,' +
                    'SBQQ__Product__r.Family',                    
                    getSObjectName(),
                    getOrderBy()
            }
        ));
    }

    /**
     * getBundlesForQuote This method returns a list of quote lines for a quote in bundle format
     * @param  quoteIds quoteIds List of Quote Ids
     * @return          return List of Quote Line Bundles with child quote line items
     */
    public List<SBQQ__QuoteLine__c> getBundlesForQuote(Set<Id> quoteIds)
    {
        if(quoteIds == null || quoteIds.size() == 0)
        {
            throw new IllegalArgumentException('No valid quoteIds provided to getBundlesForQuote');
        }
        
        return  [Select Id, SBQQ__RequiredBy__c, Offer_Primary_Quote_Line__c, Offer_Option_Quote_Line__c, SBQQ__Product__r.Document_Generation_Spec__c,
                                            Total_Tuition_Fee__c, Net_Total_Tuition_Fee__c,
                                            Admin_Fee__c, SBQQ__ProductFamily__c, SBQQ__ProductCode__c,
                                            SBQQ__PackageListTotal__c, SBQQ__SpecialPrice__c, SBQQ__Quote__c, 
                                            SBQQ__ListTotal__c, SBQQ__NetTotal__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__c, CreditPoints__c,
                 							SBQQ__Quote__r.SBQQ__Opportunity2__c
                                            FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c in :quoteIds
                                           	LIMIT 500];
    }    

    public String selectFirstCourseQuoteLineProductCodeByQuoteId(Id quoteId) {
        //BUNIAP not added here in the filter here(not sure of the reason) - all the OR could have been replaced with IN if BUNIAP was also used
        List<SBQQ__QuoteLine__c> quotelines = [SELECT SBQQ__ProductCode__c from SBQQ__QuoteLine__c 
            where SBQQ__Quote__c = :quoteId and (SBQQ__ProductCode__c = 'BUNENG' 
            OR SBQQ__ProductCode__c = 'BUNMEC' 
            OR SBQQ__ProductCode__c = 'BUNFOU' OR SBQQ__ProductCode__c = 'BUNCOL' 
            OR SBQQ__ProductCode__c = 'BUNDIP' OR SBQQ__ProductCode__c = 'BUNUNI') 
            order by SBQQ__Number__c Limit 1];

        if (quotelines.isEmpty()) {
            return '';
        } else {
            return quotelines[0].SBQQ__ProductCode__c;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description This method returns a list of quote lines for a quote
     * @param idSet
     * @return return List of Quote Line 
     */
    public List<SBQQ__QuoteLine__c> selectByQuoteId(Set<Id> idSet) {
        String query = String.format(
            'SELECT {0} FROM {1} WHERE SBQQ__Quote__c in :idSet ORDER BY {2}', 
            new List<String>{
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy()
            }
        );
         return (List<SBQQ__QuoteLine__c>) Database.query(query);
    }
}