/**
 * @description GrScholarshipViewOfferController class to show Scholarship offer details
 * @author      Vishal Gupta
 * @since       3.2.2025
 * @revision
 */
public with sharing class GrScholarshipViewOfferController {
    private static final String PENDING = 'PENDING';
    private static final String OFFER = 'OFFER';
    private static final String COND_OFFER = 'COND-OFFER';

    //enum for switch case constants
    private enum ENUMConstants {PENDING, OFFER, COND_OFFER}
    //map for constants used for switch case statements
    private static Map<String, ENUMConstants> constantsMap = new Map<String, ENUMConstants> {
        PENDING => ENUMConstants.PENDING,
        OFFER => ENUMConstants.OFFER,
        COND_OFFER => ENUMConstants.COND_OFFER
    };
    
    /**
    * @description function to fetch offer quote
    * @param quoteId
    * @return SBQQ__Quote__c
    */
    @AuraEnabled
    public static QuoteData fetchQuote(String quoteId){
        try {
            QuoteData qd = new QuoteData();
            qd.quote = new QuotesSelector().selectQuoteAndLineItemsById(new Set<String>{quoteId})[0];
            List<Calendar_Dates__c> dates = [SELECT Date_Value__c, Name FROM Calendar_Dates__c WHERE 
                                            CalendarId__c = :qd.quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Scholarship_Calendar__c AND
                                            Name IN ('HDR-SCH-AA', 'HDR-SCI-AA') LIMIT 2];
            //get the scholarshipApplicationDueDate based on 'HDR-SCH-AA', 'HDR-SCI-AA' calendar dates
            qd.scholarshipApplicationDueDate = getCalendarDate(dates, qd.quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__r.Citizenship_Classification__c);
            // get the scholarship round published date
            qd.scholarshipPublishedDate = getSholarshipPublishedDate(qd.quote, qd.quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__r.Citizenship_Classification__c);
            //get the Application Course Status for Scholarship only application
            qd.scholOnlyApplicationCourseStatus = getApplicationCourseStatus(qd.quote);
            qd.lineItemsDescription = new List<String>();
            qd.lineItemsConditions = new Set<String>();
            //get the quote line item description
            for(SBQQ__QuoteLine__c ql : qd.quote.SBQQ__LineItems__r) {
                qd.lineItemsDescription.add(getLineItemDescription(ql));
                if(!String.isBlank(ql.Additional_Clause_Notes__c)) {
                    qd.lineItemsConditions.add(ql.Additional_Clause_Notes__c);
                }
                if(ql.Scholarship_Type__c == 'APA' && ql.Scholarship_Value_Year__c != null && ql.Scholarship_Value_Range__c != null) {
                    qd.rtpStipendYearValueRange = 'In ' + ql.Scholarship_Value_Year__c + ' the estimated annual value of Australian Government support for an RTP Fees Offset is in the range of ' + ql.Scholarship_Value_Range__c;
                } else if(ql.Scholarship_Type__c == 'APA' && ql.Scholarship_Previous_Value_Year__c != null && ql.Scholarship_Previous_Value_Range__c != null) {
                    qd.rtpStipendYearValueRange = 'In ' + ql.Scholarship_Previous_Value_Year__c + ' the estimated annual value of Australian Government support for an RTP Fees Offset is in the range of ' + ql.Scholarship_Previous_Value_Range__c;
                }
            }
            //are there any conditions with the offer
            qd.isConditionalOffer = qd.lineItemsConditions != null && qd.lineItemsConditions.size() > 0 ? true : false;
            
            qd.isOfferAcceptedOrDeclined = qd.quote.SBQQ__Status__c == 'Accepted' || qd.quote.SBQQ__Status__c == 'Declined' ? true : false;
            
            qd.isOfferReadyToAcceptDecline = qd.quote.SBQQ__Status__c == 'New' || qd.quote.SBQQ__Status__c == 'In Review' || qd.quote.SBQQ__Status__c == 'Offered' ? true : false;

            //duration of scholarship description based on the Course Code - 02
            qd.durationOfScholarship = qd.quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Course__r.Sub_Level__c == '02' ? 
                                        '3 years 6 months equivalent full-time (less any periods of prior study undertaken towards the degree).':
                                        '2 years equivalent full-time (less any periods of prior study undertaken towards the degree).';
            
            return qd;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description get the quote line item description for the offer
    * @param ql
    * @return String
    */
    private static String getLineItemDescription(SBQQ__QuoteLine__c ql) {
        String description = '';
        List<String> internationalScholarshipType = new List<String>{'IPRS', 'MIPRS', 'VMIPRS'};
        description = ql.Scholarship_Name__c + ': ';
        if(internationalScholarshipType.contains(ql.Scholarship_Type__c)) {
            description = description + 'covers International course fees and Overseas Student Health Cover (OSHC) - single cover only ';
        } else {
            description = description + 'stipend paid in fortnightly instalments to assist with living expenses ';
        }

        if(ql.Scholarship_Value__c != null) {
            description = description +'- AUD $'+ (ql.Scholarship_Value__c.format());
        } else if(ql.Scholarship_Previous_Value__c != null) {
            description = description +'- AUD $'+ (ql.Scholarship_Previous_Value__c.format());
        }

        if(ql.Scholarship_Value_Year__c != null) {
            description = description +' ('+ String.valueOf(ql.Scholarship_Value_Year__c) + ' annual full-time rate)';
        } else if(ql.Scholarship_Previous_Value_Year__c != null) {
            description = description +' ('+ String.valueOf(ql.Scholarship_Previous_Value_Year__c) + ' annual full-time rate)';
        }
        return description;
    }
    
    /**
    * @description get the calendar date HDR-SCH-AA(Domestic) or HDR-SCI-AA(international)
    * @param dates
    * @param classification
    * @return Date
    */
    private static Date getCalendarDate(List<Calendar_Dates__c> dates, String classification){
        for(Calendar_Dates__c cd : dates) {
            if(classification == 'Domestic' && cd.Name == 'HDR-SCH-AA') {
                return cd.Date_Value__c;
            } else if(classification == 'International' && cd.Name == 'HDR-SCI-AA') {
                return cd.Date_Value__c;
            }
        }
        return Date.Today();
    }

    /**
    * @description get the date when the scholarship round was published
    * @param quote
    * @param classification
    * @return Date
    */
    private static Date getSholarshipPublishedDate(SBQQ__Quote__c quote, String classification){
        if(classification == 'Domestic') {
            return quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Scholarship_Calendar__r.Published_Date_for_Domes_ScholarRound__c;
        } else if(classification == 'International') {
            return quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Scholarship_Calendar__r.Published_Date_for_Inter_ScholarRound__c;
        }
        return Date.Today();
    }

    /**
    * @description Application Course Status for Scholarship only application
    * @param quote
    * @return String
    */
    private static String getApplicationCourseStatus(SBQQ__Quote__c quote){

        if(quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Graduate_Research_Application_Type__c == 'Admission and Scholarship') {
            ENUMConstants constants = constantsMap.get(quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Outcome_Status_LOV__r?.System_Code__c);
            switch on constants {
                when PENDING {
                    return 'Please note that your application for admission is currently in progress. Your offer of admission will be issued as soon as all necessary approvals have been obtained from your academic unit and faculty.';
                }
                when OFFER, COND_OFFER {
                    return 'Offered';
                }
                when else {	
                    return quote.SBQQ__Opportunity2__r.Application_Course_Preference__r.Outcome_Status_LOV__r?.System_Code__c;
                }
            }
        }
        return '';
    }

    /**
     * @description update the objects without sharing settings
     * @param objData
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> updateRecord(sObject objData, String applicationId, String applicantId, String quoteId){
        Map<String,Object> objResults = new Map<String,Object>();
        try {
            String offerStatus;
            Boolean continueCandidatureWithoutScholarshipFlag;
            String oppId;
            Schema.SObjectType objectName = (objData.Id).getSObjectType();
            if(objectName == Application__c.SObjectType) {
                Application__c app = (Application__c) objData;
                offerStatus = 'REJECTED';
                continueCandidatureWithoutScholarshipFlag = app.Proceed_without_scholarship__c == 'Yes' ? true : false;
                //send the response to callista
                EventBus.publish(GRScholarshipOfferResponseService.formAsyncPayload(
                    quoteId,
                    applicationId,
                    applicantId,
                    offerStatus,
                    null,
                    null,
                    continueCandidatureWithoutScholarshipFlag
                ));
            } else {
                SBQQ__Quote__c quote = (SBQQ__Quote__c) objData;
                oppId = quote.SBQQ__Opportunity2__c;
                //response sync to callista from quote will be fired from the quote trigger. 
            }
            Database.upsert(objData);
           
            objResults.put('success', 'successfully update');
            Nebula.Logger.info('updateRecord msg: updated the record successfully').addTag('GrScholarshipViewOfferController');
        } catch(exception ex) {
            objResults.put('error', ex.getMessage());
            Nebula.Logger.error(ex.getMessage(), ex).addTag('GrScholarshipViewOfferController');
        }
        Nebula.Logger.saveLog();
        return objResults;
    }

    public class QuoteData {
        @AuraEnabled public SBQQ__Quote__c quote {get; set;}
        @AuraEnabled public Date scholarshipApplicationDueDate {get; set;}
        @AuraEnabled public Date scholarshipPublishedDate {get; set;}
        @AuraEnabled public Boolean isConditionalOffer {get; set;}
        @AuraEnabled public Boolean isOfferAcceptedOrDeclined {get; set;}
        @AuraEnabled public Boolean isOfferReadyToAcceptDecline {get; set;}
        @AuraEnabled public List<String> lineItemsDescription {get; set;}
        @AuraEnabled public Set<String> lineItemsConditions {get; set;}
        @AuraEnabled public String durationOfScholarship {get; set;}
        @AuraEnabled public String rtpStipendYearValueRange {get; set;}
        @AuraEnabled public String scholOnlyApplicationCourseStatus {get; set;}
    }
}