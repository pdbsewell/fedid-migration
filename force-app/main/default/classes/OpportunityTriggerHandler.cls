/*
 * @File Name          : OpportunityTriggerHandler.cls
 * @Description        : Service layer containing most business logic for opportunity object 
 * @Author             : David Browaeys
 * @Group              : 
 * @Last Modified By   : Sachin Shetty
 * @Last Modified On   : 17/04/2024
 * @Modification Log   : 
 * Date         Author      		    Modification
 * 10/15/2019   David Browaeys          Initial Version
 * 3/08/2020    Shalini Mendu           Modifying to fix SFTG-1098 - When many offers are created,some opportunities are stuck in Processing Offers 
 * 20/04/2021   Inderpal Dhanoa         Modifying for ENGAGEIE - 625 Validate Stage changes
 * 30/08/2021   Inderpal Dhanoa         Modifying for ENGAGEIE - 456 Opportunity access control
 * 08/09/2021   Inderpal Dhanoa         Modifying for ENGAGEIE - 1019 Sync DUNS and Pure Id to generate Unique Pure Id
 * 11/03/2022   Inderpal Dhanoa         Modifying for ENGAGEIE - 1269 Do not lock an Opportunity from updating the stage if we have an open IP enquiry
 * 29/06/2023   Davey Yu                Modifying for RO - 215   Update ValidateStageChange method query on case to only check for Enterprise record type
 * 17/04/2024   Sachin Shetty           Update to point to DBConnect fields
 * 24/06/2024   Inderpal Dhanoa         PENGAGE-2758 Sync COntact for Bequestor Oppty
**/
public class OpportunityTriggerHandler {
	public class CPQQuoteGeneration extends TriggerAbstract {
        List<Id> oppIds = new List<Id>();
        Map<Id,Opportunity_Event__e> oppEvMap = new Map<Id,Opportunity_Event__e>();
        Map<Id, Opportunity> oppMap = new  Map<Id, Opportunity>();

        public override void process(SObject rec) {
            for (Opportunity_Event__e evnRec :  (List<Opportunity_Event__e>)Trigger.New) {
                //put Opportunity_ID__c and Opportunity_Event__e record to the map
                oppEvMap.put(evnRec.Opportunity_ID__c, evnRec);
            }
            
            // add Opportunity_ID__c to a list
            oppIds.addAll(oppEvMap.keySet());

            //Query Opportunity with the Opportunity_ID__c list
            Opportunity[] opps   = new OpportunitiesSelector().selectByIdWithOpportunityLines((Set<ID>)JSON.deserialize(JSON.serialize(oppIds), Set<ID>.class));
            
            //Loop over Opportunity_Event__e
            for (Opportunity_Event__e evnRec : (List<Opportunity_Event__e>) Trigger.New) {
                //Loop over queried Opportunities
                for(Opportunity opp:opps)
                {
                    if(opp.Id ==evnRec.Opportunity_ID__c )
                    {
                        oppMap.put(evnRec.Opportunity_ID__c, opp );
                    }
                   
                }
            }
        }

        public override void execute() {
            Opportunity opp = null;
            for(Id idd:oppMap.keySet())
            {
                //get the Opportunity_Event__e record for the Opportunity_ID__c id
                Opportunity_Event__e evntRec  = oppEvMap.get(idd);
                //get the Opportunity  for the Opportunity_ID__c id
                opp = oppMap.get(idd);
                try{
                    Boolean result = new QuoteGenerator(opp).execute();
                    if (result){    //quote created successfully
                             opp.NextStep = 'Calculate Pricing';
                    }else{  //error
                        //what should be the opportunity stage or next step ? How to report the error ? 
                        opp.StageName = 'Specialist Review';
                        opp.NextStep = 'Quote Generation Failed!';
                    }
                   
                    String sRepId = (String)evntRec.get('replayId');
                    //Replay Opportunity_Event__e one at a time
                    EventBus.TriggerContext.currentContext().setResumeCheckpoint(sRepId);
                    break;
                }catch(Exception err){
                    LogUtilityException.logException(err, opp);
                }
               
            }
            try{
                TriggerCommon.disableTrigger('Opportunity');
                update opp; 
                TriggerCommon.enableTrigger('Opportunity');
            }catch(Exception err){
                LogUtilityException.logException(err, opp);
            }
           
          
           
        }
    }
	
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         2020-04-10
     * @description  Sync Pure Id and DUNS Number for before Update.
     * @revision     2020-04-10 - Inderpal Dhanoa - Initial version
     *               2024-04-10 - Sachin Shetty   - Update to point to DBConnect fields
     *******************************************************************************/
    public class SyncPureId extends TriggerAbstract {
        Id enterpriseRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
        List<Opportunity> l_impactedRecords = new List<Opportunity>();
        Set<Id> s_accntId = new Set<Id>();

