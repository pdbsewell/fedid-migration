/**
 * @author Inderpal Dhanoa
 * @description Trigger Handler for Coaching Oppty object.
 * @revision    Inderpal Dhanoa - 11.Dec.2023 - Initial Version
 */
public class CoachngOpptyTriggerHandler {
    /**
    * @description Auto-links Survey to Coaching Oppty.
    * @revision    DEC.11.2023  IDhanoa - Created
    */
    public class LinkSurveyDetails extends TriggerAbstract {
        public Set<Id> s_surveyIds = new Set<Id>();
        public override void process(SObject record) {
            Coaching_Opportunities__c coachOpptyRecord = (Coaching_Opportunities__c)record;
            if(String.isNotBlank(String.ValueOf(coachOpptyRecord.Survey__c))){
                records.add(coachOpptyRecord);
                s_surveyIds.add(coachOpptyRecord.Survey__c);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Coaching_Opportunities__c coachOpptyRecord = (Coaching_Opportunities__c)record;
            Coaching_Opportunities__c oldCoachOpptyRecord = (Coaching_Opportunities__c)oldRec;
            if(coachOpptyRecord.Survey__c != oldCoachOpptyRecord.Survey__c ){
                if(String.IsBlank(String.ValueOf(coachOpptyRecord.Survey__c))){
                    // Clear the fields  
                    coachOpptyRecord.Enquiry_Number__c = NULL; coachOpptyRecord.Officer_TC_Faculty_Other_Sources__c = NULL;
                    coachOpptyRecord.Process_Owner__c = ''; coachOpptyRecord.TC_TL_actions_to_be_taken__c = '';
                }else{
                    records.add(coachOpptyRecord);
                    s_surveyIds.add(coachOpptyRecord.Survey__c);
                }                
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!s_surveyIds.isEmpty()){
                Map<Id,Survey__c> m_surveyDetails = retrieveSurveyDetails(s_surveyIds);
                Survey__c linkedSurvey ;
                String s_ownerId;
                for(Coaching_Opportunities__c coachOppty : (List<Coaching_Opportunities__c>)records){
                    if(m_surveyDetails.containsKey(coachOppty.Survey__c)){
                        linkedSurvey = m_surveyDetails.get(coachOppty.Survey__c);
                        coachOppty.Enquiry_Number__c = linkedSurvey.Enquiry__c;
                        // Check the Owner should be a User and not a Queue
                        s_ownerId = String.ValueOf(linkedSurvey.Enquiry__r.OwnerId);
                        If(s_ownerId.startsWith('005')){
                        	coachOppty.Officer_TC_Faculty_Other_Sources__c = linkedSurvey.Enquiry__r.OwnerId; 	   
                        }else{
                            coachOppty.addError(Label.SurveySyncError);
                        }
                    	coachOppty.Process_Owner__c = linkedSurvey.Process_owned_by__c;
                    	coachOppty.Summary_of_error__c = linkedSurvey.Action_Taken__c;
                    }
                }
            }
            LogUtilityException.getLimits();
        }
        
        public Map<Id,Survey__c> retrieveSurveyDetails(Set<Id> s_surveyIds){
            Map<Id,Survey__c> m_surveyDetails = new Map<Id,Survey__c>();
            for(Survey__c linkedSurvey : [SELECT Id,Enquiry__c, Enquiry__r.OwnerId, Enquiry__r.SuppliedName, Process_owned_by__c,Action_Taken__c 
                                          FROM Survey__c WHERE Id IN :s_surveyIds]){
                m_surveyDetails.put(linkedSurvey.Id, linkedSurvey);
            }
            return m_surveyDetails;
        }
    }
    
    /**
    * @description Auto send Notifications to Coaching Oppty Owner.
    * @revision    DEC.11.2023  IDhanoa - Created
    */
    public class NotifyOwner extends TriggerAbstract {
        public override void process(SObject record) {
            Coaching_Opportunities__c coachOpptyRecord = (Coaching_Opportunities__c)record;
            records.add(coachOpptyRecord);
        }

        public override void process(SObject record, SObject oldRec) {
            Coaching_Opportunities__c coachOpptyRecord = (Coaching_Opportunities__c)record;
            Coaching_Opportunities__c oldCoachOpptyRecord = (Coaching_Opportunities__c)oldRec;
            String s_ownerId = String.ValueOf(coachOpptyRecord.OwnerId);
            if(coachOpptyRecord.OwnerId != oldCoachOpptyRecord.OwnerId ){
                if(s_ownerId.startsWith('005')){
                    // Notify the Owner  
                    records.add(coachOpptyRecord);
                }               
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                // Cannot send Bulk notifications
                // https://ideas.salesforce.com/s/idea/a0B8W00000GdZ61UAF/custom-notifications-to-support-bulk-creation-thru-apex
                CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Coaching_Opportunities' LIMIT 1];
                Messaging.CustomNotification notification;
                for(Coaching_Opportunities__c coachOppty : (List<Coaching_Opportunities__c>)records){
                    // Create a new custom notification
                    notification = new Messaging.CustomNotification();
                    // Set the contents for the notification
                    notification.setTitle('A new Coaching Opportunity Record has been assigned to you');
                    notification.setBody(coachOppty.Name);
                    notification.setSenderId(UserInfo.getUserId());
                    // Set the notification type and target
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetId(coachOppty.Id);
                    notification.send(new set<String>{String.valueOf(coachOppty.OwnerId)});
                }
            }
            LogUtilityException.getLimits();
        }

    }
}