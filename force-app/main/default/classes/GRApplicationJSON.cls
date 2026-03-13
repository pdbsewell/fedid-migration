/*******************************************************************************
* @author		Vishal Gupta
* @date         30/09/2024   
* @description  Request structure for sending Application for Graduate Research to Calista 
* @revision     
*******************************************************************************/
public class GRApplicationJSON {

    public Applicant applicant;
    public Application application;
    public class Applicant {
        public List<AdditionalDetails> additionalDetails;
        public String previousMonashId;
        public List<Qualifications> qualifications;
        public String smsContactId;
        public String studentId;
        public Visa visa;
    }
    public class AdditionalDetails {
        public String name;
        public object value;
        public String code;
        public AdditionalDetails(String name, object value, String code) {
            this.name = name; this.value = value; this.code = code;
        }
    }
    public class Visa {
        public List<AdditionalDetails> additionalDetails;
    }
    public class Qualifications {
        public List<AdditionalDetails> additionalDetails;
        public String conferredDate;
        public String startDate;
        public String endDate;
        public String expectedDateOfCompletion;
        public Type type;
        public String name;
        public CountryObtained countryObtained;
        public Institution institution;
        public Status status;
        public Boolean isEnglishInstruction;
    }
    public class CountryObtained {
        public String sacCountryCode;
        public String isoCountryName;
        public CountryObtained(String sacCountryCode, String isoCountryName) {
            this.sacCountryCode = sacCountryCode; this.isoCountryName = isoCountryName;
        }
    }
    public class Institution {
        public String institutionCode;
        public String institutionName;
        public Institution(String institutionCode, String institutionName) {
            this.institutionCode = institutionCode; this.institutionName = institutionName;
        }
    }
    public class Status {
        public String code;
        public Status(String code) {
            this.code = code;
        }
    }
    public class Type {
        public String name;
        public String type;
        public Type(String name, String type) {
            this.name = name; this.type = type;
        }
    }
    public class Application {
        public ApplicationType applicationType;
        public List<CourseDetail> courseDetail;
        public HdrApplicationDetails hdrApplicationDetails;
        public String smsApplicationId;
    }
    public class ApplicationType {
        public String code;
        public ApplicationType(String code) {
            this.code = code;
        }
    }
    public class CourseDetail {
        public Course course;
    }
    public class Course {
        public String code;
        public CourseOffering courseOffering;
        public Faculty faculty;
        public String title;
        public Integer versionNumber;
    }
    public class Faculty {
        public String effectiveDate;
        public String id;
        public Faculty(String effectiveDate, String id) {
            this.effectiveDate = effectiveDate; this.id = id;
        }
    }
    public class CourseOffering {
        public String attendanceMode;
        public String attendanceType;
        public List<CalendarDetail> calendarDetail;
        public Location location;
    }
    public class Location {
        public String code;
        public Location(String code) {
            this.code = code;
        }
    }
    public class CalendarDetail {
        public String calendarInstanceCode;
        public String code;
        public String type;
        public CalendarDetail(String calendarInstanceCode, String code, String type) {
            this.calendarInstanceCode = calendarInstanceCode; this.code = code; this.type = type;
        }
    }
    public class HdrApplicationDetails {
        public AcademicOrgUnit academicOrgUnit;
        public Agency agency;
        public AgentDetail agentDetail;
        public String commencementDate;
        public String countryOfStudy;
        public String declarationText;
        public String externalModeContactPlans;
        public String hdrApplicationType;
        public String mumNRICPassportNumber;
        public String mumPassExpiryDate;
        public String mumPassType;
        public Boolean mumResidenceFlag;
        public ResearchProposal researchProposal;
        public Scholarship scholarship;
        public String submissionDate;
        public List<SupportingDocuments> supportingDocuments;
        public object addedAgentFlag;
    }
    public class AcademicOrgUnit {
        public String effectiveDate;
        public String id;
        public AcademicOrgUnit(String effectiveDate, String id) {
            this.effectiveDate = effectiveDate; this.id = id;
        }
    }
    public class ResearchProposal {
        public String employerNameAndPostion;
        public Boolean employmentFlag;
        public String employmentLoadCode;
        public String employmentSchedule;
        public String externalFundingDurationAndValue;
        public Boolean externalFundingFlag;
        public String externalFundingName;
        public String externalFundingSurrenderInd;
        public String externalFundingType;
        public Boolean externalScholarshipApplicationFlag;
        public String externalScholarshipName;
        public Boolean externalSupervisorFlag;
        public String researchSchedule;
        public String summary;
        public String supervisorName;
        public String title;
    }
    public class Scholarship {
        public Boolean changeToFullTimeFlag;
        public Boolean changeToInternalFlag;
        public Boolean equityScholarshipFlag;
        public Boolean indigenousScholarshipFlag;
        public Boolean mastersUpgradeFlag;
        public String previousApplicationYear;
        public List<CalendarDetail> scholarshipRoundCalendarDetail;
    }
    public class SupportingDocuments {
        public List<AdditionalDetails> additionalDetails;
        public String type;
    }
    public class AgentDetail {
        public Cls_Contact contact;
        public AgentDetail(Cls_Contact contact) {
            this.contact = contact;
        }
    }
    public class Cls_Contact {
        public String email;
        public String name;
        public Cls_Contact(String email, String name) {
            this.email = email; this.name = name;
        }
    }
    public class Agency {
        public String agencyCode;
        public String agencyName;
        public Agency(String agencyCode, String agencyName) {
            this.agencyCode = agencyCode; this.agencyName = agencyName;
        }
    }
    public static Map<String,Object> parse(String json) {
        return (Map<String,Object>) System.JSON.deserializeUntyped(json);
    }
}