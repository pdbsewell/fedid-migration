/**
 * @author : [Babyshark]
 * @description : Handler class for ContentDocumentTrigger 
 *                  AOupdateSubmissionResponse - Re-evaluates the Json in case a file is deleted from Form Submission record 
 * @group : Abroad Outbound
 * @date : 16/09/2024
 * @rev
 * 
 */ 
public with sharing class ContentDocumentTriggerHandler {
    public with sharing class AOupdateSubmissionResponse extends TriggerAbstract {

        List<ContentDocument> recList = new List<ContentDocument>();
        Set<String> deletedIds  = new Set<String>();
        public override void process(SObject sobj) {
            ContentDocument newRec = (ContentDocument) sobj;
            recList.add(newRec);
            deletedIds.add(newRec.Id);
        }
        public override void execute() {
            Set<Id> formSubmissionIds = new Set<Id>();
            //Checks if deleted Document relates to Form Submission Object
            String submissionPrefix = Schema.SObjectType.AO_Form_Submission__c.getKeyPrefix();
            for(ContentDocumentLink cdl : [SELECT Id,LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: deletedIds WITH SECURITY_ENFORCED]){
                if(cdl.LinkedEntityId.toString().startsWith(submissionPrefix)){
                    formSubmissionIds.add(cdl.LinkedEntityId);
                }
            }
            if(!formSubmissionIds.isEmpty()){
                List<AoFormClientController.Answer> answers = new List<AoFormClientController.Answer>();
                List<AO_Form_Submission__c> updateList = new List<AO_Form_Submission__c>();
                for(AO_Form_Submission__c obJS : [SELECT Id, AO_Response_Json__c FROM AO_Form_Submission__c WHERE Id IN:formSubmissionIds WITH SECURITY_ENFORCED]){
                    //Deserialize the Student response in Object type
                    List<Object> individualResponseList = (List<Object>) JSON.deserializeUntyped(obJS.AO_Response_Json__c);
                    for(Object obj: individualResponseList){
                        AoFormClientController.Answer ans = new AoFormClientController.Answer();
                        Map<String, Object> answer = (Map<String, Object>) obj;
                        if(!answer.isEmpty()){  
                            ans.name = (String)answer.get('name');
                            ans.label = (String)answer.get('label');
                            ans.elementId =(String)answer.get('elementId');
                            ans.type = (String)answer.get('type');
                            String elemType = (String)answer.get('type');
                            //If selected node of JSON is of file type then remove the file upload node from Object type in order to update the response 
                            if(elemType == 'file upload') {
                                List<Object> files = (List<Object>)answer.get('value');
                                List<Object> fileOutput = new List<Object>();
                                if(files!= null && !files.isEmpty()){
                                    for(Object file :files) {
                                        Map<String,Object> fileMap = (Map<String,Object>)file;
                                        Map<String, String> fileTemp =  new Map<String, String>();
                                        if(!deletedIds.contains((String)fileMap.get('documentId'))){
                                            fileTemp.put('name', (String)fileMap.get('name'));
                                            fileTemp.put('documentId',(String)fileMap.get('documentId'));
                                            fileOutput.add(fileTemp);
                                        }
                                    }
                                    ans.value = fileOutput;
                                }
                            }
                            else if(elemType == 'checkbox'){
                                //Parse the boolean type of value from string
                                ans.value = (Boolean)answer.get('value');
                            }
                            else{
                                ans.value = (String)answer.get('value');
                            }
                        }
                        answers.add(ans);
                    }
                    //update the response json based upon document evaluation
                    obJS.AO_Response_Json__c = JSON.serializePretty(answers);
                    updateList.add(obJS);
                }
                try{
                    if(!updateList.isEmpty()){
                        update updateList;
                    }
                }
                catch(Exception ex){
                    nebula.logger.exception(ex.getMessage(), ex);
                }
            }
        }
    }
}