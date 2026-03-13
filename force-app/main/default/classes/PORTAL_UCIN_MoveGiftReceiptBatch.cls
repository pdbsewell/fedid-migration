/**
 * @author Charlie Park, UC Innovation
 * @date 2019-12-29
 * @group PORTAL_UCIN
 * @group-content 
 * @description Batch class to create donation document link for gift receipts from review transaction to converted opportunity.
 * @revision
 * Date         Author              Modification
 * 18/07/2022   Chaldrin Cruz       Replaced rt with rtv2
*/
global class PORTAL_UCIN_MoveGiftReceiptBatch implements Database.Batchable<sObject> {
    String query;
    
    /*******************************************************************************************************
     * @description Constructor to query PORTAL_UCIN_Donation_Raw_Document_Link__c
     * @param N/A.
     * @return N/A.
     */
    global PORTAL_UCIN_MoveGiftReceiptBatch() {
        if (string.isEmpty(query)) {
            query = 'Select Id, Moved_Gift_Receipt__c, (SELECT ID FROM ucinn_ascendv2__Opportunities_Review_Transaction_v2__r) '
                    + 'From ucinn_ascendv2__Review_Transaction_v2__c WHERE Moved_Gift_Receipt__c = false AND '
                    + 'ucinn_ascendv2__Status__c = \'Posted\' AND RecordType.DeveloperName = \'Online_Donation_Transaction\'';
        }
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
    global void execute(Database.BatchableContext BC, List<ucinn_ascendv2__Review_Transaction_v2__c> scope) {
        Set<ID> rtIDSet = new Set<ID>();
        for (ucinn_ascendv2__Review_Transaction_v2__c eachRT: scope) {
            rtIDSet.add(eachRT.Id);
        }

        List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN: rtIDSet];
        Map<Id, Id> RTIdtoFileIdMap = new Map<Id, Id>();
        List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
        List<ucinn_ascendv2__Review_Transaction_v2__c> rtToUpdate = new List<ucinn_ascendv2__Review_Transaction_v2__c>();

        for (ContentDocumentLink eachCDL: cdlList) {
            RTIdtoFileIdMap.put(eachCDL.LinkedEntityId, eachCDL.ContentDocumentId);
        }

        for (ucinn_ascendv2__Review_Transaction_v2__c eachRT: scope) {
            if (RTIdtoFileIdMap.containsKey(eachRT.Id) && !eachRT.ucinn_ascendv2__Opportunities_Review_Transaction_v2__r.isEmpty()) {
                for (Opportunity eachOpp: eachRT.ucinn_ascendv2__Opportunities_Review_Transaction_v2__r) {
                    ContentDocumentLink newCDL = new ContentDocumentLink();
                    newCDL.LinkedEntityId = eachOpp.Id;
                    newCDL.ContentDocumentId = RTIdtoFileIdMap.get(eachRT.Id);
                    newCDL.ShareType = 'V';
                    cdlToInsert.add(newCDL);
                }

                eachRT.Moved_Gift_Receipt__c = true;
                rtToUpdate.add(eachRT);
            }
        }

        insert cdlToInsert;

        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Review_Transaction_v2__c', false);
        update rtToUpdate;
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Review_Transaction_v2__c', true);
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