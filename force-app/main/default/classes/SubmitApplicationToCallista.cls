/**
 * @author Trent De Laney
 * @date 3 Jul 2019 at 4:08:44 pm
 * @group Integration
 * @Revision 06 Aug 2019 - Shalini Mendu - Fixed code to update the Application with unsuccessful webservice response.
 * @description Used to trigger the outbound submission to Callista and create the request for the application to be used in MIX
 *              14/07/2020 - Martin Cadman - Added Null record checks for SFTN-780
 */
public without sharing class SubmitApplicationToCallista implements Queueable, Database.AllowsCallouts{

    /********************************************************
    Statics
    ********************************************************/
    private static final String SUCCESSFUL_SUBMISSION = 'Submitted';
    private static final String UNSUCCESSFUL_SUBMISSION = 'Review';

    /********************************************************
    Class Variables
    ********************************************************/
    private String request;
    private String applicationId;
    private Boolean throttled;

    /**
    * @author Trent De Laney
    * @description Contructor
    * @date 4 Jul 2019 at 8:56:06 am
    * @param String request, String applicationId
    */
    public SubmitApplicationToCallista(String request, String applicationId, Boolean throttled) {
        this.request = request;
        this.applicationId = applicationId;
        this.throttled = throttled;
    }

    /**
    * @author Trent De Laney
    * @description Execute implementation from interface
    * @date 4 Jul 2019 at 8:53:15 am
    * @param QueueableContext context
    */
    public void execute(QueueableContext context){
        try {
            String requestStr = StudFirst_Utilities.convertTo7BitAcceptedString(this.request, '?');
            // Prepare request
            HttpRequest request = new HttpRequest();

            // Retrieve integration settings
            IntegrationSettings_SubmitApplication__c is = IntegrationSettings_SubmitApplication__c.getInstance();

            // Endpoint
            if (is.Enable_Mock__c) {
                request.setEndpoint(is.Mock_Endpoint_Applications__c);
            } else {
                request.setEndpoint(is.Base_Url__c + is.Path__c);
            }

            // HTTP method
            request.setMethod(is.Method__c);

            // HTTP request
            request.setBody(requestStr);

            // HTTP timeout
            request.setTimeout(Integer.valueOf(is.Timeout__c));

            // HTTP headers
            request.setHeader('Content-Type', is.Header_ContentType__c);
            request.setHeader('client_id', is.Header_ClientId__c);
            request.setHeader('client_secret', is.Header_ClientSecret__c);

            // Send Request
            Http httpClient = new Http();
            HttpResponse resp = httpClient.send(request);

            // Update the record with response from Callista
            parseResponse(requestStr, resp, applicationId, throttled);

        } catch (Exception ex) {
            ExLog.add('Error on Queueable Class', 'SubmitApplicationToCallista', 'execute', ex + 'line: ' + ex.getLineNumber());
        }
    }

    /**
    * @author Trent De Laney
    * @description Used to parse the response from the Mix submission to Callista. Does a number of check to ensure validity of response and in turn, protect against subsequent requests based on the resultant IDs.
    * @date 3 Jul 2019 at 4:29:26 pm
    * @param HttpResponse response, String applicationId
    * @return Boolean
    */
    @TestVisible
    private static void parseResponse(String request, HttpResponse response, String applicationId, Boolean throttled) {
        //Get the reference to the application object here
        List<Application__c> applications = [
                SELECT Id, Callista_Applicant_Id__c, Callista_Application_Id__c, Status__c, API_Request_Message__c, API_Response_Message__c, Assessment_Status__c
                FROM Application__c
                WHERE Id = :applicationId
        ];

        Map<String, ObdAdmissionApplicationResponse.CoursePreference> acpRespMap = new Map<String, ObdAdmissionApplicationResponse.CoursePreference>();

        //Another early out to make sure that we have an application to link back to
        if (applications.isEmpty()) {
            ExLog.add('Unable to find application of id - ' + applicationId, 'SubmitApplicationToCallista', 'parseApplication', request + response);
            return;
        }

        //This is the app that has been returned from Callista.
        Application__c app = applications[0];

        if (throttled) {
            app.Assessment_Status__c = 'Required';
        } else {
            app.Assessment_Status__c = 'Not Required';
        }

        //Early out to make sure that we got a response
        if (response == null || response.getStatusCode() != 200) {
            ExLog.add('Bad Response - ' + response.getStatusCode(), 'SubmitApplicationToCallista', 'parseApplication', (request + '\r\r' + response).abbreviate(10000)) ;
            app.Status__c = UNSUCCESSFUL_SUBMISSION;
            app.API_Response_Message__c = response.toString();
            app.API_Request_Message__c = request;
            update app;
            return;
        }

        String responseBody = response.getBody();

        //Ensure that we have a body upon calling the request
        if (String.isNotEmpty(responseBody)) {
            //As we are casting, we should catch any sneaky errors
            try {
                ObdAdmissionApplicationResponse structuredResponse = (ObdAdmissionApplicationResponse) JSON.deserialize(responseBody, ObdAdmissionApplicationResponse.class);

                //Set the applicant ID first
                if (!structuredResponse.applications.isEmpty()) {
                    app.Callista_Applicant_Id__c = structuredResponse.applications.get(0).smsApplicantId;
                }

                //Check to make sure we have 1 in the list
                if (!structuredResponse.applications.get(0).smsApplications.isEmpty()) {
                    //Store a handy reference to the Application from Callista - Same as the internal application
                    ObdAdmissionApplicationResponse.SmsApplication callistaApplication = structuredResponse.applications.get(0).smsApplications.get(0);

                    //Have to cast it cause of mismatched data - As always, try catch
                    try {
                        app.Callista_Application_Id__c = String.valueOf(callistaApplication.applicationId);
                    } catch (Exception e) {
                        ExLog.add('No Application Id', 'SubmitApplicationToCallista', 'parseApplication', e + ' at line: ' + e.getLineNumber());
                    }
                }

                if (structuredResponse.applications.get(0).smsApplications.size() > 0 ) { 
                    for (ObdAdmissionApplicationResponse.CoursePreference acpResp : structuredResponse.applications.get(0).smsApplications.get(0).coursePreferences) {
                        acpRespMap.put(acpResp.courseCode + '-' + acpResp.preferenceNumber, acpResp);
                    }
                }

                List<Application_Course_Preference__c> childACPs = new List<Application_Course_Preference__c>();
                for (Application_Course_Preference__c acp : [
                        SELECT Id,
                                Portal_Sequence_Number__c,
                                Unique_External_Id__c,
                                Course_Code__c,
                                Preference_Number__c
                        FROM Application_Course_Preference__c
                        WHERE Application__c = :applicationId
                ]) {
                    //if the ACP is found on the retrieved ACPs from Callista, update the records with the unique keys
                    //create map of childValues and add first preference with throttle
                    if (!acpRespMap.isEmpty() && acpRespMap.containsKey(acp.Course_Code__c + '-' + acp.Preference_Number__c)) {
                        ObdAdmissionApplicationResponse.CoursePreference callistaACP = acpRespMap.get(acp.Course_Code__c + '-' + acp.Preference_Number__c);
                        acp.Portal_Sequence_Number__c = callistaACP.sequenceNumber;

                        acp.Unique_External_Id__c = replaceBlankWithNull(app.Callista_Application_Id__c) + '-' +
                                replaceBlankWithNull(callistaACP.courseCode) + '-' +
                                replaceBlankWithNull(callistaACP.sequenceNumber);
                        acp.Callista_Unique_Key_AP__c = replaceBlankWithNull(app.Callista_Application_Id__c) + '-' + replaceBlankWithNull(callistaACP.sequenceNumber);
                        
                        childACPs.add(acp);
                    }
                }

                //if there are ACPs found, update it
                if (!childACPs.isEmpty()) {
                    update childACPs;

                    if (String.isNotBlank(app.Callista_Applicant_Id__c) && String.isNotBlank(app.Callista_Application_Id__c)) {
                        app.Status__c = SUCCESSFUL_SUBMISSION;
                    } else {
                        app.Status__c = UNSUCCESSFUL_SUBMISSION;
                    }
                }

            } catch (Exception e) {
                ExLog.add('Unable to deserialize the Application Response from Callsita', 'SubmitApplicationToCallista', 'parseApplication', e + ' at line: ' + e.getLineNumber());
                app.Status__c = UNSUCCESSFUL_SUBMISSION;

            }
            app.API_Response_Body__c = responseBody;
            app.API_Response_Status__c = response.getStatusCode();
            app.API_Request_Message__c = request;
            app.API_Response_Message__c = 'HTTP Status Code : ' + response.getStatusCode() + '\n HTTP Status : ' + response.getStatus() + '\n Response : \n--------------\n\n' + responseBody;
            update app;
        }
    }

    /*******************************************************************************
   * @author       Ant Custodio
   * @date         29.Jan.2018
   * @description  Replaces blank String with the text 'null'
   * @revision
   *******************************************************************************/
    public static String replaceBlankWithNull(String strValue) {
        if (String.isBlank(strValue)) {
            strValue = 'null';
        }
        return strValue;
    }
}