/**
 * @Class              : AffiliationCheckService.cls
 * @Description        : Service class for running Affiliation rules
 *                       Complete details on https://docs.google.com/spreadsheets/d/1QGJ4Wnme_wOp1TY5oFqUIVdMKB0CgQ0aWt4OTBcIrlw/edit#gid=0
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 
 * 2023-03-14     Vinothraja   Created 
 * 2024-01-12     Vinothraja   Corrected the Error messages for Blocked Affiliation
 */
public class AffiliationCheckService {
    // Constants
    public static final String BLOCKED_STATE = 'BLOCKED';
    public static final String BLOCKED_MESSAGE = 'Applicant is already affiliated to another Agent. Applicant needs to complete Agent nomination process. Agent will be informed once request is processed.';
    public static final String BLOCKED_BY_SAME_AGENCY_MESSAGE = 'You have already submitted another application ({0}) with this course ({1}) and intake ({2}). Submit new documents or new request from that application.';
    public static final String ALLOWED_STATE = 'ALLOWED';
    public static final String ALLOWED_MESSAGE = 'Agent may proceed with creating Applications.';
    // Agency status
    public static final Set<String> AGENCY_INACTIVE_STATUSES = new Set<String> {'Contract Terminated', 'Suspended'};
    public static final Set<String> EXCLUDED_AGENCIES = new Set<String> {'DIRECT', 'AVENU-IND', 'PARTNR', 'M-DIRECT'}; // duplicated in BLACKLISTED_AGENCIESsystem setting mdt
    // Application statuses - START
    public static final Set<String> DRAFT_STATUSES = new Set<String> {'Draft', 'Cancelled'};
    public static final Set<String> SUBMITTED_STATUSES = new Set<String> {'Submitted', 'Submission on Hold (Duplicate Contact)', 'Sent for Submission', 'Review'};
    // Application statuses - END
    // ACP Statuses - START
    public static final Set<String> IN_PROGRESS_OUTCOME_STATUSES = new Set<String> {'AP-PROGRES', 'IN-PROG-MI', 'IN-PROGRES', 'P-OFFER', 'P-OFFR-CND', 'P-OFFR-PCK', 'P-REJECT'};
    public static final Set<String> IN_PROGRESS_OFFER_RESPONSE_STATUSES = new Set<String> {'PENDING', 'DEFERRAL', 'SIGNED', 'ACC-C-AG-P', 'ACCEPT-CND', 'ACCEPT-PRV'};
    public static final Set<String> REJECTED_OUTCOME_STATUSES = new Set<String> {'REJECTED', 'AP-LAPSED', 'APP-WDRWN', 'CHANGE-R', 'CITZ-CHNG', 'ERROR-ACAL', 'ERROR-ACAT', 'ERROR-CRS', 'NTAKE-CL', 'REJECT-FRD', 'REJECT-GAC', 'REJECT-GTE', 'REJECT-PSC', 'REJECT-Q', 'EJ-MICERT', 'REJ-MIDIP', 'REJ-MIMUFY', 'REJ-MINEXT', 'VOIDED', 'WITHDRAWC', 'WITHDRAWN', 'WITHDRAWQ', 'WTHDRN-C-R', 'WTHDRN-R', 'OFFER-LAP'};
    public static final Set<String> REJECTED_OFFER_RESPONSE_STATUSES = new Set<String> {'REJECTED', 'ACC-DEL', 'NO-RESP'};
    public static final Set<String> ACCEPTED_OUTCOME_STATUSES = new Set<String> {'OFFER', 'OFFER-C-E', 'OFFER-C-FY', 'OFFER-C-MC ', 'OFFER-COND ', 'OFFER-PROV'};
    public static final Set<String> ACCEPTED_OFFER_RESPONSE_STATUSES = new Set<String> {'ACCEPTED'};
    // ACP Statuses - END
    // responses
    public static final AffiliationResult BLOCKED = new AffiliationResult(BLOCKED_STATE);
    public static final AffiliationResult ALLOWED = new AffiliationResult(ALLOWED_STATE);

