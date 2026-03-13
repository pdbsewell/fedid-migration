/**
 * @author Ibrahim Rumi
 * @date 29-05-2024
 * @group Monash Abroad
 * @description Trigger handler for AO_Form_Submission__c object (Monash Abroad)
 **/
public with sharing class AOFormSubmissionTriggerHandler {

     /**
     * @description - handler class to create a program applicant when a form submission record is created
     * @revision    
     */
    public class createProgramApplicant extends TriggerAbstract {

        public Map<id,AO_Form_Submission__c> fsMap = new Map<id,AO_Form_Submission__c>();
        public override void process(SObject sobj) {
			AO_Form_Submission__c newObj = (AO_Form_Submission__c) sobj;
            if(newObj.AO_Status__c == AOFormSubmissionHelper.SUBMITTED || newObj.AO_Status__c == AOFormSubmissionHelper.DRAFT){
                fsMap.put(newObj.id,newObj);
            }
		}
        
        public override void process(SObject sobj, SObject oldRec) {
        	AO_Form_Submission__c newObj = (AO_Form_Submission__c) sobj;
            AO_Form_Submission__c oldObj = (AO_Form_Submission__c) oldRec;
            
            if(oldObj.AO_Status__c != newObj.AO_Status__c &&
               newObj.AO_Status__c == AOFormSubmissionHelper.SUBMITTED ){
                fsMap.put(newObj.id,newObj);
            }
        }

        public override void execute() {
			try {
				AOFormSubmissionHelper.handleFormSubmissions(fsMap);
			} catch(Exception e) {
				nebula.logger.exception(e.getMessage(), e);
                
			}
        }

    }
}