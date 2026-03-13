/**
 * @author : [Babyshark]
 * @description : Trigger handler class for QuestionLibrary Object
 * - ValidateQuestionDuplication - Validates if a question is duplicate based upon Name and Type.
 * @group : Abroad Outbound
 * @date : 19/05/2024
 * @rev
 * 
 */
public with sharing class AOQuestionLibraryHandler {
    public static final String DUPLICATE_ERROR_MSG = 'The Question with same type has already been created please use the existing Question or rename your question';
    
    public class ValidateQuestionDuplication extends TriggerAbstract {

        List<AO_Question_Library__c> recList = new List<AO_Question_Library__c>();
        Set<String> nameSet = new Set<String>();
        Set<String> typeSet = new Set<String>();

        public override void process(SObject sobj) {
            AO_Question_Library__c newRec = (AO_Question_Library__c) sobj;
            //if(String.isNotBlank(newRec.Name) && String.isNotBlank(newRec.AO_Type__c)){
                recList.add(newRec);
                nameSet.add(newRec.Name);
                typeSet.add(newRec.AO_Type__c);
            //}
        }

        public override void process(SObject sobj, SObject oldRec) {
            AO_Question_Library__c newRec = (AO_Question_Library__c) sobj;
            AO_Question_Library__c previousRec = (AO_Question_Library__c) oldRec;
            if(newRec.Name != previousRec.Name || newRec.AO_Type__c != previousRec.AO_Type__c){
                recList.add(newRec);
                nameSet.add(newRec.Name);
                typeSet.add(newRec.AO_Type__c);
            }
        }

        public override void execute() {
            Set<String> uniqueSet = new Set<String>();
            
            try {
                for(AO_Question_Library__c objQL : [SELECT Id, Name, AO_Type__c FROM AO_Question_Library__c WHERE Name IN: nameSet AND AO_Type__c IN :typeSet WITH SECURITY_ENFORCED]){
                    uniqueSet.add(objQL.Name+'_'+objQL.AO_Type__c);
                    
                }
                if(!recList.isEmpty()) {
                    for(AO_Question_Library__c objQ : recList){
                        if(uniqueSet.contains(objQ.Name+'_'+objQ.AO_Type__c)){
                            
                            objQ.addError(DUPLICATE_ERROR_MSG);
                        }
                    }
                }
            } catch(Exception e) {
                nebula.logger.exception(e.getMessage(), e);
            } 
        }
    }
}