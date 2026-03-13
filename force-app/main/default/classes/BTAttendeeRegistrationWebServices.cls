/**
 * @author       : Ibrahim Rumi
 * @date         : 16-06-2022
 * @group        : Event Management
 * @description  : Webservice to register attendees and return attendeeLink
**/
@RestResource(urlMapping='/btattendeeRegistration/*')
global with sharing class BTAttendeeRegistrationWebServices{

    @HttpPost
    global static BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse handleAttendeeRegistration(){
        BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse attendeeResponse = new BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse();
        BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest attendeerequest ;
        RestRequest request = RestContext.request;
        List<conference360__attendee__c> attList = new List<conference360__attendee__c>();

        try{
            String jSONRequestBody = request.requestBody.toString().trim();
            attendeerequest = (BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest) JSON.deserializeStrict(jSONRequestBody, BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest.class);

                conference360__attendee__c attendee = new conference360__attendee__c();
                attendee.conference360__Registration_Status__c = attendeerequest.registrationStatus;
                attendee.conference360__Contact__c = id.valueof(attendeerequest.contactId);
                attendee.conference360__Event__c = id.valueof(attendeerequest.eventId);
                
                attList.add(attendee);
            
            if (attList.size() > 0) {
                Database.SaveResult[] srList = Database.insert(attList, false);
                List<Id> successIds = new List<Id>();
                
                for (Integer j =0 ; j < attList.size(); j++){
                    BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse resp = new BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse();
                    if (srList.get(j).isSuccess()){ 
                        conference360__Attendee__c att = attList[j];
                        
                        successIds.add(srList[j].getId());
                        
                    }else if(!srList.get(j).isSuccess()){
                        Database.Error errors =  srList.get(j).getErrors().get(0);
                        
                            resp.status = 'error';
                            resp.error = errors.getMessage();
                            return resp;
                    }
                }
                
                for(conference360__Attendee__c att: [SELECT id,conference360__Contact__c, conference360__AttendeeLink__c
															FROM conference360__Attendee__c
                                                            WHERE id in: successIds
                                                    		WITH SECURITY_ENFORCED])
                {
           
					attendeeResponse.contactId = att.conference360__Contact__c;
                    attendeeResponse.attendeeId = att.id;
                    attendeeResponse.attendeelink = att.conference360__AttendeeLink__c;
                    attendeeResponse.status = 'success';
                    attendeeResponse.error = null;
                    
                }
                
            }
            
        }catch(exception ex){
            BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse resp = new BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse();
			resp.status = 'error';
            resp.error = ex.getMessage();
            
			return resp;
        }
        return attendeeResponse;
    }
}