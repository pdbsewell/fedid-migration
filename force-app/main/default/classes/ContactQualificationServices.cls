/*******************************************************************************
* @author		Sethu Venna
* @date         17/03/2025 
* @description  Services class for Contact Qualification Object
* @revision     17/03/2025  - Initial Version
*******************************************************************************/
public with sharing class ContactQualificationServices {


    public static final Set<String> FIELD_NAMES_TO_TRIGGER_ATAR_CALLOUT = new Set<String>{
        'Qualification__c',
        'Year_of_Completion__c',
        'Verification_Status__c',
        'Institution_Code__c',
        'Institution_Name__c',
        'Other_Institution__c',
        'Score__c',
        'isTestCompleted__c',
        'Qualification_Country__c',
        'State__c',
        'Retry_API_Callout__c'
    };

    public static final Id SECONDARY_EDU_RECORD_TYPE_ID = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Secondary Education').getRecordTypeId();
    
    /*******************************************************************************
    * @author       Sethu Venna
    * @date         17/03/2025
    * @description  execute a callout to ATAR when conditions met
    * @revision     17/03/2025 - Initial Version
    *******************************************************************************/
    public class ATARCalloutFromTrigger implements Triggers.Handler {
        /*******************************************************************************
        * @author       Sethu Venna
        * @date         17/03/2025
        * @description  override run() method
        * @revision     17/03/2025 - Initial Version
        *******************************************************************************/
        public void run()
        {   
            List<Id> countryAustraliaIdList = new List<Id>();
            for(Country_Attribute__c ca : new CountriesSelector(true).selectByName(new Set<String>{'AUSTRALIA'})) {
                countryAustraliaIdList.add(ca.Id);
            }
            Set<Contact_Qualification__c> contactQualificationSet = new Set<Contact_Qualification__c>();
            Map<Id,Contact_Qualification__c> oldTriggerMap = (Map<Id,Contact_Qualification__c>)Trigger.oldMap;
            for(Contact_Qualification__c contactQualificationRec : (List<Contact_Qualification__c>)Trigger.new)
            {
                
                if( contactQualificationRec.RecordTypeId == SECONDARY_EDU_RECORD_TYPE_ID && 
                    contactQualificationRec.Qualification__c != null && 
                    countryAustraliaIdList.contains(contactQualificationRec.Qualification_Country__c)
                ){
                    if(Trigger.isInsert) {
                        contactQualificationSet.add(contactQualificationRec);
                    }
                    else {
                        for(String fieldAPIName : FIELD_NAMES_TO_TRIGGER_ATAR_CALLOUT) 
                        {
                            if(contactQualificationRec.get(fieldAPIName) != oldTriggerMap.get(contactQualificationRec.Id).get(fieldAPIName)) {
                                contactQualificationSet.add(contactQualificationRec);
                                break;
                            }
                        }
                    }
                }
                
            }
            if(contactQualificationSet.size() > 0) {
                System.enqueueJob(
                    new ATARIntegrationQueuable(contactQualificationSet)
                );
            }
        }
    }
}