        public override void process(SObject record) {
            
            // before and or after update logic here
            Opportunity newOpportunity = (Opportunity)record;
            if(newOpportunity.RecordTypeId == enterpriseRecordTypeId && newOpportunity.AccountId != null && String.isNotBlank(newOpportunity.PURE_Application_ID__c)){     
                s_accntId.add(newOpportunity.AccountId);
                l_impactedRecords.add(newOpportunity);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            // before and or after update logic here
            Opportunity newOpportunity = (Opportunity)record;
            Opportunity oldOpportunity = (Opportunity)oldRec;
            if(newOpportunity.RecordTypeId == enterpriseRecordTypeId && 
               (newOpportunity.AccountId != newOpportunity.AccountId || newOpportunity.PURE_Application_ID__c != oldOpportunity.PURE_Application_ID__c)){ 
                l_impactedRecords.add(newOpportunity);
                s_accntId.add(newOpportunity.AccountId);
            }
        }

        public override void execute(){
            // Sync Opportunity
            Map<Id,Account> m_IdAccount = linkOppWithAccount(s_accntId);
            for(Opportunity opportunity : l_impactedRecords){
				// Opportunity's Pure ID is updated using Account Details and Application Pure ID
                if(opportunity.AccountId == null || String.isBlank(opportunity.PURE_Application_ID__c)){
                    opportunity.Pure_ID__c = '';
                }else if(opportunity.AccountId != null && m_IdAccount != null && m_IdAccount.containsKey(opportunity.AccountId)){
                    Account linkedAccnt = m_IdAccount.get(opportunity.AccountId);
                    if(!String.isBlank((String)linkedAccnt.DBC_DUNS_Number__c)){  
                        opportunity.Pure_ID__c = opportunity.PURE_Application_ID__c + linkedAccnt.DBC_DUNS_Number__c; 
                    }else{
                        opportunity.Pure_ID__c = opportunity.PURE_Application_ID__c + linkedAccnt.Id;    
                    }
                } 
			}
        }

        public Map<Id,Account> linkOppWithAccount(Set<Id> s_accntId){
            Map<Id,Account> m_IdAccount = new Map<Id,Account>();
            for(Account accnt : [SELECT Id, DBC_DUNS_Number__c FROM Account WHERE Id in :s_accntId]){
                m_IdAccount.put(accnt.Id, accnt);
            }
            return m_IdAccount;
        }
    }
	
	/**
	 * validateStageChange Method to provide Opportunity Support
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Sync VisibilityCategory with IsPrivate for before Update.
	*******************************************************************************/
    public class SyncVisibilityCategoryAndIsPrivate extends TriggerAbstract {
        Id enterpriseRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
        List<Opportunity> l_impactedRecords = new List<Opportunity>();

        public override void process(SObject record) {
            // before and or after update logic here
            Opportunity newOpportunity = (Opportunity)record;
            if(newOpportunity.RecordTypeId == enterpriseRecordTypeId){
                l_impactedRecords.add(newOpportunity);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            // before and or after update logic here
            Opportunity newOpportunity = (Opportunity)record;
            Opportunity oldOpportunity = (Opportunity)oldRec;
            if(newOpportunity.RecordTypeId == enterpriseRecordTypeId && newOpportunity.Visibility_Category__c != oldOpportunity.Visibility_Category__c){
                l_impactedRecords.add(newOpportunity);
            }
        }

        public override void execute() {
            for (Opportunity opportunity : l_impactedRecords) {
				// Opportunity's Visibility Category is updated
                if(opportunity.Visibility_Category__c == 'Private'){
                    opportunity.IsPrivate = true;        
                }else{
                    opportunity.IsPrivate = false; 
                }
			}
        }
    }

    /**
	 * Sync Contact field Bequestor based on Oppty Stage and COnfirmation date 
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Sync Contact Bequestor for after Update.
	*******************************************************************************/
    public class SyncContactForBequestOppty extends TriggerAbstract {
        Id bequestRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Bequest_Proposal').getRecordTypeId();
        List<Opportunity> l_impactedRecords = new List<Opportunity>();
        List<Opportunity> l_delRecords = new List<Opportunity>();
        Set<Id> linkedContIds = new Set<Id>();

        public override void process(SObject oldRec) {
            // before Delete logic here
            Opportunity opportunityRec = (Opportunity)oldRec;
            if(opportunityRec.RecordTypeId == bequestRecordTypeId && opportunityRec.ucinn_ascendv2__Contact__c != null){
                // Check for Insert
                if(trigger.isInsert && opportunityRec.ucinn_ascendv2__Confirmation_Date__c != null){
                    l_impactedRecords.add(opportunityRec);linkedContIds.add(opportunityRec.ucinn_ascendv2__Contact__c);
                }
                // Check for Deletion
                if(trigger.isDelete){
                    l_delRecords.add(opportunityRec);
                }
            }
        }

