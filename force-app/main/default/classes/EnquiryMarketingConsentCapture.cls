/**
 * @author       : Ibrahim Rumi
 * @date         : 14-04-2022
 * @group        : consent management
 * @description  : Class to Create Monash Info and events Subscription Members from enquiries
**/
public with sharing class EnquiryMarketingConsentCapture{

	@InvocableMethod(label='Create Monash Info and events Subscription Members' description='Creates a marketing subscription to monash info and events Campaign')
	public static void createMIECampaignMember(List<Case> caseRecs) {
        
        try {
            Map<Id, String> conWithSource = new Map<Id, String>();

            if(caseRecs!=null){
                
                for(Case enquiry: caseRecs){
                    if(enquiry.ContactId != null){
                        String caseNumber = 'Case: '+enquiry?.CaseNumber;
                        conWithSource.put(enquiry.contactId, caseNumber);
                    }
                }

                //get monash info and events from custom setting
                Marketing_Subscription_List__c listSetting = Marketing_Subscription_List__c.getOrgDefaults();
                Id mie = (Id) listSetting.MIE__c;
                
                //dispatch event to create campaign members asynchronously
                CampaignSubscriptionService service = new CampaignSubscriptionService(new Set<Id> { mie });
                service.setMembersWithSource(conWithSource);
                service.runAsync();
                service.execute();
            }
        }
        catch(Exception e) {
            LogUtilityException.logException(e);
            System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
        } finally {
            LogUtilityException.getLimits();
        }
    }
}