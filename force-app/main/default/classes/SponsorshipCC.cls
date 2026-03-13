/*******************************************************************************
* @author       Majid Reisi Dehkordi
* @date         25.April.2018      
* @description  
* @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
* @revision     Ken McGuire (2022-08-12): security uplift
*******************************************************************************/
public with sharing class SponsorshipCC {
	/*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         25.April.2018
    * @description  get the sponsorship question
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Map<String, Object> retrieveApplication(String appId) {
 		if (ExperienceAuthenticationServices.isUnsafe(appId)) return null;
        Map<String, Object> data = new Map<String, Object>();

        List<Application__c> applicationList = 	[	SELECT 	Id, Status__c, Name, Sponsor_Name__c, Proxy_Email_Address__c, Sponsor_Email_Address__c,
                Name_Of_Proxy__c,Proxy_Relationship_to_you__c,Sponsor_Scholarship_organisation__c, Sponsorship_Type__c
													FROM 	Application__c
													WHERE 	Id =: appId ];

		if (!applicationList.isEmpty()) {
            data.put('application', applicationList[0]);
		}

        List<Map<String,String>> options = new List<Map<String, String>>();

        Map<String, String> blankOption = MyApplicationUtilities.getPicklistOptionsMap('Sponsorship_Type__c', 'Application__c');

        for(String key : blankOption.keySet())
        {
            Map<String, String> mapOption = new Map<String, String>();
            mapOption.put('value', blankOption.get(key));
            mapOption.put('label', key);
            options.add(mapOption);
        }

        data.put('sponsor_pick', options);
        
		//will return new application if application Id is not found
		return data;
    }


    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         25.April.2018
    * @description  update the sponsorship question
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Application__c updateApplicationSponsor (Application__c application) {
        if (ExperienceAuthenticationServices.isUnsafe(application)) return application;
        switch on application.Sponsorship_Type__c {
            when 'Sponsorship' {
                application.Proxy_Email_Address__c = null;
            }	
            when 'Proxy' {
                application.Sponsor_Email_Address__c = null;            
            }
            when '' {
                application.Proxy_Email_Address__c = null;
                application.Sponsor_Email_Address__c = null;             
            }
            when else {
                application.Proxy_Email_Address__c = null;
                application.Sponsor_Email_Address__c = null;    
            
            }
        }
        update application;
		return application;
    }
}