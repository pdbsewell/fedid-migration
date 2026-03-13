/**
 * @description Controller for the Graduation Award Form Lightning Web Component
 * @group       Grads
 * @revision    2024-11-12 - Tom Gangemi - Initial version
 *
 */
public with sharing class GradsAwardFormController {

    public class Application {
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Boolean hasPaymentPendingState { get; set; }
        @AuraEnabled public String paymentPendingStateExpiry { get; set; }
    }

    /**
     * Award data class for passing back and forth between LWC and Apex
     */
    public class Award {
        @AuraEnabled public Id existingRecordId { get; set; }
        @AuraEnabled public String existingRecordName { get; set; }
        @AuraEnabled public Boolean isCurrentRecord { get; set; }
        @AuraEnabled public Boolean onlyExistsInCallista { get; set; }

        @AuraEnabled public String transactionNumber { get; set; }
        @AuraEnabled public String awardTypeIndicator { get; set; }
        @AuraEnabled public String courseCode { get; set; }
        @AuraEnabled public String awardCourseCode { get; set; }
        @AuraEnabled public Integer awardCourseVersionNumber { get; set; }
        @AuraEnabled public String awardCourseTitle { get; set; }
        @AuraEnabled public String awardCode1 { get; set; }
        @AuraEnabled public String awardTitle1 { get; set; }
        @AuraEnabled public String awardCode2 { get; set; }
        @AuraEnabled public String awardTitle2 { get; set; }
        @AuraEnabled public String receiptNumber { get; set; }
        @AuraEnabled public Boolean isCancelled { get; set; }

        @AuraEnabled public Integer courseVersionNumber { get; set; }
        @AuraEnabled public String courseTitle { get; set; }
        @AuraEnabled public Boolean hasFeeWaiver { get; set; }

        // Fields only used for input (new awards)
        @AuraEnabled public Boolean isAttendingCeremony { get; set; }
        @AuraEnabled public String staffComments { get; set; }

        public Award(GradsCallistaCalloutService.EligibilityGraduationAvailableSelection gas, GradsCallistaCalloutService.EligibilityCourseAttempt eca) {
            this.awardTypeIndicator = gas.awardDetails.awardTypeIndicator;
            this.courseCode = eca.courseCode;
            this.awardCourseCode = gas.awardDetails.awardCourseCode;
            this.awardCourseVersionNumber = gas.awardDetails.awardCourseVersionNumber;
            this.awardCourseTitle = gas.awardDetails.awardCourseTitle;
            this.awardCode1 = gas.awardDetails.awardCode1;
            this.awardTitle1 = gas.awardDetails.awardTitle1;
            this.awardCode2 = gas.awardDetails.awardCode2;
            this.awardTitle2 = gas.awardDetails.awardTitle2;
            this.courseVersionNumber = eca.courseVersionNumber;
            this.courseTitle = eca.courseTitle;
        }

        public Award(Graduation_Award__c record) {
            this.transactionNumber = record.Callista_Transaction_Number__c;
            this.awardTypeIndicator = GradsUtils.getCallistaAwardType(record.Award_Type__c);
            this.courseCode = record.Course_Code__c;
            this.awardCourseCode = record.Award_Course_Code__c;
            this.awardCourseVersionNumber = Integer.valueOf(record.Award_Course_Version__c);
            this.awardCourseTitle = record.Award_Course_Title__c;
            this.awardCode1 = record.Award_Code_1__c;
            this.awardTitle1 = record.Award_Title_1__c;
            this.awardCode2 = record.Award_Code_2__c;
            this.awardTitle2 = record.Award_Title_2__c;
            this.courseVersionNumber = Integer.valueOf(record.Course_Version_Number__c);
            this.courseTitle = record.Course_Title__c;
            this.receiptNumber = record.Receipt_Number_External_System__c;
            this.isCancelled = record.Cancellation_Date__c != null && (record.Cancellation_Succeeded__c || String.isBlank(record.Callista_Transaction_Number__c));
        }

        public Award() {}
    }

    /**
     * Container for all form data
     */
    public class AwardFormData {
        @AuraEnabled public Award[] awards;
        @AuraEnabled public Application application;
        @AuraEnabled public Map<String,String[]> courseWarnings = new Map<String,String[]>();
        @AuraEnabled public Award currentAward;
        @AuraEnabled public String personId;
        @AuraEnabled public String formType; // 'application' or 'award'
    }

    /**
     * Retrieves form data for either a Graduation Application or Award
     * @param recordOrStudentId The Id of the record or the Person ID of the student
     * @return AwardFormData containing awards and related information
     * @throws AuraHandledException if eligibility check fails
     */
    @AuraEnabled
    public static AwardFormData getFormData(String recordOrStudentId) {
        Id recordId;
        String personId;
        try {
            // if it is an Id, get the Person ID from the record
            recordId = (Id)recordOrStudentId;
            personId = getPersonId(recordId);
        } catch (Exception e) {
            // if it is not an Id, assume it is a Person ID
            personId = recordOrStudentId;
        }

        if(personId == null) throw new AuraHandledException('UniCRM data not found');

        String formType = recordId?.getSobjectType() == Graduation_Award__c.SObjectType ? 'award' : 'application';

        AwardFormData formData = getStudentsAwards(personId, recordId);
        formData.personId = personId;
        formData.formType = formType;

        if(recordId != null) {
            if(formType == 'application') {
                Graduation_Application__c app = [
                    SELECT Status__c, Payment_Pending_State__c, Payment_Pending_State_Expiry__c
                    FROM Graduation_Application__c WHERE Id = :recordId
                ];
                formData.application = new Application();
                formData.application.status = app.Status__c;
                formData.application.hasPaymentPendingState = String.isNotBlank(app.Payment_Pending_State__c) &&
                    (app.Payment_Pending_State_Expiry__c == null || app.Payment_Pending_State_Expiry__c > Datetime.now());
                formData.application.paymentPendingStateExpiry = app.Payment_Pending_State_Expiry__c?.format();
            } else {
                formData.application = new Application();
                formData.application.status = [
                    SELECT Graduation_Application__r.Status__c
                    FROM Graduation_Award__c WHERE Id = :recordId
                ].Graduation_Application__r.Status__c;
            }
        }

        return formData;
    }

    /**
     * Retrieves the Person ID of the student from a Graduation_Application__c or Graduation_Award__c
     */
    private static String getPersonId(Id recordId) {
        if (recordId.getSobjectType() == Graduation_Application__c.SObjectType) {
            return [
                SELECT Student_Person_Id__c FROM Graduation_Application__c WHERE Id = :recordId
            ]?.Student_Person_Id__c;
        } else if (recordId.getSobjectType() == Graduation_Award__c.SObjectType) {
            return [
                SELECT Graduation_Application__r.Student_Person_Id__c FROM Graduation_Award__c WHERE Id = :recordId
            ]?.Graduation_Application__r.Student_Person_Id__c;
        }
        throw new AuraHandledException('Invalid record sobject type');
    }

    private static String[] getCourseWarningText(GradsCallistaCalloutService.EligibilityCourseAttempt ca) {
        String[] warnings = new String[0];
        if(ca.meetCPRequirement == 'N') {
            warnings.add('Credit point requirement not met');
        }
        if(ca.meetCourseStatusRequirement == 'N') {
            warnings.add('Course status requirement not met');
        }
        if(ca.graduateStudentIndicator == 'N') {
            warnings.add('Student not eligible to graduate');
        }
        if(ca.graduateModuleEnabled == 'N') {
            warnings.add('Graduate module not enabled');
        }
        return warnings;
    }

    /**
     * Retrieves awards for student from CRM and Eligibility API
     * @param personId The Person ID of the student
     * @param awardId The Id of the award to highlight
     * @return AwardFormData
     */
    private static AwardFormData getStudentsAwards(String personId, Id awardId) {
        if (personId == null) return null;

        AwardFormData formData = new AwardFormData();
        formData.awards = new List<Award>();

        // Get awards from CRM - Create a key for each award to match with Eligibility API data
        Map<String, Graduation_Award__c> awardsByKey = new Map<String, Graduation_Award__c>();
        for (Graduation_Award__c ga : [
            SELECT Name, Course_Code__c, Course_Title__c, Award_Type__c, Award_Course_Code__c,
                Course_Version_Number__c, Award_Course_Version__c, Award_Course_Title__c,
                Award_Code_1__c, Award_Title_1__c, Award_Code_2__c, Award_Title_2__c,
                Callista_Transaction_Number__c, Receipt_Number_External_System__c,
                Cancellation_Date__c, Cancellation_Succeeded__c
            FROM Graduation_Award__c
            WHERE Graduation_Application__r.Student__r.Person_ID_unique__c = :personId AND Cancellation_Date__c = NULL
        ]) {
            awardsByKey.put(
                createAwardKey(ga.Course_Code__c, ga.Award_Course_Code__c, ga.Award_Code_1__c, ga.Award_Code_2__c),
                ga
            );

            if(awardId != null && ga.Id == awardId) {
                formData.currentAward = new Award(ga);
            }
        }

        // Get awards from Eligibility API
        GradsCallistaCalloutService.EligibilityCalloutResult eligibility = GradsCallistaCalloutService.getEligibility(personId);
        if (!eligibility.success) {
            if (eligibility.ex != null) {
                throw eligibility.ex;
            }
            throw new AuraHandledException('Eligibility API error: ' + eligibility.errorMessage);
        }

        if(eligibility.eligibilityDetails == null || eligibility.eligibilityDetails.courseAttempts == null) {
            throw new AuraHandledException('No course attempts found');
        }

        // Create return data from mix of Existing Awards and Eligibility API data
        for (GradsCallistaCalloutService.EligibilityCourseAttempt ca : eligibility.eligibilityDetails.courseAttempts) {
            if (ca.graduationAvailableSelections == null) continue;

            String[] warnings = getCourseWarningText(ca);
            if(warnings.size() > 0) {
                formData.courseWarnings.put(ca.courseCode, warnings);
            }

            // Create a lookup of existing applications from the Eligibility API data
            Map<String,String> callistaExistingAppsByAwardKey = new Map<String,String>();
            if(ca.graduationApplications != null) {
                for (GradsCallistaCalloutService.EligibilityGraduationApplication ga : ca.graduationApplications) {
                    GradsCallistaCalloutService.EligibilityAppAward aa = ga.awardDetails;
                    callistaExistingAppsByAwardKey.put(
                        createAwardKey(ca.courseCode, aa.awardCourseCode1, aa.awardCode1, aa.awardCode2),
                        ga.transactionNo
                    );
                }
            }

            for (GradsCallistaCalloutService.EligibilityGraduationAvailableSelection gas : ca.graduationAvailableSelections) {
                // For each available award from Eligibility API
                Award award = new Award(gas, ca);

                String key = createAwardKey(award.courseCode, award.awardCourseCode, award.awardCode1, award.awardCode2);
                Graduation_Award__c existingCrmAward = awardsByKey.get(key);

                if (existingCrmAward != null) {
                    award.existingRecordName = existingCrmAward.Name;
                    award.existingRecordId = existingCrmAward.Id;
                    award.isCurrentRecord = existingCrmAward.Id == awardId;
                    award.onlyExistsInCallista = false;
                } else {
                    award.transactionNumber = callistaExistingAppsByAwardKey.get(key);
                    award.onlyExistsInCallista = String.isNotBlank(award.transactionNumber);
                }

                formData.awards.add(award);
            }
        }

        return formData;
    }

    /**
     * Updates an award record
     * @param awardId The Id of the award to update
     * @param award The updated award data
     */
    @AuraEnabled
    public static void updateAward(Id awardId, Award award, Boolean clearTransactionNumber) {
        Graduation_Award__c existingAward = [
            SELECT Cancellation_Date__c, Cancellation_Succeeded__c,
                Writeback_Requested_Age_Minutes__c, Graduation_Application__c,
                Callista_Transaction_Number__c
            FROM Graduation_Award__c WHERE Id = :awardId
        ];
        String errorMessage = null;
        if(existingAward.Callista_Transaction_Number__c != null) {
            if(existingAward.Cancellation_Date__c != null && !existingAward.Cancellation_Succeeded__c) {
                errorMessage = 'Cannot update award that is pending cancellation';
            }
            else if(existingAward.Writeback_Requested_Age_Minutes__c != null) {
                errorMessage = 'Cannot update award that is pending writeback';
            }
        }
        if(errorMessage != null) {
            AuraHandledException ex = new AuraHandledException(errorMessage);
            ex.setMessage(errorMessage);
            throw ex;
        }

        Graduation_Award__c updatedAward = new Graduation_Award__c(
            Id = awardId,
            Course_Code__c = award.courseCode,
            Course_Version_Number__c = award.courseVersionNumber,
            Course_Title__c = award.courseTitle,
            Award_Type__c = GradsUtils.getCrmAwardType(award.awardTypeIndicator),
            Award_Course_Code__c = award.awardCourseCode,
            Award_Course_Version__c = award.awardCourseVersionNumber,
            Award_Course_Title__c = award.awardCourseTitle,
            Award_Code_1__c = award.awardCode1,
            Award_Title_1__c = award.awardTitle1,
            Award_Code_2__c = award.awardCode2,
            Award_Title_2__c = award.awardTitle2,
            Cancellation_Date__c = null,
            Cancellation_Succeeded__c = false
        );

        if(clearTransactionNumber) {
            // For creating new app after cancellation
            updatedAward.Callista_Transaction_Number__c = null;
        }
        if(String.isNotBlank(award.transactionNumber)) {
            // For selecting an award that already exists in Callista
            updatedAward.Callista_Transaction_Number__c = award.transactionNumber;
        }

        updatedAward.Integration_Id__c = GradsUtils.createAwardIntegrationId(
            updatedAward,
            existingAward.Graduation_Application__c
        );
        update updatedAward;
    }

    /**
     * Creates new awards for a Graduation Application
     * @param applicationId The Id of the Graduation_Application__c record
     * @param awards List of awards to create
     * @return List of created award Ids
     */
    @AuraEnabled
    public static List<Id> createAwards(Id applicationId, List<Award> awards) {
        List<Graduation_Award__c> newAwards = new List<Graduation_Award__c>();

        for(Award award : awards) {
            Graduation_Award__c newAward = new Graduation_Award__c(
                Graduation_Application__c = applicationId,
                Course_Code__c = award.courseCode,
                Award_Type__c = GradsUtils.getCrmAwardType(award.awardTypeIndicator),
                Award_Course_Code__c = award.awardCourseCode,
                Award_Course_Version__c = award.awardCourseVersionNumber,
                Award_Course_Title__c = award.awardCourseTitle,
                Award_Code_1__c = award.awardCode1,
                Award_Title_1__c = award.awardTitle1,
                Award_Code_2__c = award.awardCode2,
                Award_Title_2__c = award.awardTitle2,
                Is_Attending_Ceremony__c = award.isAttendingCeremony,
                Receipt_Number_External_System__c = award.receiptNumber,
                Staff_Comments__c = award.staffComments,
                Course_Title__c = award.courseTitle,
                Course_Version_Number__c = award.courseVersionNumber,
                Has_Attendance_Fee_Waiver__c = award.hasFeeWaiver ?? false,
                Callista_Transaction_Number__c = award.transactionNumber
            );
            newAward.Integration_Id__c = GradsUtils.createAwardIntegrationId(newAward, applicationId);
            newAwards.add(newAward);
        }

        insert newAwards;
        return new List<Id>(new Map<Id,SObject>(newAwards).keySet());
    }


    public static String createAwardKey(String courseCode, String awardCourseCode, String awardCode1, String awardCode2) {
        return courseCode + '-' + awardCourseCode + '-' + awardCode1 + '-' + (awardCode2 ?? '');
    }

    @AuraEnabled
    public static void cancelAward(Id awardId) {
        update new Graduation_Award__c(
            Id = awardId, Cancellation_Date__c = Datetime.now(), Bypass_Writeback_Trigger__c = true
        );
    }

}