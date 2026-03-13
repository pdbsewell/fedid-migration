/*******************************************************************************
* @author       Ant Custodio
* @date         19.June.2017         
* @description  Controller class for appCreditIntention lightning component
* @revision     Stefan Scheit (2018-09-15): Removed filter on contact.id (inferred from sharing set)
				Suman Gunaganti(2018-12-20) Commented out reference to online credit components
*******************************************************************************/
public with sharing class appCreditIntentionCC {

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         19.June.2017         
    * @description  retrieves the application record using the given ID
    * @revision     
    *******************************************************************************/
    @AuraEnabled
	public static Application__c retrieveApplicationById (String appIdParam) {
		Application__c applicationRecord = [SELECT 	Id, Applying_for_Credit__c,
													Applicant__c,
													Applicant__r.Online_Credit_Applicant_URL__c
											FROM 	Application__c
											WHERE 	Id =: appIdParam];
		return applicationRecord;
	}

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         20.June.2017         
    * @description  updates the application record given
    * @revision     
    *******************************************************************************/
    @AuraEnabled
	public static Application__c updateApplication (Application__c appRecord) {

		try {
			update appRecord;
		} catch (Exception ex) {
			throw new AuraHandledException('Unable to update your details: ' + ex.getMessage());
		}

		return appRecord;
	}
	
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         22.Feb.2017
    * @description  Calls the OnlineCreditService class to help generate the Staff
    *					and Student URLs on the Contact record
    * @revision     
    *******************************************************************************/
    /*@AuraEnabled
	public static Contact retrieveOnlineCreditURL (String contactId) {
		Contact contactRec;
		//check if not empty
		if (!String.isBlank(contactId)) {
			//call the API to generate Staff and Student links for Online Credit
			//then save the links into the Contact record
			contactRec = OnlineCreditService.submitRequestByContactId(contactId);
		}
		return contactRec;
	}*/
}