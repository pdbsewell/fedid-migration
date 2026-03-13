/**
 * Bulk Data Processing visual force page List Button and lwc class controller
 * @author Jasmin Joy Rudio
 * @group Bulk Data Processing
 */
public with sharing class BulkAddManualClauseController {
    public String selectedRecordIds {get; set;}
    public Schema.SObjectType objectType {get; set;}
    Map<Id, Bulk_Data_Processing__c> bdpMap;
    ApexPages.StandardSetController ctrlVar;

    public BulkAddManualClauseController(ApexPages.StandardController controller){}
    
    public BulkAddManualClauseController(ApexPages.StandardSetController controller) {
        bdpMap = new Map<Id, Bulk_Data_Processing__c>((List<Bulk_Data_Processing__c>)controller.getSelected());
        objectType = controller.getRecord().getsObjectType();
        selectedRecordIds = JSON.serialize(bdpMap.keySet());
    }

    
    /**
     * Aura enabled method that get the list of Manual Clauses
     * @param  bdpIds selected BDP record Ids
     * @return JSON string of the available Manual Clauses
     */
    @AuraEnabled(cacheable=true)
    public static String getManualClauses(String bdpIds){
        return new BulkDataProcessingService.BDPManualClauseMatcher(bdpIds).execute();
    }

    /**
     * Aura enabled method that insert selected Manual Clauses under Bulk Data Processing
     * @param  BDPSelectedManualCLauses JSON string of selected BDP record with manual clauses wrapper
     * @return N/A
     */
    @AuraEnabled
    public static String saveBDPmanualClauses(String BDPSelectedManualCLauses){
        return BulkDataProcessingService.saveBDPmanualClauses(BDPSelectedManualCLauses);
    }
}