        public override void process(SObject record, SObject oldRec) {
            // before and or after update logic here
            Opportunity newOpportunity = (Opportunity)record;
            Opportunity oldOpportunity = (Opportunity)oldRec;
            
            if(newOpportunity.RecordTypeId == bequestRecordTypeId && newOpportunity.ucinn_ascendv2__Contact__c != null && 
            (newOpportunity.ucinn_ascendv2__Confirmation_Date__c != oldOpportunity.ucinn_ascendv2__Confirmation_Date__c || newOpportunity.StageName != oldOpportunity.StageName
            ||  newOpportunity.ucinn_ascendv2__Contact__c != oldOpportunity.ucinn_ascendv2__Contact__c || newOpportunity.AccountId != oldOpportunity.AccountId)){
                l_impactedRecords.add(newOpportunity);
                linkedContIds.add(newOpportunity.ucinn_ascendv2__Contact__c);
            }
        }

        public override void execute() {
            List<Contact> updateBequestor = new List<Contact>();
            if(!l_impactedRecords.isEmpty()){
                Set<String> s_validStages = getValidStages();
                Map<Id,Boolean> m_linkedBequestors = getlinkedBequestors(linkedContIds);
                
                Boolean isBequestor;
                // Check for each Oppty and update the linked COntact accordingly
                for (Opportunity opportunity : l_impactedRecords) {
                    // Opportunity's linked Contact's Bequestor is updated
                    if(s_validStages.contains(opportunity.StageName)){
                        isBequestor = opportunity.ucinn_ascendv2__Confirmation_Date__c == null ? false : true;
                        updateBequestor.add(new Contact(Id = opportunity.ucinn_ascendv2__Contact__c, Is_Bequestor__c = isBequestor));         
                    }else{
                        if(m_linkedBequestors.containsKey(opportunity.ucinn_ascendv2__Contact__c) && m_linkedBequestors.get(opportunity.ucinn_ascendv2__Contact__c)){
                            updateBequestor.add(new Contact(Id = opportunity.ucinn_ascendv2__Contact__c, Is_Bequestor__c = false));
                        }
                    }
                }
            }
            if(!l_delRecords.isEmpty()){
                // Check for Deleted recds
                for (Opportunity opportunity : l_delRecords) {
                    updateBequestor.add(new Contact(Id = opportunity.ucinn_ascendv2__Contact__c, Is_Bequestor__c = false));
                }
            }            
            // update the linked Contacts
            if(!updateBequestor.isEmpty()){
                try{
                    update updateBequestor;
                }catch(Exception ex){
                    Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog(); 
                }
            } 
        }

        /**
         * getlinkedBequestors Method to retrieve the linked Bequestor
         * 
         * @author Inderpal Dhanoa - idha0002
         */
        public Map<Id,Boolean> getlinkedBequestors(Set<Id> linkedContIds){
            Map<Id,Boolean> m_linkedBequestors = new Map<Id,Boolean>();            
            String validStages = String.valueOf(Label.BequestOpptyDonorStages);
            for(Contact con : [SELECT Id, Is_Bequestor__c FROM Contact WHERE Id IN :linkedContIds]){
                m_linkedBequestors.put(con.Id, con.Is_Bequestor__c);
            }
            return m_linkedBequestors;
        }
        
        /**
         * getValidStages Method to provide get the Valid Stages to update the linked Bequestor
         * 
         * @author Inderpal Dhanoa - idha0002
         */
        public Set<String> getValidStages(){
            Set<String> s_validStages = new Set<String>();            
            String validStages = String.valueOf(Label.BequestOpptyDonorStages);
            for(String stage : validStages.split(';')){
                s_validStages.add(stage);
            }
            return s_validStages;
        }
    }
	
	/**
	 * validateStageChange Method to provide Opportunity Support
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Validate Stage for before Update.
	*******************************************************************************/
    public class ValidateStageChange extends TriggerAbstract {
        Id enterpriseRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(); 
        Set<Id> s_opportunityIds = new Set<Id>();
        List<Opportunity> l_impactedRecords = new List<Opportunity>();
        Map<Id, List<Case>> m_oppIdLinkedCases = new Map<Id, List<Case>>();

        public override void process(SObject record, SObject oldRec) {
            // before and or after update logic here
            Opportunity newOpportunity = (Opportunity)record;
            Opportunity oldOpportunity = (Opportunity)oldRec;
            if(newOpportunity.RecordTypeId == enterpriseRecordTypeId && newOpportunity.StageName != oldOpportunity.StageName){
                s_opportunityIds.add(newOpportunity.Id);
                l_impactedRecords.add(newOpportunity);
            }
        }

