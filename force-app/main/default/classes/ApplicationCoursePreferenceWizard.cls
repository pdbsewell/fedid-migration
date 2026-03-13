/**
 * @author          Kristian Vegerano
 * @description     Service class used by addApplicationCoursePreferenceWizard lwc
 * @group           Service
 * @history         04/11/2019
 * 31/08/2021       SFTG-2166 Removed references to Task_Course_Entry_Check__c 
 * 4/4/2023 Ken McGuire - improve error handling
 *  17.04.2023 Ken McGuire: Changed Comments__c (255 characters) to LongComments__c (4000 characters)
 */
public with sharing class ApplicationCoursePreferenceWizard implements Database.AllowsCallouts {
    
    // Constants
    @testVisible private static final String MAPKEY_APPLICATION = 'Application';
    @testVisible private static final String MAPKEY_APPLICATION_COURSE_PREFERENCE = 'ApplicationCoursePreference';
    @testVisible private static final String MAPKEY_COURSE_OFFERINGS = 'CourseOfferings';
    @testVisible private static final String MAPKEY_CURRENT_COURSE_OFFERING = 'CurrentCourseOffering';
    @testVisible private static final String MAPKEY_URL_REPLACE_KEY_VALUE_PAIRS = 'urlReplaceKeyValuePairs';
    @testVisible private static final String MAPKEY_STATE = 'state';
    @testVisible private static final String MAPKEY_MESSAGE = 'message';
    @testVisible private static final String MAPKEY_REQUEST_JSON = 'requestJSON';
    @testVisible private static final String MAPVALUE_ERROR = 'error';
    @testVisible private static final String MAPVALUE_SUCCESS ='success';
   	private static final String ERROR_NO_APPLICATION_RECORDS = 'No application record found';
    @testVisible private static final String ERROR_NO_APPLICATION_COURSE_PREFERENCE_RECORDS = 'Application course preference not found';
    private static final String ERROR_NO_COURSE_PREFERENCE_RECORDS = 'No primary course preference record found';
    private static final String ERROR_RETRIEVE_APP_DETAILS_COURSE_OFFERINGS = 'An error occurred while retrieving application details and course offerings';
    private static final String ERROR_RETRIEVE_COURSE_OFFERINGS = 'An error occured while retrieving course offerings';     
    private static final String ERROR_UPDATE_COURSE_PREFERENCES = 'An error occured while updating Application Course Preferences'; 
	private static final String ERROR_INIT_CALLOUT = 'Failed to initiates the Callista callout to edit an Application_Course_Preference__c record';    
    private static final String ERROR_PROCESS_CALLOUT = 'Failed to processes the HttpResponse from Callista callout';
    private static final String ERROR_BUILDING_CALLOUT = 'Error occurred while building callout parameters';
    private static final String ERROR_NO_PERSON_ID = 'Unable to add the ACP record as there is no Person ID and ADM Key';
    private static final String DEBUG_INFO_APPLICATION_ID = ' for application Id ';
    private static final String DEBUG_INFO_ACP_ID = ' for ACP Id ';
    @testVisible private static final String IP07_CALLISTA_ACP_UPDATE = 'IP07_Callista_ACP_Update';
    
        
    
    // Aura Enabled Methods
   
    /**
     * @description Query ACP and course offering options
     * @param acpId The ID of the Application Course Preference record
     * @return Map<String, Object> A map containing the ACP, current course offering, and related course offerings
     * 4/4/2023 Ken McGuire - improve error handling
     */
    @AuraEnabled
    public static Map<String, Object> retrieveAcpDetailsAndCourseOfferings(String acpId) {
        Map<String, Object> resultMap = new Map<String, Object>();
    
        try {
            Application_Course_Preference__c acpRecord = getCoursePreferenceWithCourseOffering(acpId);
            if (acpRecord == null) {
                throw new AuraHandledException(ERROR_NO_APPLICATION_COURSE_PREFERENCE_RECORDS);
            }
            resultMap.put(MAPKEY_APPLICATION_COURSE_PREFERENCE, acpRecord);
            
            resultMap.put(MAPKEY_CURRENT_COURSE_OFFERING, acpRecord.Course_Offering__r);
    
            List<Course_Offering__c> courseOfferings = searchCourseOfferingsEdit(
                acpRecord.Application__r.Residency_Status__c, 
                acpRecord.Attendance_Mode__c, 
                acpRecord.Attendance_Type__c,
                Integer.valueOf(acpRecord.Course_Offering__r.Academic_Year__c), 
                acpRecord.Course_Offering__r.Course_Code__c,
                acpRecord.Course_Offering__r.Course_Title__c, 
                acpRecord.Course_Offering__r.Admission_Calendar_Description__c, 
                acpRecord.Course_Offering__r.Admission_Category__c
            );
    
            resultMap.put(MAPKEY_COURSE_OFFERINGS, courseOfferings);
    
        } catch (Exception e) {
            LogUtilityException.logException(e,ERROR_RETRIEVE_APP_DETAILS_COURSE_OFFERINGS + DEBUG_INFO_ACP_ID + acpId);
            throw new AuraHandledException(ERROR_RETRIEVE_APP_DETAILS_COURSE_OFFERINGS);
        }
    
        return resultMap;
    }

    
    /**
     * Retrieves application details and course offerings for the given application ID.
     * @param applicationId The ID of the application to retrieve details and course offerings for.
     * @return A map containing the application details, application course preference, and course offerings.
     * @throws AuraHandledException If no application records or course preference records are found for the given ID.
     * 4/4/2023 Ken McGuire - improve error handling
     */
    @AuraEnabled
    public static Map<String, Object> retrieveApplicationDetailsAndCourseOfferings(String applicationId) {
        // Initialize results map
        Map<String, Object> resultMap = new Map<String, Object>();
        String attendanceMode;
        String attendanceType;
        Integer academicYear;
        
        try {
            // Retrieve application details
            Application__c applicationRecord = getApplicationRecordAndCoursePreference(applicationId);
            if (applicationRecord == null) {
                throw new AuraHandledException(ERROR_NO_APPLICATION_RECORDS);
            }
            resultMap.put(MAPKEY_APPLICATION, applicationRecord);
            List<Application_Course_Preference__c> acpRecords = applicationRecord.Application_Course_Preferences__r;
            if (acpRecords.isEmpty()) {
                //throw new AuraHandledException(ERROR_NO_COURSE_PREFERENCE_RECORDS);
                resultMap.put(MAPKEY_APPLICATION_COURSE_PREFERENCE, null);
                attendanceMode = 'FT';
                attendanceType =  'IN';
                academicYear = 2024;
            }else{
                resultMap.put(MAPKEY_APPLICATION_COURSE_PREFERENCE, acpRecords[0]);
                attendanceMode = acpRecords[0].Attendance_Mode__c;
                attendanceType = acpRecords[0].Attendance_Type__c;
                academicYear = Integer.valueOf(acpRecords[0].Course_Offering__r.Academic_Year__c);
            }
        	
        	//resultMap.put(MAPKEY_COURSE_OFFERINGS, CourseOfferingsSearch(applicationRecord.Residency_Status__c, acpRecords[0].Attendance_Mode__c, acpRecords[0].Attendance_Type__c, Integer.valueOf(acpRecords[0].Course_Offering__r.Academic_Year__c)));
            resultMap.put(MAPKEY_COURSE_OFFERINGS, CourseOfferingsSearch(applicationRecord.Residency_Status__c, attendanceMode, attendanceType, academicYear));
        } catch (Exception e) {
            // Log error and re-throw the exception to propagate it to the calling code
            LogUtilityException.logException(e,ERROR_RETRIEVE_APP_DETAILS_COURSE_OFFERINGS + DEBUG_INFO_APPLICATION_ID + applicationId);
            throw new AuraHandledException(ERROR_RETRIEVE_APP_DETAILS_COURSE_OFFERINGS);
        }
        
        // Return result map
        return resultMap;
    }
    


    /**
    This method searches for course offerings based on given parameters.
    @param citizenshipType the type of citizenship for the course offering
    @param attendanceMode the mode of attendance for the course offering
    @param attendanceType the type of attendance for the course offering
    @param academicYear the academic year for the course offering
    @return a list of Course_Offering__c records that match the search parameters
     * @Revision 
     * 24/08/2022  Smendu - SFTG-2747 Remove excluding OES categories
     * 4/4/2023 Ken McGuire - improve error handling
    */
    @AuraEnabled
    public static List<Course_Offering__c> CourseOfferingsSearch(String citizenshipType, String attendanceMode, String attendanceType, Integer academicYear)  {
        try {
        	return CourseOfferingsFilter(citizenshipType, attendanceMode, attendanceType, academicYear);
        } catch (Exception e) {
            LogUtilityException.logException(e,ERROR_RETRIEVE_COURSE_OFFERINGS);
        	throw new AuraHandledException(ERROR_RETRIEVE_COURSE_OFFERINGS);        
        }
    }
    
    /**
     * Inserts or updates an Application Course Preference and reorders the course preferences
     * @param applicationId ID of the application
     * @param selectedCourseOfferingId ID of the selected Course Offering
     * @return Map of result data including new ACP ID and preference number
     * @throws AuraHandledException if any exceptions are caught
     * 4/4/2023 Ken McGuire - improve error handling
     */
    @AuraEnabled
    public static Map<String, Object> addACP(String applicationId, String selectedCourseOfferingId) {
        Map<String, Object> resultMap = new Map<String, Object>();
        try {
            Application__c contextApplication = getApplicationRecordAndCoursePreferences(applicationId);
            Integer newPreferenceRank = 0;
            if(contextApplication.Application_Course_Preferences__r != null) {
                for(Application_Course_Preference__c loopAcp : contextApplication.Application_Course_Preferences__r) {
                    if(Integer.valueOf(loopAcp.Preference_Number__c) > newPreferenceRank) {
                        newPreferenceRank = Integer.valueOf(loopAcp.Preference_Number__c);
                    }
                }
            }
            newPreferenceRank++;
    
            Set<String> selectedCourseOfferingSet = new Set<String>();
            selectedCourseOfferingSet.add(selectedCourseOfferingId);
            CourseOfferingCC.addACPs(applicationId, JSON.serialize(selectedCourseOfferingSet));
    
            Application_Course_Preference__c contextAcp = [SELECT Id
                            FROM Application_Course_Preference__c
                            WHERE Application__c = :applicationId
                            ORDER BY CreatedDate DESC
                            LIMIT 1];
    
            resultMap.put('acpId', contextAcp.Id);
            resultMap.put('preference', newPreferenceRank);
        } catch(Exception e) {
            // Log error
            LogUtilityException.logException(e,ERROR_UPDATE_COURSE_PREFERENCES + DEBUG_INFO_APPLICATION_ID + applicationId + DEBUG_INFO_ACP_ID + selectedCourseOfferingId);
            throw new AuraHandledException(ERROR_UPDATE_COURSE_PREFERENCES);
        }
        return resultMap;
    }
    

    /**
     * @description Initiates the Callista callout to edit an Application_Course_Preference__c record (ACP) and sets up the continuation with a callback function.
     * @param acpId String representing the Id of the Application_Course_Preference__c record to be edited
     * @param newCourseOfferingId String representing the new Course Offering Id to be assigned to the ACP record
     * @return Object representing the Continuation object to handle the asynchronous callout
     * @AuraEnabled(continuation=true) Allows the method to be invoked from a Lightning component and enables continuation support
     * 4/4/2023 Ken McGuire - improve error handling
     */
    @AuraEnabled(continuation=true)
	public static Object editAcpContinuation(String acpId, String newCourseOfferingId) {
    // Initialize results map
    ContinuationService continuationItem = new ContinuationService(IP07_CALLISTA_ACP_UPDATE);

    try {
        // Build parameter details
        Map<String, Object> parametersMap = buildCalloutParameters(acpId, newCourseOfferingId);
        if (parametersMap.isEmpty()) {
            throw new AuraHandledException(ERROR_NO_PERSON_ID); 
        }
        // Serialize the state into a JSON string
        StateWrapper stateWrapper = new StateWrapper();
        stateWrapper.acpId = acpId;
        stateWrapper.newCourseOfferingId = newCourseOfferingId;
        stateWrapper.acpRequestItem = (String)parametersMap.get(MAPKEY_REQUEST_JSON);
        String stateString = JSON.serialize(stateWrapper);

        // Configure continuation callout
        continuationItem.constructEndPoint((Map<String, String>)parametersMap.get(MAPKEY_URL_REPLACE_KEY_VALUE_PAIRS));
        continuationItem.setupContinuation(60, (String)parametersMap.get(MAPKEY_REQUEST_JSON), 'processResponse', stateString);
    } catch (Exception e) {
        LogUtilityException.logException(e,ERROR_INIT_CALLOUT + DEBUG_INFO_APPLICATION_ID + acpId + DEBUG_INFO_ACP_ID + newCourseOfferingId);
        throw new AuraHandledException(ERROR_INIT_CALLOUT);
    }

    // Return the continuation
    return continuationItem.retrieveContinuation();
}

    
        
    /**
     * @description This method processes the HttpResponse from the ACP to Callista callout and updates the related Application_Course_Preference__c record.
     * @param labels List of String containing unique labels
     * @param state StateWrapper object containing state variables
     * @return Object containing success/error state and relevant messages
     * 4/4/2023 Ken McGuire  - refactored
     */
    @AuraEnabled
	public static Object processResponse(List<String> labels, Object state) {
    	// Deserialize the state from a JSON string
    	StateWrapper deserializedState = (StateWrapper)JSON.deserialize((String)state, StateWrapper.class);
 

        // Initialize results map
        Map<String, Object> resultMap = new Map<String, Object>();
    
    
        try {
            // Perform the callout
            HttpResponse continuationResponse = performCallout(labels);
    
            // Process response results
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(continuationResponse.getBody());
    
            // Update ACP record based on response
            updateACPRecord(deserializedState.acpId, deserializedState.newCourseOfferingId, deserializedState.acpRequestItem, continuationResponse, responseMap, resultMap);
    
        } catch (Exception e) {
            // Log the exception and update the resultMap
           	LogUtilityException.logException(e,ERROR_PROCESS_CALLOUT + DEBUG_INFO_APPLICATION_ID + deserializedState.acpId);
            resultMap.put(MAPKEY_STATE,MAPVALUE_ERROR);
        }
    
        return resultMap;
    }

    /**
     * @description Fetches Application_Course_Preference__c record with the given ID.
     * @param acpId ID of the Application_Course_Preference__c record.
     * @return Application_Course_Preference__c record.
     * 4/4/2023 Ken McGuire - improve error handling
     */
    @AuraEnabled
    public static Application_Course_Preference__c getApplicationCoursePreference(String acpId) {
        try {
            return getCompleteApplicationCoursePreference(acpId);
        } catch (Exception e) {
            LogUtilityException.logException(e,ERROR_UPDATE_COURSE_PREFERENCES + DEBUG_INFO_APPLICATION_ID + acpId);
            throw new AuraHandledException(ERROR_UPDATE_COURSE_PREFERENCES);
        }
    }
    /**
     * Searches for Course Offerings based on provided filters.
     *
     * @param citizenshipType The Citizenship Type filter
     * @param attendanceMode The Attendance Mode filter
     * @param attendanceType The Attendance Type filter
     * @param academicYear The Academic Year filter
     * @param courseCode The Course Code filter
     * @param courseTitle The Course Title filter
     * @param admissionCalendarDescription The Admission Calendar Description filter
     * @param admissionCategory The Admission Category filter
     * @return List of filtered Course Offerings
     * @Revision 
     * 24/08/2022  Smendu - SFTG-2747 Remove excluding OES categories
     *  4/4/2023 Ken McGuire - improve error handling
     */
    @AuraEnabled
    public static List<Course_Offering__c> searchCourseOfferingsEdit(String citizenshipType, String attendanceMode, String attendanceType, Integer academicYear, String courseCode, String courseTitle, String admissionCalendarDescription, String admissionCategory) {
        try {
            return ExtendedCourseOfferingsFilter(citizenshipType, attendanceMode, attendanceType, academicYear, courseCode, courseTitle, admissionCalendarDescription, admissionCategory);
        } catch (Exception e) {
            LogUtilityException.logException(e,ERROR_RETRIEVE_COURSE_OFFERINGS);
            throw new AuraHandledException(ERROR_RETRIEVE_COURSE_OFFERINGS);
        }
    }

    /**
     * @description Retrieves and updates the ACP with the details of a new Course Offering.
     * @param acpId ID of the Application_Course_Preference__c record.
     * @param newCourseOfferingId ID of the new Course_Offering__c record.
     * @return Updated Application_Course_Preference__c record with the new Course Offering details.
     * @throws AuraHandledException if any errors occur during the processing.
     *  4/4/2023 Ken McGuire - created
     */
    @AuraEnabled
    public static Application_Course_Preference__c retrieveAcpCompleteDetails(Id acpId, String newCourseOfferingId) {
        try {
            Application_Course_Preference__c acpRecord = getCompleteApplicationCoursePreference(acpId);
            Course_Offering__c newCourseOffering = getCompleteCourseOffering(newCourseOfferingId);
            return updateAcpWithCourseOffering(acpRecord, newCourseOffering);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving ACP complete details: ' + e.getMessage());
        }
    }
    // Helper methods


    /**
     * @description This method performs the callout using the unique label.
     * @param labels List of String containing unique labels
     * @return HttpResponse containing the callout response
     * 4/4/2023 Ken McGuire  - refactored
     */
    private static HttpResponse performCallout(List<String> labels) {
        return Continuation.getResponse(labels[0]);
    }

    /**
     * @description This method updates the Application_Course_Preference__c record based on the HttpResponse.
     * @param acpId Id of the Application_Course_Preference__c record
     * @param newCourseOfferingId String containing the new Course Offering Id
     * @param acpRequestItem String containing the ACP request item
     * @param continuationResponse HttpResponse containing the callout response
     * @param responseMap Map<String, Object> containing the deserialized response
     * @param resultMap Map<String, Object> containing the success/error state and relevant messages
     * 4/4/2023 Ken McGuire  - refactored
     */
    @testVisible
    private static void updateACPRecord(Id acpId, String newCourseOfferingId, String acpRequestItem, HttpResponse continuationResponse, Map<String, Object> responseMap, Map<String, Object> resultMap) {
        // Check for successful response
        Application_Course_Preference__c acpRecord = getACPRecord(acpId);
    
        // Process ACP if found
        if (acpRecord != null) {
            if (continuationResponse.getStatusCode() == 200) {
                ObdACPResponse acpResponse = (ObdACPResponse) System.JSON.deserialize(JSON.serializePretty(responseMap), ObdACPResponse.class);
                updateSuccessfulACPRecord(acpRecord, acpRequestItem, newCourseOfferingId, acpResponse);
            } else {
                updateFailedACPRecord(acpRecord, acpRequestItem, responseMap, continuationResponse);
            }
            update acpRecord;
    
            resultMap.put(MAPKEY_STATE, MAPVALUE_SUCCESS);
            resultMap.put(MAPKEY_MESSAGE, acpRecord.Callista_Error_Message__c);
        } else {
            resultMap.put(MAPKEY_STATE, MAPVALUE_ERROR);
            resultMap.put(MAPKEY_MESSAGE, ERROR_NO_APPLICATION_COURSE_PREFERENCE_RECORDS);
        }
    }


    /**
     * @description This method updates the Application_Course_Preference__c record with successful callout response data.
     * @param acpRecord Application_Course_Preference__c record to be updated
     * @param acpRequestItem String containing the ACP request item
     * @param newCourseOfferingId String containing the new Course Offering Id
     * @param acpResponse ObdACPResponse containing the deserialized callout response
     * 4/4/2023 Ken McGuire  - refactored
     */
    private static void updateSuccessfulACPRecord(Application_Course_Preference__c acpRecord, String acpRequestItem, String newCourseOfferingId, ObdACPResponse acpResponse) {
        acpRecord.Admission_Application_Number__c = acpResponse.applications[0].admissionApplNumber;
        acpRecord.Application_Sequence_Number__c = acpResponse.applications[0].coursePreferences[0].coursePreferenceInstances[0].sequenceNumber;
        String resCourseCode = acpResponse.applications[0].coursePreferences[0].courseCode;
        acpRecord.Callista_Submission_Message__c = acpRequestItem;
    
        if (String.isBlank(acpRecord.Callista_Unique_Key_ADM__c)) {
            acpRecord.Callista_Unique_Key_ADM__c = acpRecord.Person_ID__c + '-' + acpRecord.Admission_Application_Number__c + '-' + resCourseCode + '-' + acpRecord.Application_Sequence_Number__c;
        }
    
        acpRecord.Send_to_callista__c = false;
        acpRecord.Callista_Sync_Successful__c = true;
        acpRecord.Course_Offering__c = newCourseOfferingId;
    }

    /**
     * @description This method updates the Application_Course_Preference__c record with failed callout response data.
     * @param acpRecord Application_Course_Preference__c record to be updated
     * @param acpRequestItem String containing the ACP request item
     * @param responseMap Map<String, Object> containing the deserialized response
     * @param continuationResponse HttpResponse containing the callout response
     * 4/4/2023 Ken McGuire  - refactored
     */
    private static void updateFailedACPRecord(Application_Course_Preference__c acpRecord, String acpRequestItem, Map<String, Object> responseMap, HttpResponse continuationResponse) {
        acpRecord.Callista_Sync_Successful__c = false;
        acpRecord.Callista_Submission_Message__c = acpRequestItem;
        acpRecord.Callista_Error_Message__c = responseMap != null ? JSON.serializePretty(responseMap) : String.valueOf(continuationResponse.getStatusCode());
    }
    
    /**
    Returns a Set of field names that should be cloned for an Application Course Preference (ACP) object.
    This method provides a convenient way to obtain the field names that need to be copied when cloning an ACP.
    @return Set<String> - A set of field API names that should be cloned for an ACP object.
    * 4/4/2023 Ken McGuire - created
    */
    private static  Set<String> getAPCFieldsToClone() {
        return new Set<String> {
            'Status__c', 'Admissions_Assessment_Status__c', 'Admissions_Process_Type__c', 'Outcome_Status_LOV__c',
                'Offer_Response_Status_LOV__c', 'Conditional_Offer_Status_LOV__c', 'Deferment_Status_LOV__c',
                'Documentation_Status_LOV__c', 'Entry_Qualification_Status_LOV__c', 'Offer_Condition__c',
                'Admissions_Assessment_Status__c', 'Task_Course_Preference__c', 'Task_Additional_Requirements__c',
                'Task_Credit__c', 'Task_GTE_Check__c', 'Task_DSS_Check__c', 'Task_Outcome_Finalisation__c',
                'Selection_Activity_Type__c', 'Additional_Reqs_Assessment_Decision__c', 'Credit_Assessment_Decision__c',
                'Approved_Credit_Points__c', 'Credit_Adjusted_Course_Duration__c', 'DSS_Decision__c',
                'Offer_Round__c', 'Conditional_Offer_Satisfied_Date__c', 'Assessment_Status__c',
                'Basis_For_Adminssion_Type__c', 'Recruitment_Reference_Code__c', 'Precedent_ID__c',
                'Requirement_Satisfied_Code__c', 'Acceptance_Condition__c', 'Conditions_Must_Be_Satisfied__c',
                'Workflow_Status__c'
   		};
   }

    /**
     * @description Query complete acp details and add course offering details
     * @param acpId Id of the Application_Course_Preference__c record
     * @param newCourseOfferingId Id of the new Course Offering
     * @return Map<String, Object> containing requestJSON and urlReplaceKeyValuePairs for the callout
     *  4/4/2023 Ken McGuire - created
     */
    private static Map<String, Object> buildCalloutParameters(Id acpId, String newCourseOfferingId){
        // Initialize variables
        Map<String, Object> resultMap = new Map<String, Object>();
        
        try {
            Application_Course_Preference__c acpItem = retrieveAcpCompleteDetails(acpId, newCourseOfferingId);
            ObdACPRequest acpRequest = ObdACPImplementation.createRequest(acpItem);
            String prettyAcpRequestJSON = '';
    
            if (acpItem.Person_ID__c == null && acpItem.Callista_Unique_Key_ADM__c == null) {
                logError(acpId, acpItem);
                return resultMap;
            }
    
            buildUrlReplaceKeyValuePairs(resultMap, acpItem);
            
            prettyAcpRequestJSON = JSON.serializePretty(acpRequest);
            
            handleDomesticResidency(resultMap, acpItem, prettyAcpRequestJSON);
    
        } catch (Exception e) {
            // Log exceptions
            LogUtilityException.logException(e,ERROR_BUILDING_CALLOUT +  DEBUG_INFO_APPLICATION_ID + acpId  +DEBUG_INFO_ACP_ID + newCourseOfferingId );
        }
        
        return resultMap;
    }
    
     /**
     * @description Logs an error message when Person ID and ADM Key are missing, sets Callista_Error_Message__c and Callista_Sync_Successful__c fields, and updates the ACP record
     * @param acpId Id of the Application_Course_Preference__c record
     * @param acpItem Application_Course_Preference__c object containing the ACP record
     *  4/4/2023 Ken McGuire - created
     */
    private static void logError(Id acpId, Application_Course_Preference__c acpItem) {
        LogUtilityException.logExceptionMSG('User', DEBUG_INFO_APPLICATION_ID + acpId,ERROR_NO_PERSON_ID);
        acpItem.Callista_Error_Message__c =ERROR_NO_PERSON_ID;
        acpItem.Callista_Sync_Successful__c = false;
        update acpItem;
    }
    
    /**
     * @description Builds the urlReplaceKeyValuePairs map and adds it to the resultMap
     * @param resultMap Map<String, Object> containing the result data
     * @param acpItem Application_Course_Preference__c object containing the ACP record
     *  4/4/2023 Ken McGuire - created
     */
    private static void buildUrlReplaceKeyValuePairs(Map<String, Object> resultMap, Application_Course_Preference__c acpItem) {
        Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
        urlReplaceKeyValuePairs.put('{0}', acpItem.Person_ID__c != NULL ? acpItem.Person_ID__c : acpItem.Callista_Unique_Key_ADM__c.left(8));
        resultMap.put(MAPKEY_URL_REPLACE_KEY_VALUE_PAIRS, urlReplaceKeyValuePairs);
    }
    
   /**
     * @description Handles domestic residency by removing null recruitmentReferenceCode and primaryNationalityCode from the request JSON and adds the updated JSON to the resultMap
     * @param resultMap Map<String, Object> containing the result data
     * @param acpItem Application_Course_Preference__c object containing the ACP record
     * @param prettyAcpRequestJSON String containing the serialized ACP request JSON
     *  4/4/2023 Ken McGuire - created
     */

    private static void handleDomesticResidency(Map<String, Object> resultMap, Application_Course_Preference__c acpItem, String prettyAcpRequestJSON) {
        if (acpItem.Application__r.Residency_Status__c != null && acpItem.Application__r.Residency_Status__c.contains('DOM')) {
            prettyAcpRequestJSON = ApplicationCoursePreferenceWizard.removeSubString(prettyAcpRequestJSON, '"recruitmentReferenceCode" : null,');
            prettyAcpRequestJSON = ApplicationCoursePreferenceWizard.removeSubString(prettyAcpRequestJSON, '"primaryNationalityCode" : null,');
        }
        resultMap.put('requestJSON', prettyAcpRequestJSON);
    }


    
       /**
        * @description Updates the ACP record with the details of the new Course Offering.
        * @param acpRecord The Application_Course_Preference__c record to be updated.
        * @param newCourseOffering The Course_Offering__c record with the new Course Offering details.
        * @return Updated Application_Course_Preference__c record with the new Course Offering details.
        * 4/4/2023 Ken McGuire - created
        */
        private static Application_Course_Preference__c updateAcpWithCourseOffering(Application_Course_Preference__c acpRecord, Course_Offering__c newCourseOffering) {
            acpRecord.Correspondence_Category__c        = newCourseOffering.Correspondence_Category__c;
            acpRecord.Enrolment_Category__c             = newCourseOffering.Enrolment_Category__c;
            acpRecord.Fee_Category__c                   = newCourseOffering.Fee_Category__c;
            acpRecord.Fee_Payment_Option__c             = newCourseOffering.Hecs_Payment_Option__c;
            acpRecord.Academic_Calendar_Type__c         = newCourseOffering.Academic_Calendar_Type__c;
            acpRecord.Academic_CI_Sequence_Number__c    = newCourseOffering.Academic_CI_Sequence_Number__c;
            acpRecord.Admission_Calendar_Type__c        = newCourseOffering.Admission_Calendar_Type__c;
            acpRecord.Admission_CI_Sequence_Number__c   = newCourseOffering.Admission_CI_Sequence_Number__c;
            acpRecord.Attendance_Mode__c                = newCourseOffering.Attendance_Mode__c;
            acpRecord.Attendance_Mode_Description__c    = newCourseOffering.Attendance_Mode_Description__c;
            acpRecord.Attendance_Type__c                = newCourseOffering.Attendance_Type__c;
            acpRecord.Attendance_Type_Description__c    = newCourseOffering.Attendance_Type_Description__c;
            acpRecord.Commencement_Period__c            = newCourseOffering.Admission_Calendar_Description__c;
            acpRecord.Course_Code__c                    = newCourseOffering.Course_Code__c == null ? newCourseOffering.Course_Code_F__c : newCourseOffering.Course_Code__c;
            acpRecord.Course_Code_Unique__c             = newCourseOffering.Course_Code__c + '_' + newCourseOffering.Course_Version_Number__c;
            acpRecord.Course_Title__c                   = newCourseOffering.Course_Title__c == null ? newCourseOffering.Course_Title_F__c : newCourseOffering.Course_Title__c;
            acpRecord.Course_Version_Number__c          = newCourseOffering.Course_Version_Number__c;
            acpRecord.Unit_Set_Code__c                  = newCourseOffering.Unit_Set_Code__c;
            acpRecord.Unit_Set_Description__c           = newCourseOffering.Unit_Set_Description__c;
            acpRecord.Unit_Set_Version__c               = newCourseOffering.Unit_Set_Version__c;
            return acpRecord;
        }
    
    /**
     * @description Method to replace string from a string
     * @param  String ss - element which has null value
     * @param  String - payload after removing the element
     * 4/4/2023 Ken McGuire - created
    */
    private static String removeSubString(String prettyJSON, String ss) {
        String remvString = prettyJSON.contains(ss)?prettyJSON.remove(ss):prettyJSON;
        return remvString;
    }
    
    // SOQL queries
   
    /**
     * Queries relevant application data and course preferences
     * @param applicationId ID of the application
     * @return Application__c object containing relevant data
     * 4/4/2023 Ken McGuire - created
     */
    private static Application__c getApplicationRecordAndCoursePreferences(String applicationId) {
        return [SELECT Id, Residency_Status__c, Applicant__c,
                (SELECT Id, Preference_Number__c FROM Application_Course_Preferences__r ORDER BY Preference_Number__c DESC)
                FROM Application__c
                WHERE Id = :applicationId
                LIMIT 1];
    }
    

   /**
    * Retrieves an Application__c together with a primray course preference record for the given application ID.
    * @param applicationId The ID of the application to retrieve records for.
    * @return An  Application__c record and associated course preference for the given ID.
    * 4/4/2023 Ken McGuire  - created
    */
    private static Application__c getApplicationRecordAndCoursePreference (String applicationId) {
			List<Application__c> applicationRecords = 
                [SELECT Id, Residency_Status__c,
                (SELECT Id, Application__c, Attendance_Type__c, Attendance_Mode__c, Course_Offering__r.Academic_Year__c
                FROM Application_Course_Preferences__r WHERE Preference_Number__c = '1' LIMIT 1)
                FROM Application__c
                WHERE Id = :applicationId
             	LIMIT 1];
        return applicationRecords.isEmpty() ? null : applicationRecords[0];
    }
    
   /**
     * @description Queries Course_Offering__c record with the given ID.
     * @param courseOfferingId ID of the Course_Offering__c record.
     * @return Course_Offering__c record.
     * 4/4/2023 Ken McGuire - created
     */
    private static Course_Offering__c getCompleteCourseOffering(String courseOfferingId) {
         Course_Offering__c[] courseOfferingRecords = [SELECT Id,Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Admission_Calendar_Description__c,Admission_Calendar_Type__c,
                Admission_CI_Sequence_Number__c,Attendance_Mode__c,Attendance_Mode_Description__c,Attendance_Type__c,Attendance_Type_Description__c,
                Correspondence_Category__c,Course_Code__c,Course_Code_F__c,Course_Title__c,Course_Title_F__c,Course_Version_Number__c,
                Enrolment_Category__c,Fee_Category__c,Hecs_Payment_Option__c,Unit_Set_Code__c,Unit_Set_Description__c,Unit_Set_Version__c
                FROM Course_Offering__c
                WHERE Id = :courseOfferingId
                LIMIT 1];
        return  courseOfferingRecords.isEmpty() ? null :  courseOfferingRecords[0];
    } 
    /**
    This method executes a SOQL query for searching course offerings.
    @param citizenshipType the type of citizenship for the course offering
    @param attendanceMode the mode of attendance for the course offering
    @param attendanceType the type of attendance for the course offering
    @param academicYear the academic year for the course offering
    @return a list of Course_Offering__c records that match the search parameters
	4/4/2023 Ken McGuire - created
    */
    @testVisible
	private static List<Course_Offering__c> CourseOfferingsFilter(String citizenshipType, String attendanceMode, String attendanceType, Integer academicYear) {

    	return [ SELECT Id, Academic_Year__c, Citizenship_Type__c, Attendance_Mode__c, Attendance_Type__c, Course_Code__c, Course_Title__c, Admission_Calendar_Description__c, Admission_Category__c, Location_Code__c,
            Unit_Set_Code__c, Unit_Set_Description__c, Unit_Set_Version__c, Course_Version_Number__c, Commencement_Period__c, Admission_Alternate_Code__c
            FROM Course_Offering__c
            WHERE Citizenship_Type__c = :citizenshipType
            AND Attendance_Mode__c = :attendanceMode
            AND Attendance_Type__c = :attendanceType
            AND Academic_Year__c = :academicYear
            AND Active__c = true
            ORDER BY Course_Code__c ASC,
            Admission_Calendar_Description__c ASC,
            Admission_Category__c ASC,
            Location_Code__c ASC,
            Unit_Set_Code__c ASC,
            Unit_Set_Version__c DESC
            LIMIT 10000
            ];
    }
    
    
    /**
     * Queries Course Offerings based on provided filters.
     *
     * @param citizenshipType The Citizenship Type filter
     * @param attendanceMode The Attendance Mode filter
     * @param attendanceType The Attendance Type filter
     * @param academicYear The Academic Year filter
     * @param courseCode The Course Code filter
     * @param courseTitle The Course Title filter
     * @param admissionCalendarDescription The Admission Calendar Description filter
     * @param admissionCategory The Admission Category filter
     * @return List of filtered Course Offerings
     * 4/4/2023 Ken McGuire - created
     */
    private static List<Course_Offering__c> ExtendedCourseOfferingsFilter(String citizenshipType, String attendanceMode, String attendanceType, Integer academicYear, String courseCode, String courseTitle, String admissionCalendarDescription, String admissionCategory) {
        return [SELECT Id, Academic_Year__c, Citizenship_Type__c, Attendance_Mode__c, Attendance_Type__c, Course_Code__c, Course_Title__c, Admission_Calendar_Description__c, Admission_Category__c, Location_Code__c,
                Unit_Set_Code__c, Unit_Set_Description__c, Unit_Set_Version__c, Course_Version_Number__c, Commencement_Period__c, Admission_Alternate_Code__c
                FROM Course_Offering__c
                WHERE Citizenship_Type__c = :citizenshipType
                AND Attendance_Mode__c = :attendanceMode
                AND Attendance_Type__c = :attendanceType
                AND Academic_Year__c = :academicYear
                AND Course_Code__c = :courseCode
                AND Course_Title__c = :courseTitle
                AND Admission_Calendar_Description__c = :admissionCalendarDescription
                AND Admission_Category__c = :admissionCategory
                AND Active__c = true
                ORDER BY Course_Code__c ASC,
                Admission_Calendar_Description__c ASC,
                Admission_Category__c ASC,
                Location_Code__c ASC,
                Unit_Set_Code__c ASC,
                Unit_Set_Version__c DESC
                LIMIT 10000];
    }

    /**
     * @description This method retrieves the Application_Course_Preference__c record by Id.
     * @param acpId Id of the Application_Course_Preference__c record
     * @return Application_Course_Preference__c record with specified Id
     * 4/4/2023 Ken McGuire - created
     */
    private static Application_Course_Preference__c getACPRecord(Id acpId) {
        Application_Course_Preference__c[] acpRecords = [SELECT Id, Admission_Application_Number__c, Application_Sequence_Number__c, Callista_Unique_Key_ADM__c, Person_ID__c, Callista_Submission_Message__c, 
                                                         Callista_Sync_Successful__c, Send_to_callista__c, Course_Offering__c, Callista_Error_Message__c
                                                      FROM Application_Course_Preference__c
                                                      WHERE Id = :acpId LIMIT 1];
        return acpRecords.isEmpty() ? null : acpRecords[0];
    }
    
    
    /**
     * @description Get Application Course Preference record and associated course offering record
     * @param acpId The ID of the Application Course Preference record
     * @return Application_Course_Preference__c The queried Application Course Preference record
     * 4/4/2023 Ken McGuire - created
     */
    private static Application_Course_Preference__c getCoursePreferenceWithCourseOffering(String acpId) {
        Application_Course_Preference__c[] applicatonRecords =  
            [SELECT Id, Application__c, Application__r.Residency_Status__c, Attendance_Type__c, Attendance_Mode__c, 
                 Course_Offering__c,Course_Offering__r.id,Course_Offering__r.Academic_Year__c, Course_Offering__r.Citizenship_Type__c, Course_Offering__r.Attendance_Mode__c, 
                Course_Offering__r.Course_Code__c, Course_Offering__r.Course_Title__c, Course_Offering__r.Admission_Calendar_Description__c, Course_Offering__r.Admission_Category__c,
                 Course_Offering__r.Location_Code__c, Course_Offering__r.Unit_Set_Code__c, Course_Offering__r.Unit_Set_Description__c,
             	Course_Offering__r.Attendance_Type__c, Course_Offering__r.Unit_Set_Version__c, 
                 Course_Offering__r.Course_Version_Number__c, Course_Offering__r.Commencement_Period__c, Course_Offering__r.Admission_Alternate_Code__c
                 FROM Application_Course_Preference__c
                 WHERE Id = :acpId
                 LIMIT 1];
        return  applicatonRecords.isEmpty() ? null :  applicatonRecords[0];
    }
    
    /**
     * @description Queries Application_Course_Preference__c record with the given ID.
     * @param acpId ID of the Application_Course_Preference__c record.
     * @return Application_Course_Preference__c record.
     * 4/4/2023 Ken McGuire - created
     */
    private static Application_Course_Preference__c getCompleteApplicationCoursePreference(String acpId) {
        Application_Course_Preference__c[] applicatonRecords =  
            [SELECT Id,Callista_Unique_Key_ADM__c,Admission_Application_Number__c,Application__c,Application__r.Submitted_Date__c,Application__r.CitizenCountryCode__c,Application__r.Residency_Status__c,
             Application__r.Credit_Intention__c,Application__r.Source_System__c,Application__r.Callista_Application_Id__c,Application__r.Agent__c,Callista_Unique_Key_AP__c,
             Course_Code__c,Basis_For_Adminssion_Type__c,Admission_Code__c,Application_Sequence_Number__c,Course_Version_Number__c,Location_Code__c,Attendance_Mode__c,
             Attendance_Type__c,Unit_Set_Code__c,Unit_Set_Version__c,Preference_Number__c,Documentation_Status_LOV__r.Value__c,Entry_Qualification_Status_LOV__r.Value__c,Outcome_Status_LOV__r.Value__c,
             Authorising_Person_ID__c,Authorised_Date__c,Override_Outcome_Reason__c,Offer_Date__c,Offer_Response_Date__c,Offer_Response_Status_LOV__r.Value__c,Proposed_Commencement_Date__c,
             Conditional_Offer_Status_LOV__r.Value__c,Conditional_Offer_Satisfied_Date__c,Conditions_Must_Be_Satisfied__c,Actual_Offer_Response_Date__c,Deferment_Status_LOV__r.Value__c,
             Deferred_Admission_Ci_Sequence__c,Deferred_Admission_Calendar_Type__c,Fee_Category__c,Fee_Payment_Option__c,Correspondence_Category__c,Enrolment_Category__c,
             Funding_Source__c,Acceptance_Condition__c,Offer_Condition__c,Agreed_Start_Date__c,Offer_Round__c,LongComments__c,Person_ID__c,Academic_Calendar_Type__c,
             Academic_CI_Sequence_Number__c,Admission_Category__c,Admission_CI_Sequence_Number__c,Admission_Calendar_Type__c,Requirement_Satisfied_Code__c,Precedent_ID__c,Recruitment_Reference_Code__c
             ,Application__r.Submission_Location_Country__r.Callista_Code__c,Bulk_Data_Processing__r.Transfer_From__r.course_code__c,Bulk_Data_Processing__r.Transfer_To__r.course_code__c
             FROM Application_Course_Preference__c
                WHERE Id =: acpId Limit 1];
         return  applicatonRecords.isEmpty() ? null :  applicatonRecords[0];
        
    }


    
    /**
     * @class StateWrapper
     * @description A custom wrapper class to store state information for the asynchronous callout
     *            	in the editAcpContinuation and processResponse methods. This class is used to
     *              serialize and deserialize the state data, providing a more robust and
     *              maintainable way to pass state information between the methods.
     * @property acpId Id representing the Application_Course_Preference__c record Id
     * @property newCourseOfferingId String representing the new Course Offering Id to be assigned to the ACP record
     * @property acpRequestItem String representing the request JSON payload for the callout
     * 4/4/2023 Ken McGuire - created
     */
    public class StateWrapper {
        public Id acpId;
        public String newCourseOfferingId;
        public String acpRequestItem;
    }

}