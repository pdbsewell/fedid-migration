/**
 * @author      APRivera
 * @description serves as the central data structure, encapsulating all necessary details about the test and candidate.
 * @group       Admissions - English Test
 * @revision   15/12/2024 - APRivera - Created
 * @revision   10/04/2025 - APRivera - Added the usage on Provider attribute
 */
public with sharing class EnglishTestVerificationPayload {

    // Provider Information
    @AuraEnabled public String provider { get; set; }          // e.g., "IELTS"

    // Test Details
    @AuraEnabled public String testType { get; set; }          // e.g., "IBT"
    @AuraEnabled public Date testDate { get; set; }            // e.g., 2020-01-30
    @AuraEnabled public String testNumber { get; set; }        // e.g., "T12345678"

    // Candidate Details
    @AuraEnabled public String lastName { get; set; }          // e.g., "Wick"
    @AuraEnabled public String firstName { get; set; }         // e.g., "John"
    @AuraEnabled public Date dateOfBirth { get; set; }         // e.g., 2020-01-30

    // Test Scores
    @AuraEnabled public Decimal listeningScore { get; set; }   // e.g., 8.5
    @AuraEnabled public Decimal readingScore { get; set; }     // e.g., 8.5
    @AuraEnabled public Decimal speakingScore { get; set; }    // e.g., 8.5
    @AuraEnabled public Decimal writingScore { get; set; }     // e.g., 8.5
    @AuraEnabled public Decimal overallScore { get; set; }     // e.g., 8.5

    // Validation Result
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public Boolean success { get; set; }

    // Attachments
    @AuraEnabled public String photoBase64 { get; set; }       // e.g., "Base64 String"
    @AuraEnabled public String photoMediaType { get; set; }    // e.g., "JPG"
    @AuraEnabled public String pdfBase64 { get; set; }         // e.g., "Base64 String"

    // Default constructor
    public EnglishTestVerificationPayload() {}

    /**
    * @description Wrapper class for managing test report data, including personal details.
    * @group       Admissions
    * @revision    06/01/2025 - APRivera - Created
    */
    public class TestReportFormWrapper {
        // Properties to hold the relevant data
        @AuraEnabled public String Provider { get; set; }
        @AuraEnabled public String TestType { get; set; }
        @AuraEnabled public String TestReportNumber { get; set; }
        @AuraEnabled public Date DOB { get; set; }
        @AuraEnabled public String FirstName { get; set; }
        @AuraEnabled public String LastName { get; set; }
        @AuraEnabled public String PreviousFirstName { get; set; }
        @AuraEnabled public String PreviousLastName { get; set; }
        @AuraEnabled public Date DateCompleted { get; set; }
        @AuraEnabled public Boolean PhotoFlag { get; set; }
        @AuraEnabled public Date StartDate { get; set; }
        @AuraEnabled public Date EndDate { get; set; }

        /**
         * Default constructor
         */
        public TestReportFormWrapper() {}

        /**
         * Parameterized constructor to easily initialize all fields.
         * @param provider The English test provide
         * @param testType The type of English test
         * @param testReportNumber The test report number.
         * @param dob The date of birth.
         * @param firstName The First name.
         * @param lastName The last name.
         * @param previousFirstName The previous first name.
         * @param previousLastName The previous last name.
         * @param dateCompleted Test Completion Date.
         * @param photoFlag Indicates photo inclusion.
         * @param startDate The date of birth.
         * @param endDate The date of birth.
         */
        public TestReportFormWrapper(String provider, String testType, String testReportNumber, Date dob, String firstName, String lastName,
                String previousFirstName, String previousLastName, Date dateCompleted, Boolean photoFlag, Date startDate, Date endDate) {
            this.Provider = provider;
            this.TestType = testType;
            this.TestReportNumber = testReportNumber;
            this.DOB = dob;
            this.FirstName = firstName;
            this.LastName = lastName;
            this.PreviousFirstName = previousFirstName;
            this.PreviousLastName = previousLastName;
            this.DateCompleted = dateCompleted;
            this.PhotoFlag = photoFlag;
            this.StartDate = startDate;
            this.EndDate = endDate;
        }
    }


}