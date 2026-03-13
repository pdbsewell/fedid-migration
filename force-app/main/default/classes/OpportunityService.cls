/**
* @author Mathew Jose
* @date 30/10/2019
* @group SF Offer
* @description Service layer containing most business logic for opportunity standard object 
*/
global with sharing class OpportunityService {
    /*******************************************************************************************************
    * @description Get Opportunity by Id with opportunity line and clause
    * @param opptyId - id of opportunity
    * @return Opportunity
    */ 
    @AuraEnabled
    public static Opportunity getOffer(String opptyId){
        try {
            return new OpportunitiesSelector().selectByIdForOfferUpdate(new Set<ID>{opptyId})[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*******************************************************************************************************
    * @description Method which creates opportunity line items on finish of the make an offer flow.
    * @param offerRequest - the JSON string representing the OfferWizardWrapper passed from the lwc. The wrapper class contains needed records for Offer creation.
    * @return a success string or exception in case of an error.
    */ 
    @AuraEnabled
    public static Opportunity createOffer(String offerRequest) {
        Savepoint sp = Database.setSavepoint();
        try{
            return new OfferCreationService((OfferWizardWrapper)JSON.deserialize(offerRequest, OfferWizardWrapper.class)).execute();
        }catch(Exception e){
            Database.rollback( sp );
            LogUtilityException.throwAura('Ooops! Something went wrong', e.getMessage(), 400, 'error');
        }
        return null;
    }
   
    public class OfferCreationService{
        OfferWizardWrapper wrapper;
        Offer_Setting__c offerSetting;
        public OfferCreationService(OfferWizardWrapper wrapper){
            this.wrapper = wrapper;
            this.offerSetting = Offer_Setting__c.getOrgDefaults();
        }
        public Opportunity execute(){            
            // translate the offer type to the offer conga template name
            Offer_Setting__c offerSetting = Offer_Setting__c.getOrgDefaults();

            // query conga template
            String templateId;
            //Add logic when Indonesia offers button is clicked
            switch on wrapper.opptyRecord.Offer_Template__c {
                when 'Domestic Monash College - Australia' {
                    templateId = offerSetting.Domestic_Template_Id__c;
                    wrapper.opptyRecord.Template_Type__c ='Domestic Monash College Australia';
                }	
                when 'International Coursework - Australia' {
                    templateId = offerSetting.Isca_Template_Id__c;
                    wrapper.opptyRecord.Template_Type__c ='International Coursework Australia';
                }
                when 'International Coursework - Monash Abroad' {
                    templateId = offerSetting.Monash_Abroad_Template_Id__c;
                    wrapper.opptyRecord.Template_Type__c ='International Monash Abroad Australia';
                }
                when 'Online Coursework - Avenu' {
                    templateId = offerSetting.Avenu_Monash_Online_Template_Id__c;
                    wrapper.opptyRecord.Template_Type__c ='Online Coursework - Avenu';
                }
                when 'Domestic Coursework - Australia' {
                    templateId = offerSetting.Monash_Abroad_Template_Id__c;
                    wrapper.opptyRecord.Template_Type__c ='Domestic Coursework Australia';
                    wrapper.opptyRecord.Signature_Type__c ='Not Applicable';
                } 
                when 'Domestic Coursework - Indonesia' {
                    templateId = offerSetting.Indonesia_ENG_Template_Id__c;
                    wrapper.opptyRecord.Template_Type__c ='Domestic Coursework Indonesia';
                }
                when else {
                }
            }
            wrapper.opptyRecord.Offer_Template__c = templateId;
            wrapper.opptyRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId();
            wrapper.opptyRecord.In_Shadow__c = offerSetting != null ? offerSetting.IS_SHADOW_PHASE__c : true;
            wrapper.opptyRecord.CloseDate = wrapper.offerLapsedDate;
            //add currencycode on the opportunity
            switch on wrapper.opptyRecord.Template_Type__c {
                when 'Domestic Coursework Indonesia' {
                    wrapper.opptyRecord.currencyISOCode = Constants.IDR_CURRENCY;
                }	
                when 'Online Coursework - Avenu' {
                    wrapper.opptyRecord.currencyISOCode = Constants.INR_CURRENCY;
                }
                when else {
                    wrapper.opptyRecord.currencyISOCode = Constants.AUD_CURRENCY;
                }
            }
            upsert wrapper.opptyRecord;

            //update acp's
            if (wrapper.updatedACPs != null) new OfferACPUpdateService(wrapper).execute().commitAll();

            //close original oppty
            if (wrapper.opptyRecord.Original_Offer__c != null) update setOpptyForDeferral(wrapper.opptyRecord.Original_Offer__c);

            //copy offer template of the original offer
            if (wrapper.opptyRecord.Original_Offer__c != null) {
                wrapper.opptyRecord.Offer_Template__c = retrieveOriginalOpportunityTemplateId(wrapper.opptyRecord.Original_Offer__c);
            }

            //insert opportunity products
            if(wrapper.additionalProducts != null || wrapper.selectedACPList != null) insert new OpportunityLineItemService.OppLineItemCreator(wrapper).execute();

            //insert manual clauses
            if(wrapper.selectedClauses != null) upsert AssociatedClauseService.createAssociatedClause(wrapper.opptyRecord, wrapper.selectedClauses);

            //Update opportunity to kick off quote generation
            setOpptyForQuoteGen(wrapper.opptyRecord);
            update wrapper.opptyRecord;
            return wrapper.opptyRecord;
        }     
    }

    public static Opportunity createInternationalOfferOpp(Contact student, Application_Course_Preference__c destinationACP){
        Opportunity oppRecord = new Opportunity();
        oppRecord.CloseDate = destinationACP.Offer_Response_Date__c;
        oppRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId();
        // Opportunity Name generation logic
        oppRecord.Name = '';
        // First Name - handle mononymous names
        if (!String.isBlank(student.First_Name__c)) {
            oppRecord.Name += (student.First_Name__c.length() >= 40 ? student.First_Name__c.substring(0,40) : student.First_Name__c) + ' ';
        }
        // Last Name
        oppRecord.Name += (student.Last_Name__c.length() >= 30 ? student.Last_Name__c.substring(0,30) : student.Last_Name__c);
        // Course Code
        oppRecord.Name += '-'+ (destinationACP.Course_Code__c.length() >= 6 ? destinationACP.Course_Code__c.substring(0,6) : destinationACP.Course_Code__c);
        // Course Start date
        oppRecord.Name += '-'+ destinationACP.Course_Start_Date_Updated__c;
        oppRecord.Name = oppRecord.Name.replace('00:00:00','');
        oppRecord.Bulk_Gen__c = true;
        oppRecord.AccountId = student.AccountId;
        oppRecord.Fee_Category__c = 'AU_INT';
        oppRecord.Offer_Category__c = 'International Offer';
        oppRecord.Destination_Course_Name__c = destinationACP.Course_Title__c;
        oppRecord.Agent_Account__c = destinationACP.Application__r.Agent__c;
        oppRecord.Pricebook2 = new Pricebook2(External_ID__c = 'AU_INT');
        oppRecord.StageName = 'New Offer';
        oppRecord.Offer_Type__c = destinationACP.Outcome_Status_LOV__r.System_Code__c;
        oppRecord.PrimaryContact__c = student.Id;
        return oppRecord;
    }

    public static void setOpptyForQuoteGen(Opportunity oppty){
        oppty.stagename = 'Processing Offer';
        oppty.NextStep = 'Generate Offer';
    }

    public static Opportunity setOpptyForDeferral(String opptyId){
        return new Opportunity(
            Id = opptyId,
            StageName = 'Canceled/Rejected',
            Closed_Reason__c = 'Deferred',
            Closed_Reason_Details__c = 'Student requested deferral'
        );
    }
    
    /*******************************************************************************************************
    * @description This method calculate visa/oshc start and end date base base on course start and end date passed in parameters.
    * If under 10 months course, then visa start/end dates are 1 month before and after. 
    * If over 10 months and course ends between Jan to Oct, then visa start date is still one month before but will end 2 months after course ends date. 
    * If over 10 months and course ends between Nov to Dec, then visa start date is still one month before but will end on 15/3 of next year. 
    * @param startDate start date of the earliest course
    * @param endDate end date of the latest course course
    * @return OverrideDates
    */ 
    @AuraEnabled
    public static OverrideDates calculateVisaDates(Date startDate, Date endDate){
        OverrideDates tmp = new OverrideDates();
        try{
            tmp = calculateOfferVisaDates(startDate, endDate);
        }catch(Exception e){
            LogUtilityException.throwAura('Ooops! Something went wrong', e.getMessage(), 400, 'error');
        }
        return tmp;
    }
    
    /**
     * @description Calculates Visa dates for Offers
     * @param startDate start date of the earliest course
     * @param endDate end date of the latest course course
     * @return Returns the calculated visa dates for the offer
     */
    public static OverrideDates calculateOfferVisaDates(Date startDate, Date endDate){
        OverrideDates tmp = new OverrideDates();
        tmp.startDate = startDate;
        tmp.endDate = endDate;
        System.debug(startDate + ' >> '+ endDate);
        Integer monthsBetween = tmp.startDate.monthsBetween(tmp.endDate);

        tmp.startDate = tmp.startDate.addMonths(-1);

        if (monthsBetween == 10) {
           
            if ((endDate.month() >= 1 && endDate.month() <= 10)) {
                tmp.endDate = tmp.endDate.addMonths(2);
            } else {
                tmp.endDate = Date.newInstance(tmp.endDate.year() + 1, 3, 15);
            }

        } else {
            if (monthsBetween < 10){  //under 10 months ? 
                tmp.endDate = tmp.endDate.addMonths(1);
            }else if (tmp.endDate.month() <= 10){ //over 10 months, end between jan to oct?
                tmp.endDate = tmp.endDate.addMonths(2);
            }else if (monthsBetween > 10){  //over 10 months, end between nov to dec
                tmp.endDate = Date.newInstance(tmp.endDate.year() + 1, 3, 15);
            }
        }
        return tmp;
    }


    public static Opportunity updateOpptyForSpecialistReview(String opptyId){
        return new Opportunity(Id = opptyId, StageName='Specialist Review', NextStep = '');
    }

    public class OverrideDates{
        @AuraEnabled
        public Date startDate {get; set;}
        @AuraEnabled
        public Date endDate {get; set;}
    } 

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the offer template of the opportunity id
     * @revision    06/15/2021 - Kristian Vegerano - Created
     */
    public static String retrieveOriginalOpportunityTemplateId(String opptyId){
        String originalOfferTemplateId = null;
        for(Opportunity loopOpportunity : [SELECT Id, Offer_Template__c
                                           FROM Opportunity
                                           WHERE Id = :opptyId]){
            originalOfferTemplateId = loopOpportunity.Offer_Template__c;
        }
        return originalOfferTemplateId;
    }
}