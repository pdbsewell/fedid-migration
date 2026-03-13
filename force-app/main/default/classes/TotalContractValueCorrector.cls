/**
* @author Shalini Mendu
* @date 12/05/2022
* @group Batch Class
* @description  Batch Class to correct Total contract value
*/
public with sharing class TotalContractValueCorrector implements Database.Batchable<sObject> {
    private String bqueryType;
    private String bupdateType;
    private List<String> bfailedQuotes;
    private String query;
    private List<String> stageList = new List<String>{Constants.QUOTE_STATUS_IN_REVIEW, 
                                                      Constants.QUOTE_STATUS_PUBLISHED, 
                                                      Constants.QUOTE_STATUS_SIGNED, 
                                                      Constants.QUOTE_STATUS_EXPIRED, 
                                                      Constants.QUOTE_STATUS_EXPIRED_REGEN, 
                                                      Constants.QUOTE_STATUS_DEFERRED, 
                                                      Constants.QUOTE_STATUS_CANCELLED};

    /**
     * Constructor to initialise params
     * @param  queryType - SBQQ__Type__c for query
     * @param  updateType - SBQQ__Type__c for update
     * @param  failedQuotes - List of Failed Ids
     */
    public TotalContractValueCorrector(String queryType, String updateType, List<String> failedQuotes) {
        bqueryType = queryType;
        bupdateType = updateType;
        bfailedQuotes = failedQuotes; 
    }

    /**
     * Method to initialise query locator
     * @param  bc as BatchableContext
     * @return    QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
       
        query = 'SELECT SBQQ__Type__c FROM SBQQ__Quote__c where SBQQ__Opportunity2__r.RecordType.Name=\'Applicant Enrolment\'  AND SBQQ__Type__c=:bqueryType and  SBQQ__Status__c IN :stageList ';
       
        if(bfailedQuotes!=null && !bfailedQuotes.isEmpty())
        {
            query += ' and name in :bfailedQuotes';
        }
        return Database.getQueryLocator(query);
    }

    /**
	 * Method to update the SBQQ__Type__c to retrigger calculation logic
	 * @param  scope as List<sObject>
	 */
    public void execute(Database.BatchableContext BC,List<SBQQ__Quote__c> scope) {
    
         for(SBQQ__Quote__c quote : scope)
         {
            quote.SBQQ__Type__c = bupdateType;
         }
        
        try{
                 //update the SBQQ__Type__c
                 Database.SaveResult [] srList = Database.update(scope, false);
                for (Database.SaveResult sr : srList) {
                   if (!sr.isSuccess()) {
                        LogUtilityException.debug('Total Contract Value correction failure for : ' + sr.getId());
                   }
                }
            } catch(Exception ex) {
                LogUtilityException.logException(ex);
            }
    }
    
    /**
	 * Method to finish processing
	 * @param  bc as BatchableContext
	 */
    public void finish(Database.BatchableContext bc) {
    }
}