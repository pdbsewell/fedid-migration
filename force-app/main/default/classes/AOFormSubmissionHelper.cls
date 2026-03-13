/**
 * @author Ibrahim Rumi
 * @date 19-07-2024
 * @group Monash Abroad
 * @description Helper class for AOFormSubmissionTrigger
 * 	handleFormSubmissions - manages creation of Program Applicant when Form is submitted by students
 **/
public class AOFormSubmissionHelper {

    private static final Map<String, String> SEQUENCE_STATUS_MAP = new Map<String, String>{
        'Primary' => 'Submitted'
    };
    public static final string SUBMITTED = 'Submitted';
    public static final string DRAFT = 'Draft';

    public static void handleFormSubmissions(Map<id,AO_Form_Submission__c> formSubmissionsMap) {
        Set<Id> pfmIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, ProgramApplicantWrapper> programApplicantWrapperMap = new Map<Id, ProgramApplicantWrapper>();
        Set<Id> programIds = new Set<Id>();
        
        try{
            
            for (AO_Form_Submission__c formSubmission : formSubmissionsMap.values()) {
                if (formSubmission.AO_Student__c != null) {
                    ProgramApplicantWrapper wrapper = new ProgramApplicantWrapper(formSubmission);
                    programApplicantWrapperMap.put(formSubmission.Id, wrapper);
                    pfmIds.add(formSubmission.AO_Program_Form_Map__c);
                    contactIds.add(formSubmission.AO_Student__c);
                }
            }
            
            // Query program form maps
            Map<Id, AO_Program_Form_Map__c> programFormMapMap = new Map<Id, AO_Program_Form_Map__c>([
                SELECT Id, AO_Program__c, AO_Sequence__c, AO_Form__c 
                FROM AO_Program_Form_Map__c 
                WHERE id IN :pfmIds
            ]);
            
            
            for (ProgramApplicantWrapper wrapper : programApplicantWrapperMap.values()) {
                if (programFormMapMap.containsKey(wrapper.formSubmission.AO_Program_Form_Map__c)) {
                    wrapper.programFormMap = programFormMapMap.get(wrapper.formSubmission.AO_Program_Form_Map__c);
                    programIds.add(wrapper.programFormMap.AO_Program__c);
                }
            }
            
            // Query programs
            Map<Id, AO_Program__c> programMap = new Map<Id, AO_Program__c>([
                SELECT Id, Start_Date__c, End_Date__c, AO_Country__c, AO_Program_Location__c 
                FROM AO_Program__c 
                WHERE Id IN :programIds
            ]);
            
            for (ProgramApplicantWrapper wrapper : programApplicantWrapperMap.values()) {
                Id programId = wrapper.programFormMap.AO_Program__c;
                if (programMap.containsKey(programId)) {
                    wrapper.program = programMap.get(programId);
                }
            }
            
            // Query existing program applicants
            Map<Id, Map<Id, AO_Program_Applicant__c>> contactProgramApplicantMap = new Map<Id, Map<Id, AO_Program_Applicant__c>>();
            for (AO_Program_Applicant__c applicant : [
                SELECT Id, AO_Contact__c, AO_Program__c , AO_Application_Status__c 
                FROM AO_Program_Applicant__c 
                WHERE AO_Contact__c IN :contactIds 
                AND AO_Program__c IN :programIds
            ]) {
                if (!contactProgramApplicantMap.containsKey(applicant.AO_Contact__c)) {
                    contactProgramApplicantMap.put(applicant.AO_Contact__c, new Map<Id, AO_Program_Applicant__c>());
                }
                contactProgramApplicantMap.get(applicant.AO_Contact__c).put(applicant.AO_Program__c, applicant);
            }
            
            List<AO_Program_Applicant__c> newApplicants = new List<AO_Program_Applicant__c>();
            List<AO_Program_Applicant__c> existingApplicantsToUpdate = new List<AO_Program_Applicant__c>();
            List<AO_Form_Submission__c> formSubmissionsToUpdate = new List<AO_Form_Submission__c>();
            
            // Process each form submission using the wrapper
            for (ProgramApplicantWrapper wrapper : programApplicantWrapperMap.values()) {
                Id programId = wrapper.programFormMap.AO_Program__c;
                Id contactId = wrapper.formSubmission.AO_Student__c;
                AO_Program__c program = wrapper.program;
                String status = '';
                
                if(wrapper.formSubmission.AO_Status__c != null && wrapper.formSubmission.AO_Status__c == SUBMITTED){
                        status = SEQUENCE_STATUS_MAP.get(wrapper.programFormMap.AO_Sequence__c);
                    }
                
                if (contactProgramApplicantMap.containsKey(contactId) && contactProgramApplicantMap.get(contactId).containsKey(programId)) {
                    wrapper.existingApplicant = contactProgramApplicantMap.get(contactId).get(programId);
                    
                    //Set Status of Existing Applicant
                    if( wrapper.existingApplicant != null && 
                        String.isNotBlank(status) &&
                        wrapper.existingApplicant.AO_Application_Status__c != status)
                        {
                            wrapper.existingApplicant.AO_Application_Status__c = status;  
                            
                            existingApplicantsToUpdate.add(wrapper.existingApplicant);
                        }
                } else {
                    
                    
                    wrapper.newApplicant = new AO_Program_Applicant__c(
                        AO_Contact__c = contactId,
                        AO_Program__c = programId,
                        AO_Start_Date__c = program?.Start_Date__c,
                        AO_End_Date__c = program?.End_Date__c,
                        AO_Application_Status__c = status,
                        AO_Country__c = program?.AO_Country__c,
                        AO_Program_Location__c = program?.AO_Program_Location__c
                    );
                    newApplicants.add(wrapper.newApplicant);
                }
                
                //formSubmissionsToUpdate.add(wrapper.formSubmission);
            }
            
            if (!newApplicants.isEmpty()) {
                insert newApplicants;
            } 
            
            if(!existingApplicantsToUpdate.isEmpty()){
                //system.debug(existingApplicantsToUpdate);
                update existingApplicantsToUpdate;
            }
              
            for (ProgramApplicantWrapper wrapper : programApplicantWrapperMap.values()) {
                AO_Form_Submission__c fs = new AO_Form_Submission__c();
                if (wrapper.newApplicant != null) {
                    fs.id = wrapper.formSubmission.Id;
                    fs.AO_Program_Applicant__c = wrapper.newApplicant.Id;
                    
                    formSubmissionsToUpdate.add(fs);
                }else if(wrapper.existingApplicant != null){
                    fs.id = wrapper.formSubmission.Id;
                    fs.AO_Program_Applicant__c = wrapper.existingApplicant.Id;
                    
                    formSubmissionsToUpdate.add(fs);
                }
            }
            
            
            if (!formSubmissionsToUpdate.isEmpty()) {
                update formSubmissionsToUpdate;
            }
        }catch(exception e){
            nebula.logger.exception(e.getMessage(), e);
        }
    }
    
    public class ProgramApplicantWrapper {
        public AO_Form_Submission__c formSubmission;
        public AO_Program_Form_Map__c programFormMap;
        public AO_Program__c program;
        public AO_Program_Applicant__c existingApplicant;
        public AO_Program_Applicant__c newApplicant;
        
        public ProgramApplicantWrapper(AO_Form_Submission__c formSubmission) {
            this.formSubmission = formSubmission;
        }
    }
      
}