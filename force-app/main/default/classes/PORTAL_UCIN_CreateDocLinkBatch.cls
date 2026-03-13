/**
 * @author Sulung Chandra, UC Innovation
 * @date 2019-12-19
 * @group PORTAL_UCIN
 * @group-content 
 * @description Batch class to create donation document link.
 * @revision
 * Date         Author              Modification 
 * 18/07/2022   Chaldrin Cruz       Replaced rt with rtv2
 * 2022-07-14   Inderpal Dhanoa   Replaced refereces to review transaction with review transaction v2
 * 2019-12-19   Sulung Chandra   Initial version.
 */
global class PORTAL_UCIN_CreateDocLinkBatch implements Database.Batchable<sObject> {
    String query;
    
    /*******************************************************************************************************
     * @description Constructor to query PORTAL_UCIN_Donation_Raw_Document_Link__c
     * @param N/A.
     * @return N/A.
     */
    global PORTAL_UCIN_CreateDocLinkBatch() {
        query = 'Select Id, Review_Transaction_v2__c, ContentDocumentId__c From PORTAL_UCIN_Donation_Raw_Document_Link__c';
    }
    
    /*******************************************************************************************************
     * @description Passes query results in batches to execute.
     * @param BC Parameter type of a batch job. This interfaced is implemented internally by Apex.
     * @return Query Locator representing place in query.
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    /*******************************************************************************************************
     * @description Create ContentDocumentLink records and delete the PORTAL_UCIN_Donation_Raw_Document_Link__c records.
     * @param scope List of PORTAL_UCIN_Donation_Raw_Document_Link__c records returned by query.
     * @return N/A.
     */
    global void execute(Database.BatchableContext BC, List<PORTAL_UCIN_Donation_Raw_Document_Link__c> scope) {
        List<ContentDocumentLink> insertCdlList = new List<ContentDocumentLink>();
        List<PORTAL_UCIN_Donation_Raw_Document_Link__c> deleteDrdlList = new List<PORTAL_UCIN_Donation_Raw_Document_Link__c>();
        
        for (PORTAL_UCIN_Donation_Raw_Document_Link__c drdl : scope) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = drdl.ContentDocumentId__c;
            cdl.LinkedEntityId = drdl.Review_Transaction_v2__c;
            cdl.ShareType = 'V';
            insertCdlList.add(cdl);
            
            deleteDrdlList.add(drdl);
        }
        
        if (!insertCdlList.isEmpty()) {
            insert insertCdlList;
        }
        
        if (!deleteDrdlList.isEmpty()) {
            delete deleteDrdlList;
        }
    }
	
    /*******************************************************************************************************
     * @description Get apex job Id for debugging.
     * @param BC Parameter type of a batch job. This interfaced is implemented internally by Apex.
     * @return N/A.
     */
    global void finish(Database.BatchableContext BC) {
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems,CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()]; 
		System.debug('### AsyncApexJob ID: ' + a.Id); 
    }
}