global class CalabrioServices {
    public static final string CALABRIO_ACTIVE_CALL_ENDPOINT = '/v1/active-call?userName=';
    public static final string CALABRIO_RECORDING_ENDPOINT = '/v1/recording?id=';

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         24/01/2017         
    * @description  Future Method use by the Case trigger only
    * @revision     
    *******************************************************************************/
    @future(callout=true)
    public static void calabrioCallout(String param, ID enquiryId) {
        CalabrioIntegration__c testCal = CalabrioIntegration__c.getValues('Credentials');
        List<Call_Recording__c> callRecordList = new List<Call_Recording__c>();
        Map<String, Call_Recording__c> mapCallRecords = new Map<String, Call_Recording__c>();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:CalabrioAuthorization'+CALABRIO_ACTIVE_CALL_ENDPOINT+param);
        req.setHeader('Content-Type','application/json');
        req.setHeader('client_id',testCal.Client_ID__c);
        req.setHeader('client_secret',testCal.Client_Secret__c);
        req.setMethod('GET');
        System.debug('***REQUEST:'+req);
        
        try{
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('***STATUS Code:'+res.getStatusCode());
            System.debug('***RESPONSE:'+res.getBody());

            if(res.getStatusCode() == 200){
                //parse response
                Call_Recording__c callRecord = new Call_Recording__c();
                callRecord.Agent_Name__c =  UserInfo.getUserId();
                callRecord.Enquiry__c = enquiryId;
                
                
                JSONParser parser = JSON.createParser(res.getBody());
                System.JSONToken token;
                String strText = '';

                while (parser.nextToken() != null){
                    if((token = parser.getCurrentToken()) != JSONToken.END_OBJECT){
                        strText = parser.getText();
                        if (token == JSONToken.FIELD_Name && strText == 'id') {
                            token=parser.nextToken();
                            System.debug('****VALUE1: '+parser.getText());
                            callRecord.Call_Id__c = parser.getText();
                            callRecord.Link_To_Recording__c = testCal.CalabrioURL__c+callRecord.Call_Id__c;
                        }
                        if (token == JSONToken.FIELD_Name && strText == 'startTime') {
                            token=parser.nextToken();
                            System.debug('****VALUE2: '+parser.getText());
                            DateTime startTime = datetime.newInstance(0);
                            Integer intUnixTime = Integer.valueOf(parser.getText().substring(0,10));
                            callRecord.Start_Date_Time__c = startTime.addSeconds(intUnixTime);
                        }
                    }
                }
                callRecordList.add(callRecord);
            }
            else{
                if(res.getStatusCode() != 404){
                    ExLog.add('Calabrio Callout', 'CalabrioServices', 'calabrioCallout' , 'Agent Name:'+UserInfo.getName()+',Error:'+res.getBody());
                }
            }
            
            TriggerCommon.inFutureContext = true;
            if(callRecordList.size() > 0){
                try{
                    insert callRecordList;
                }
                catch(Exception e){
                    //for catching duplicate Call Ids
                }
                
            }
        }
        catch(Exception ex){
            ExLog.add('Calabrio Callout', 'CalabrioServices', 'calabrioCallout' , 'Exception: '+ex.getMessage());
        }
        
    }
}