    private ReferenceData refData;

    public AffiliationCheckService(String contactId, String agencyId, String campus, List<Application_Course_Preference__c> incomingACPs) {
        // create Reference data for running the rules
        if (String.isBlank(contactId) || String.isBlank(agencyId) || String.isBlank(campus)){
            throw new AffiliationException('Parameters required for processing rules found missing!');
        } else {
            this.refData = new ReferenceData(contactId, agencyId, campus, incomingACPs); 
        }
    }
    public AffiliationResult result {
        get{
            return new Start().run(this.refData);
        }
    }

    private class Start extends AffiliationRule {
        public override AffiliationResult run(ReferenceData ref) {
            return new NoOtherApplicationsCheck().run(ref);
        }
    }

    /*
    * NoOtherApplicationsCheck - Check if other applications exist?
    * Positive Outcome:  Proceed to Rule Two.
    * Negative Outcome:  Agent can be affiliated to Applicant.
    */
    private class NoOtherApplicationsCheck extends AffiliationRule {
        public override AffiliationResult run(ReferenceData ref) {
            LogUtilityException.debug('rule : NoOtherApplicationsCheck');
            if (ref.allApplications == null || ref.allApplications.isEmpty()) {
                return ALLOWED;
            }
            return new AllowIfDraftsCheck().run(ref);
        }
    }
    /*
    * AllowIfDraftsCheck - Are all other existing applications Drafts or Cancelled?
    * Positive Outcome:  Agent can be affiliated to Applicant.
    * Negative Outcome:  Proceed to Rule Four.
    */
    private class AllowIfDraftsCheck extends AffiliationRule {
        public override AffiliationResult run(ReferenceData ref) {
            LogUtilityException.debug('rule : AllowIfDraftsCheck');
            // Check whether all the other existing applications are in DRAFT Status
            if (ref.draftApplications != null && 
                    ref.draftApplications.size() == ref.allApplications.size()) { 
                return ALLOWED;
            } 
            return new CompletedApplicationsCheck().run(ref);
        }
    }
    /*
    * Completed Applications check - Are all the other Applications COMPLETED?
    * NOTE : An Application is considered Completed, if it is REJECTED by either Monash Admissions(OUTCOME_STATUS) or Applicant(OFFER_RESPONSE_STATUS)
    * Positive Outcome:  Agent can be affiliated to Applicant.
    * Negative Outcome:  Proceed to next Rule
    */
    private class CompletedApplicationsCheck extends AffiliationCheckService.AffiliationRule {
        public override AffiliationResult run(ReferenceData ref) {
            LogUtilityException.debug('rule : CompletedApplicationsCheck');
            LogUtilityException.debug('rejected appns: ' + ref.rejectedApplications.size() + 'submitted appns: ' + ref.submittedApplications.size());
            // Check if all submitted appns are rejected; If yes, Allow Affiliation
            if (ref.rejectedApplications != null && 
                    ref.rejectedApplications.size() == ref.submittedApplications.size()) { 
                return ALLOWED;
            }

            Set<Application__c> appsWithNonRejectedACPs = new Set<Application__c> ();
            for (Application_Course_Preference__c acp : ref.nonRejectedACPs) {
                appsWithNonRejectedACPs.add(ref.applications.get(acp.Application__c));
            }
            ref.filteredApplications = new List<Application__c> (appsWithNonRejectedACPs);
            return new CampusCheck().run(ref); 
        }
    }
    /*
    * Intake check - Are the accepted Applications for different Intakes from the new application?
    * Same:  Proceed to Campus Check
    * Different:  Agent can be affiliated to Applicant.
    */
    private class DifferentCourseAndIntakeCheck extends AffiliationCheckService.AffiliationRule {
        public override AffiliationResult run(ReferenceData ref) {
            LogUtilityException.debug('rule : DifferentIntakeCheck');
            LogUtilityException.debug('# of appns taken for checking: ' + ref.filteredApplications.size());
                
            // Filter only those applications which have different Intakes from the new appn's intakes
            Set<Application__c> sameIntakeApplications = new Set<Application__c> ();
            for (Application__c existingAppn : ref.filteredApplications) {
                for (Application_Course_Preference__c existingACP : existingAppn.Application_Course_Preferences__r) {
                    for (Application_Course_Preference__c incomingACP : ref.incomingACPs) {
                        if (incomingACP.Course_Offering__r.Course__c != null && incomingACP.Course_Offering__r.Course__c == existingACP.Course_Offering__r.Course__c 
                            && incomingACP.Calendar_Start_Date__c != null && incomingACP.Calendar_Start_Date__c == existingACP.Calendar_Start_Date__c) {
                            sameIntakeApplications.add(existingAppn);
                            ref.conflictingACPs.add(incomingACP);
                        }
                    }
                }
            }
            // if there are same intake applications, check if the Agency is different 
            LogUtilityException.debug('sameIntakeApplications ==> ' + sameIntakeApplications);
            if (!sameIntakeApplications.isEmpty()) {
                ref.filteredApplications = new List<Application__c> (sameIntakeApplications);
                return new AgencyCheck().run(ref);
            }
                
            // return new ModeCheck().run(ref);
            return ALLOWED;
        }
    }
    /*
    * CampusCheck - Is the campus destination different and allowed? 
    * NOTE : Checks whether the applicant is applying for a Campus using a different Agent, for which he has already applied for.
    * NOTE : Approved region check not necessary as, the Agency is limited from submitting any Application for other regions, from UI level
    * Different Campus:  Agent can be affiliated to Applicant.
    * Same Campus:  Proceed to next rule :: DifferentCourseAndIntakeCheck
    */
    private class CampusCheck extends AffiliationRule {
        public override AffiliationResult run(ReferenceData ref) {
            LogUtilityException.debug('rule : CampusCheck');
            // Check if running Agent is trying to apply for an ALREADY APPLIED Campus
            if (ref.mapCampusOldApplications.keySet().contains(ref.campus)) {
                ref.filteredApplications = ref.mapCampusOldApplications.get(ref.campus); 
                return new DifferentCourseAndIntakeCheck().run(ref);
            }
            // return new ModeCheck().run(ref);
            return ALLOWED;
        }
    }
    /*
    * AgencyCheck - Is the Incoming Appn's agency same as Conflicting Appn's agency ?
    * NOTE : When run during Creation, Intake is assumed. Hence, 
    * Same Agency:  Blocked with Additional details on Course/Intake
    * Different Agency:  Blocked with generic message
    */
    private class AgencyCheck extends AffiliationRule {
        public override AffiliationResult run(ReferenceData ref) {
            LogUtilityException.debug('rule : AgencyCheck');
            System.debug(ref.agency + ' === ' + JSON.serialize(ref.conflictingAppnAgencies));
            if (ref.conflictingAppnAgencies.contains(ref.agency)) {
                AffiliationResult ar = new AffiliationResult(BLOCKED_STATE);
                String errorMessage = '';
                for (Application_Course_Preference__c conflictACP : ref.conflictingACPs) {
                    errorMessage += String.format(BLOCKED_BY_SAME_AGENCY_MESSAGE, new List<String> {conflictACP.Application__r.Name, conflictACP.Course_Title__c, conflictACP.Calendar_Start_Date__c.format()}) + ';';
                }
                ar.message = errorMessage;
                return ar;
            }
            return BLOCKED;
        }
    }

