/**
 * @author : [Babyshark]
 * @description : Trigger Handler class for Program Applicant
 *  - Handles generation of subsequent form automatically on chnage of status on Primary
 *  - Hanldes auatomated emails from SF to Students
 * @group : Abroad Outbound
 * @date : 16/05/2024
 * @rev
 * 
 */ 
public with sharing class AOProgramApplicantTriggerHandler {

    private static final Set<String> AUTOMATED_STATUS = new Set<String>{'Accepted','Successful', 'Allocated','Conditionally Allocated'};
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_SUBMITTED = 'Submitted';
    public class CreateAutomatedForms extends TriggerAbstract {

        List<AO_Program_Applicant__c> recList = new List<AO_Program_Applicant__c>();
        Set<Id> programIds = new Set<Id>();

        public override void process(SObject sobj, SObject oldRec) {
            
            AO_Program_Applicant__c newRec = (AO_Program_Applicant__c) sobj;
            AO_Program_Applicant__c previousRec = (AO_Program_Applicant__c) oldRec;
            if(newRec.AO_Application_Status__c != previousRec.AO_Application_Status__c && AUTOMATED_STATUS.contains(newRec.AO_Application_Status__c)){
                recList.add(newRec);
                programIds.add(newRec.AO_Program__c);
            }
        }

        public override void execute() {
            try {
                if(!recList.isEmpty()) {
                    List<AO_Form_Submission__c> subsequentForms = new List<AO_Form_Submission__c>();
                    Map<Id, Set<Id>> applicantformMap = new Map<Id, Set<Id>>();
                    Map<Id, List<AO_Program_Form_Map__c>> programformMap = new Map<Id, List<AO_Program_Form_Map__c>>();
                    for(AO_Form_Submission__c objS : [SELECT AO_Program_Form_Map__c,AO_Program_Applicant__c, Id From AO_Form_Submission__c WHERE AO_Program_Applicant__c IN:recList AND AO_Program_Form_Map__c!= null WITH SYSTEM_MODE ]){
                        if(applicantformMap.containsKey(objS.AO_Program_Applicant__c)){
                            Set<Id> tempSet = applicantformMap.get(objS.AO_Program_Applicant__c);
                            tempSet.add(objS.AO_Program_Form_Map__c);
                            applicantformMap.put(objS.AO_Program_Applicant__c, tempSet);
                        }else{
                            applicantformMap.put(objS.AO_Program_Applicant__c, new Set<Id>{objS.AO_Program_Form_Map__c});
                        }
                    }
                    for(AO_Program_Form_Map__c objMap : [SELECT Id,AO_Form__c,AO_Enable_on_Condition__c,AO_Program__c FROM AO_Program_Form_Map__c WHERE AO_Program__c IN:programIds AND AO_Sequence__c = 'Subsequent' WITH SYSTEM_MODE ]){
                        if(programformMap.containsKey(objMap.AO_Program__c)){
                            List<AO_Program_Form_Map__c> tempSet = programformMap.get(objMap.AO_Program__c);
                            tempSet.add(objMap);
                            programformMap.put(objMap.AO_Program__c, tempSet);
                        }else{
                            programformMap.put(objMap.AO_Program__c, new List<AO_Program_Form_Map__c>{objMap});
                        }
                    }

                    for(AO_Program_Applicant__c objApp : recList){
                        if(applicantformMap.containsKey(objApp.Id) && programformMap.containskey(objApp.AO_Program__c)){
                            Set<Id> submissionSet = applicantformMap.containsKey(objApp.Id)?applicantformMap.get(objApp.Id):new Set<Id>();
                            for(AO_Program_Form_Map__c objMap : programformMap.get(objApp.AO_Program__c)){
                                if(objApp.AO_Application_Status__c == objMap.AO_Enable_on_Condition__c && !submissionSet.contains(objMap.Id)){
                                    subsequentForms.add(new AO_Form_Submission__c(AO_Program_Applicant__c = objApp.Id,
                                                                                    AO_Program_Form_Map__c = objMap.Id,
                                                                                    AO_Status__c = STATUS_DRAFT,
                                                                                    AO_Student__c = objApp.AO_Contact__c, 
                                                                                    AO_Form__c = objMap.AO_Form__c));
                                }
                            }
                        }
                    }
                    if(!subsequentForms.isEmpty()){
                        insert subsequentForms;
                    }
                }
            } catch(Exception e) {
                nebula.logger.exception(e.getMessage(), e);
            } 
        }
    }
    
    /**
     * @description Creates an Applicant Email record when a program applicant's status is Submitted
     */
    public class CreateAutomatedEmails extends TriggerAbstract {

        List<AO_Program_Applicant__c> recList = new List<AO_Program_Applicant__c>();

        public override void process(SObject sobj) {
            
            AO_Program_Applicant__c newRec = (AO_Program_Applicant__c) sobj;

            if(newRec.AO_Application_Status__c != null && newRec.AO_Application_Status__c == STATUS_SUBMITTED){
                recList.add(newRec);
            }
        }
        public override void process(SObject sobj, SObject oldRec) {
            
            AO_Program_Applicant__c newRec = (AO_Program_Applicant__c) sobj;
            AO_Program_Applicant__c previousRec = (AO_Program_Applicant__c) oldRec;
            if(newRec.AO_Application_Status__c != previousRec.AO_Application_Status__c&&
                newRec.AO_Application_Status__c == STATUS_SUBMITTED){
                recList.add(newRec);
            }
        }

        public override void execute() {
            try {
                if(!recList.isEmpty()) {
                    new AOProgramApplicantHelper().sendAutomatedComms(recList);
                }
            } catch(Exception e) {
                nebula.logger.exception(e.getMessage(), e);
                
            } 
        }
    }
}