/**
 * @author David Browaeys
 * @description This service class create opportunity and quote for mass offe generation
 * @group Bulk Data Processing
 */
public inherited sharing class BulkGenerateOfferService {
    @TestVisible Bulk_Data_Processing__c bdp;
    @TestVisible Application_Course_Preference__c destinationACP;
    @TestVisible ACPSelector acpSelector;
    @TestVisible OpportunitiesSelector opptySelector;
    @TestVisible Dao myDao;
    @TestVisible Boolean disableOpptyLineItems;
    @TestVisible Boolean disableQuoteGen;
    public BulkGenerateOfferService() {
        this.acpSelector = new ACPSelector();
        this.opptySelector = new OpportunitiesSelector();
        this.myDao = new SObjectDao();
    }
    public void execute(Bulk_Data_Processing__c bdp){
        this.bdp = bdp;
        Contact student = this.bdp.Applicant__r;
        this.destinationACP = this.acpSelector.selectOfferedById(this.bdp.Transfer_To__c);
        //create opportunity
        OfferWizardWrapper wrapper = setOfferWrapper(student);
        this.myDao.upsertRecords(new Opportunity[]{wrapper.opptyRecord});
        //set init acp & course offering into wrapper
        wrapper.selectedACPList = new Application_Course_Preference__c[]{destinationACP};
        wrapper.courseOfferingByAcpId = new Map<String,Course_Offering__c>{destinationACP.Id => destinationACP.Course_Offering__r};
        
        if (String.isNotBlank(this.bdp.Student_Notes__c)) {
            wrapper.additionalACPClauses = new Map<String, String>{
                destinationACP.Id => this.bdp.Student_Notes__c
            };
        }

        //create opportunity line item for destination acp    
        if (this.disableOpptyLineItems != true) this.myDao.insertRecords(new OpportunityLineItemService.OppLineItemCreator(wrapper).execute());
        //link associated clause with oppty (if any)
        for (Associated_Clause__c ac : this.bdp.Associated_Clauses__r) {
            ac.Opportunity__c = wrapper.opptyRecord.Id;
			ac.ACP__c = this.bdp.Transfer_To__c;
        }
        this.myDao.updateRecords(this.bdp.Associated_Clauses__r);
        //reselect all oppty info before quote gen 
        Opportunity[] opps = this.opptySelector.selectByIdWithOpportunityLines(new Set<ID>{wrapper.opptyRecord.Id});
        if (this.disableQuoteGen != true) generateQuote(bdp, opps);
        TriggerCommon.disableTrigger('Opportunity');
        this.myDao.updateRecords(opps); 
        TriggerCommon.enableTrigger('Opportunity');
    }

    /**
     * Create opportunity offer in wrapper for offer
     * @param student contact information
     * @return   offer wrapper
     */
    @TestVisible private OfferWizardWrapper setOfferWrapper(Contact student){
        if (destinationACP.Agreed_Start_Date__c == null || destinationACP.Revised_End_Date__c == null) {
            throw new IllegalArgumentException('ACP Start & End Dates cannot be blank.');
        }
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.opptyRecord = OpportunityService.createInternationalOfferOpp(student,destinationACP);
        wrapper.opptyRecord.Onshore_MU_Transfer__c = this.bdp.Onshore_MU_Transfer__c;
        wrapper.opptyRecord.Destination_ACP__c = destinationACP.Id;
        wrapper.opptyRecord.Destination_Course_Name__c = destinationACP.Course_Title__c;
        wrapper.opptyRecord.Bulk_Job_ID__c = this.bdp.Bulk_Job_ID__c;
        wrapper.opptyRecord.OwnerId = this.bdp.OwnerId;
        wrapper.opptyRecord.StageName = 'Processing Offer';
        wrapper.opptyRecord.NextStep = 'Bulk Generate Offer';
        wrapper.opptyRecord.Signature_Type__c = this.bdp.Signature_Type__c != null ? this.bdp.Signature_Type__c : 'Wet Signature';
        wrapper.opptyRecord.Bulk_Data_Processing__c = this.bdp.Id;
        wrapper.opptyRecord.Offer_Type__c = (this.bdp != null ? 'TRANSFER' : destinationACP.Outcome_Status_LOV__r.System_Code__c);
        //SFTG-2150 Added Offer Template and Template Type during Offer Generation
        wrapper.opptyRecord.Offer_Template__c = (this.bdp != null ? this.bdp.Offer_Template__c : '');
        wrapper.opptyRecord.Template_Type__c = (this.bdp != null ? this.bdp.Template_Type__c : '');

        OpportunityService.OverrideDates visaDates = OpportunityService.calculateOfferVisaDates(destinationACP.Agreed_Start_Date__c,destinationACP.Revised_End_Date__c);
        wrapper.opptyRecord.Visa_Start_Date__c = visaDates.startDate;
        wrapper.opptyRecord.Visa_End_Date__c = visaDates.endDate;
        if (this.bdp != null && String.isNotBlank(this.bdp.Type__c) && (this.bdp.Type__c == 'Course Transfer' || this.bdp.Type__c == 'Campus Transfer')) {
            //populate Regeneration_Reason__c as Course Transer when
            //assessor/offers specialist generate an offer for course or campus transfer via the bulk offer generation process or the offer wizard
            wrapper.opptyRecord.Regeneration_Reason__c = 'Course transfer';
        }
        return wrapper;
    }

    /**
     * Call cpq api for quote gen
     * @param bdp transfer record
     * @param opps list of opportunities(should be really only one)
     */
    @TestVisible private void generateQuote(Bulk_Data_Processing__c bdp, Opportunity[] opps){
        //start quote gen
        QuoteGenerator handler = new QuoteGenerator(opps[0]);
        //mark quote as manual isca if pure campus transfer (no course change) from malaysia/south africa
        handler.manualISCAEdit = bdp.Manual_ISCA_Edit__c;
        Boolean result = handler.execute();
        if (result){    //quote created successfully
            opps[0].NextStep = 'Calculate Pricing';
        }else{  //error
            //what should be the opportunity stage or next step ? How to report the error ? 
            opps[0].StageName = 'Specialist Review';
            opps[0].NextStep = 'Quote Generation Failed!';
        }
    }
}