/**
 * Controlling the End Page of the Offline Bulk Registration Flow
 * 
 * @author Nadula Karunaratna, PD
 * 
 */ 
 
public class OfflineRegistrationFlowController {    
    
    public OfflineRegistrationFlowController(ApexPages.StandardController stdController) {}
    
    public Flow.Interview.Offline_Bulk_Registration OfflineBulkRegistration { get; set; }
    
    public static String getApplicationID(Flow.Interview.Offline_Bulk_Registration OfflineBulkRegistration) {
        if (OfflineBulkRegistration==null) return ''; //critical error
        else return OfflineBulkRegistration.varApplicationID;
    }

    public String getCourseOfferingID() {
        if (OfflineBulkRegistration==null) return ''; //critical error
        else return OfflineBulkRegistration.varCourseOfferingId;
    }  

    public String getPaymentType() {
        if (OfflineBulkRegistration==null) return ''; //critical error
        else return OfflineBulkRegistration.varPaymentType;
    }

    public String getHowManyApplicants() {
        if (OfflineBulkRegistration==null) return ''; //critical error
        //else return integer.valueof(OfflineBulkRegistration.varHowManyApplicants);
        else return OfflineBulkRegistration.varHowManyApplicants; 
    }

    public String getCourseCode() {
        if (OfflineBulkRegistration==null) return ''; //critical error
        else return OfflineBulkRegistration.varCourseCode;
    }

    public String getCourseName() {
        if (OfflineBulkRegistration==null) return ''; //critical error
        else return OfflineBulkRegistration.varSelectedCourseName;
    }        

    public PageReference getCSVUploadPage(){
        //PageReference p = new PageReference('/apex/OfflineBulkRegistration_CSV_Upload_Page?ApplicationID=' + getApplicationID() + '&CourseCode=' + getCourseCode() + '&CourseName=' + getCourseName() + '&CourseOfferingID=' + getCourseOfferingID() + '&PaymentType=' + getPaymentType() + '&HowManyApplicants=' + getHowManyApplicants() + '&inline=1');
        PageReference p = new PageReference('/apex/OfflineBulkRegistration_CSV_Upload_Page?ApplicationID=' + getApplicationID(OfflineBulkRegistration) + '&CourseCode=' + getCourseCode() + '&CourseName=' + getCourseName() + '&CourseOfferingID=' + getCourseOfferingID() + '&PaymentType=' + getPaymentType() + '&HowManyApplicants=' + getHowManyApplicants() + '&inline=1');
        p.setRedirect(true);
        return p;
    }
}