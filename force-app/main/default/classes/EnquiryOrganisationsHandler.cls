/**
 * @description       : Trigger Handler to manage all DML and events on EnquiryOrganisations
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
**/
public with sharing class EnquiryOrganisationsHandler {
    /**
     * @author      Inderpal Dhanoa
     * @description On the Enterprise Enquiry if Users are re-adding existing organisation, then the Validation should stop them  
     * @revision    18/05/2021 - Inderpal Dhanoa - Created
     */
    public class ValidateDuplicateOrganisations extends TriggerAbstract {

        /**
         * Before insert process for Validation
         */
        public override void process(SObject record) {
            records.add(record);      
        }

        /**
        * Handle before update event checking and filtering
        */
        public override void process(SObject record, SObject oldRec) {
            //Process selected Enquiry_Organisations__c
            Enquiry_Organisations__c oldEnqOrg = (Enquiry_Organisations__c)oldRec;
            Enquiry_Organisations__c newEnqOrg = (Enquiry_Organisations__c)record;
            if(oldEnqOrg.Enquiry__c != newEnqOrg.Enquiry__c || oldEnqOrg.Account__c != newEnqOrg.Account__c){
                records.add(record);
            }         
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            Map<Id,Id> m_existingOrgIdEnquiryId = new Map<Id,Id>();
            Map<Id,Id> m_incomingOrgIdEnquiryId = new Map<Id,Id>();
            for(Enquiry_Organisations__c newExistingRecord : (List<Enquiry_Organisations__c>)records){
                if(m_incomingOrgIdEnquiryId.containsKey(newExistingRecord.Account__c)){
                    newExistingRecord.addError(Label.EnquiryOrganisation_ValidationError);     
                }else{
                    m_incomingOrgIdEnquiryId.put(newExistingRecord.Account__c, newExistingRecord.Enquiry__c);
                }
            }
            for(Enquiry_Organisations__c existingRecord : [SELECT Id,Account__c,Enquiry__c FROM Enquiry_Organisations__c 
                                                           WHERE Enquiry__c in :m_incomingOrgIdEnquiryId.values() AND Account__c in :m_incomingOrgIdEnquiryId.keyset()]){
                m_existingOrgIdEnquiryId.put(existingRecord.Account__c, existingRecord.Enquiry__c);
            }

            // Check if the Map exists
            if(!m_existingOrgIdEnquiryId.isEmpty() && !records.isEmpty()){
                for(Enquiry_Organisations__c newEditedRecord : (List<Enquiry_Organisations__c>)records){
                    // system.debug('@@@m_existingOrgIdEnquiryId.get(newEditedRecord.Account__c)'+m_existingOrgIdEnquiryId.get(newEditedRecord.Account__c));
                    // system.debug('@@@newEditedRecord.Enquiry__c'+newEditedRecord.Enquiry__c);
                    if(m_existingOrgIdEnquiryId.get(newEditedRecord.Account__c) == newEditedRecord.Enquiry__c){
                        newEditedRecord.addError(Label.EnquiryOrganisation_ValidationError);    
                    }
                }    
            }
        }
    }
}