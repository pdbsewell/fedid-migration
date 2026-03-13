/*******************************************************************************
* @author       Ant Custodio
* @date         2.Nov.2017         
* @description  Batch class that sends the documents to callista using application ids
* @revision     
*******************************************************************************/
global class SendDocumentsBatch implements Database.Batchable<sObject> {
	
	private String query;
	private Set<String> applicationIds;

	global SendDocumentsBatch(Set<String> appIds) {
		applicationIds = appIds;
	}
	
	/*******************************************************************************
	* @author       Ant Custodio
	* @date         2.Nov.2017         
	* @description  Batch start method to collect all applications using the given ids
	* @revision     
	*******************************************************************************/
	global Database.QueryLocator start(Database.BatchableContext BC){ 
	    query = 'SELECT Id FROM Application__c WHERE Id IN: applicationIds';
        return Database.getQueryLocator(query);
	}


   	/*******************************************************************************
	* @author       Ant Custodio
	* @date         2.Nov.2017         
	* @description  Batch Execute
	* @revision     
	*******************************************************************************/
   	global void execute(Database.BatchableContext BC, List<Application__c> scope) {
   		if (!scope.isEmpty()) {
   			Set<String> appIds = new Set<String>();
   			for (Application__c appRec: scope) {
   				appIds.add(appRec.Id);
   			}

   			StudFirst_SendDocumentsService.sendToCallistaByAppIds(appIds);
   		}
		
	}
	
	global void finish(Database.BatchableContext BC) {
		//TODO
	}
}