        public override void execute() {
            if (!s_opportunityIds.isEmpty()){
				//Updated by DYU 29/06/2023 RO - 215 updated query to check only for open enterprise cases
				for(Case relatedCase :  [SELECT Id, Status, Opportunity__c,MonashCollege_Outcome__c,IsClosed 
                                         FROM CASE 
                                         WHERE Opportunity__c in :s_opportunityIds 
                                         AND Type != 'IP'
                                         AND RecordType.DeveloperName = 'Enterprise']){
					List<Case> l_linkedCases = new List<Case>();
					if(m_oppIdLinkedCases.containsKey(relatedCase.Opportunity__c)){
						l_linkedCases = m_oppIdLinkedCases.get(relatedCase.Opportunity__c);	
					}
					l_linkedCases.add(relatedCase);
					m_oppIdLinkedCases.put(relatedCase.Opportunity__c, l_linkedCases); 
				}	
			}

            for (Opportunity opportunity : l_impactedRecords) {
				// Opportunity's related enquiries that have been closed with Status 'Not Approved', then the oppty can only move to 'Closed Lost' status
                if(opportunity.StageName != 'Closed Lost' && opportunity.StageName != 'Identify Opportunity'){
                    if(m_oppIdLinkedCases.containsKey(opportunity.Id)){
                        List<Case> l_linkedCases = m_oppIdLinkedCases.get(opportunity.Id);
                        if(!l_linkedCases.isEmpty()){
                            for(Case relatedCase : l_linkedCases){
                                if(relatedCase.Status == 'Closed' && relatedCase.MonashCollege_Outcome__c == 'Not Approved'){
                                    opportunity.addError(System.Label.OpportunityClosedValidation);
                                }
                            }
                        }
                    }
                    
                }
                //If the opportunity has Open enquiries then the enquiry can not move into the following status: Negotiation/Review, Closed Won, Closed Lost.	
                if(opportunity.StageName == 'Develop/Prepare' || opportunity.StageName == 'Negotiation/Review' || opportunity.StageName == 'Closed Won' || opportunity.StageName == 'Closed Lost' ){
                    if(m_oppIdLinkedCases.containsKey(opportunity.Id)){
                        List<Case> l_linkedCases = m_oppIdLinkedCases.get(opportunity.Id);
                        if(!l_linkedCases.isEmpty()){
                            for(Case relatedCase : l_linkedCases){
                                if(!relatedCase.IsClosed){
                                    opportunity.addError(System.Label.OpportunityReviewValidation); 
                                }
                            }
                        }
                    }
                }
			}
        }
    }

    /**
    * @author       Kristian Vegerano
    * @Revision     Shalini Mendu - Publish Async_Process__e event to run the CPQ calculations in
    * system context
    * @description  Sync opportunity to primary quote after nominating a health cover
    * @param        quoteId - quote id to be updated
    *               selectedProvider - nominated provider type
    *               selectedProviderName - nominated provider name
    *               subStatus - new sub status of the quote
    *               selectedHealthOption - nominated health cover option
    * @return       CPQ_ApiDataModels.QuoteModel - updated cpq quote model
    */    
    public class NominateOfferHealthCover extends TriggerAbstract {
        Id offerRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId();
        List<Opportunity> l_impactedRecords = new List<Opportunity>();

        public override void process(SObject record) {
        }

        public override void process(SObject record, SObject oldRec) {
            // before and or after update logic here
            Opportunity newOpportunity = (Opportunity)record;
            Opportunity oldOpportunity = (Opportunity)oldRec;
            if(newOpportunity.RecordTypeId == offerRecordTypeId && newOpportunity.Nominated_Health_Cover__c != oldOpportunity.Nominated_Health_Cover__c && newOpportunity.Nominated_Health_Cover__c != null){
                l_impactedRecords.add(newOpportunity);
            }
        }
        public override void execute() {
            // Prepare Async_Process__e event 
            for(Opportunity opportunity : l_impactedRecords) {

                AsyncProcessPayload payload = new AsyncProcessPayload();
                List<Async_Process__e> syncQuoteEventsPub = new List<Async_Process__e>();
    
                payload.put('quoteId', JSON.serializePretty(opportunity.SBQQ__PrimaryQuote__c));
                payload.put('selectedProvider', JSON.serializePretty('Allianz'));
                payload.put('selectedProviderName', JSON.serializePretty('Allianz'));
                payload.put('selectedHealthOption', JSON.serializePretty(opportunity.Nominated_Health_Cover__c));
                // send event
                syncQuoteEventsPub.add(new Async_Process__e(
                    Process_Name__c = 'QuoteService.SyncQuote',
                    Parameter__c = payload.serialize()
                ));
                //publish event
                EventBus.publish(syncQuoteEventsPub);
		    }
        }
    }

}