/**
 * @author      Kristian Vegerano
 * @description Container class for all the document checklist rule evaluations
 * @group       Document Checklist Rules Evaluation
 * @revision    30/05/2019 - Kristian Vegerano - Created
 */
public with sharing class DocumentChecklistRuleChecks {
    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant needs to submite documents to verify their name change
     *              This criteria is valid when
     *                  - Applicant Previous Surname is not blank.
     * @group       Document Checklist Rule Check
     * @revision    17/06/2019 - Kristian Vegerano - Created
     * @revision    10/4/2025 - APRivera - remove the exclusion of verified test results
     */
    public with sharing class NameChangeCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;

            //Check if age is below 18 on time of submission
            if(String.isNotBlank(contextApplication.Applicant__r.Previous_Surname__c)){
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant has expressed a credit intention
     * @group       Document Checklist Rule Check
     * @revision    29/08/2019 - Kristian Vegerano - Created
     */
    public with sharing class CreditIntentionCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Application__c contextApplication = (Application__c)evaluatedObject;

            //Check if applicant has expressed credit intention
            if(contextApplication.Credit_Intention__c){
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant need to submit visa 
     *              This criteria is valid when
     *                  - Applicant has been refused an entry visa to any country?
     *                  - Have you breached any visa conditions in any country?
     *                  - Do you have any medical or health issues that may prevent you from obtaining your visa?
     *                  - Have you been issued a protection visa in any country to date?
     *                  - Have you been convicted of any crime or offence in any country?
     * @group       Document Checklist Rule Check
     * @revision    17/06/2019 - Kristian Vegerano - Created
     */
    public with sharing class VisaCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;

            //Check if age is below 18 on time of submission
            if(contextApplication.Refused_entry_visa_to_any_country__c == 'Yes' ||
               contextApplication.Breached_visa_condition__c == 'Yes' ||
               contextApplication.Medical_health_prevent_visa__c == 'Yes' ||
               contextApplication.Protection_visa_in_any_country__c == 'Yes' ||
               contextApplication.Convicted_of_crime_offence__c == 'Yes'){

                result = true;

            }

            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant need to submit guardian/parent consent form
     * @group       Document Checklist Rule Check
     * @revision    30/05/2019 - Kristian Vegerano - Created
     */
    public with sharing class AgeCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for age check unless the criteria proves that they need to send one //When birthday is blank then ask for the consent form
            Application__c contextApplication = (Application__c)evaluatedObject;

            //Check if age is below 18 on time of submission
            if(contextApplication.Applicant__c != null){
                //Set comparison date 
                Date referenceBirthDate;
                if(contextApplication.Submitted_Date__c != null){
                    referenceBirthDate = contextApplication.Submitted_Date__c;
                }else{
                    referenceBirthDate = Date.parse(System.NOW().format('dd/MM/yyyy', 'Australia/Sydney'));
                }
                referenceBirthDate = referenceBirthDate.addYears(-18);
                
                //Applicant's birthdate is within today and today - 18 years or
                //Applicant's birthdate is within application date of submission and application date of submission - 18 years or
                if(((contextApplication.Birthdate__c == null) || (contextApplication.Birthdate__c > referenceBirthDate))
                //Only require checklist if the applicant is an international student
                && (ApplicationAssessmentUtil.getCitizenshipType(contextApplication) == 'INTERNATIONAL')){
                    result = true;
                }
            }

            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant need to submit forms for an complete secondary qualification
     * @group       Document Checklist Rule Check
     * @revision    30/05/2019 - Kristian Vegerano - Created
     */
    public with sharing class CompleteSecondaryQualificationCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if secondary education
            //Check Year_of_Completion__c if populated
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_SECONDARY_REC_TYPE && 
               contextContactQualification.Year_of_Completion__c != null && 
               contextContactQualification.Verification_Status__c != 'Verified'){

                result = true;

            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant need to submit forms for an incomplete secondary qualification
     * @group       Document Checklist Evaluation
     * @revision    30/05/2019 - Kristian Vegerano - Created
     */
    public with sharing class IncompleteSecondaryQualificationCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if secondary education
            //Check Year_of_Completion__c is blank
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_SECONDARY_REC_TYPE && 
               contextContactQualification.Year_of_Completion__c == null && 
               contextContactQualification.Verification_Status__c != 'Verified'){

                result = true;

            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant need to submit English Test Results 
     *                  - The qualification is is an english test
     *                  - The qualification is complete
     * @group       Document Checklist Evaluation
     * @revision    17/06/2019 - Kristian Vegerano - Created
     * @revision    10/4/2025 - APRivera - remove the exclusion of verified test results
     */
    public with sharing class CompleteEnglishTestCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if english test
            //Check Date_Achieved__c if populated
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_ENGLISH_REC_TYPE &&
                    contextContactQualification.English_Proficiency__c == null &&
                    contextContactQualification.Date_Achieved__c != null){

                result = true;
            
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to confirm English Prof for Grad research application
     *          
     * @group       Document Checklist Evaluation
     */
    public with sharing class GRCompleteEnglishTestCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if english test
            //Check Date_Achieved__c if populated
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_ENGLISH_REC_TYPE &&
                    contextContactQualification.English_Proficiency__c != null &&
                    contextContactQualification.Date_Achieved__c != null){

                result = true;
            
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to confirm English Prof 
     *          
     * @group       Document Checklist Evaluation
     */
    public with sharing class EnglishEvidenceTestCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if english test
            //Check English_Proficiency__c values
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_ENGLISH_REC_TYPE && 
               (contextContactQualification.English_Proficiency__c == 'ENG-STUDY' || 
               contextContactQualification.English_Proficiency__c == 'MONASH-OS' ||
               contextContactQualification.English_doc_required_during_assessment__c)){
                
                result = true;
            
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant need to submit English Test Results  
     *              This criteria is valid when
     *                  - The qualification is is an english test
     *                  - The qualification is not complete yet
     * @group       Document Checklist Evaluation
     * @revision    08/07/2019 - Kristian Vegerano - Created
     * @revision    10/4/2025 - APRivera - remove the exclusion of verified test results
     */
    public with sharing class IncompleteEnglishTestCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if english test
            //Check Expected_date_of_completion__c if populated
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_ENGLISH_REC_TYPE && 
               contextContactQualification.Expected_date_of_completion__c != null &&
               contextContactQualification.English_Proficiency__c == null){

                result = true;

            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant need to submit evidence of Tertiary non Monash qualifications
     * @group       Document Checklist Evaluation
     * @revision    17/06/2019 - Kristian Vegerano - Created
     */
    public with sharing class CompleteTertiaryQualificationCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if tertiary education
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_TERTIARY_REC_TYPE &&
               contextContactQualification.Evidence_Type__c == null && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;

                //Excludes monash related tertiary qualifications from being asked with checklist
                //Excludes contact qualification where the institution is selected from the data reference list and has selected a monash related institution
                if(contextContactQualification.Institution_Name__c != null){
                    if(contextContactQualification.Institution_Name__c.containsIgnoreCase('monash')){
                        result = false;
                    }
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of Tertiary for Grad Research application
     * @group       Document Checklist Evaluation
     * @revision    1/07/2025 - Vishal Gupta - Created
     */
    public with sharing class GRTertiaryQualificationCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if tertiary education
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_TERTIARY_REC_TYPE &&
               contextContactQualification.Evidence_Type__c != null && //Evidence type field is used for Grad research application only
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;

                //Excludes monash related tertiary qualifications from being asked with checklist
                //Excludes contact qualification where the institution is selected from the data reference list and has selected a monash related institution
                if(contextContactQualification.Institution_Name__c != null){
                    if(contextContactQualification.Institution_Name__c.containsIgnoreCase('monash')){
                        result = false;
                    }
                }
            }
            
            return result;
        }
    }
    
    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    09/08/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchAwardCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;
            //Check record type if awards
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_AWARDS_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;

            }
            
            return result;
        }
    }
    
    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    13/08/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchExperienceCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;
            //Check record type if Employment_and_Research
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_EXPERIENCE_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    14/08/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchRefereeCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;
            //Check record type if Referee
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_REFEREE_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    14/08/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchMusicCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;
            //Check record type if music
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_MUSIC_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    14/08/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchPublicationCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;
            //Check record type if publications
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_PUBLICATIONS_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;
            }
            
            return result;
        }
    }
    
    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    14/08/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchTheatrePerformanceCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;
            //Check record type if Theatre
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_THEATRE_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    26/08/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchExhibitionCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;
            //Check record type if exhibition
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_EXHIBITION_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    26/08/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchCreativeWorkCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;
            //Check record type if creative work
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_CREATIVE_WORK_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified'){
                
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation needed for checking if the applicant need to submit evidence of GR qualifications
     * @group       Document Checklist Evaluation
     * @revision    13/09/2024 - Vishal Gupta - Created
     */
    public with sharing class GraduateResearchMiscCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if other
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_OTHER_REC_TYPE && 
               contextContactQualification.Title_of_Publication_Work_Chapter_Paper__c != null){
                
                result = true;

            }
            
            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation for Graduate Research applications on Curriculum Vitae
     * @group       Document Checklist Rule Check
     */
    public with sharing class CurriculumVitaeCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;

            if(contextApplication.Type_Of_Study__c == 'Graduate Research') {
                result = true;
            }

            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Evaluation for Graduate Research applications on Curriculum Vitae
     * @group       Document Checklist Rule Check
     */
    public with sharing class AgentCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;
            if(contextApplication.Type_Of_Study__c == 'Graduate Research' && contextApplication.Agent__c != null && contextApplication.Applicant_Agent__c == 'Yes') {
                result = true;
            }

            return result;
        }
    }

    /**
     * @author      Sethu Venna
     * @description Check if the applicant has a previous degree or scholarship
     * @group       Document Checklist Rule Check
     */
    public with sharing class PreviousResearchDegreeOrScholarshipCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {

            Boolean result = false; 
            Application_Course_Preference__c contextACP = (Application_Course_Preference__c)evaluatedObject;
            if(contextACP.Has_Previous_Res_Degree_or_Scholarship__c == true) {
                result = true;
            }
            return result;
        }
    }

    /**
     * @author      Davey Yu
     * @description Evaluation for Graduate Research applications on Equity Scholarship Application Form
     * @group       Document Checklist Rule Check
     */
    public with sharing class EquityScholarshipCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;

            //Check if age is below 18 on time of submission
            if(contextApplication.Apply_for_Equity_Scholarship__c) {
                result = true;
            }

            return result;
        }
    }

    /**
     * @author      Davey Yu
     * @description Research Program Invitation Details
     * @group       Document Checklist Rule Check
     */
    public with sharing class ResearchProgramInvitationDetails implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;
           
            List<Application_Course_Preference__c> acp = [Select id FROM Application_Course_Preference__c WHERE Application__c =: contextApplication.id LIMIT 1];
            //Check if age is below 18 on time of submission
            if(contextApplication.Type_Of_Study__c == 'Graduate Research' && !acp.isEmpty()) {
                result = true;
            }            

            return result;
        }
    }

    /**
     * @author      Davey Yu
     * @description Research Program Research Proposal
     * @group       Document Checklist Rule Check
     */
   public with sharing class ResearchProgramResearchProposal implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;
            
            List<Application_Course_Preference__c> acp = [Select id, Research_Title__c FROM Application_Course_Preference__c WHERE Application__c =: contextApplication.id LIMIT 1];
            //Check if age is below 18 on time of submission
            if(!acp.isEmpty() && acp[0].Research_Title__c != null) {
                result = true;
            }
            return result;
        }
    }

    /**
     * @author      Davey Yu
     * @description Research Program Supervisor Form
     * @group       Document Checklist Rule Check
     */
    public with sharing class ResearchProgramSupervisorForm implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;
            List<Application_Course_Preference__c> acp = [Select id, External_Supervisor__c FROM Application_Course_Preference__c WHERE Application__c =: contextApplication.id LIMIT 1];
            //Check if age is below 18 on time of submission
            if(!acp.isEmpty() && acp[0].External_Supervisor__c) {
                result = true;
            }

            return result;
        }
    }
    
    /**
     * @author      Davey Yu
     * @description Research Program Sponsorship Letter
     * @group       Document Checklist Rule Check
     */
    public with sharing class ResearchProgramSponsorshipLetter implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;
            List<Application_Course_Preference__c> acp = [Select id, External_Funding__c FROM Application_Course_Preference__c WHERE Application__c =: contextApplication.id LIMIT 1];

            //Check if age is below 18 on time of submission
            if(!acp.isEmpty() && acp[0].External_Funding__c) {
                result = true;
            }

            return result;
        }
    }

    /**
     * @author      Vishal Gupta
     * @description Research Program Sponsorship Letter for existing scholatship
     * @group       Document Checklist Rule Check
     */
    public with sharing class ResearchProgramExistingSponsorshipLetter implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;
            List<Application_Course_Preference__c> acp = [Select id, External_Funding__c, Applied_for_External_Scholarship_Name__c FROM Application_Course_Preference__c WHERE Application__c =: contextApplication.id LIMIT 1];

            //Check if age is below 18 on time of submission
            if(!acp.isEmpty() && !acp[0].External_Funding__c && !String.isBlank(acp[0].Applied_for_External_Scholarship_Name__c)) {
                result = true;
            }

            return result;
        }
    }

    /**
     * @author      Davey Yu
     * @description Research Program Attendance Commitments
     * @group       Document Checklist Rule Check
     */
    public with sharing class ResearchProgramAppointmentCommitments implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false; //Default it to don't ask the applicant for visa check unless the criteria proves that they need to send one
            Application__c contextApplication = (Application__c)evaluatedObject;
            List<Application_Course_Preference__c> acp = [Select id, Employment_During_Research__c, Course_Offering__r.Attendance_Type__c FROM Application_Course_Preference__c WHERE Application__c =: contextApplication.id LIMIT 1];
            //Check if age is below 18 on time of submission
            if(!acp.isEmpty() && acp[0].Employment_During_Research__c && (acp[0].Course_Offering__r.Attendance_Type__c == 'Part Time' || acp[0].Course_Offering__r.Attendance_Type__c == 'PT')) {
                result = true;
            }

            return result;
        }
    }


    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant need to submit evidence of other qualifications
     * @group       Document Checklist Evaluation
     * @revision    17/06/2019 - Kristian Vegerano - Created
     */
    public with sharing class OtherQualificationCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Contact_Qualification__c contextContactQualification = (Contact_Qualification__c)evaluatedObject;

            //Check record type if other
            if(contextContactQualification.RecordTypeId == ContactQualificationUtility.CONTACT_QUALIFICATION_OTHER_REC_TYPE && 
               contextContactQualification.Verification_Status__c != 'Verified' && contextContactQualification.Title_of_Publication_Work_Chapter_Paper__c == null){
                
                result = true;

            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant claimed at least 1 work experience
     * @group       Document Checklist Evaluation
     * @revision    16/10/2019 - Kristian Vegerano - Created
     */
    public with sharing class WorkExperienceCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Application__c contextApplication = (Application__c)evaluatedObject;

            //Check if application has child application work experience provided records
            if(contextApplication.Application_Work_Experiences_Provided__r != null){
                if(!contextApplication.Application_Work_Experiences_Provided__r.isEmpty()){
                    result = true;
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the application has atleast one unit preference that is tagged having prerequisite
     * @group       Document Checklist Evaluation
     * @revision    09/02/2021 - Kristian Vegerano - Created
     */
    public with sharing class UnitPrerequisiteCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Application__c contextApplication = (Application__c)evaluatedObject;

            //Check if application has child application work experience provided records
            if(contextApplication.Has_Unit_Prerequisite__c){
                result = true;
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the application course preference has a course prerequisite
     * @group       Document Checklist Evaluation
     * @revision    02/08/2021 - Kristian Vegerano - Created
     */
    public with sharing class CoursePrerequisiteCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Application_Course_Preference__c contextACP = (Application_Course_Preference__c)evaluatedObject;

            //Check if application course preference course has a course prerequisite
            if(contextACP.Course_Code__c != null){
                if(DocumentChecklistRuleServices.courseSpecificDocumentMap.containsKey(contextACP.Course_Code__c)){
                    result = true;
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the application faculty preference has a course prerequisite
     * @group       Document Checklist Evaluation
     * @revision    02/08/2021 - Kristian Vegerano - Created
     */
    public with sharing class FacultyPrerequisiteCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Application_Course_Preference__c contextACP = (Application_Course_Preference__c)evaluatedObject;
            
            //Check if application course preference course has a course prerequisite
            if(contextACP.Managing_Faculty__c != null){
                if(DocumentChecklistRuleServices.facultySpecificDocumentMap.containsKey(contextACP.Managing_Faculty__c)){
                    result = true;
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant has needs to provide a proof of payment for the signed offer
     * @group       Document Checklist Evaluation
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class AcceptancePaymentProofCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if quote status is signed
            if(contextOpportunity.Offer_Type__c == 'OFFER'){
                //if(contextOpportunity.StageName != null){
                //    if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                        result = true;
                //    }
                //}
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the under 18 applicant has needs to provide a proof of guardian's signature 
     * @group       Document Checklist Evaluation
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class GuardianSignatureCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if quote status is signed, applicant is under 18 and guardian email is provided
            if(contextOpportunity.Offer_Type__c == 'OFFER' || contextOpportunity.Offer_Type__c == 'COND-OFFER'){
                if(contextOpportunity.PrimaryContact__r.Under_18__c && !contextOpportunity.Guardian_Provided_Email__c){
                //    if(contextOpportunity.StageName != null){
                //        if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                            result = true;
                //        }
                //    }
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the applicant has met the conditions for the offer
     * @group       Document Checklist Evaluation
     * @revision    17/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class MeetingConditionProofCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if quote status is signed, and has a quote line item linked to an acp with offer condition
            if(contextOpportunity.Offer_Type__c == 'COND-OFFER'){
                //if(contextOpportunity.StageName != null){
                //    if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                        if(contextOpportunity.OpportunityLineItems != null){
                            for(OpportunityLineItem loopOpporunityLine : contextOpportunity.OpportunityLineItems){
                                if(loopOpporunityLine.Application_Course_Preference__r.Offer_Condition__c != null){
                                    result = true;
                                }
                            }
                        }
                //    }
                //}
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if the under 18 applicant is required to send a document
     * @group       Document Checklist Evaluation
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class UnderageWelfareAccomodationCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if offer type is offer
            if(contextOpportunity.Offer_Type__c == 'OFFER'){
                //Set comparison date 
                Date referenceBirthDate;
                if(contextOpportunity.Quote_Start_Date__c != null){
                    referenceBirthDate = contextOpportunity.Quote_Start_Date__c;
                }else{
                    referenceBirthDate = Date.parse(System.NOW().format('dd/MM/yyyy', 'Australia/Sydney'));
                }
                referenceBirthDate = referenceBirthDate.addYears(-18);

                //Check if offer is signed and the applicant is underage
                if((contextOpportunity.PrimaryContact__r.BirthDate > referenceBirthDate)){
                    //if(contextOpportunity.StageName != null){
                    //    if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                            result = true;
                    //    }
                    //}
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if applicant is requred to supply evidence of their health cover
     * @group       Document Checklist Evaluation
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class OhscHealthCoverProofCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if quote status is signed, and applicant selected their own cover
            if(contextOpportunity.Offer_Type__c == 'OFFER'){
                if(contextOpportunity.Health_Cover_Provider_Type__c != null){
                    if(!contextOpportunity.Health_Cover_Provider_Type__c.equalsIgnoreCase('Allianz')){
                        //if(contextOpportunity.StageName != null){
                        //    if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                                result = true;
                        //    }
                        //}
                    }
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if applicant needs to supply additional documents for their visa
     * @group       Document Checklist Evaluation
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class VisaAdditionalInfoCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if quote status is signed, and applicant selected their own cover
            if(contextOpportunity.Offer_Type__c == 'OFFER'){
                if(contextOpportunity.Is_Visa_document_provided__c != null){
                    if(contextOpportunity.Is_Visa_document_provided__c.equalsIgnoreCase('Yes - Additional information required')){
                        //if(contextOpportunity.StageName != null){
                        //    if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                                result = true;
                        //    }
                        //}
                    }
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if applicant needs add documents to confirm their visa
     * @group       Document Checklist Evaluation
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class VisaConfirmCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if quote status is signed, and applicant selected their own cover
            if(contextOpportunity.Offer_Type__c == 'OFFER'){
                if(contextOpportunity.Is_Visa_document_provided__c != null){
                    if(contextOpportunity.Is_Visa_document_provided__c.equalsIgnoreCase('No')){
                        //if(contextOpportunity.StageName != null){
                        //    if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                                result = true;
                        //    }
                        //}
                    }
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if applicant needs to supply additional documents for their passport
     * @group       Document Checklist Evaluation
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class PassportAdditionalInfoCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if quote status is signed, and applicant selected their own cover
            if(contextOpportunity.Offer_Type__c == 'OFFER'){
                if(contextOpportunity.Is_passport_document_provided__c != null){
                    if(contextOpportunity.Is_passport_document_provided__c.equalsIgnoreCase('Yes - Additional information required')){
                        //if(contextOpportunity.StageName != null){
                        //    if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                                result = true;
                        //    }
                        //}
                    }
                }
            }
            
            return result;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Evaluation needed for checking if applicant needs add documents to confirm their passport
     * @group       Document Checklist Evaluation
     * @revision    14/02/2020 - Kristian Vegerano - Created
     */
    public with sharing class PassportConfirmCheck implements IDocumentRuleEvaluator {
        /**
        * @description Rule Check
        * @param evaluatedObject
        * @return boolean
        */
        public Boolean evaluateCriteria(SObject evaluatedObject) {
            //Initialize Variables
            Boolean result = false;
            Opportunity contextOpportunity = (Opportunity)evaluatedObject;

            //Check if quote status is signed, and applicant selected their own cover
            if(contextOpportunity.Offer_Type__c == 'OFFER'){
                if(contextOpportunity.Is_passport_document_provided__c != null){
                    if(contextOpportunity.Is_passport_document_provided__c.equalsIgnoreCase('No')){
                        //if(contextOpportunity.StageName != null){
                        //    if(contextOpportunity.StageName.equalsIgnoreCase('Signed')){
                                result = true;
                        //    }
                        //}
                    }
                }
            }
            
            return result;
        }
    }
}