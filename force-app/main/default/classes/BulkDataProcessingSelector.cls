/**
 * @author      Jasmin Joy Rudio
 * @description Selector class for bulk data processing object processes
 * @group       Selectors
 * @revision    03/07/2020 - Jasmin Joy Rudio - Created
 */
public with sharing class BulkDataProcessingSelector extends BaseSelector{
    /**
     * Constructors
     */
	public BulkDataProcessingSelector() {
	    super(false);
	}
	
    public BulkDataProcessingSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      Jasmin Joy Rudio
     * @date        03/07/2020
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return Bulk_Data_Processing__c.sObjectType;
	}
    
	/**
     * @author      Jasmin Joy Rudio
     * @date        03/07/2020
     * @description Query bulk data processing by ids
     */
    public List<Bulk_Data_Processing__c> selectById(Set<Id> idSet) {
		return (List<Bulk_Data_Processing__c>) selectSObjectsById(idSet);
    }
	/**
     * @author      Jasmin Joy Rudio
     * @date        03/07/2020
     * @description Query bulk data processing by ids
     */
    public List<Bulk_Data_Processing__c> selectByIdOrderByCourseCode(Set<Id> idSet) {
		String queryString = String.format(
            'SELECT {0}, {1} FROM {2} WHERE Id IN: idSet ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),
                    '(SELECT Id, Name, Offer_Request__c, Clause__c, Mirror_Clause__c FROM Associated_Clauses__r)',                
                    getSObjectName(),    
                    'Transfer_Course_Code__c ASC'
            }
        );
        return (List<Bulk_Data_Processing__c>) Database.query(queryString);
    }
    /**
     * @author      David Browaeys
     * @date        03/07/2020
     * @description Query bulk data processing by ids with ACP Details
     */
    public List<Bulk_Data_Processing__c> selectByIdWithACPDetails(Set<ID> idSet){
        return [SELECT  Id, Person_ID__c, Status__c, Transfer_From__c, Current_Course_Campus__c, Transfer_Course_Campus__c, Transfer_To_Application__c, 
                        Transfer_From__r.Application__r.Citizenship_Country__c, Transfer_To__c, Offer_Lapsed_Date__c, Applicant__c, Transfer_Course_Code__c, 
                        Credit_Duration_Value__c, Credit_Duration_Unit__c, Credit_Points__c, Preference__c, Transfer_Citizenship_Country__c, Type__c, Student_Notes__c, Is_OnShore__c,
                        Offer_Condition__c 
                FROM    Bulk_Data_Processing__c WHERE Id IN: idSet];
    }
    /**
     * @author      David Browaeys
     * @date        03/07/2020
     * @description Query bulk data processing ready for offer
     */
    public Database.QueryLocator selectGenerateOffers(){
        String query =  'SELECT Id, OwnerId, Applicant__r.FirstName, Applicant__r.LastName, Applicant__r.First_Name__c, Applicant__r.Last_Name__c, Applicant__r.AccountId, Person_ID__c, Status__c, Transfer_From__c, Current_Course_Campus__c, Transfer_Course_Campus__c, Transfer_To_Application__c, Manual_ISCA_Edit__c,'+ 
                            'Transfer_From__r.Application__r.Citizenship_Country__c, Transfer_To__c, Offer_Lapsed_Date__c, Applicant__c, Transfer_Course_Code__c, Transfer_To_Application__r.Submission_Location_Country__r.Name, Onshore_MU_Transfer__c, Signature_Type__c, '+
                            'Credit_Duration_Value__c, Credit_Duration_Unit__c, Credit_Points__c, Preference__c, Transfer_Citizenship_Country__c, Type__c, Student_Notes__c, Offer_Template__c, Template_Type__c, '+
                            '(select Id, Opportunity__c from Associated_Clauses__r)'+
                        ' FROM Bulk_Data_Processing__c'+
                        ' WHERE Status__c = \'Generate Offer\'';
        return Database.getQueryLocator(query);
    }
}