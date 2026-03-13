/*******************************************************************************
* @author       Ryan Wilson
* @date         15.Mar.2017         
* @description  Batch class that calls Marketing Cloud services to send SMS
* @revision     
*******************************************************************************/
global class BMSMassSMSSendBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {
	
	private String campaignId;
	private String crmMassEmailId;
	private String attachmentId;
	global final blob contentFile;
	private String accessToken;
	private String smsMessageBody;
	private String callOutStatus;
	private DateTime sendDateTime;
	private Integer smsCount;

	public final string SUCCESS_STATUS = 'Success';
    public final string NOT_AUTHORIZED = 'Not Authorized';
    public final string ERROR = 'Error';

	global BMSMassSMSSendBatch(String attachmentRecordId, String campaignRecordId) {
		smsCount = 0;
		accessToken = getAccessToken();

		Attachment attachmentRecord = [SELECT Id, Body FROM Attachment WHERE Id =: attachmentRecordId];
		campaignId = campaignRecordId;
		contentFile = attachmentRecord.Body;

		Campaign crmRec = [SELECT Id, SMS_Body__c, Send_Date_Time__c FROM Campaign WHERE Id =:campaignRecordId];
		smsMessageBody = crmRec.SMS_Body__c;
		sendDateTime = crmRec.Send_Date_Time__c;
	}
	
	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         15.Mar.2017         
	* @description  Batch start method to call in the CSV Iterator
	* @revision     
	*******************************************************************************/
	global Iterable<String> start(Database.batchableContext batchableContext){ 
	    String csvfile = contentFile.toString();
	    return new CSVIterator(csvfile, '\r\n');
	}


   	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         15.Mar.2017         
	* @description  Batch Execute
	* @revision     
	*******************************************************************************/
   	global void execute(Database.BatchableContext BC, List<String> scope) {
		String csvFile = '';
       	for(String row : scope)
       	{
        	csvFile += row + '\r\n';
       	}
       	List<List<String>> csvLines = CSVReader.readIETFRFC4180CSVFile(csvFile);
       	//System.debug('****CSV Lines:'+csvLines);

       	List<String> mobileNumbers = new List<String>();

       	if(csvLines != null && !csvLines.isEmpty()){
			for(Integer i=0; i<csvLines.size(); i++){
				List<String> csvLine = csvLines[i];
				for(String stringValue: csvLine){
					if(!String.isEmpty(stringValue)){
                        if(stringValue != 'MobilePhone'){
                        	mobileNumbers.add(stringValue);
                        }
                    }
				}
			}
		}

		callOutStatus = sendSMSCallout(mobileNumbers, smsMessageBody, accessToken);
		
		//if the access token expires, request for a new token then call sendSMS service again.
		if(callOutStatus == NOT_AUTHORIZED){
			accessToken = getAccessToken();
			callOutStatus = sendSMSCallout(mobileNumbers, smsMessageBody, accessToken);
		}

	}
	
	global void finish(Database.BatchableContext BC) {
		List<Campaign> campaignRecord = [SELECT	Id, Status, SMS_Count__c 
											FROM 	Campaign
											WHERE 	Id =: campaignId];
		campaignRecord[0].SMS_Count__c = smsCount;
		update campaignRecord;
	}

	private String getAccessToken() {
		String returnToken = '';

		MarketingCloudApp__c mcApp = MarketingCloudApp__c.getValues('Credentials');

		authWrapper reqBody = new authWrapper();
		reqBody.clientId = mcApp.Client_ID__c;
		reqBody.clientSecret = mcApp.Client_Secret__c;
		String jsonBody = JSON.serialize(reqBody);

		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:MarketingCloudRequestToken');
		req.setHeader('Content-Type','application/json');
		req.setMethod('POST');
		req.setBody(jsonBody);
		System.debug('***REQUEST:'+req);

		Http http = new Http();
		HttpResponse res = http.send(req);
		System.debug('***STATUS Code:'+res.getStatusCode());
		System.debug('***RESPONSE:'+res.getBody());

		if(res.getStatusCode() == 200){
			JSONParser parser = JSON.createParser(res.getBody());
			System.JSONToken token;
			String strText = '';

			while (parser.nextToken() != null){
				if((token = parser.getCurrentToken()) != JSONToken.END_OBJECT){
					strText = parser.getText();
					if (token == JSONToken.FIELD_Name && strText == 'accessToken') {
						token=parser.nextToken();
						System.debug('****VALUE1: '+parser.getText());
						returnToken = parser.getText();
					}
				}
			}
		}
		else{
			ExLog.add('Marketing Cloud Callout', 'MarketingCloudServices', 'getAccessToken' , res.getBody());
		}
		return returnToken;
	}

	private String sendSMSCallout(List<String> mobileNumbers, String smsMessage, String bearerToken){
		//get Access Token first, transfer to batch job once tested...
		String strStatus = '';
		
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:MarketingCloudSendSMS');
		req.setHeader('Content-Type','application/json');
		req.setMethod('POST');
		req.setHeader('Content-Type','application/json');
		req.setHeader('Authorization', 'Bearer '+bearerToken);
		
		JSONGenerator jgen = JSON.createGenerator(true);
		jgen.writeStartObject();
		jgen.writeObjectField('mobileNumbers', mobileNumbers);
		jgen.writeBooleanField('Subscribe', true);
		jgen.writeBooleanField('Resubscribe', true);
		jgen.writeBooleanField('Override', true);
		jgen.writeStringField('keyword', 'JOIN');
		jgen.writeStringField('messageText', smsMessage);
		if(sendDateTime != null){
			jgen.writeStringField('SendTime', setSendDateTime(sendDateTime));
		}
		jgen.writeEndObject();
		
		req.setBody(jgen.getAsString());
		req.setTimeout(30000);
		System.debug('***REQUEST:'+req);

		Http http = new Http();
		try{
			HttpResponse res = http.send(req);
			System.debug('***STATUS Code:'+res.getStatusCode());
			System.debug('***RESPONSE:'+res.getBody());

			if(res.getStatusCode() == 202){
				//success
				strStatus = SUCCESS_STATUS;
				smsCount += mobileNumbers.size();
			}
			else{ //check 400 errors...
				if(res.getStatusCode() == 400){
					strStatus = ERROR;
				}
				if(res.getStatusCode() == 401){
					strStatus = NOT_AUTHORIZED;
				}
				ExLog.add('Marketing Cloud Callout', 'MarketingCloudServices', 'sendSMSCallout' , res.getBody());
			}
		}
		catch(Exception ex){
			ExLog.add('Marketing Cloud Callout', 'MarketingCloudServices', 'sendSMSCallout' , ex.getMessage());
		}

		return strStatus;	
	}

	private String setSendDateTime(DateTime sdt){
		Integer year = sdt.yearGmt();
		Integer month = sdt.monthGmt();
		Integer day = sdt.dayGmt();
		Integer hour = sdt.hourGmt();
		Integer minutes = sdt.minuteGmt();
		String mcDateTimeFormat = String.valueOf(year)+'-'+String.valueOf(month)+'-'+String.valueOf(day)+' '+String.valueOf(hour)+':'+String.valueOf(minutes);

		return mcDateTimeFormat;
	}

	public class authWrapper {
		public String clientId {get; set;}
        public String clientSecret {get; set;}
	}
}