/**
 * @File Name          : FindPerfectMatchContactWebService.cls
 * @Description        : Webservice class for finding a perfect match contact from the payload
 * @Author             : Kristian Vegerano
 * @Group              : Admissions
 * @Revision           : OCT.14.2021     Kristian Vegerano   Created class
 *                     : 2022-03-18   Martin C - Added legal first name (First_Name__c) to the virtual contact record
 *                     : 2022-07-05   Martin C - Added Mobile Dup to the virtual contact record
 *                     : 2022-08-24   Martin C - Apply formatting to the inbound mobile number for matching purposes
 *                                               Return the lastest updated contact if multiple perfect matches are found
 *                     : 2023-08-09   Vinothraja - Changed to without sharing mode to accomodate APNG users (Portal users with limited access to only their contacts)
 *                                               verify whether their Applicant already exists in Monash database
 * 
 */
@RestResource(urlMapping='/FindPerfectMatchContactWebService')
global without sharing class FindPerfectMatchContactWebService {

    /**
	 * @description     finds perfect matching contacts and returns relevant ids
	 * @param           JSON that can be serialized into PerfectMatchingContactPayload.FindPerfectMatchContactRequest object
	 * @return          JSON that follows PerfectMatchingContactPayload.FindPerfectMatchContactResponse object
	 */
    @HttpPost
    global static PerfectMatchingContactPayload.FindPerfectMatchContactResponse handleMatchingContacts() {
        //Initialize variables
        Integer firstRecord = 0;
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest requestWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        PerfectMatchingContactPayload.FindPerfectMatchContactResponse responseWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactResponse();

        RestRequest request = RestContext.request;
       
        try {
            //deserialize request
            requestWrapper = (PerfectMatchingContactPayload.FindPerfectMatchContactRequest) JSON.deserialize(request.requestBody.toString(), 
                                                                                                             PerfectMatchingContactPayload.FindPerfectMatchContactRequest.class);

            // Treat the Birthdate_Dup__c field in the same way it is on the contact
            String tmpBDate;
            if (String.isNotEmpty(requestWrapper.birthDate)) {
                Datetime bDate = Date.valueOf(requestWrapper.birthDate); // implicit cast
                tmpBDate = bDate.format('yyyyMMdd');
            }
            
            //execute contact finding logic
            PerfectMatchingContactFinder perfectMatchFinder = new PerfectMatchingContactFinder(new Contact(FirstName = requestWrapper.firstName,
                                                                                                           First_Name__c = requestWrapper.firstName,
                                                                                                           LastName = requestWrapper.lastName,
                                                                                                           Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                                                                                           Birthdate_Dup__c = tmpBDate,
                                                                                                           MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                                                                                           MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?phoneservices.rawFormatPhone(requestWrapper.mobilePhone):null,
                                                                                                           Email = requestWrapper.email, 
                                                                                                           Personal_Email__c = requestWrapper.email,
                                                                                                           Previous_Monash_Id__c = requestWrapper.previousMonashId, 
                                                                                                           Account_Record_Type_Name__c = 'Household_Account'));
            List<Contact> matchedContacts = perfectMatchFinder.findMatchingContacts();
            
            //return a result if there is only a single matching contact
            if(matchedContacts.size() > 0) {
                //handle single contact matches
                
                //include contact ids
                Contact matchingContact = perfectMatchFinder.getLatestContactByLastModifiedDate();
                responseWrapper.status = 'Success';
                responseWrapper.personId = matchingContact.Person_ID_unique__c;
                responseWrapper.unicrmContactId = matchingContact.Id;
                responseWrapper.crmId = matchingContact.CRM_Id__c;

                // Multiple perfect match results is still a perfect match. Report the fact but the first contact has been selected.
				if(matchedContacts.size() > 1){
                	//handle multiple contact matches
                	responseWrapper.warningMessage = PerfectMatchingContactPayload.MULTIPLE_MATCH;                
                }

                //include callista applicant id
                Application__c matchingContactApplication = perfectMatchFinder.retrieveResultApplicationDetails();
                if(matchingContactApplication != null){
                    responseWrapper.applicantId = matchingContactApplication.Callista_Applicant_Id__c;
                }
            }else if(matchedContacts.isEmpty() || matchedContacts == null) {
                //handle no contact matches
                responseWrapper.status = 'Success';
                responseWrapper.warningMessage = PerfectMatchingContactPayload.NO_MATCH;
            }
        } catch (Exception ex) {
            ExLog.add('FindPerfectMatchContactWebService', 'PerfectMatchContact Rest WebService', 'FindPerfectMatchContactWebService.handleMatchingContacts', ex, 
                      'Contact failed with: FirstName: ' + requestWrapper.firstName + ' LastName: ' + requestWrapper.lastName + ' Email: ' + requestWrapper.email);
            responseWrapper.status = 'Error';
            responseWrapper.errorMessage = 'Internal Error Occured - ' + ex.getMessage();
        }
        return responseWrapper;
    }
 }