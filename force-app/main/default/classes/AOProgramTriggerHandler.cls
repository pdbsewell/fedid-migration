/**
 * @author : [Babyshark]
 * @description : Trigger Handler class for Program Applicant
 *  - Handles duplicate Name for Program
 *  - Hanldes Dates on Applicant
 * @group : Abroad Outbound
 * @date : 16/08/2024
 * @rev
 * 
 */ 
public with sharing class AOProgramTriggerHandler {
    public static final String DUPLICATE_ERROR_MSG = 'The Program Name has already been taken , Please use a different Name';
    public class CheckDuplicateName extends TriggerAbstract {

        List<AO_Program__c> recList = new List<AO_Program__c>();
        Set<String> programNames = new Set<String>();

        public override void process(SObject sobj) {
            AO_Program__c newRec = (AO_Program__c) sobj;
            if(String.isNotBlank(newRec.Name)){
                recList.add(newRec);
                programNames.add(newRec.Name);
            }
        }
        public override void process(SObject sobj, SObject oldRec) {
            
            AO_Program__c newRec = (AO_Program__c) sobj;
            AO_Program__c previousRec = (AO_Program__c) oldRec;
            if(String.isNotBlank(newRec.Name) && newRec.Name != previousRec.Name){
                recList.add(newRec);
                programNames.add(newRec.Name);
            }
        }

        public override void execute() {
            try {
                Map<String, Id> existingNames = new Map<String, Id>();
                if(!recList.isEmpty()) {
                    for(AO_Program__c objP : [SELECT Id, Name FROM AO_Program__c WHERE Name IN: programNames WITH SECURITY_ENFORCED]){
                        existingNames.put(objP.Name, objP.Id);
                    }
                }
                for(AO_Program__c objProgram : recList){
                    if(existingNames.containsKey(objProgram.Name) && objProgram.Id != existingNames.get(objProgram.Name)){
                        objProgram.addError(DUPLICATE_ERROR_MSG);
                    }
                }
            } catch(Exception e) {
                nebula.logger.exception(e.getMessage(), e);
            } 
        }
    }
}