/**
 * @author      APRivera
 * @description handling external API interactions and managing the flow of data between the system and the API.
 * @group       Admissions - English Test
 * @revision   15/12/2024 - APRivera - Created
 * @revision   10/04/2025 - APRivera - Added the usage on Provider attribute
 */
public with sharing class EnglishTestApiService {

    public static final String LOGGER_TAG = 'My.App - English Verification';

    /**
     * Makes a GET call to the given endpoint and parses the response.
     * @param testReportForm Wrapper class for managing test report data, including personal details.
     * @return EnglishTestVerificationPayload containing the parsed API response data.
     */
    @AuraEnabled
    public static EnglishTestVerificationPayload makeGetCall(EnglishTestVerificationPayload.TestReportFormWrapper testReportForm) {
        EnglishTestVerificationPayload newPayload = new EnglishTestVerificationPayload();
        try {
            String testReportNumber = testReportForm.TestReportNumber?.trim();
            String provider = testReportForm.Provider;
//            Boolean photoFlag = testReportForm.PhotoFlag; // TODO next release - Pearson

            // Perform the GET request
            Integration_Point__mdt interfaceDetails = Integration_Point__mdt.getInstance('English_Test');
            String correlationId = Datetime.now().getTime() + '-' + Crypto.getRandomInteger();

            HttpRequest request = new HttpRequest();

            String formattedStartDate = '';
            String formattedEndDate = '';

            if (!provider.contains('IELTS') && testReportForm.DateCompleted != null) { // FOR TOEFL with DateCompleted
                Date startDt = testReportForm.DateCompleted;
                Date endDt = startDt.addYears(1);

                // Format StartDate and EndDate as "YYYY-MM-DD"
                formattedStartDate = startDt.year() + '-' +
                        formatDateComponent(startDt.month()) + '-' +
                        formatDateComponent(startDt.day());
                formattedEndDate = endDt.year() + '-' +
                        formatDateComponent(endDt.month()) + '-' +
                        formatDateComponent(endDt.day());
            }

            // Build the endpoint dynamically based on the conditions
            request.setEndpoint('callout:Monash_MiX_APIs'
                    + interfaceDetails.Endpoint_Relative_URL__c
                    + testReportNumber
                    + '?testType=' + provider
                    + (String.isNotBlank(formattedStartDate) ? '&startDate=' + formattedStartDate : '')
                    + (String.isNotBlank(formattedEndDate) ? '&endDate=' + formattedEndDate : ''));

            request.setHeader('client_id', '{!$Credential.Username}');
            request.setHeader('client_secret', '{!$Credential.Password}');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('X-CORRELATION-ID', correlationId);
            request.setMethod('GET');

            HttpResponse response = new Http().send(request);

            // Log headers and body
            Nebula.Logger.info('Request Endpoint: ' + request.getEndpoint() + '\nCorrelationId: ' + JSON.serialize(request.getHeader('X-CORRELATION-ID'))).addTag(LOGGER_TAG);
            Nebula.Logger.saveLog();

            // Validate response status code
            if (response.getStatusCode() == 200) {
                // Parse the response and return
                String resultString = response.getBody().toString();
                return parseResponse(resultString);
            } else {
                return generateResponse(newPayload,'Error', 'Verification Unsuccessful - Cannot Verify English Test. \nResponse: ' + response, true);
            }
        } catch (Exception e) {
            return generateResponse(newPayload,'Error', 'Error during English Test API call: ' + e.getTypeName() + '-' +e.getMessage() + '\n Exception: ' + e, true);
        }
    }

    // Helper method to pad single-digit numbers with a leading zero
    private static String formatDateComponent(Integer dateComponent) {
        return dateComponent < 10 ? '0' + dateComponent : String.valueOf(dateComponent);
    }

    /**
     * Parses and deserializes the JSON response body into an EnglishTestVerificationPayload object,
     * ensuring the ResponseWrapper is populated with a success status on success.
     * @param responseBody The JSON string from the API response.
     * @return EnglishTestVerificationPayload containing the parsed data along with a ResponseWrapper.
     */
    private static EnglishTestVerificationPayload parseResponse(String responseBody) {
        EnglishTestVerificationPayload newPayload = new EnglishTestVerificationPayload();
        try {
            // Deserialize the JSON response into an EnglishTestVerificationPayload object
            newPayload = (EnglishTestVerificationPayload) JSON.deserialize(responseBody, EnglishTestVerificationPayload.class);
            newPayload.success = true;
            newPayload.message = 'Payload received from MIX';
            // Return the populated payload
            return newPayload;
        } catch (JSONException e) {
            // Return a payload with an error ResponseWrapper
            return generateResponse(newPayload,'Error', 'Failed to parse English Test API response: ' + e.getMessage() + '\n Exception: ' + e, true);
        }
    }

    /**
     * Generates and returns an EnglishTestVerificationPayload object with only the ResponseWrapper populated.
     *
     * @param verifiedPayload The payload return from MIX
     * @param strStatus The status string to be set in the ResponseWrapper (e.g., "success" or "error").
     * @param strMessage The message string to be set in the ResponseWrapper (e.g., "Operation successful").
     * @param isToLog Flag to indicate whether to log or not
     * @return EnglishTestVerificationPayload containing a populated ResponseWrapper.
     */
    public static EnglishTestVerificationPayload generateResponse(EnglishTestVerificationPayload verifiedPayload, String strStatus, String strMessage, Boolean isToLog) {
        // Initialize the payload object
        EnglishTestVerificationPayload payload = new EnglishTestVerificationPayload();
        payload = verifiedPayload;
        payload.message = strMessage;
        payload.success = strStatus == 'success';

        if(isToLog){
            if(strStatus == 'success'){
                Nebula.Logger.info(strMessage).addTag(EnglishTestApiService.LOGGER_TAG);
            } else{
                Nebula.Logger.error(strMessage).addTag(EnglishTestApiService.LOGGER_TAG);
            }
            Nebula.Logger.saveLog();
        }
        // Return the payload with the populated ResponseWrapper
        return payload;
    }

    /**
         * @description Handles validation by invoking the EnglishTestApiService and the validation factory.
         *              Processes the input test report data, validates the contact and application details,
         *              and generates a qualification record. Returns the validation response.
         * @param incomingTestReportForm - A JSON string of type EnglishTestVerificationPayload.TestReportFormWrapper containing the test report details.
         * @param contactId - The ID of the contact to be validated and associated with the qualification.
         * @param applicationId - The ID of the application associated with the contact and validation process.
         * @param qualification - The ID of the Qualification record in CRM (e.g, SF ID of 'IELTS Academic')
         * @param isCompleted - A Boolean flag indicating the completion of the test. (true or false)
         * @param provider - The type of English test provider related to the validation (e.g., IELTS, TOEFL, etc.)
         * @param englishRequirement - The English proficiency requirement (Level of English Proficiency)
         * @return EnglishTestVerificationPayload.ResponseWrapper containing the results of the validation logic
         *         and generated qualification details.
         */
    @AuraEnabled
    public static EnglishTestVerificationPayload handleValidation(String incomingTestReportForm, Id contactId, Id applicationId, String qualification,
                                                                    Boolean isCompleted, String provider, String englishRequirement) {

            // Log the response for debugging/tracking purposes
            Nebula.Logger.info('Applicant Test Details : ' + incomingTestReportForm).addTag(LOGGER_TAG);
            Nebula.Logger.saveLog();

            // deserialize parameter application
            EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = (EnglishTestVerificationPayload.TestReportFormWrapper)JSON.deserialize(incomingTestReportForm, EnglishTestVerificationPayload.TestReportFormWrapper.class);

            // Get the test type value (ignoring case)
            String testProvider = testReportForm.Provider.trim().toUpperCase();
            // Map the test type to EnglishTestProviderType
            EnglishTestProviderType providerType;
            switch on testProvider {
                when 'IELTS' {
                    providerType = EnglishTestProviderType.IELTS;
                }
                when 'PEARSON' {
                    providerType = EnglishTestProviderType.PEARSON;
                }
                when 'TOEFL' {
                    providerType = EnglishTestProviderType.TOEFL;
                }
            }

            // Step 1: Call makeGetCall to retrieve payload from MIX
            EnglishTestVerificationPayload mixPayload = EnglishTestApiService.makeGetCall(testReportForm);

            if(mixPayload.success){
                // Step 2: Call EnglishTestProviderValidationFactory to get the validator
                EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(providerType);

                // Step 3: Perform validation and return the result
                EnglishTestVerificationPayload validationResponse = validator.validate(mixPayload, testReportForm);
                String status = '';
                if(validationResponse.success){
                    status = 'success';
                    try {
                        Contact_Qualification__c contactQualification = new Contact_Qualification__c();
                        contactQualification = generateContactQualification(validationResponse, contactId, qualification, isCompleted, testProvider, englishRequirement);
                        appAddQualificationCC.upsertQualificationToContact(contactId, applicationId, contactQualification);
                    }
                    catch (Exception e) {
                        return generateResponse(validationResponse, 'error', 'Error in saving contact qualification. \n Error:' + e.getMessage(), true);
                    }
                } else{
                    status = 'error';
                }
                return generateResponse(validationResponse, status, validationResponse.message, true);
            } else{
                // return payload
                return mixPayload;
            }
    }


    /**
     * @description Generates a Contact Qualification record based on the validation response and other input parameters.
     *              Populates the qualification details, associates it with the provided contact, and specifies test details.
     * @param validationResponse The validation response object of type EnglishTestVerificationPayload, containing test result details.
     * @param contactId The ID of the contact to associate with the qualification record.
     * @param strQual A string representing the qualification status or details.
     * @param isCompleted A Boolean flag indicating whether the qualification process is completed or not.
     * @param provider The type of English test provider related to the qualification (e.g., IELTS, TOEFL, etc.).
     * @param englishRequirement The English proficiency requirement.
     * @return A Contact_Qualification__c record populated with the provided data and validation results.
     */
    public static Contact_Qualification__c generateContactQualification(EnglishTestVerificationPayload validationResponse, Id contactId,
                                                                        String strQual, Boolean isCompleted, String provider, String englishRequirement) {
        Contact_Qualification__c contactQualification = new Contact_Qualification__c();
        contactQualification.RecordTypeId = appAddQualificationCC.getRecordTypeIdForEnglishTest();
        contactQualification.Contact__c = contactId;
        contactQualification.Qualification__c = strQual;
        contactQualification.Source_Channel__c = provider;
        contactQualification.Date_Achieved__c = validationResponse.testDate;
        contactQualification.isTestCompleted__c = isCompleted;
        contactQualification.English_Test_Number__c = validationResponse.testNumber;
        contactQualification.Score__c = String.valueOf(validationResponse.overallScore);
        contactQualification.Listening__c = String.valueOf(validationResponse.listeningScore);
        contactQualification.Writing__c = String.valueOf(validationResponse.writingScore);
        contactQualification.Speaking__c = String.valueOf(validationResponse.speakingScore);
        contactQualification.Reading__c = String.valueOf(validationResponse.readingScore);
        contactQualification.Other_Qualification_Comments__c = englishRequirement;
        contactQualification.Verification_Status__c = 'Score Verified';
        return contactQualification;
    }


    /**
     * Fetches the current custom setting record for English Verification.
     * @return Feature_Switch__c - Custom setting record with English_Verification__c field.
     */
    @AuraEnabled(Cacheable=true)
    public static Feature_Switch__c getEnglishVerificationCustomSetting() {
        return [SELECT English_Verification__c FROM Feature_Switch__c LIMIT 1];
    }

    /**
     * Method to retrieve a record from Contact_Qualification__c
     *
     * @param recordId The ID of the Contact_Qualification__c record to retrieve
     * @return A Contact_Qualification__c record with the selected fields
     * @throws AuraHandledException if the record is not found or an error occurs
     */
    @AuraEnabled(Cacheable=true)
    public static Contact_Qualification__c getContactQualificationById(Id recordId) {
        try {
            // Query the record with the specified fields
            Contact_Qualification__c qualification = [
                    SELECT Id, Qualification_Name__c, Verification_Status__c, Source_Channel__c, English_Test_Number__c,
                            Expected_date_of_completion__c, Qualification_Type__c
                    FROM Contact_Qualification__c
                    WHERE Id = :recordId
                    LIMIT 1
            ];
            return qualification;
        } catch (Exception e) {
            // Handle any errors gracefully
            throw new AuraHandledException('Unable to retrieve the record: ' + e.getMessage());
        }
    }

}