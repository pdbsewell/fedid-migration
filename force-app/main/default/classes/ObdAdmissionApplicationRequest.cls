/*
    AUTHOR : Vineeth Batreddy
    DESCRIPTION : This class maintains the request data model for Admission applications.
*/

public with sharing class ObdAdmissionApplicationRequest {
    
    public AdmissionApplication admissionApplication {get; set;}

    public class AdmissionApplication {
        public Agent agent {get; set;}
        public List<Application> applications {get; set;}
    }

    public class Agent {
        public String agentPersonId {get; set;}
    }

    public class Application {
        public Applicant applicant {get; set;}
        public CourseApplication courseApplication {get; set;}
    } 

    public class Applicant {
        public String externalApplicantId {get; set;}
        public String surname {get; set;}
        public String firstName {get; set;}
        public String otherName {get; set;}
        public String title {get; set;}
        public String sex {get; set;}
        public String preferredGivenName {get; set;}
        public String previousSurname {get; set;}
        public Boolean previousStudentIndicator {get; set;}
        public String previousInstitutionCode {get; set;}
        public String previousPersonId {get; set;}
        public String birthDate {get; set;}
        public String emailAddress {get; set;}
        public String addressType {get; set;}
        public String addressLine1 {get; set;}
        public String addressLine2 {get; set;}
        public String addressLine3 {get; set;}
        public String addressLine4 {get; set;}
        public String addressLine5 {get; set;}
        public String postcode {get; set;}
        public String osCode {get; set;}
        public String phone1 {get; set;}
        public String phone2 {get; set;}
        public String phone3 {get; set;}
        public String addressOtherDetail {get; set;}
        public String citizenshipType {get; set;}
        public String chessNumber {get; set;}
        public String birthCountryCode {get; set;}
        public String citizenCountryCode {get; set;}
        public String passportNumber {get; set;}
        public Boolean prApplicationIndicator {get; set;}
        public String prApplicationDate {get; set;}
        public String nameFormatCode {get; set;}
        public String addressSubmissionDate {get; set;}
        public String registrationPhoneNumber {get; set;}
        public Boolean readOnlyAccessIndicator {get; set;}
        public String password {get; set;}
        public String applicantId {get; set;}
        public Visa visa {get; set;}
        public List<Secondary> secondary {get; set;}
        public List<Tertiary> tertiary {get; set;}
        public List<OtherQualification> otherQualification {get; set;}
        public List<WorkExperience> workExperience {get; set;}
        public List<AdmissionTest> admissionTest {get; set;}
        public Document document {get; set;}
    }

    public class CourseApplication {
        public String applicationNumber {get; set;}
        public String standardApplicationType {get; set;}
        public String accessEquityComments {get; set;}
        public Boolean requestForAdvancedStandingIndicator {get; set;}
        public Boolean fromPortal {get; set;}
        public Boolean requestForScholarshipIndicator {get; set;}
        public ServiceQuestions serviceQuestions {get; set;}
        public List<String> accessEquityCategories {get; set;}
        public List<Marketing> marketing {get; set;}
        public List<CourseData> courseData {get; set;}   
    }

    public class Visa {
        public String startDate {get; set;}
        public String endDate {get; set;}
        public String type {get; set;}
        public String visanumber {get; set;}
    }

    public class Secondary {
        public String countryCode {get; set;}
        public String stateCode {get; set;}
        public String assessmentQualificationType {get; set;}
        public String otherAssessmentQualification {get; set;}
        public Boolean englishInstructionIndicator {get; set;}
        public String schoolCode {get; set;}
        public String otherSchool {get; set;}
        public String completionYear {get; set;}
        public String score {get; set;}
        public String result {get; set;}
    }

    public class Tertiary {
        public String countryCode {get; set;}
        public String qualificationName {get; set;}
        public Boolean englishInstructionIndicator {get; set;}
        public String institutionCode {get; set;}
        public String otherInstitution {get; set;}
        public String firstYearEnrolled {get; set;}
        public String lastYearEnrolled {get; set;}
        public String levelOfCompletion {get; set;}
    }

    public class OtherQualification {
        public String qualificationType {get; set;}
        public String otherQualification {get; set;}
        public String achievedDate {get; set;}
        public String comments {get; set;}
    }

    public class WorkExperience {
        public String position {get; set;}
        public String employer {get; set;}
        public String startDate {get; set;}
        public String endDate {get; set;}
        public String contactPersonName {get; set;}
        public String contactAddress {get; set;}
    }

    public class AdmissionTest {
        public String admissionTestType {get; set;}
        public String plannedDate {get; set;}
        public String achievedDate {get; set;}
        public String resultType {get; set;}
        public String score {get; set;}
        public String grade {get; set;}
        public List<AdmissionTestSubscore> admissionTestSubscore {get; set;}
    }

    public class AdmissionTestSubscore {
        public String referenceCode {get; set;}
        public String subscore {get; set;}
    }

    public class Document {
        public String documentType {get; set;}
        public String mimeContentType {get; set;}
        public String filename {get; set;}
        public String binaryDocument {get; set;}
        public String documentComments {get; set;}
    }

    public class Marketing {
        public String question {get; set;}
        public String applicantAnswer {get; set;}
    }

    public class UnitSet {
        public String unitSetCode {get; set;}
        public String usVersionNumber {get; set;}
    }

    public class CourseData {
        public String courseCode {get; set;}
        public String courseVersionNumber {get; set;}
        public String locationCode {get; set;}
        public String attendanceMode {get; set;}
        public String attendanceType {get; set;}
        public String preferenceNumber {get; set;}
        public String academicCalendarType {get; set;}
        public String academicCiSequenceNumber {get; set;}
        public String admissionCalendarType {get; set;}
        public String admissionCiSequenceNumber {get; set;}
        public String typeOfPlaceCode {get; set;}
        public String unitDetails {get; set;}
        public UnitSet unitSet {get; set;}
    }

    public class YesNo {
        public String serviceCode {get; set;}
        public String startDate {get; set;}
        public Boolean yesNoAnswer {get; set;}
    }

    public class Answer {
        public String answerCode {get; set;}
        public String selectAnswerIndicator {get; set;}
    }

    public class SingleMultiChoice {
        public String serviceCode {get; set;}
        public String startDate {get; set;}
        public String openQuestionResponse {get; set;}
        public List<Answer> answer {get; set;}
    }

    public class MultiMulti {
        public String serviceCode {get; set;}
        public String startDate {get; set;}
        public String openQuestionResponse {get; set;}
        public List<Answer> answer {get; set;}
    }

    public class OpenResponse {
        public String serviceCode {get; set;}
        public String startDate {get; set;}
        public String openQuestionResponse {get; set;}
    }

    public class ServiceQuestions {
        public List<YesNo> yesNo {get; set;}
        public List<SingleMultiChoice> singleMultiChoice {get; set;}
        public List<MultiMulti> multiMulti {get; set;}
        public List<OpenResponse> openResponse {get; set;}
    }

}