/**
 * @description GrReleaseScholarshipOffer class release the offer from lwc quick action
 * @author      Vishal Gupta
 * @since       28.1.2025
 * @revision
 */
public with sharing class GrReleaseScholarshipOffer {
    public static Map<Id, Calendar__c> lstCalendarDates = new Map<Id, Calendar__c>(); 
    public static Map<Id, List<Application_Course_Preference__c>> lstCalendarWithACP;
    public static Map<Id, List<SBQQ__Quote__c>> lstCalendarWithQuotes;
    public static Map<Id, List<Opportunity>> lstCalendarWithOpportunityPublished;
    /**
     * @description get calendar dates for GR scholarship round
     * @param       round
     * @return      Map<Id, Calendar__c>
     */
    public static Map<Id, Calendar__c> fetchCalendars(String round)
    {
        Date scholarshipDateToConsider = Date.newInstance(2025,01,20);//we need to give a GR golive date so that we can filter the records accordingly
        
        // query the calendar
        // For International, query a list of all Calendar Records WHERE
        // Calendar Type ADM-RES1 or ADM-RES2, and
        // Published_Date_for_Inter_ScholarRound__c is empty, and
        // Calendar_Date__c’s Date Type Code under the calendar is “HDR-SCI-CL” is in the past
        
        // For Domestic, query a list of all Calendar Records WHERE
        // Calendar Type ADM-RES1 or ADM-RES2, and
        // Published_Date_for_Domes_ScholarRound__c is empty, and
        // Calendar_Date__c’s Date Type Code under the calendar is “HDR-SCH-CL” is in the past
        if(round == 'Domestic') {
            return new Map<Id, Calendar__c>([SELECT Id, Name, Year__c, Type__c, Published_Date_for_Domes_ScholarRound__c, Inter_schol_round_publish_in_progress__c, Domes_schol_round_publish_in_progress__c,
                    (SELECT Date_Value__c, Date_Type_Description__c FROM Calendar_Dates__r WHERE 
                    (Name = 'HDR-SCH-OP' OR (Name = 'HDR-SCH-CL' AND Date_Value__c < TODAY)) AND Date_Value__c >= :scholarshipDateToConsider) 
                    from Calendar__c WHERE Type__c in ('ADM-RES2','ADM-RES1') 
                    AND Id in (SELECT CalendarId__c FROM Calendar_Dates__c 
                    WHERE (Name = 'HDR-SCH-OP' OR (Name = 'HDR-SCH-CL' AND Date_Value__c < TODAY)) AND Date_Value__c >= :scholarshipDateToConsider) ORDER BY Published_Date_for_Domes_ScholarRound__c ASC]);       
        } else {
            return new Map<Id, Calendar__c>([SELECT Id, Name, Year__c, Type__c, Published_Date_for_Inter_ScholarRound__c, Inter_schol_round_publish_in_progress__c, Domes_schol_round_publish_in_progress__c, (SELECT Date_Value__c, Date_Type_Description__c FROM Calendar_Dates__r WHERE 
                    (Name = 'HDR-SCI-OP' OR (Name = 'HDR-SCI-CL' AND Date_Value__c < TODAY)) AND Date_Value__c >= :scholarshipDateToConsider) from Calendar__c WHERE Type__c in ('ADM-RES2','ADM-RES1') 
                    AND Id in (SELECT CalendarId__c FROM Calendar_Dates__c 
                    WHERE (Name = 'HDR-SCI-OP' OR (Name = 'HDR-SCI-CL' AND Date_Value__c < TODAY)) AND Date_Value__c >= :scholarshipDateToConsider) ORDER BY Published_Date_for_Inter_ScholarRound__c ASC]);
        }
    }

    /**
     * @description get fetch Calendar Rounds for GR scholarship
     * @param       round
     * @return      List<CalendarData>
     */
    @AuraEnabled
    public static Map<String, Object> fetchCalendarRounds(String round){
        Map<String, Object> resultMap = new Map<String, Object>();
        Set<Id> calendarIds = new Set<Id>();
        Set<Id> acpIds = new Set<Id>();
        lstCalendarWithACP = new Map<Id, List<Application_Course_Preference__c>>();
        lstCalendarWithQuotes = new Map<Id, List<SBQQ__Quote__c>>();
        lstCalendarWithOpportunityPublished = new Map<Id, List<Opportunity>>();
        List<CalendarData> lstCalendarData = new List<CalendarData>();
        if(round == 'Domestic') {
            lstCalendarDates = fetchCalendars('Domestic');
        } else if(round == 'International') {
            lstCalendarDates = fetchCalendars('International');
        }
        //form the calendar data to show on UI
        for(Calendar__c calendar : lstCalendarDates.values()) {
            CalendarData calendardata = new CalendarData();
            if(calendar.Calendar_Dates__r != null && calendar.Calendar_Dates__r.size() == 2) { //opening and closing date 
                calendarIds.add(calendar.Id);
                calendarData.calendarId = calendar.Id;
                calendarData.publishInProgress = (round == 'Domestic') ? calendar.Domes_schol_round_publish_in_progress__c : (round == 'International') ? calendar.Inter_schol_round_publish_in_progress__c : false;
                calendarData.calendarName = calendar.Name;
                calendarData.calendarType = calendar.Type__c;
                calendarData.calendarYear = calendar.Year__c;
                for(Calendar_Dates__c calendarDate : calendar.Calendar_Dates__r) {
                    if(calendarDate.Date_Type_Description__c.contains('OPENING DATE') && calendarDate.Date_Value__c != null) {
                        calendarData.openingDate = calendarDate.Date_Value__c;
                    } else if(calendarDate.Date_Type_Description__c.contains('CLOSING DATE')) {
                        calendarData.closingDate = calendarDate.Date_Value__c;
                    }
                }
                lstCalendarData.add(calendardata);
            }

        }

        //find the existing applications related to the calendar
        for(Application_Course_Preference__c acp : [SELECT Id, Scholarship_Calendar__c, Applicant__r.FirstName, Applicant__r.LastName, 
                                                    (SELECT Id FROM GraduateResearchOffers__r) FROM Application_Course_Preference__c 
                                                    WHERE Scholarship_Calendar__c IN :calendarIds 
                                                    AND Graduate_Research_Application_Type__c IN ('Admission and Scholarship','Scholarship')
                                                    AND Application__r.Citizenship_Classification__c = :round
                                                    AND GradRes_Callista_Id__c <> null]) {
            acpIds.add(acp.Id);
            if(lstCalendarWithACP.containsKey(acp.Scholarship_Calendar__c)) {
                lstCalendarWithACP.get(acp.Scholarship_Calendar__c).add(acp);
            } else {
                lstCalendarWithACP.put(acp.Scholarship_Calendar__c, new List<Application_Course_Preference__c>{acp});
            } 
        }
        if(!acpIds.isEmpty()) {
            //find the existing offers related to the applications
            for(Opportunity opp : [SELECT Id, Application_Course_Preference__r.Scholarship_Calendar__c, Application_Course_Preference__c, Offer_published_date__c, Offer_Type__c, Faculty_Sponsorship_Awarded__c, Faculty_Scholarship_Awarded__c,
                                        (SELECT Id, SBQQ__Status__c, SBQQ__Opportunity2__r.Application_Course_Preference__c, SBQQ__Opportunity2__r.Application_Course_Preference__r.Applicant__c, SBQQ__LineItemCount__c FROM SBQQ__Quotes2__r LIMIT 1) 
                                        FROM Opportunity WHERE Application_Course_Preference__c IN :acpIds]) {
                if(!opp.SBQQ__Quotes2__r.isEmpty()) {
                    //check either for central scholarship with line items or the faculty scholarship/sponsorship
                    if(opp.SBQQ__Quotes2__r[0].SBQQ__LineItemCount__c > 0 || opp.Faculty_Sponsorship_Awarded__c || opp.Faculty_Scholarship_Awarded__c) {
                        if(lstCalendarWithQuotes.containsKey(opp.Application_Course_Preference__r.Scholarship_Calendar__c)) {
                            lstCalendarWithQuotes.get(opp.Application_Course_Preference__r.Scholarship_Calendar__c).add(opp.SBQQ__Quotes2__r[0]);
                        } else {
                            lstCalendarWithQuotes.put(opp.Application_Course_Preference__r.Scholarship_Calendar__c, new List<SBQQ__Quote__c>{opp.SBQQ__Quotes2__r[0]});
                        }
                    }                                        
                }

                //adding opportunity with publihsed offer
                if(opp.Offer_published_date__c != null) {
                    if(lstCalendarWithOpportunityPublished.containsKey(opp.Application_Course_Preference__r.Scholarship_Calendar__c)) {
                        lstCalendarWithOpportunityPublished.get(opp.Application_Course_Preference__r.Scholarship_Calendar__c).add(opp);
                    } else {
                        lstCalendarWithOpportunityPublished.put(opp.Application_Course_Preference__r.Scholarship_Calendar__c, new List<Opportunity>{opp});
                    }
                }
            }
        }

        for(integer count = 0; count < lstCalendarData.size(); count++) {
            CalendarData cd = lstCalendarData[count];
            cd.numberOfApplications = lstCalendarWithACP.get(cd.calendarId) != null && !lstCalendarWithACP.get(cd.calendarId).isEmpty() ? lstCalendarWithACP.get(cd.calendarId).size() : 0;
            cd.numberOfApplicationsWithOffer = lstCalendarWithQuotes.get(cd.calendarId) != null && !lstCalendarWithQuotes.get(cd.calendarId).isEmpty() ? lstCalendarWithQuotes.get(cd.calendarId).size() : 0;
            cd.numberOfNoOffer = cd.numberOfApplications - cd.numberOfApplicationsWithOffer;
            cd.numberOfPublishedOffer = lstCalendarWithOpportunityPublished.get(cd.calendarId) != null && !lstCalendarWithOpportunityPublished.get(cd.calendarId).isEmpty() ? lstCalendarWithOpportunityPublished.get(cd.calendarId).size() : 0;
            cd.canBePublished = (cd.numberOfApplications > cd.numberOfPublishedOffer) && !cd.publishInProgress ? true : false;

            if(cd.numberOfApplications == 0) {
                lstCalendarData.remove(count);
            } 
            
        } 
        resultMap.put('calendarData', lstCalendarData);
        
        return resultMap;
    }

    /**
    * @description CalendarData to show on publish scholarship offer quick action screen
    * @author      Vishal Gupta
    * @since       28.1.2025
    * @revision
    */
    public class CalendarData {
        @AuraEnabled public String calendarId {get; set;}
        @AuraEnabled public String calendarName {get; set;}
        @AuraEnabled public String calendarType {get; set;}
        @AuraEnabled public String calendarYear {get; set;}
        @AuraEnabled public Date openingDate {get; set;}
        @AuraEnabled public Date closingDate {get; set;}
        @AuraEnabled public Integer numberOfApplications {get; set;}
        @AuraEnabled public Integer numberOfApplicationsWithOffer {get; set;}
        @AuraEnabled public Integer numberOfNoOffer {get; set;}
        @AuraEnabled public Integer numberOfPublishedOffer {get; set;}
        @AuraEnabled public Boolean canBePublished {get; set;}
        @AuraEnabled public Boolean publishInProgress {get; set;}
    }

    /**
     * @description publish the Scholarship Round for selected calendar
     * @param       calendarId
     * @param       round
     * @return      string
     */
    @AuraEnabled
    public static string publishScholarshipRound(Id calendarId, String round) {
        Calendar__c calendar = [SELECT Inter_schol_round_publish_in_progress__c, Domes_schol_round_publish_in_progress__c, 
                                Published_Date_for_Inter_ScholarRound__c, Published_Date_for_Domes_ScholarRound__c FROM Calendar__c WHERE Id = :calendarId];
        if(round == 'Domestic') {
            calendar.Domes_schol_round_publish_in_progress__c = true;
            calendar.Published_Date_for_Domes_ScholarRound__c = Date.Today();
        } else if(round == 'International') {
            calendar.Inter_schol_round_publish_in_progress__c = true;
            calendar.Published_Date_for_Inter_ScholarRound__c = Date.Today();
        }
        update calendar;
        
        return 'success';
    }
}