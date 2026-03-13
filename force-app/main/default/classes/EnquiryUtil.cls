/**
 * @author              Kristian Vegerano
 * @description         Utility class for enquiries
 * @History                     
 *      AUG.09.2018     Kristian Vegerano   -   Created
 */
public class EnquiryUtil {
    /**
     * Enum to list different enquiry purposes
     */
    public enum EnquiryPurpose {
        GENERAL, STUDENT, STAFF, AGENT
    }
    
    /**
     * Record Type Id - Case - Standard Enquiry 
     */
    public static final Id CASE_RECTYPE_STANDARDENQUIRY = Schema.SObjectType.Case
                                                    .getRecordTypeInfosByName()
                                                    .get(Label.Case_Rectype_StandardEnquiry)
                                                    .getRecordTypeId();
}