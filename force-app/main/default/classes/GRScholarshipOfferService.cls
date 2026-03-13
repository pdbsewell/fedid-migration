/**
 * @description GRScholarshipOfferService class to read response of Platform event for GR Scholarship offer
 * @author      Vishal Gupta
 * @since       9.1.2025
 * @revision
 */
public with sharing class GRScholarshipOfferService {
    public static Opportunity existingOpportunity;
    public static SBQQ__Quote__c existingQuote;
    public static Map<String, SBQQ__QuoteLine__c> mapExistingQuoteLine = new Map<String, SBQQ__QuoteLine__c>();
    public static String offerPayload;

    /**
    * @description function to parse the JSON response of scholarship offer
    * @param json
    */
    public static void parseJson(String json){
        offerPayload = json;
		GRScholarshipOfferJSON scholarShipJson = (GRScholarshipOfferJSON)System.JSON.deserialize(json, GRScholarshipOfferJSON.class);

        String smsContactId = scholarShipJson.Scholarship?.applicationDetails?.applicant?.smsContactId;
        String responseStatus = scholarShipJson.Scholarship?.responseStatus;
        String quoteStatus;
        String hdrApplicationId = scholarShipJson.Scholarship?.applicationDetails?.application?.hdrApplicationDetails?.hdrApplicationNumber;
        GRScholarshipOfferJSON.AcademicOrgUnit aou = scholarShipJson.Scholarship?.applicationDetails?.application?.hdrApplicationDetails?.academicOrgUnit;
        String academicOrgUnitCallistaId = aou?.id;
        try{
            if(String.isNotBlank(smsContactId) && String.isNotBlank(hdrApplicationId)) {            
                //fetch the application course preference via hdrApplicationId
                List<Application_Course_Preference__c> lstACP = new ApplicationCoursePreferenceSelector().selectByApplicantIdWithCalendarDetails(new Set<String>{smsContactId}, new Set<String>{hdrApplicationId});
                if(!lstACP.isEmpty()) {
                    List<Account> lstAcademicOrgUnit;
                    //fetch the academic org unit
                    if(String.isNotBlank(academicOrgUnitCallistaId)) {
                        lstAcademicOrgUnit = [SELECT Id FROM Account WHERE Callista_Org_Unit_Code__c = :academicOrgUnitCallistaId LIMIT 1];
                    }
                    
                    //update the academic org unit in ACP
                    updateAcademicOrgUnit(lstAcademicOrgUnit, lstACP[0]);

                    // fetch the scholarship opportunity and quote if exists
                    List<Opportunity> lstExistingOpp = new OpportunitiesSelector().selectScholarshipOpportunityByACPId(new Set<Id>{lstACP[0].Id});
                    //get the existing quote and opportunity
                    getExistingQuoteAndOpportunity(lstExistingOpp);
                    
                    //get existing quotelineitems
                    getExistingQuoteLines();

                    String oppName = lstACP[0].Applicant__r.FirstName + ' ' + lstACP[0].Applicant__r.LastName + '-GRSS-'+ String.valueOf(Date.Today());
                    //upsert the opportunity
                    Opportunity opp = upsertOpportunity(oppName, lstACP[0].Applicant__c, lstACP[0].Applicant__r.AccountId, lstACP[0].Id, scholarShipJson.Scholarship);
                    upsert opp;

                    //get the quote status based on the response status
                    quoteStatus = getQuoteStatus(responseStatus, lstACP[0]);

                    //upsert the quote
                    SBQQ__Quote__c quote = upsertQuote(opp.Id, null, quoteStatus, scholarShipJson.Scholarship?.offerLapseDate);
                    upsert quote;

                    //upsert quote lines
                    upsertQuoteLines(quote.Id, lstACP[0].Course__c, scholarShipJson.Scholarship);
                }                        
            } else {
                Nebula.Logger.error('Unable to find the applicant').addTag('GRScholarshipOfferService');
                //throw exception
                throw new GRScholarshipOfferServiceException('Unable to find the applicant.');
            }
        }
        catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex).addTag('GRScholarshipOfferService');
        }    
        Nebula.Logger.saveLog();
	}

    /**
    * @description update the academic org unit in ACP
    * @param lstAcademicOrgUnit
    * @param acp
    */
    private static void updateAcademicOrgUnit(List<Account> lstAcademicOrgUnit, Application_Course_Preference__c acp) {
        if(lstAcademicOrgUnit != null) {
            //update the ACP's academic org unit
            acp.Academic_Org_Unit__c = lstAcademicOrgUnit[0].Id;
            update acp;
        }
    }

    /**
    * @description get existing quotelineitems
    */
    private static void getExistingQuoteLines() {
        if(existingQuote != null) {
            // fetch the quote line if exists
            for(SBQQ__QuoteLine__c existingQuoteLine : new QuoteLinesSelector().selectByQuoteId(new Set<Id>{existingQuote.Id})) {
                mapExistingQuoteLine.put(existingQuoteLine.Scholarship_Type__c, existingQuoteLine);
            }
        } 
    }

    /**
    * @description get the existing quote and opportunity
    * @param lstExistingOpp
    */
    private static void getExistingQuoteAndOpportunity(List<Opportunity> lstExistingOpp) {
        if(!lstExistingOpp.isEmpty()) {
            existingOpportunity = lstExistingOpp[0];
            if(existingOpportunity.SBQQ__Quotes2__r != null && !existingOpportunity.SBQQ__Quotes2__r.isEmpty()) {                        
                existingQuote = existingOpportunity.SBQQ__Quotes2__r[0];
            }
        }
    }

    /**
    * @description get the quote status based on the response status
    * @param responseStatus
    */
    private static String getQuoteStatus(String responseStatus, Application_Course_Preference__c acp) {
        String quoteStatus;
        //get the quote status based on the response status
        if(responseStatus == 'emptyOrNull') {
            quoteStatus = (acp.Scholarship_Calendar__r.Published_Date_for_Inter_ScholarRound__c != NULL || acp.Scholarship_Calendar__r.Published_Date_for_Domes_ScholarRound__c != NULL) ?
                                'Offered' : 'In Review';
        } else if(responseStatus == 'Accepted') {
            quoteStatus = 'Accepted';
        } else if(responseStatus == 'Declined') {
            quoteStatus = 'Declined';
        } else if(responseStatus == 'Lapsed') {
            quoteStatus = 'Expired';
        }
        return quoteStatus;
    }

    /**
    * @description function to upsert the opportunity for GR Scholarship offer
    * @param oppName
    * @param acpId
    * @return Opportunity
    * @param scholarship
    */
    public static Opportunity upsertOpportunity(String oppName, Id contactId, Id accountId, Id acpId, GRScholarshipOfferJSON.Scholarship scholarship) {
        Id gradResecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Graduate_Research_Offer').getRecordTypeId(); 
        Opportunity opp = new Opportunity();
        if(existingOpportunity != null) {
            opp.Id = existingOpportunity.Id;
        }
        if(offerPayload != null) {
            opp.Offer_Request_Payload__c = offerPayload;
        }
        opp.Name = oppName;
        opp.PrimaryContact__c = contactId;
        opp.AccountId = accountId;
        opp.Application_Course_Preference__c = acpId;
        opp.RecordTypeId = gradResecordTypeId;
        opp.StageName = 'New Offer';
        opp.Research_Offer_Type__c = 'Scholarship Offer';
        if(scholarship != null) {
            opp.CloseDate = String.isNotBlank(scholarship.offerLapseDate) ? Date.valueOf(scholarship.offerLapseDate) : Date.today().addDays(-1);
            opp.Offer_End_Date__c = String.isNotBlank(scholarship.offerLapseDate) ? Date.valueOf(scholarship.offerLapseDate) : Date.today().addDays(-1);      
            opp.Faculty_Scholarship_Awarded__c = scholarship.hasFacultyScholarshipAwarded;
            opp.Faculty_Sponsorship_Awarded__c = scholarship.hasFacultySponsorshipAwarded;
            opp.Offer_Type__c = scholarship.offerStatus; 
            if(scholarship.offerStatus == 'REJECTED' && !opp.Faculty_Scholarship_Awarded__c && !opp.Faculty_Sponsorship_Awarded__c) {
                //NO-OFFER will only be considered if there is no FacultyScholarshipAwarded & no FacultySponsorshipAwarded
                setNoOffer(opp);
            }
        } else {
            setNoOffer(opp);
        }
        
        return opp;
    }

    /**
    * @description function to return no offer opportunity 
    * @param opp
    * @return Opportunity
    */
    private static Opportunity setNoOffer(Opportunity opp) {
        opp.Offer_Type__c = 'NO-OFFER';
        opp.CloseDate = Date.today().addDays(-1);
        return opp;
    }

    /**
    * @description function to upsert the quote for GR Scholarship offer
    * @param oppId
    * @param status
    * @param offerLapseDate
    * @return Id
    */
    public static SBQQ__Quote__c upsertQuote(Id oppId, Id contactId, String status, String offerLapseDate) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        if(existingQuote != null) {
            quote.Id = existingQuote.Id;
        }
        if(contactId != null) {
            quote.Contact_Access__c = contactId;
            quote.SBQQ__PrimaryContact__c = contactId;
            quote.SBQQ__Primary__c = true;
        }
        quote.SBQQ__Opportunity2__c = oppId;
        if(String.isNotBlank(status)) {
            quote.SBQQ__Status__c = status;
        }
        quote.SBQQ__ExpirationDate__c = String.isNotBlank(offerLapseDate) ? Date.valueOf(offerLapseDate) : Date.Today();
        quote.Is_GR_Offer__c = true;
        return quote;
    }

    /**
    * @description function to set the value to publish the opportunity
    * @param opp
    */
    public static Opportunity publishOpportunity(Opportunity opp) {
        opp.Offer_published_date__c = Date.Today(); 
        return opp;
    }

    /**
    * @description function to set the value to publish the quote
    * @param quote
    */
    public static SBQQ__Quote__c publishQuote(SBQQ__Quote__c quote) {
        quote.SBQQ__Status__c = 'Offered';
        quote.Contact_Access__c = quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Applicant__c;
        quote.SBQQ__PrimaryContact__c = quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Applicant__c;
        quote.SBQQ__Primary__c = true;
        return quote;
    }

    /**
    * @description function to upsert the quote line for GR Scholarship offer
    * @param quoteId
    * @param courseId
    * @param scholarship
    */
    private static void upsertQuoteLines(Id quoteId, Id courseId, GRScholarshipOfferJSON.Scholarship scholarship) {
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        for(GRScholarshipOfferJSON.ScholarshipAwards awards : scholarship.scholarshipAwards) {
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
            if(!mapExistingQuoteLine.isEmpty() && mapExistingQuoteLine.containsKey(awards.scholarshipType)) {
                quoteLine.Id = mapExistingQuoteLine.get(awards.scholarshipType).Id;
                mapExistingQuoteLine.remove(awards.scholarshipType);//removing the item from the map so that we can deactivate the existing quote line with no updates
            }else {
                quoteLine.SBQQ__Quote__c = quoteId;//for master detail relationship, this field cant be updated if quote line already exisit
            }            
            quoteLine.Course__c = courseId;
            quoteLine.Scholarship_Type__c = awards.scholarshipType;
            quoteLine.Scholarship_Name__c = awards.scholarshipName;
            quoteLine.Scholarship_Value__c = String.isNotBlank(awards.value) ? Decimal.valueOf(awards.value) : null;
            quoteLine.Scholarship_Value_Range__c = awards.valueRange;
            quoteLine.Scholarship_Value_Year__c = awards.valueYear;
            quoteLine.Scholarship_Previous_Value__c = String.isNotBlank(awards.previousValue) ? Decimal.valueOf(awards.previousValue) : null;
            quoteLine.Scholarship_Previous_Value_Range__c = awards.previousValueRange;
            quoteLine.Scholarship_Previous_Value_Year__c = awards.previousValueYear;
            quoteLine.Additional_Clause_Notes__c = awards.conditionText;
            quoteLines.add(quoteLine);
        }
        if(!mapExistingQuoteLine.isEmpty()) {
            for(SBQQ__QuoteLine__c existingQuoteLine : mapExistingQuoteLine.values()) {
                existingQuoteLine.Scholarship_Deactivated__c = true;
                quoteLines.add(existingQuoteLine);
            }
        }
        
        upsert quoteLines;
    }

    /**
    * @description GRScholarshipOfferService exception class
    */
    public class GRScholarshipOfferServiceException extends Exception {}
}