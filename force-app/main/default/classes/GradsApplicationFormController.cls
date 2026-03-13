/**
 * @description Controller class for the GradsApplicationForm LWC
 * @group       Grads
 * @revision    2025-01-12 - Tom Gangemi - Initial version
 * @revision    2025-08-21 - Tom Gangemi - Return all grad cals
 */
public with sharing class GradsApplicationFormController {

    /**
     * @description Student data returned for the application form
     */
    public class StudentData {
        // non cancelled applications by calendar code
        @AuraEnabled public Map<String,Id> appsByCalendarCode { get; set; }
        @AuraEnabled public List<Calendar__c> gradCalendars { get; set; }
        @AuraEnabled public String personId { get; set; }
    }

    /**
     * @description Application details for creating a new application
     */
    public class Application {
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String studentPersonId { get; set; }
        @AuraEnabled public Id calendarId { get; set; }
        @AuraEnabled public String studentTestamurName { get; set; }
        @AuraEnabled public String studentPersonalEmail { get; set; }
        @AuraEnabled public String additionalReqsStaff { get; set; }
        @AuraEnabled public String staffComments { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date lateApplicationDeadline { get; set; }
        @AuraEnabled public Boolean hasLateFeeWaiver { get; set; }
        @AuraEnabled public GradsAwardFormController.Award[] awards { get; set; }
    }

    @AuraEnabled(Cacheable=false)
    public static StudentData getStudentDataFromApp(Id appId) {
        return getStudentData([SELECT Student__c FROM Graduation_Application__c WHERE Id = :appId].Student__c);
    }

    @AuraEnabled(Cacheable=false)
    public static StudentData getStudentData(Id contactId) {
        StudentData data = new StudentData();
        data.personId = [SELECT Person_ID_unique__c FROM Contact WHERE Id = :contactId].Person_ID_unique__c;
        data.appsByCalendarCode = getExistingApplications(contactId);
        data.gradCalendars = getGradCalendars();
        return data;
    }

    @AuraEnabled(Cacheable=true)
    public static Calendar__c[] getGradCalendars() {
        return [
            SELECT Id, Calendar_Code__c, Description__c, Type__c, Year__c, End_Date__c
            FROM Calendar__c
            WHERE Category__c = 'Graduation'
            ORDER BY Year__c DESC, Type__c ASC
        ];
    }

    /**
     * @param contactId
     *
     * @return  Map of existing applications by calendar code
     */
    @AuraEnabled(Cacheable=false)
    public static Map<String,Id> getExistingApplications(Id contactId) {
        Map<String,Id> existingAppsByCalendar = new Map<String,Id>();
        for (Graduation_Application__c app : [
            SELECT Id, Graduation_Calendar__r.Calendar_Code__c
            FROM Graduation_Application__c
            WHERE Student__c = :contactId AND Status__c != 'Cancelled'
        ]) {
            existingAppsByCalendar.put(app.Graduation_Calendar__r.Calendar_Code__c, app.Id);
        }
        return existingAppsByCalendar;
    }

    /**
     * @param app  Application details to create
     *
     * @return  Id of the created application
     */
    @AuraEnabled
    public static Id createApplication(Application inputApp) {
        Calendar__c cal = [SELECT Type_Alt__c, Calendar_Code__c FROM Calendar__c WHERE Id = :inputApp.calendarId];
        GradsUtils.AppConfig ap = GradsUtils.getAppConfig();

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = inputApp.contactId,
            Graduation_Calendar__c = inputApp.calendarId,
            Late_Application_Deadline__c = inputApp.lateApplicationDeadline,
            Status__c = inputApp.status,
            Student_Testamur_Name__c = inputApp.studentTestamurName,
            Student_Personal_Email__c = inputApp.studentPersonalEmail,
            Unique_Key__c = GradsUtils.createApplicationUniqueKey(cal.Calendar_Code__c, inputApp.studentPersonId),
            Attendance_Mode__c = 'In Absentia',
            Staff_Comments__c = inputApp.staffComments,
            Additional_Reqs_Description_Staff__c = inputApp.additionalReqsStaff,
            Has_Late_Fee_Waiver__c = inputApp.hasLateFeeWaiver
        );
        for(GradsAwardFormController.Award award : inputApp.awards) {
            if(award.isAttendingCeremony) {
                app.Attendance_Mode__c = 'Attending';
            }
        }
        if(cal.Type_Alt__c == 'Clayton') {
            app.Expected_Attendance_Fee_Unit_Amount__c = ap.prices.attendanceAustralia;
        } else {
            app.Expected_Attendance_Fee_Unit_Amount__c = ap.prices.attendanceInternational;
        }

        try {
            insert app;
            GradsAwardFormController.createAwards(app.Id, inputApp.awards);
            return app.Id;
        } catch (Exception e) {
            Nebula.Logger.error('Error creating Graduation Application', e);
            Nebula.Logger.saveLog();
            // yibbida-yibbida
            throw e;
        }
    }

    /**
     * @description Search for contacts by name or Person ID
     * @param searchTerm       Name or PersonId to search for
     * @param isNumericSearch  True if searching by Person ID, otherwise search by Name
     *
     * @return List of matching contacts (Limited to 10)
     */
    @AuraEnabled(cacheable=false)
    public static List<Contact> searchContacts(String searchTerm, Boolean isNumericSearch) {
        if (String.isBlank(searchTerm)) {
            return new List<Contact>();
        }

        if (isNumericSearch) {
            // Exact match for Person_ID_Unique__c
            return [
                SELECT Id, Name, Person_ID_unique__c, Email, First_Name__c, Last_Name__c, Personal_Email__c
                FROM Contact
                WHERE Person_ID_unique__c = :searchTerm
                LIMIT 10
            ];
        } else {
            // SOSL search for name
            String formattedSearchTerm = '*' + searchTerm + '*';
            String searchQuery = 'FIND :formattedSearchTerm IN NAME FIELDS RETURNING ';
            searchQuery += 'Contact(Id, Name, Person_ID_unique__c, Email, First_Name__c, Last_Name__c, Personal_Email__c ';
            searchQuery += 'WHERE Person_ID_unique__c != NULL ORDER BY Name LIMIT 10)';

            List<List<SObject>> searchResults = Search.query(searchQuery);

            if (!searchResults.isEmpty() && !searchResults[0].isEmpty()) {
                return searchResults[0];
            }
            return new List<Contact>();
        }
    }

    @AuraEnabled(cacheable=false)
    public static void setApplicationCalendar(Id appId, Id calendarId) {
        Graduation_Application__c app = [SELECT Student_Person_Id__c FROM Graduation_Application__c WHERE Id = :appId];
        Calendar__c cal = [SELECT Calendar_Code__c FROM Calendar__c WHERE Id = :calendarId];
        app.Graduation_Calendar__c = calendarId;
        app.Unique_Key__c = GradsUtils.createApplicationUniqueKey(cal.Calendar_Code__c, app.Student_Person_Id__c);
        update app;
    }

    public class EligibilityApiResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public String jsonBody { get; set; }
    }

    @AuraEnabled(cacheable=false)
    public static EligibilityApiResponse getStudentEligibilityDetails(String studentId) {
        GradsCallistaCalloutService.EligibilityCalloutResult eligibility = GradsCallistaCalloutService.getEligibility(
            studentId
        );

        EligibilityApiResponse response = new EligibilityApiResponse();
        response.success = eligibility.success;
        response.errorMessage = eligibility.errorMessage;
        response.jsonBody = eligibility.response?.getBody();

        return response;
    }

    @AuraEnabled(cacheable=false)
    public static EligibilityApiResponse getAppEligibilityDetails(Id appId) {
        Graduation_Application__c app = [SELECT Student_Person_Id__c FROM Graduation_Application__c WHERE Id = :appId];
        return getStudentEligibilityDetails(app.Student_Person_Id__c);
    }

}