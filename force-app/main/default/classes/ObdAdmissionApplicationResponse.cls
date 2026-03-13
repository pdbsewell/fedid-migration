/**
 * @author Vineeth Batreddy
 * @date Unknown
 * @group Integration
 * @description This class maintains the response data model for Admission applications.
 * @revision Trent De Laney - 29/11/2019 - Updated class name for consistency
 */
public with sharing class ObdAdmissionApplicationResponse {
    
    public List<Application> applications {get;set;}

    public class Application {
        public Boolean success;
        public Boolean isNewApplicant;
        public String externalApplicantId;
        public String smsApplicantId;
        public List<SmsApplication> smsApplications;
        public List<String> info;
        public List<String> errors;
    }

    public class SmsApplication {
        public Integer applicationId;
        public String updatedDate;
        public Boolean isNewApplication;
        public List<CoursePreference> coursePreferences;
    }

    public class CoursePreference {
        public String transferStatus;
        public Integer preferenceNumber;
        public String sequenceNumber;
        public String courseCode;
        public Integer courseVersionNumber;
        public String locationCode;
        public String attendanceMode;
        public String attendanceType;
        public String academicCalendarType;
        public Integer academicCiSequenceNumber;
        public String admissionCalendarType;
        public Integer admissionCiSequenceNumber;
        public String typeOfPlaceCode;
    }

}