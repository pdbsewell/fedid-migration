/**
 * @author Inderpal Dhanoa
 * @description Trigger Handler for Survey object.
 * @revision    Inderpal Dhanoa - 11.Dec.2023 - Initial Version
 */
public class SurveyTriggerHandler {
    /**
    * @description Auto-links Survey to Coaching Oppty.
    * @revision    DEC.11.2023  IDhanoa - Created
    */
    public class SyncSurveyDetails extends TriggerAbstract {
        public Set<Id> s_surveyIds = new Set<Id>();
        Id recType = Schema.SObjectType.Survey__c.getRecordTypeInfosByDeveloperName().get('Surveys').getRecordTypeId();
        
        public override void process(SObject record, SObject oldRec) {
            Survey__c newSurveyRecord = (Survey__c)record;
            Survey__c oldSurveyRecord = (Survey__c)oldRec;
            if(newSurveyRecord.RecordTypeId == recType && ((newSurveyRecord.Enquiry__c != oldSurveyRecord.Enquiry__c && String.IsNotBlank(String.valueOf(newSurveyRecord.Enquiry__c)) || 
               newSurveyRecord.Action_Taken__c != oldSurveyRecord.Action_Taken__c || newSurveyRecord.Process_owned_by__c != oldSurveyRecord.Process_owned_by__c))){
                records.add(newSurveyRecord);
                s_surveyIds.add(newSurveyRecord.Id);                
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!s_surveyIds.isEmpty()){
                Map<Id,List<Coaching_Opportunities__c>> m_surveyDetails = retrieveLinkedCoachingOpptyRecds(s_surveyIds);
                List<Coaching_Opportunities__c> linkedCoachOpptyRecds;
                List<Coaching_Opportunities__c> l_updateCoachOpptyRecds = new List<Coaching_Opportunities__c>();
                Coaching_Opportunities__c updateCoachOpptyRecd;
                String s_ownerId;
                for(Survey__c survey : (List<Survey__c>)records){
                    if(m_surveyDetails.containsKey(survey.Id)){
                        linkedCoachOpptyRecds = m_surveyDetails.get(survey.Id);
                        for(Coaching_Opportunities__c linkedCoachOppty : linkedCoachOpptyRecds){
                            updateCoachOpptyRecd = new Coaching_Opportunities__c();
                            updateCoachOpptyRecd.Id = linkedCoachOppty.Id;
                            updateCoachOpptyRecd.Enquiry_Number__c = linkedCoachOppty.Survey__r.Enquiry__c;
                            s_ownerId = String.ValueOf(linkedCoachOppty.Survey__r.Enquiry__r.OwnerId);
                            If(s_ownerId.startsWith('005')){
                                updateCoachOpptyRecd.Officer_TC_Faculty_Other_Sources__c = linkedCoachOppty.Survey__r.Enquiry__r.OwnerId; 	   
                            }else{
                                survey.addError(Label.SurveySyncError);
                            }                            
                            updateCoachOpptyRecd.Summary_of_error__c = linkedCoachOppty.Survey__r.Action_Taken__c;
                            updateCoachOpptyRecd.Process_Owner__c = linkedCoachOppty.Survey__r.Process_owned_by__c;
                            l_updateCoachOpptyRecds.add(updateCoachOpptyRecd);
                        }
                    }
                    if(!l_updateCoachOpptyRecds.isEmpty()){
                    	try{
                            update l_updateCoachOpptyRecds;
                        }catch(Exception ex){
                            LogUtilityException.logException(ex,'SurveyTriggerHandler SyncSurveyDetails.execute');
                            throw ex;
                        }    
                    }
                }
            }
            LogUtilityException.getLimits();
        }
        
        public Map<Id,List<Coaching_Opportunities__c>> retrieveLinkedCoachingOpptyRecds(Set<Id> s_surveyIds){
            Map<Id,List<Coaching_Opportunities__c>> m_surveyDetails = new Map<Id,List<Coaching_Opportunities__c>>();
            List<Coaching_Opportunities__c> linkedCoachOpptyRecds ;
            for(Coaching_Opportunities__c linkedCoachOppty : [SELECT Id,Enquiry_Number__c, Officer_TC_Faculty_Other_Sources__c, Survey__c, Survey__r.Enquiry__c, 
                                                              Survey__r.Enquiry__r.OwnerId, Survey__r.Action_Taken__c, Survey__r.Process_owned_by__c 
                                          					  FROM Coaching_Opportunities__c WHERE Survey__c IN :s_surveyIds]){
               if(m_surveyDetails.containsKey(linkedCoachOppty.Survey__c)){
                  linkedCoachOpptyRecds = m_surveyDetails.get(linkedCoachOppty.Survey__c);
               }else{
                  linkedCoachOpptyRecds = new List<Coaching_Opportunities__c>();
               }
               linkedCoachOpptyRecds.add(linkedCoachOppty);
               m_surveyDetails.put(linkedCoachOppty.Survey__c, linkedCoachOpptyRecds);
            }
            return m_surveyDetails;
        }
    }
}