/**
 * @description     Service class for Conga_Bulk_Processing__c sObject
 * 
 * @author          K. Vegerano
 * @date            26/08/2020
 * 
 * @revision
 * 
 *      26/08/2020 - K Vegerano - created
 *      26/08/2020 - K Vegerano - added logic on before insert and before update to build the conga parameters field
 */
public with sharing class BulkPermitServices {

    /**
    * BuildCongaParameters
    */
    public class BuildCongaParameters extends TriggerAbstract {
        //Id variables
        private Map<String, Id> congaTemplateMap {get; set;}
        private Map<String, Id> emailTemplateMap {get; set;}
        private Map<String, Id> orgWideEmailAddressMap {get; set;}
        private Map<String, Bulk_Permits_Setting__mdt> bulkPermitSettingMap {
            get{
                //query bulk permit settings if the map is null
                if(bulkPermitSettingMap == null){
                    bulkPermitSettingMap = new Map<String, Bulk_Permits_Setting__mdt>();
                    for(Bulk_Permits_Setting__mdt loopBulkPermitSetting : [SELECT Id, Conga_Template__c, Email_BCC__c, Email_From__c, 
                                                                                  Email_Template__c, Permitted_Worker_Category__c, Permit_Type__c,
                                                                                  Subject_Content__c
                                                                           FROM Bulk_Permits_Setting__mdt]){
                        bulkPermitSettingMap.put(loopBulkPermitSetting.Permit_Type__c + ':::' + (loopBulkPermitSetting.Permitted_Worker_Category__c != null ? loopBulkPermitSetting.Permitted_Worker_Category__c : ''), loopBulkPermitSetting);
                    }
                }
                return bulkPermitSettingMap;
            } 
            set;
        }
        
        //retrieve the related conga template id from the conga template name
        private Id retrieveCongaTemplateId(String congaTemplateName){
            if(congaTemplateMap == null){
                //Collect possible conga templates
                Set<String> congaTemplateNames = new Set<String>();
                for(Bulk_Permits_Setting__mdt loopBulkPermitSetting : bulkPermitSettingMap.values()){
                    congaTemplateNames.add(loopBulkPermitSetting.Conga_Template__c);
                }
                //build conga templates
                congaTemplateMap = new Map<String, Id>();
                for(APXTConga4__Conga_Template__c loopCongaTemplates : [SELECT Id, APXTConga4__Name__c 
                                                                        FROM APXTConga4__Conga_Template__c 
                                                                        WHERE APXTConga4__Name__c IN :congaTemplateNames]){
                    congaTemplateMap.put(loopCongaTemplates.APXTConga4__Name__c, loopCongaTemplates.Id);
                }
            }

            return congaTemplateMap.get(congaTemplateName);
        }

        //retrieve the related email template id from the conga template name
        private Id retrieveEmailTemplateId(String emailTemplateName){
            if(emailTemplateMap == null){
                //Collect possible conga templates
                Set<String> emailTemplateNames = new Set<String>();
                for(Bulk_Permits_Setting__mdt loopBulkPermitSetting : bulkPermitSettingMap.values()){
                    emailTemplateNames.add(loopBulkPermitSetting.Email_Template__c);
                }
                //build conga templates
                emailTemplateMap = new Map<String, Id>();
                for(EmailTemplate loopEmailTemplates : [SELECT Id, DeveloperName 
                                                        FROM EmailTemplate 
                                                        WHERE DeveloperName IN :emailTemplateNames]){
                    emailTemplateMap.put(loopEmailTemplates.DeveloperName, loopEmailTemplates.Id);
                }
            }

            return emailTemplateMap.get(emailTemplateName);
        }

        //retrieve the related org wide email address id from the email address
        private Id retrieveOrgWideEmailAddressId(String orgWideAddress){
            if(orgWideEmailAddressMap == null){
                //Collect possible conga templates
                Set<String> emailFromAddresses = new Set<String>();
                for(Bulk_Permits_Setting__mdt loopBulkPermitSetting : bulkPermitSettingMap.values()){
                    emailFromAddresses.add(loopBulkPermitSetting.Email_From__c);
                }
                //build conga templates
                orgWideEmailAddressMap = new Map<String, Id>();
                for(OrgWideEmailAddress loopOrgWideEmailAddress : [SELECT Id, Address 
                                                                   FROM OrgWideEmailAddress 
                                                                   WHERE Address IN :emailFromAddresses]){
                    orgWideEmailAddressMap.put(loopOrgWideEmailAddress.Address, loopOrgWideEmailAddress.Id);
                }
            }

            return orgWideEmailAddressMap.get(orgWideAddress);
        }

        /**
        * Method is called on the Before insert / After insert event
        */
        public override void process(SObject record) {
            //Cast to specific object
            Conga_Bulk_Processing__c bulkPermit = (Conga_Bulk_Processing__c)record;

            //Defaulting field logic example
            if (bulkPermit.Status__c == 'Ready for Processing' && bulkPermit.Status__c != 'Permit Issued') {
                
                //Setup conga parameters
                setupCongaParameters(bulkPermit);

            }
        }

        /**
        * Method is called on the Before update / After update event
        */
        public override void process(SObject record, SObject oldRec) {
            //Cast to specific object
            Conga_Bulk_Processing__c bulkPermit = (Conga_Bulk_Processing__c)record;
            Conga_Bulk_Processing__c oldBulkPermit = (Conga_Bulk_Processing__c)oldRec;

            //Defaulting field logic example
            if (bulkPermit.Status__c == 'Ready for Processing' && bulkPermit.Status__c != 'Permit Issued') {
                
                //Setup conga parameters
                setupCongaParameters(bulkPermit);

            }
        }

        /**
        * Method that builds the required conga parameters
        */
        public void setupCongaParameters(Conga_Bulk_Processing__c contextBulkPermit){
            //Retrieve related bulk permit setting
            String permitSettingKey = contextBulkPermit.Permit_Type__c + ':::' + (contextBulkPermit.Permitted_Worker_Category__c != null ? contextBulkPermit.Permitted_Worker_Category__c : '');
            
            //Set dynamic details
            if(bulkPermitSettingMap.containsKey(permitSettingKey)){
                Bulk_Permits_Setting__mdt relevantPermitSetting = bulkPermitSettingMap.get(permitSettingKey);

                if(relevantPermitSetting != null){
                    contextBulkPermit.Conga_Template_Id__c = retrieveCongaTemplateId(relevantPermitSetting.Conga_Template__c);
                    contextBulkPermit.Email_Template_Id__c = retrieveEmailTemplateId(relevantPermitSetting.Email_Template__c);
                    contextBulkPermit.Email_From_Id__c = retrieveOrgWideEmailAddressId(relevantPermitSetting.Email_From__c);
                    contextBulkPermit.Subject_Content__c = relevantPermitSetting.Subject_Content__c;   
                    contextBulkPermit.Email_BCC__c = relevantPermitSetting.Email_BCC__c;
                }
            }
        }
    }
}