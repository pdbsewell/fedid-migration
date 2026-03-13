/**
 * @author          Inderpal Dhanoa
 * @description     This class contains trigger logic (handler classes) for the Review Transaction object
 * @group           Service Class
 * @revision
 *					01/03/2023 - Inderpal D        - Sync Designations & Appeals PENGAGE-2642
 */
public without sharing class ReviewTransactionv2Service { 
    /*******************************************************************************
     * @author       Inderpal
     * @date         2023-03-01
     * @description  Sync info from RTv2 to Designations & Appeals (PENGAGE-2642)
     *******************************************************************************/
    public class SyncAppealDesignationInfo extends TriggerAbstract { 
        //Id onlineDonationRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Review_Transaction_v2__c.getRecordTypeInfosByDeveloperName().get('Online_Donation_Transaction').getRecordTypeId();
        Map<Id, ucinn_ascendv2__Review_Transaction_v2__c> m_postedReviewTrnsctns = new Map<Id, ucinn_ascendv2__Review_Transaction_v2__c>();
        List<sObject> otherReviewTransList = new List<sObject>();
        Set<Id> s_relRecTypes = new Set<Id>();
        Set<String> s_selDesignations = new Set<String>();
        Set<String> s_selAppeals = new Set<String>();
        
        public SyncAppealDesignationInfo(){
			if(s_relRecTypes.isEmpty()){
				for(RecordType rectyp : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ucinn_ascendv2__Review_Transaction_v2__c' AND DeveloperName = 'Online_Donation_Transaction']){
					s_relRecTypes.add(rectyp.Id);
				}
			}
		}

        public override void process(SObject record) {
            ucinn_ascendv2__Review_Transaction_v2__c newReviewTrnscnRec = (ucinn_ascendv2__Review_Transaction_v2__c)record;
            if (newReviewTrnscnRec != null && s_relRecTypes.contains(newReviewTrnscnRec.recordTypeId)) {
                // Check if Designations have been populated
                if(String.isNotBlank(newReviewTrnscnRec.ucinn_ascendv2__Designation_External_ID_1__c)){
                    otherReviewTransList.add(record);
                    s_selDesignations.add(newReviewTrnscnRec.ucinn_ascendv2__Designation_External_ID_1__c);
                }
                // Check if Appeals have been populated
                if(String.isNotBlank(newReviewTrnscnRec.ucinn_ascendv2__Campaign_External_ID__c)){
                    otherReviewTransList.add(record);
                    s_selAppeals.add(newReviewTrnscnRec.ucinn_ascendv2__Campaign_External_ID__c);
                }

            }  
        }

		public override void process(SObject record, SObject oldRec) {
            ucinn_ascendv2__Review_Transaction_v2__c oldReviewTrnscnRec = (ucinn_ascendv2__Review_Transaction_v2__c)oldRec;
            ucinn_ascendv2__Review_Transaction_v2__c newReviewTrnscnRec = (ucinn_ascendv2__Review_Transaction_v2__c)record;
            if (newReviewTrnscnRec != null && s_relRecTypes.contains(newReviewTrnscnRec.recordTypeId) && 
                oldReviewTrnscnRec.ucinn_ascendv2__Designation_External_ID_1__c != newReviewTrnscnRec.ucinn_ascendv2__Designation_External_ID_1__c) {
                    otherReviewTransList.add(record);
                    s_selDesignations.add(newReviewTrnscnRec.ucinn_ascendv2__Designation_External_ID_1__c);
            } 
            if (newReviewTrnscnRec != null && s_relRecTypes.contains(newReviewTrnscnRec.recordTypeId) && 
                oldReviewTrnscnRec.ucinn_ascendv2__Campaign_External_ID__c != newReviewTrnscnRec.ucinn_ascendv2__Campaign_External_ID__c) {
                    otherReviewTransList.add(record);
                    s_selAppeals.add(newReviewTrnscnRec.ucinn_ascendv2__Campaign_External_ID__c);
            }
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            try{
                Map<String, Id> m_mappedAppeals = new Map<String, Id>();
                Map<String, Id> m_mappedDesignations = new Map<String, Id>();
                if(!s_selDesignations.isEmpty()){
                    for(ucinn_ascendv2__Designation__c selDesig : [SELECT Id,Name FROM ucinn_ascendv2__Designation__c WHERE Name IN :s_selDesignations]){
                        m_mappedDesignations.put(selDesig.Name, selDesig.Id);
                    }
                }
                if(!s_selAppeals.isEmpty()){
                    for(Campaign selCamp : [SELECT Id,Name,ucinn_ascendv2__Motivation_Code__c FROM Campaign WHERE ucinn_ascendv2__Motivation_Code__c IN :s_selAppeals]){
                        m_mappedAppeals.put(selCamp.ucinn_ascendv2__Motivation_Code__c, selCamp.Id);
                    }
                }

                for (ucinn_ascendv2__Review_Transaction_v2__c oneRT : (List<ucinn_ascendv2__Review_Transaction_v2__c>)otherReviewTransList) {
                    // Map Designations
                    if(m_mappedDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_External_ID_1__c)){
                        oneRT.ucinn_ascendv2__Designation_1__c = m_mappedDesignations.get(oneRT.ucinn_ascendv2__Designation_External_ID_1__c);
                    }else{
                        oneRT.ucinn_ascendv2__Designation_1__c = null;
                    }
                    // Map Appeals 
                    if(m_mappedAppeals.containsKey(oneRT.ucinn_ascendv2__Campaign_External_ID__c)){
                        oneRT.ucinn_ascendv2__Campaign__c = m_mappedAppeals.get(oneRT.ucinn_ascendv2__Campaign_External_ID__c);
                    }else{
                        oneRT.ucinn_ascendv2__Campaign__c = null;
                    }
                }                 
            }catch(exception e){ 
                LogUtilityException.LogException(e);
            }
        }
    }


    /*******************************************************************************
     * @author       Inderpal
     * @date         2022-01-22
     * @description  Sync info from RTv2 to linked Payment (PENGAGE-2601)
     *******************************************************************************/
    /*public class SyncSettlementInfoToLinkedPayment extends TriggerAbstract {
        //Id onlineDonationRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Review_Transaction_v2__c.getRecordTypeInfosByDeveloperName().get('Online_Donation_Transaction').getRecordTypeId();
        Map<Id, ucinn_ascendv2__Review_Transaction_v2__c> m_postedReviewTrnsctns = new Map<Id, ucinn_ascendv2__Review_Transaction_v2__c>();

        public override void process(SObject record) {
            ucinn_ascendv2__Review_Transaction_v2__c newReviewTrnscnRec = (ucinn_ascendv2__Review_Transaction_v2__c)record;
            // Check if Status field is changed
            // if(newReviewTrnscnRec.RecordTypeId == onlineDonationRecordTypeId && oldReviewTrnscnRec.ucinn_ascendv2__Status__c != newReviewTrnscnRec.ucinn_ascendv2__Status__c && newReviewTrnscnRec.ucinn_ascendv2__Status__c == 'Posted'){
            //     m_postedReviewTrnsctns.put(newReviewTrnscnRec.Id, newReviewTrnscnRec); 
            // }
			system.debug('$$$$NEW newReviewTrnscnRec.Payment_Settlement_Date__c'+newReviewTrnscnRec.Payment_Settlement_Date__c);
			system.debug('$$$$NEW newReviewTrnscnRec.ucinn_ascendv2__Status__c'+newReviewTrnscnRec.ucinn_ascendv2__Status__c);
			if(newReviewTrnscnRec.ucinn_ascendv2__Status__c == 'Posted' && newReviewTrnscnRec.Payment_Settlement_Date__c != null){
				m_postedReviewTrnsctns.put(newReviewTrnscnRec.Id, newReviewTrnscnRec); 
			}
        }

        public override void process(SObject record, SObject oldRec) {
            ucinn_ascendv2__Review_Transaction_v2__c newReviewTrnscnRec = (ucinn_ascendv2__Review_Transaction_v2__c)record;
            ucinn_ascendv2__Review_Transaction_v2__c oldReviewTrnscnRec = (ucinn_ascendv2__Review_Transaction_v2__c)oldRec;
            // Check if Status field is changed
            system.debug('$$$$UPD NEW newReviewTrnscnRec.ucinn_ascendv2__Status__c'+newReviewTrnscnRec.ucinn_ascendv2__Status__c);
            system.debug('$$$$UPD OLD newReviewTrnscnRec.ucinn_ascendv2__Status__c'+oldReviewTrnscnRec.ucinn_ascendv2__Status__c);
            if(oldReviewTrnscnRec.ucinn_ascendv2__Status__c != newReviewTrnscnRec.ucinn_ascendv2__Status__c && newReviewTrnscnRec.ucinn_ascendv2__Status__c == 'Posted'){
                m_postedReviewTrnsctns.put(newReviewTrnscnRec.Id, newReviewTrnscnRec); 
            }
        }
        /**
        * Run functionality logic
        */
        /*public override void execute() {
            try{
                system.debug('$$$$m_postedReviewTrnsctns'+m_postedReviewTrnsctns);
                if(!m_postedReviewTrnsctns.isEmpty()){
                    List<ucinn_ascendv2__Payment__c> l_paymnts = new List<ucinn_ascendv2__Payment__c>();
                    for(ucinn_ascendv2__Payment__c linkedPaymnt :   [SELECT Id, Payment_Settlement_Date__c, Batch_Id__c, ucinn_ascendv2__Review_Transaction_v2__c, Payment_Settled__c,Payment_Request_Date__c 
                                                                    FROM ucinn_ascendv2__Payment__c 
                                                                    WHERE ucinn_ascendv2__Review_Transaction_v2__c IN :m_postedReviewTrnsctns.keyset()
                                                                    AND Payment_Settlement_Date__c = NULL
                                                                    AND Batch_Id__c = NULL]){
                        system.debug('$$$$linkedPaymnt'+linkedPaymnt);
                        if(m_postedReviewTrnsctns.containsKey(linkedPaymnt.ucinn_ascendv2__Review_Transaction_v2__c)){
                            ucinn_ascendv2__Review_Transaction_v2__c newReviewTrnscnRec = m_postedReviewTrnsctns.get(linkedPaymnt.ucinn_ascendv2__Review_Transaction_v2__c);
                            l_paymnts.add(new ucinn_ascendv2__Payment__c(Id=linkedPaymnt.Id, Payment_Request_Date__c = newReviewTrnscnRec.Payment_Request_Date__c, Payment_Settlement_Date__c = newReviewTrnscnRec.Payment_Settlement_Date__c, Batch_Id__c = newReviewTrnscnRec.Batch_Id__c, Payment_Settled__c = true));
                        }                        
                    }
                    system.debug('$$$$l_paymnts'+l_paymnts);
                    // Update the Info on the Payment Records
                    if(!l_paymnts.isEmpty()){
                        Database.SaveResult[] lsr = Database.update(l_paymnts, false);
                        for(Integer i=0; i<l_paymnts.size(); i++){
                            for(Database.SaveResult sr : lsr){
                                if(!sr.isSuccess()){
                                    // Get the first save result error
                                    Database.Error err = sr.getErrors()[0];logUtilityException.addLogEvent('Update on ucinn_ascendv2__Payment__c failed for Review Transaction Trigger SyncSettlementInfoToLinkedPayment', l_paymnts[i], err, 'SyncSettlementInfoToLinkedPayment Update Settltment Info');
                                }
                            }
                        }
                    }
                }                
            }catch(exception e){
                system.debug('$$$$Error'+e.getMessage());
                LogUtilityException.LogException(e);
            }
        }
    }*/
}