    public abstract class AffiliationRule {

        abstract AffiliationResult run(ReferenceData ref);
    }

    public class AffiliationResult {
        private string state;
        public AffiliationResult(String s) {
            this.state = s;
        }
        public boolean canCreateApplications {
            get {
                if (state.equalsIgnoreCase(BLOCKED_STATE)) {
                    return false;
                }
                return true;
            }
        }
        public boolean canSubmitApplications {
            get {
                if (state.equalsIgnoreCase(BLOCKED_STATE)) {
                    return false;
                }
                return true;
            }
        }
        public String message {
            get {
                if (String.isBlank(message)){
                    if (state.equalsIgnoreCase(BLOCKED_STATE)) {
                        return BLOCKED_MESSAGE;
                    }

                    return ALLOWED_MESSAGE;
                }
                return message;
            }
            set {
                message = value;
            }
        }
    }
    public without sharing class ReferenceData {
        private String applicant;
        private String agency;
        private String campus;

        // singletons holding different classifications of applications - START
        private Map<Id, Application__c> applications;
        private List<Application__c> drafts;
        private List<Application__c> others;
        private List<Application__c> submitted;
        private List<Application__c> accepted;
        private List<Application__c> rejected;
        private List<Application__c> inprogress;
        private List<Application__c> filtered;
        private Map<Id, Set<String>> mapOutcomes;
        private Map<Id, Set<String>> mapResponses;
        // singletons holding different classifications of applications - END
        public String runMode;
        private List<Application_Course_Preference__c> incomingACPs;
        private List<Application_Course_Preference__c> conflictingACPs;

        public ReferenceData(String contactId, String agencyId, String campus, List<Application_Course_Preference__c> incomingACPs) {
            this.applicant = contactId; 
            this.agency = agencyId;
            this.campus = campus;
            // Intakes will be null during the initial check upon Application creation; Intake based rules can be run only upon Submission
            if (incomingACPs == null || incomingACPs.isEmpty()) {
                // this.intakes = new List<Date> {Date.today()};
                this.incomingACPs = new List<Application_Course_Preference__c> {new Application_Course_Preference__c()};
                this.runMode = 'CREATE';
            } else {
                // this.intakes = intakes; 
                this.incomingACPs = incomingACPs;
                this.runMode = 'SUBMIT';
            }
            this.conflictingACPs = new List<Application_Course_Preference__c> ();
            this.applications = new Map<Id, Application__c> ([SELECT id, Name, Status__c, Campus_Location__c, Agent__c, Agent__r.Campus__c, Agent__r.Status__c,
                                                    (SELECT id, Application__c, Application__r.Name, Outcome_Status_LOV__r.Value__c, Offer_Response_Status_LOV__r.Value__c, Course__c, Course_Title__c, Calendar_Start_Date__c, Course_Offering__r.Course__r.id  
                                                        FROM Application_Course_Preferences__r)
                                                    FROM Application__c 
                                                    WHERE Applicant__c = :applicant 
                                                    AND Agent__r.Name NOT IN :EXCLUDED_AGENCIES
                                                    AND Agent__r.Status__c NOT IN :AGENCY_INACTIVE_STATUSES // filter out inactive agencies
                                                    AND Agent__c <> ''
                                                    ]);
            LogUtilityException.debug('Apps ==> ' + this.applications);
        }
        // contains all the applications of the Applicant
        public List<Application__c> allApplications { 
            get {
                return applications.values();
            }
        }
        // contains all draft applications of the Applicant
        public List<Application__c> draftApplications { 
            get {
                if (drafts == null){
                    drafts = new List<Application__c> ();
                    if (this.allApplications != null) {
                        for(Application__c app : this.allApplications) {
                            if (DRAFT_STATUSES.contains(app.Status__c)) {
                                drafts.add(app);
                            } 
                        }
                    }
                }
                return drafts;
            }
        }
        // contains applications which are submitted
        public List<Application__c> submittedApplications { 
            get {
                if (submitted == null){
                    submitted = new List<Application__c> ();
                    if (this.allApplications != null) {
                        for(Application__c app : this.allApplications) {
                            if (SUBMITTED_STATUSES.contains(app.Status__c)) {
                                submitted.add(app);
                            } 
                        }
                    }
                }
                return submitted;
            }
        }
        // contains only applications which are necessary for a rule
        public List<Application__c> filteredApplications { 
            get {
                if (filtered == null){
                    filtered = submittedApplications;
                }
                return filtered;
            }
            set {
                filtered = value;
            }
        }
        // contains all the campus locations Applicant had applied for earlier
        // runs on FilteredApplications
        public Map<String, List<Application__c>> mapCampusOldApplications { 
            get {
                mapCampusOldApplications = new Map<String, List<Application__c>> ();
                if (this.filteredApplications != null){
                    for (Application__c app : this.filteredApplications){
                        List<Application__c> apps;
                        if (mapCampusOldApplications.containsKey(app.Campus_Location__c)) {
                            apps = mapCampusOldApplications.get(app.Campus_Location__c);
                        } else {
                            apps = new List<Application__c> ();
                        } 
                        apps.add(app);
                        mapCampusOldApplications.put(app.Campus_Location__c, apps);
                    }
                }
                return mapCampusOldApplications;
            }
            set;
        }
        // when ALL of the ACPs are rejected (outcome_status) or rejected (offer_response), the Application is considered Rejected & Completed
        public List<Application__c> rejectedApplications {
            get {
                if (rejected == null){
                    rejected = new List<Application__c> ();
                    if (this.submittedApplications != null){
                        for (Application__c app : this.submittedApplications){
                            Boolean allACPsAreRejected = false;
                            if (app.Application_Course_Preferences__r != null && !app.Application_Course_Preferences__r.isEmpty()) {
                                for(Application_Course_Preference__c acp : app.Application_Course_Preferences__r) {
                                    // a. if rejected by Monash
                                    if (String.isNotBlank(acp.Outcome_Status_LOV__c) && REJECTED_OUTCOME_STATUSES.contains(acp.Outcome_Status_LOV__r.Value__c)) {
                                        allACPsAreRejected = true;
                                    // b. or If Monash offered, but Applicant rejected that Offer
                                    } else if (String.isNotBlank(acp.Outcome_Status_LOV__c) && ACCEPTED_OUTCOME_STATUSES.contains(acp.Outcome_Status_LOV__r.Value__c)
                                        && String.isNotBlank(acp.Offer_Response_Status_LOV__c) && REJECTED_OFFER_RESPONSE_STATUSES.contains(acp.Offer_Response_Status_LOV__r.Value__c)) {
                                        allACPsAreRejected = true;
                                    // if neither of the above, Application is either In-progress or Accepted
                                    } else {
                                        allACPsAreRejected = false;
                                        break;
                                    }
                                }
                                if (allACPsAreRejected) {
                                    rejected.add(app);
                                }
                            }
                        }
                    }
                }
                return rejected;
            }
        }
        // create a set of Agencies 
        public Set<Id> conflictingAppnAgencies {
            get {
                conflictingAppnAgencies = new Set<Id> ();
                if (this.filteredApplications != null) {
                    for (Application__c app : this.filteredApplications) {
                        conflictingAppnAgencies.add(app.Agent__c);
                    }
                }
                return conflictingAppnAgencies;
            }
            set;
        }
        public List<Application_Course_Preference__c> nonRejectedACPs {
            get {
                nonRejectedACPs = new List<Application_Course_Preference__c> ();
                if (this.submittedApplications != null){
                    for (Application__c app : this.submittedApplications){
                        if (app.Application_Course_Preferences__r != null && !app.Application_Course_Preferences__r.isEmpty()) {
                            for(Application_Course_Preference__c acp : app.Application_Course_Preferences__r) {
                                // a. if NOT rejected by Monash
                                if ((String.isBlank(acp.Outcome_Status_LOV__c) || !REJECTED_OUTCOME_STATUSES.contains(acp.Outcome_Status_LOV__r.Value__c)) ||
                                    // b. or If Monash offered, and Applicant hasn't rejected that Offer
                                    (String.isNotBlank(acp.Outcome_Status_LOV__c) && ACCEPTED_OUTCOME_STATUSES.contains(acp.Outcome_Status_LOV__r.Value__c)
                                        && (String.isBlank(acp.Offer_Response_Status_LOV__c) || !REJECTED_OFFER_RESPONSE_STATUSES.contains(acp.Offer_Response_Status_LOV__r.Value__c)))) {
                                        nonRejectedACPs.add(acp);
                                }
                            }
                        }
                    }
                }
                return nonRejectedACPs;
            }
            set;
        }
    }
    public virtual class AffiliationException extends Exception {}
}