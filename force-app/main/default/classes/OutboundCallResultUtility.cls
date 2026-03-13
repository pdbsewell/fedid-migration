/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		Service Class for Outbound Call Result trigger
 * @date            Aug.2024
 * @group			Monash Connect
 * Revision
 * 1.1   11.08.2024   Idhanoa     Enhancement to close Enquiry (MCT-456)
*/
public class OutboundCallResultUtility {

    public static final Id DOMESTIC_PRE_APP = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('Domestic_Pre_App').getRecordTypeId();
    public static final Id INTL_PRE_APP = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('International_Pre_App').getRecordTypeId();

    public static void processLead(Set<Id> leadIdSet){
        Set<id> preAppRecTypeIdSet = new Set<Id>{DOMESTIC_PRE_APP,INTL_PRE_APP}; 
        
        List<Outbound_Call_Result__c> relatedOCRs = [SELECT Id, Lead__c, RecordTypeId,Call_Status__c
                                                     FROM Outbound_Call_Result__c 
                                                     WHERE Lead__c in :LeadIdSet AND 
                                                        RecordTypeId IN : preAppRecTypeIdSet
                                                     WITH SECURITY_ENFORCED
                                                     ORDER BY CreatedDate desc];

        Map<Id, List<Outbound_Call_Result__c>> leadToOCRsMap = new Map<Id, List<Outbound_Call_Result__c>>();
        for(Outbound_Call_Result__c ocr : relatedOCRs){
            if(!leadToOCRsMap.containsKey(ocr.Lead__c)){
                leadToOCRsMap.put(ocr.Lead__c, new List<Outbound_Call_Result__c>());
            } 
            leadToOCRsMap.get(ocr.Lead__c).add(ocr);
        }

        List<Lead> leadsToUpdate = new List<Lead>();

        try{
            for(Id leadId : LeadIdSet){
                if(leadToOCRsMap.containsKey(leadId)){
                    List<Outbound_Call_Result__c> outboundCalls = leadToOCRsMap.get(leadId);
                    Boolean hasOpenOCR = false;

                    for (Outbound_Call_Result__c call : outboundCalls) {
                        if (call.Call_Status__c != 'Closed') {
                            hasOpenOCR = true;
                            break;
                        }
                    }

                    leadsToUpdate.add(new Lead(
                        Id = leadId,
                        Outbound_Call_Status__c = hasOpenOCR ? 'In Progress' : 'Closed'
                    ));
                }
            }

            if (!leadsToUpdate.isEmpty() && Schema.sObjectType.Lead.isUpdateable()) {
                update leadsToUpdate;
            }
        }catch(Exception ex){
            Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog();
        }
    }
    
    /**
     * @description asynchronous method that closes an Enquiry linked to MC OCR record
     * @param enqIdSet - set of EnqIds
     */
    @future
    public static void closeMCEnquiry(Set<Id> enqIdSet){
        List<Case> closeEnquiries = [SELECT Id,Status,Case_Outcome__c FROM Case WHERE Id IN :enqIdSet];
        if(!closeEnquiries.isEmpty()){
            for(Case closeEnq : closeEnquiries){
                closeEnq.Status = 'Solved';
            }
            try{
                update closeEnquiries;
            }catch(Exception ex){
                Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog();
            }
        }
    }
}