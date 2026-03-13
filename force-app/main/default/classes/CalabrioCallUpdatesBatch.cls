/*******************************************************************************
* @author       Ryan Wilson
* @date         25.Jan.2017         
* @description  Batch class that do callout to calabrio then update call recording details
* @revision     
*******************************************************************************/
global class CalabrioCallUpdatesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	
	String query;
	List<Call_Recording__c> callRecordList = new List<Call_Recording__c>();
	CalabrioIntegration__c testCal = CalabrioIntegration__c.getValues('Credentials');
	
	global CalabrioCallUpdatesBatch() {
		 
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		query = 'SELECT Id, Call_Id__c, Data_Completed__c, Call_Duration_Number__c FROM Call_Recording__c WHERE Data_Completed__c = false LIMIT 2000';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Call_Recording__c> scope) {
		
		for(Call_Recording__c callRecord: scope){
			try{
				HttpRequest req = new HttpRequest();
				req.setEndpoint('callout:CalabrioAuthorization'+CalabrioServices.CALABRIO_RECORDING_ENDPOINT+callRecord.Call_Id__c);
				req.setHeader('Content-Type','application/json');
				req.setHeader('client_id',testCal.Client_ID__c);
				req.setHeader('client_secret',testCal.Client_Secret__c);
				req.setMethod('GET');

				Http http = new Http();
				HttpResponse res = http.send(req);

				if(res.getStatusCode() == 200){
					JSONParser parser = JSON.createParser(res.getBody());
					System.JSONToken token;
					String strText = '';

					while (parser.nextToken() != null){
						if((token = parser.getCurrentToken()) != JSONToken.END_OBJECT){
							strText = parser.getText();
							if (token == JSONToken.FIELD_Name && strText == 'callDuration') {
								token=parser.nextToken();
								if(parser.getText() != 'null'){
									Integer callDuration = Integer.valueOf(parser.getText());
									Integer hours = callDuration / (1000*60*60);
									String strHours = (hours < 10)? '0'+String.valueOf(hours): String.valueOf(hours);
									Integer minutes = math.mod(callDuration, (1000*60*60)) / (1000*60);
									String strMinutes = (minutes < 10)? '0'+String.valueOf(minutes): String.valueOf(minutes);
									Integer seconds = math.mod(math.mod(callDuration, (1000*60*60)),(1000*60)) / 1000;
									String strSeconds = (seconds < 10)? '0'+String.valueOf(seconds): String.valueOf(seconds);

									String duration = strHours+':'+strMinutes+':'+strSeconds;
									System.debug('****DURATION: '+duration);
									callRecord.Call_Duration__c = duration;
									callRecord.Data_Completed__c = true;
								}
							}
						}
					}
					callRecordList.add(callRecord);
				}
				else{
					ExLog.write('Calabrio Callout', 'CalabrioCallUpdatesBatch', 'batch execution' , res.getStatus());
				}
			}
			catch(Exception ex){
				ExLog.write('Calabrio Callout', 'CalabrioCallUpdatesBatch', 'batch execution' , ex.getMessage());
			}
			
		}
		
	}
	
	global void finish(Database.BatchableContext BC) {
		if(callRecordList.size() > 0){
			update callRecordList;
		} 
	}
	
}