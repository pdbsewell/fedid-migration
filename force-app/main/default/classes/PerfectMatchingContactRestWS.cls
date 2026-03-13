/*******************************************************************************
 * @author       Shalini mendu
 * @date         02 Dec 2019
 * @group        Integration
 * @description  SFTN-364-CRM Applications from channels: Match Duplicate-Webservice exposed at CRM's end to handle duplicate Contacts matching the PerfectMatch rule
 *  2023-02-20   Ken McGuire   - Updated signature for get country services method
 *******************************************************************************/
@RestResource(urlMapping='/v1/PerfectMatchingContactRestWS/*')
global class PerfectMatchingContactRestWS {
    /**
   * @author Shalini mendu
   * @description Used to handle duplicate Contacts matching PerfectMatch duplicate rule
   * @date  02 Dec 2019
   * @param
   * @return PerfectMatchingContactPayload.PerfectDuplicateContactPayloadResponse
   */
    @HttpPost
    global static PerfectMatchingContactPayload.PerfectMatchingContactPayloadResponse handleMatchingContacts() {
        PerfectMatchingContactPayload.PerfectMatchingContactPayloadResponse resp = new PerfectMatchingContactPayload.PerfectMatchingContactPayloadResponse();
        PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest req ;
        RestRequest request = RestContext.request;
        
        try {
            req = (PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest) JSON.deserialize(request.requestBody.toString(), PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest.class);
            Boolean prevStudInd = false;
            if(req.previousStudentIndicator!=null) { prevStudInd = Boolean.valueOf(req.previousStudentIndicator);}

            // Align the mailing country to an ISO value if possible
            String tmpCountry = CountryServices.getCountryName(req.mailingCountry,CountryServices.FORMAT_ISO);
            if (String.isEmpty(tmpCountry)) {tmpCountry =req.mailingCountry;}

            // Ensure the formatting of the birthdat_dup field matches the result of the logic applied in the b4 trigger
            // There is otherwise a risk of not including leading 0's, depending on the format of the data supplied.
			String tmpBDate;
            if (String.isNotEmpty(req.birthDate)) {
                Datetime bDate = Date.valueOf(req.birthDate); // implicit cast
                tmpBDate = bDate.format('yyyyMMdd');
            }
            

            // Don't copy the same phone values into different fields. This allows roll-up to give priority to Mobile. 
            // Same logic is applied in channel import.
            String phone = req.phone;
            String homePhone = req.homephone;
            if (phoneServices.compareNumbers(req.homephone,req.mobilePhone)) {
	            homePhone = ''; // If the home phone is the same as the mobile, don't add it to the field
            }           
            if (phoneServices.compareNumbers(req.phone,req.Homephone) || phoneServices.compareNumbers(req.phone,req.mobilePhone)) {
                // Nothing should write to the phone field directly as it is rolled-up too, but if it is different from the other phones numbers supplied, it will be honoured.
                phone = ''; 
            }           
            
            Id conId = new PerfectMatchingContactFinder(new Contact(FirstName = req.firstName,
                                                                    first_name__c = req.firstName,
                                                                    LastName = req.lastName,
                                                                    Birthdate =  String.isBlank(req.birthDate)?null:Date.valueOf(req.birthDate),
                                                                    Birthdate_Dup__c = tmpBDate, // yyyyMMdd format
                                                                    MobilePhone = req.mobilePhone,
                                                                    MobilePhone_dup__c = String.isBlank(req.MobilePhone)?'':phoneservices.rawFormatPhone(req.mobilePhone),                  
                                                                    SourceId__c = req.sourceId,
                                                                    Salutation = req.salutation,
                                                                    Gender__c = req.gender,
                                                                    Previous_Monash_ID__c = req.previousMonashId,
                                                                    Previously_Studied_at_Monash__c = prevStudInd,
                                                                    MailingStreet = req.mailingStreet,
                                                                    MailingCity = req.mailingCity,
                                                                    MailingState = req.mailingState,
                                                                    MailingCountry = tmpCountry,
                                                                    MailingPostalCode = req.mailingPostalCode,
                                                                    HomePhone = homePhone, // should be different from mobile
                                                                    Phone = phone, // should be different from mobile and home phones
                                                                    Residency_Status__c = req.residencyStatus,
                                                                    HasDisabilities__c = String.valueOf(req.hasDisabilities),
                                                                    Personal_Email__c = req.email,
                                                                    //Email = req.email, // Allow Rollup to populate the primary email field. Only personal email is provided from the API
                                                                    Preferred_Name__c = req.preferredName,
                                                                    Country_Of_Birth__c = req.countryOfBirth , // TODO when admissions fix this field, use the countryservices get SACC  functionality
                                                                    CountryOfBirth__c = CountryServices.getCountryId(req.countryOfBirth,CountryServices.FORMAT_SAAC),
                                                                    Pronouns_v2__c  = req.pronouns,
                                                                    Previous_Surname__c = req.previousName,
                                                                    Account_Record_Type_Name__c = 'Household_Account'
                                                                   )).handleMatchingContacts();
            
            if(conId !=null) {
                resp.contactId = conId;
                resp.status = 'Success';
                resp.error = null;
            }
        } catch (Exception ee) {
            ExLog.add('PerfectMatchContactRestWS', 'PerfectMatchContact Rest WebService', 'PerfectMatchContactRestWS.postMessage', ee, 'Contact failed with: FirstName:'+req.firstName+' LastName:'+req.lastName+' Email:'+req.email);
            resp.contactId = null;
            resp.status = 'Error';
            resp.error = 'PerfectMatchContactRestWS exception:'+ee.getMessage()+' at line number:'+ ee.getLineNumber();
        }
        return resp;
    }
}