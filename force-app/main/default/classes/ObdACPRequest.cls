/*******************************************************************************
* @author:      Nitin Khandelwal
* @date:        30.August.2018
* @description: Class modelling the JSON request for the 'ACPInterface'.  To be serialized in actual callout.
* @revision:
*               30.August.2018 Nitin Khandelwal > Initial class creation.
*               24/01/2019 - Fix for  SF-135 - SMendu
*               23/07/2019 - Refactor to support insert and update ACP
*               22/08/2019 - SFTN-172 - Adding two new fields to Update integration related to PrecedentId.
*               27/08/2019 - SFTN-173 - Adding a new field to Update integration related to Recruitment Ref code.
*               13/09/2019 - SFTN-223 - Populating Recruitment Ref code only for International applicants and
*                          skipping for Domestic applicants.
*               //Pulling out code -11/10/2019 - SFTN-97 - Populating Submission location(Admission International Table)
*               29/11/2019 - SFTN-537 - Renamed the test class to ensure consistency across naming conventions
*               16/06/2020 - SFTLG-869 - Adding Agency (Account) + Agent (Contact) fields out of Salesforce for mapping into the outbound Payload structure
*               23/06/2020 - SFTLG-869 - Minor fixes based on testing outcome in SIT, removing all fields but Org Unit Code
*               Shalini Mendu - 13/09/2020 - SFTG-2212 - Remove offerRound element from Outbound ACP payload
*               Ken McGuire -    2023-05-03 - Removed comments__c field from request object            
*
*******************************************************************************/
public class ObdACPRequest {

    /********************************************************
    Class Variables
    ********************************************************/
    public List<Application> applications{get;set;}
    public Application getApplication(){return applications.get(0);}

    /**
     * @author Trent De Laney
     * @date 22 Jul 2019 at 2:09:44 pm
     * @group Integration Concretes
     * @description Used for sending information relating to the ACP object to Callista
     */
    public class Application {

        //Required for everything
        public String type{get;set;}
        public Integer admissionApplNumber{get;set;}
        public String submittedDate{get;set;}

        //Insert Fields
        public Integer academicCiSequenceNumber{get;set;}
        public String academicCalendarType{get;set;}
        public String admissionCalendarType{get;set;}
        public Integer admissionCiSequenceNum{get;set;}
        public String admissionCategory{get;set;}

        public List<CoursePreference> coursePreferences{get;set;}
        public CoursePreference getCoursePreference() {return coursePreferences.get(0);}

    }

    /**
     * @author Trent De Laney
     * @date 22 Jul 2019 at 2:10:12 pm
     * @group Integration Concretes
     * @description Used for sending information relating to the ACP object to Callista
     */
    public class CoursePreference {
        public String type{get;set;}
        public String admissionCode{get;set;}
        public String basisForAdmissionType{get;set;}
        public String courseCode{get;set;}
        public String transferCourseCode{get;set;}
        public Boolean requestForAdvancedStandingIndicator {get;set;}
        public List<CoursePreferenceInstance> coursePreferenceInstances{get;set;}
        public String primaryNationalityCode {get;set;}
        public String recruitmentReferenceCode {get;set;}
        public Agent agent {get;set;}
        public String submissionLocationCode {get;set;}
        //public CoursePreferenceInstance getCoursePreferenceInstance() {return !coursePreferenceInstances.isEmpty() ? coursePreferenceInstances.get(0) : null;}
    }

    
    /**
     * @author KL
     * @date 16 Jun 2020 at 10:40:00 am
     * @group Integration Concretes
     * @description Used for sending AGENCY information relating to the ACP object to Callista
     */
    public class Agent {

        //Insert Fields
        // public String   startDate{get;set;}
        // public String   endDate{get;set;}
        public String   agentOrgUnitCode{get;set;}
        // public String   agentOrgUnitStartDate{get;set;}
        // public Integer  agentPercentage{get;set;}
        // public Boolean  correspondenceContactIndicator{get;set;}
        // public String   contactInformation {get;set;}
        // public String   agentPersonId {get;set;}
        // public Boolean  primaryAgencyIndicator {get;set;}
        // public String   comments {get;set;}

    }
    /**
     * @author Trent De Laney
     * @date 22 Jul 2019 at 2:10:37 pm
     * @group Integration Concretes
     * @description Used for sending information relating to the ACP object to Callista
     */
    public class CoursePreferenceInstance {
        public String admissionOutcomeStatusReason{get;set;}
        public String offerDate{get;set;}
        public String offerResponseDate{get;set;}
        public String admissionOutcomeStatusAuthDate{get;set;}
        public String admissionOutcomeStatusAuthPersonId{get;set;}
        public String conditionalOfferStatus{get;set;}
        public String outcomeStatus{get;set;}
        public String conditionalOfferSatisfiedDate{get;set;}
        public String entryQualificationStatus{get;set;}
        public Boolean conditionalOfferMustBeSatisfiedIndicator{get;set;}
        public String documentationStatus{get;set;}
        public String offerResponseStatus{get;set;}
        public Integer preferenceNumber{get;set;}
        public String actualOfferResponseDate{get;set;}
        public Integer unitSetVersion{get;set;}
        public String defermentStatus{get;set;}
        public String unitSetCode{get;set;}
        public String deferredAdmissionCalendarType{get;set;}
        public String attendanceType{get;set;}
        public Integer deferredAdmissionCiSequenceNum{get;set;}
        public String attendanceMode{get;set;}
        public String feeCategory{get;set;}
        public String locationCode{get;set;}
        public String hecsPaymentOption{get;set;}
        public Integer courseVersionNumber{get;set;}
        //public String expectedCompletionYear{get;set;}
        public String courseCode{get;set;}
        //public String expectedCompletionPeriod{get;set;}
        //public String admCiSequenceNumber{get;set;} -- commented for payload to pass
        public String correspondenceCategory{get;set;}
        //public String admCalType{get;set;} -- commented for payload to pass
        public String enrolmentCategory{get;set;}
        public Integer sequenceNumber{get;set;}
        public String fundingSource{get;set;}
        public String callistaApplicationId{get;set;}
        public String agreedStartDate{get;set;}
        //public String typeOfPlaceCode{get;set;}
        public String offerCondition{get;set;}

        public String applicantAcceptanceCondition{get;set;}
        public List<PrecedentInfo> precedents{get;set;}

    }
    /**
   * @author Shalini Mendu
   * @date 22 Aug 2019 at 3:30:37 pm
   * @group Integration Concretes
   * @description Used for sending Precedent related information relating to the ACP object to Callista
   */
    public class PrecedentInfo{
        public Integer precedentId {get;set;}
        public String requirementSatisfiedCode {get;set;}
    }

    /**
    * @author Trent De Laney
    * @description Constructor to remove the setup complexity of calling this from other classes
    * @date 22 Jul 2019 at 2:04:30 pm
    */
    public ObdACPRequest() {
        this.applications = new List<Application>();
        Application app = new Application();
        app.coursePreferences = new List<CoursePreference>();
        CoursePreference pref = new CoursePreference();
        pref.coursePreferenceInstances = new List<CoursePreferenceInstance>();
        app.coursePreferences.add(pref);
        this.applications.add(app);
    }
}