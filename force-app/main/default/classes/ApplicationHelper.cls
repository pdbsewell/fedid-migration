/**
 * @author      Kristian Vegerano
 * @description Helper class for application related processes
 * @revision    17/05/2019 - Kristian Vegerano - Created
 */
public with sharing class ApplicationHelper extends BaseClass {
    
    public ApplicationHelper() {
        super(new List<Schema.sObjectType> {
            Application__c.sObjectType,
            Document_Checklist__c.sObjectType
        });
    }

    /**
     * @author      Kristian Vegerano
     * @description Update application's submission location country
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public void executeUpdateSubmissionLocationCountry(Map<Id, Application__c> applicationMap) {
        try{
            //Retrieve records reference map - for details additional to the trigger context
            Map<Id, Application__c> applicationsReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector().selectByIdWithParentDetailsAndFinalACPs(applicationMap.keySet()));
            
            //Retrieve Callista Codes considered as direct agency
            Set<String> directApplicationCodeSet = new Set<String>();
            for(Direct_Application__mdt loopDirectCode : [SELECT Label FROM Direct_Application__mdt]){
                directApplicationCodeSet.add(loopDirectCode.Label);
            }
            
            //Collect country addresses
            Set<String> countriesSet = new Set<String>();
            for(Application__c loopApplication : applicationMap.values()){
                Application__c referenceApplication = applicationsReferenceMap.get(loopApplication.Id);

                //Check and add agent's shipping country
                if(referenceApplication.Agent__c != null){
                    if(referenceApplication.Agent__r.ShippingCountry != null){
                        countriesSet.add(referenceApplication.Agent__r.ShippingCountry);
                    }
                }
                //Check and add applicant's mailing country
                if(referenceApplication.Applicant__c != null){
                    if(referenceApplication.Applicant__r.MailingCountry != null){
                        countriesSet.add(referenceApplication.Applicant__r.MailingCountry);  
                    } 
                }
            }
        
            //Process records
            for(Application__c loopApplication : applicationMap.values()){
                Application__c referenceApplication = applicationsReferenceMap.get(loopApplication.Id);
                
                //Initialize Flags
                Boolean isSentForSubmission = false;
                Boolean hasFinalAcp = false;
                Boolean isAgencyApplication = false;
                Boolean isNonAgencyApplication = false;
                
                //Check if application status is "Sent for Submission"
                if(referenceApplication.Status__c != null){
                    if(referenceApplication.Status__c.equalsIgnoreCase(Label.ApplicationStatus_Sent_for_Submission)){
                        isSentForSubmission = true;
                    }
                }
                
                //Check if has ACP with Outcome Status of either 'COND-OFFER','OFFER','REJECTED'
                if(referenceApplication.Application_Course_Preferences__r != null){
                    if(!referenceApplication.Application_Course_Preferences__r.isEmpty()){
                        hasFinalAcp = true;
                    }
                }
                
                //Check if the application is via Agency
                if(referenceApplication.Agent__c != null){
                    if(!directApplicationCodeSet.contains(referenceApplication.Agent__r.Callista_Org_Unit_Code__c)){
                        isAgencyApplication = true;
                    }
                }
                
                //Check if the application is via Direct Agency
                //Check if the application is via Applicant
                if(!isAgencyApplication){
                    if(referenceApplication.Applicant__c != null){
                        isNonAgencyApplication = true;
                    }
                }
                
                //Update Application's Submission_Location_Country__c
                if(isSentForSubmission && !hasFinalAcp && isAgencyApplication){
                    //Check if the agency's shipping country exist
                    if(referenceApplication.Agent__r.ShippingCountry != null){
                            push(new Application__c(Id = loopApplication.Id,
                                                    Submission_Location_Country__c = CountryServices.getCountry(referenceApplication.Agent__r.ShippingCountry).Id));
                        }
                }else if(isSentForSubmission && !hasFinalAcp && isNonAgencyApplication){
                    //Check if the applicant's mailing country exist
                    if(referenceApplication.Applicant__r.MailingCountry != null){
                            push(new Application__c(Id = loopApplication.Id,
                                                    Submission_Location_Country__c = CountryServices.getCountry(referenceApplication.Applicant__r.MailingCountry).Id));
                    }
                }
            }
                
            //Commit records to database
            commitRecords();
        }catch (Exception ex){
            ExLog.add('ApplicationHelper','Application','executeUpdateSubmissionLocationCountry', ex);
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Generate checklist item when application records
     * @revision    13/08/2019 - Kristian Vegerano - Created
     */
    public void applicationGenerateChecklistItems(Map<Id, Application__c> applicationMap) {
        try{
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(applicationMap.keySet());
            rulesDocChecklistEngine.evaluateRules('Application Assessment');

            //Commit records
            for(Id applicationId : applicationMap.keySet()){                
                for(Document_Checklist__c loopChecklist : rulesDocChecklistEngine.resultChecklistItemsMap.get(applicationId).values()){
                    push(loopChecklist);
                }
            }
                
            //Commit records to database
            commitRecords();
        }catch (Exception ex){
            ExLog.add('ApplicationHelper','Application','applicationGenerateChecklistItems', ex);
        }
    }
}