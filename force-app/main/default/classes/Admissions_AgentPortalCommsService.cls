/***********************************************************************
** Author: Ryan Wilson (OAKTON)
** Created Date: 13.AUG.2017
** Description: REST API service for Agent Portal comms
** History: Ant Custodio, 23.Aug.2017 - made callista Person Id not required
***********************************************************************/
@RestResource(urlMapping='/v1/APComms/*')
global without sharing class Admissions_AgentPortalCommsService {
	//global method for Agent portal messaging

	@HttpPost
	global static ObdAgentPortalCommsResponse postMessage(ObdAgentPortalCommsRequest.CommsWrapper apMessage) {
		ObdAgentPortalCommsResponse apiResponse = new ObdAgentPortalCommsResponse();

		try{
			if(isNotNullOrEmpty(apMessage.enquiryRecordId)){
				apiResponse = createChatterPost(apMessage);
				
			} else{
				apiResponse = createNewEnquiry(apMessage);
			}

		} catch(Exception ex){
			apiResponse.status = 'Error';
			apiResponse.error = ex.getMessage();
			apiResponse.enquiryRecordId = null;
		}

		return apiResponse;
	}

	private static ObdAgentPortalCommsResponse createNewEnquiry(ObdAgentPortalCommsRequest.CommsWrapper apMessage) {
		ObdAgentPortalCommsResponse apiResponse = new ObdAgentPortalCommsResponse();
		//to do, search for contact and create Enquiry record
		if(isNotNullOrEmpty(apMessage.messageSubject) && 
			isNotNullOrEmpty(apMessage.messageBody) && 
			isNotNullOrEmpty(apMessage.category) && 
			isNotNullOrEmpty(apMessage.subCategory)){

			Case caseForInsert = new Case();
			
			//search for contact if callistaPersonId has a value
			if (isNotNullOrEmpty(apMessage.callistaPersonId)) {
				List<Contact> studContact = new List<Contact>([	SELECT 	Id, Person_ID_unique__c 
																FROM 	Contact 
																WHERE 	Person_ID_unique__c =:apMessage.callistaPersonId
																LIMIT 	1 ]);
				if(!studContact.isEmpty()){
					caseForInsert.ContactId = studContact[0].Id;
				}
			}
			
			Map<String, String> apCategoryMap = new Map<String, String>();
			for (AP_Category_Code_Map__mdt categCode: [SELECT Id, Label,DeveloperName FROM AP_Category_Code_Map__mdt]) {
				apCategoryMap.put(categCode.DeveloperName.toLowerCase(), categCode.Label);
			}
			//Enquiry creation
			caseForInsert.Origin = 'Web - Agent Portal';
			caseForInsert.Subject = apMessage.messageSubject;
			caseForInsert.Description = apMessage.messageBody + '\n\nApplicant Id: ' + apMessage.applicantId;

			if (apCategoryMap.containsKey(apMessage.category.toLowerCase())) {
				caseForInsert.Category_Level_1__c = apCategoryMap.get(apMessage.category.toLowerCase());
			}

			if (apCategoryMap.containsKey(apMessage.subCategory.toLowerCase())) {
				caseForInsert.Category_Level_2__c = apCategoryMap.get(apMessage.subCategory.toLowerCase());
			}

			caseForInsert.RecordTypeId = CommonServices.recordTypeId('Case', 'Admissions');
			caseForInsert.SuppliedCompany = apMessage.agencyName;
			caseForInsert.SuppliedName = apMessage.staffName;
			caseForInsert.SuppliedPhone = apMessage.phoneNumber;
			insert caseForInsert;

			//build success response
			apiResponse.status = 'Success';
			apiResponse.error = '';
			apiResponse.enquiryRecordId = caseForInsert.Id;

		} else{
			apiResponse.status = 'Error';
			apiResponse.error = 'Required fields missing.';
			apiResponse.enquiryRecordId = null;
		}

		return apiResponse;
	}

	private static ObdAgentPortalCommsResponse createChatterPost(ObdAgentPortalCommsRequest.CommsWrapper apMessage) {
		Id enquiryId = apMessage.enquiryRecordId;
		//to do, post a chatter message against the enquiry
		ObdAgentPortalCommsResponse apiResponse = new ObdAgentPortalCommsResponse();

		try{
			FeedItem newEnquiryFeed = new FeedItem();
			newEnquiryFeed.ParentId = apMessage.enquiryRecordId;
			newEnquiryFeed.Title = apMessage.messageSubject;
			newEnquiryFeed.Body = apMessage.messageBody;
			newEnquiryFeed.Visibility = 'AllUsers';
			//newEnquiryFeed.IsRichText = true;
			insert newEnquiryFeed;

			//build success response
			apiResponse.status = 'Success';
			apiResponse.error = '';
			apiResponse.enquiryRecordId = enquiryId;
		}
		catch(Exception ex){
			apiResponse.status = 'Error';
			apiResponse.error = ex.getMessage();
			apiResponse.enquiryRecordId = enquiryId;
		}
		
		return apiResponse;
	}

	global static Boolean isNotNullOrEmpty(string str)
    {
        return str!=null && !String.isBlank(str); 
    }
}