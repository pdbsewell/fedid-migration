/**
 * @description GRScholarshipRoundPublishBatch class to process the release offer batch
 * @author      Vishal Gupta
 * @since       29.5.2025
 * @revision
 */
public with sharing class GRScholarshipRoundPublishBatch implements Database.Batchable<SObject> {
    private List<GRScholarshipCalendarRound> lstCalendarRound;
    private Id calendarId;
    private String round;
    public GRScholarshipRoundPublishBatch(Id calendarId, String round, List<GRScholarshipCalendarRound> lstCalendarRound) {
        this.calendarId = calendarId;
        this.round = round;
        this.lstCalendarRound = lstCalendarRound;

        //disabling the triggers we dont need to run for this process
        TriggerCommon.disableTrigger('EmailMessage');
        TriggerCommon.disableTrigger('Task');
        TriggerCommon.disableTrigger('Opportunity');
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();
    }

    /**
     * @description preparing the acps under the calendar id and round passed to the batch
     * @param       BC
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        //returning the Application_Course_Preference__c for scholarship applications based on the round and calendar selected
        return Database.getQueryLocator([
            SELECT Id, Scholarship_Calendar__c, Applicant__r.FirstName, Applicant__r.LastName, 
                   Applicant__c, Applicant__r.AccountId,
                   (SELECT Id FROM GraduateResearchOffers__r)
            FROM Application_Course_Preference__c
            WHERE Scholarship_Calendar__c = :calendarId
              AND Graduate_Research_Application_Type__c IN ('Admission and Scholarship', 'Scholarship')
              AND Application__r.Citizenship_Classification__c = :round
              AND GradRes_Callista_Id__c <> null
        ]);
    }

    /**
     * @description executing the batch
     * @param       scope
     */
    public void execute(Database.BatchableContext BC, List<Application_Course_Preference__c> scope) {
        
        Map<Id, Id> mapAcpContact = new Map<Id, Id>();//map for contactid and acpid to send the emails
        List<Opportunity> lstNoOfferOpportunities = new List<Opportunity>();//list for not approved offers
        List<SBQQ__Quote__c> approvedQuoteData = new List<SBQQ__Quote__c>();//list for approved offers
        List<Opportunity> approvedOpprtunityData = new List<Opportunity>();//list for approved offers
        Set<Id> acpIds = new Set<Id>();//acp ids for approved offers
        Savepoint sp = Database.setSavepoint(); // Set Savepoint
        try{
            for (Application_Course_Preference__c acp : scope) {
                if (acp.GraduateResearchOffers__r.isEmpty()) {
                    //create the No Offer opportunity and quotes if there is no offer found unde the acp
                    String oppName = acp.Applicant__r.FirstName + ' ' + acp.Applicant__r.LastName + '-GRSS-' + String.valueOf(Date.today());
                    Opportunity opp = GRScholarshipOfferService.upsertOpportunity(
                        oppName, acp.Applicant__c, acp.Applicant__r.AccountId, acp.Id, null
                    );
                    opp.Offer_published_date__c = Date.Today();
                    lstNoOfferOpportunities.add(opp);
                    mapAcpContact.put(acp.Id, acp.Applicant__c);
                } else {
                    acpIds.add(acp.Id);
                }
            }

            //insert no offer Quote And Opportunity
            insertOpportunityAndQuote(lstNoOfferOpportunities, mapAcpContact);
            
            if(!acpIds.isEmpty()) {
                //approving the quote and opportunities
                for(Opportunity opp : [SELECT Id, Application_Course_Preference__r.Scholarship_Calendar__c, Application_Course_Preference__c, Offer_published_date__c, Offer_Type__c,
                                            (SELECT Id, SBQQ__Status__c, SBQQ__Opportunity2__r.Application_Course_Preference__c, SBQQ__Opportunity2__r.Application_Course_Preference__r.Applicant__c FROM SBQQ__Quotes2__r LIMIT 1) 
                                            FROM Opportunity WHERE Application_Course_Preference__c IN :acpIds AND Offer_published_date__c = null]) {
                    if(!opp.SBQQ__Quotes2__r.isEmpty()) {
                        approvedQuoteData.add(opp.SBQQ__Quotes2__r[0]);
                        approvedOpprtunityData.add(opp);                   
                    }
                }
                //udpate the offer status as approved
                //udpate the opportunity offer publish date
                if(approvedOpprtunityData != null && !approvedOpprtunityData.isEmpty() && approvedQuoteData != null && !approvedQuoteData.isEmpty()) {
                    updateQuoteAndOpportunity(approvedQuoteData, approvedOpprtunityData, mapAcpContact);
                } 
            }

            //sending the offer email to the applicants
            sendEmail(mapAcpContact);
            Nebula.logger.info('GR scholarship offer published').addTag('Graduate Research');
        }
        catch(Exception ex) {
            Database.rollback(sp); // Rollback all operations after the savepoint
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }

    /**
     * @description insert Quote And Opportunity
     * @param       lstNoOfferOpportunities
     */
    private void insertOpportunityAndQuote(List<Opportunity> lstNoOfferOpportunities, Map<Id, Id> mapAcpContact) {
        if (!lstNoOfferOpportunities.isEmpty()) {
            insert lstNoOfferOpportunities;
            List<SBQQ__Quote__c> lstNoOfferQuotes = new List<SBQQ__Quote__c>();//list for not approved offers
            for (Opportunity opp : lstNoOfferOpportunities) {
                SBQQ__Quote__c quote = GRScholarshipOfferService.upsertQuote(
                    opp.Id, mapAcpContact.get(opp.Application_Course_Preference__c), null, null
                );
                lstNoOfferQuotes.add(quote);
            }
            insert lstNoOfferQuotes;  
        }
    }
    /**
     * @description update Quote And Opportunity
     * @param       quoteData
     * @param       opprtunityData
     * @param       mapAcpContact
     */
    private static void updateQuoteAndOpportunity(List<SBQQ__Quote__c> quoteData, List<Opportunity> opprtunityData, Map<Id, Id> mapAcpContact) {
        List<Opportunity> opportunities = new List<Opportunity>();
        for(Opportunity opp : opprtunityData) {
            opp = GRScholarshipOfferService.publishopportunity(opp);
            opportunities.add(opp);
        }
        update opportunities;

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for(SBQQ__Quote__c quote : quoteData) {
            quote = GRScholarshipOfferService.publishQuote(quote);
            quotes.add(quote);
            mapAcpContact.put(quote.SBQQ__Opportunity2__r.Application_Course_Preference__c, quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Applicant__c);
        }
        update quotes;
    }

    /**
     * @description sending the offer email to the applicants
     * @param       mapAcpContact
     */
    private static void sendEmail(Map<Id, Id> mapAcpContact) {
        OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'mgro-apply@f.e.monash.edu' LIMIT 1];
        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body 
                                        FROM EmailTemplate 
                                        WHERE Name = 'Graduate Research Scholarship Offer Email' LIMIT 1];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Loop through map and create an email for each
        for (Id acpId : mapAcpContact.keyset()) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            email.setTargetObjectId(mapAcpContact.get(acpId));  // Required for merge fields to work
            email.setTemplateId(emailTemplate.Id);
            email.setWhatId(acpId);  //acp record  
            email.setOrgWideEmailAddressId(orgWideAddress.Id);              
            emails.add(email);
        }

        // Send all emails in bulk
        Messaging.sendEmail(emails);
    }

    /**
     * @description finishing the batch and resetting the calendar inprogress flags
     * @param       BC
     */
    public void finish(Database.BatchableContext BC) {
         //enabling the triggers
        TriggerCommon.enableTrigger('Task');
        TriggerCommon.enableTrigger('EmailMessage');
        TriggerCommon.enableTrigger('Opportunity');
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.enable();

        Calendar__c calendar = [SELECT Domes_schol_round_publish_in_progress__c, Inter_schol_round_publish_in_progress__c FROM Calendar__c WHERE Id = :calendarId];
        
        //update the calendar in progress checks
        if(round == 'Domestic') {            
            calendar.Domes_schol_round_publish_in_progress__c = false;
        } else if(round == 'International') {
            calendar.Inter_schol_round_publish_in_progress__c = false;
        }
        
        try{
            update calendar;
        }
        catch(Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
        //chain the other batch jobs if there are more calendar rounds to publish
        if(lstCalendarRound != null && lstCalendarRound.size() > 0) {
            executeChainJob(lstCalendarRound);
        }
    }

    /**
     * @description execute the chaining of the batch if there are more than 1 calendar round to process
     * @param       lstCalendarRound
     */
    public void executeChainJob(List<GRScholarshipCalendarRound> lstCalendarRound) {
        Id calendar1 = lstCalendarRound[0].calendarId;
        String round1 = lstCalendarRound[0].round;
        lstCalendarRound.remove(0);
        Database.executeBatch(new GRScholarshipRoundPublishBatch(calendar1, round1, lstCalendarRound), 10);
    }

    /**
     * @description class for GRScholarshipCalendarRound 
     *              to pass the calendar id and round to the batch      
     */
    public class GRScholarshipCalendarRound {
        public Id calendarId;
        public String round;
        public GRScholarshipCalendarRound(Id calendarId, String round) {
            this.calendarId = calendarId;
            this.round = round;
        }
    }
    
}