/**
 * @description     Service class for logging entried to Exception_Log__c in async pattern
 * @author          KL
 * @date            15/07/2020
 * 
 * @revision
 *                  25.FEB.2020 - KL		- Initial class creation
 */
public with sharing class LoggingServices {
    
    public class LogAccountMerge implements IPlatformEventInvocable {

        private string SurvivingAccountJSON;
        private string VictimAccountJSON;

        public void execute(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {

                List<Exception_Log__c> exRecs = new List<Exception_Log__c>();

                for(AsyncProcessPayload payload : payloads) {
                    SurvivingAccountJSON = payload.get('SurvivingAccountJSON').toString();
                    System.debug('!@# SurvivingAccountJSON = ' + SurvivingAccountJSON);
                    
                    VictimAccountJSON = payload.get('VictimAccountJSON').toString();
                    System.debug('!@# VictimAccountJSON = ' + VictimAccountJSON);
                    
                    Exception_Log__c exRec = new Exception_Log__c(Exception_Type__c = 'INFO', Function_Name__c = 'TaskDupCheckHelper.init', Source_Type__c = 'Account Merge', Input__c = 'SurvivingAccountJSON = ' + SurvivingAccountJSON, Message__c = 'VictimAccountJSON = ' + VictimAccountJSON);
                    exRecs.add(exRec);
                }

                insert exRecs;

            }
        }
    }

    public class LogContactMerge implements IPlatformEventInvocable {
        
        private string SurvivingContactJSON;
        private string VictimContactJSON;

        public void execute(List<AsyncProcessPayload> payload) {
            run(payload);
		}

		private void run(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
                List<Exception_Log__c> exRecs = new List<Exception_Log__c>();
				for(AsyncProcessPayload payload : payloads) {
                    SurvivingContactJSON = payload.get('SurvivingContactJSON').toString();
                    System.debug('!@# SurvivingContactJSON = ' + SurvivingContactJSON);
                    
                    VictimContactJSON = payload.get('VictimContactJSON').toString();
                    System.debug('!@# VictimContactJSON = ' + VictimContactJSON);
                    
                    Exception_Log__c exRec = new Exception_Log__c(Exception_Type__c = 'INFO', Function_Name__c = 'TaskDupCheckHelper.init', Source_Type__c = 'Contact Merge', Input__c = 'SurvivingContactJSON = ' + SurvivingContactJSON, Message__c = 'VictimContactJSON = ' + VictimContactJSON);
                    exRecs.add(exRec);
				}
                insert exRecs;
			}
		}

    }

}