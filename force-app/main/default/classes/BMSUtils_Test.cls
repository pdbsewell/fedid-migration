/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class BMSUtils_Test {
	@testSetup
	static void setup() {
        // Campaign
        List<Campaign> campaigns = new List<Campaign>();
        
        Campaign campaignOne = new Campaign();
        campaignOne.Name = 'Name';
        campaigns.add(campaignOne);
        
        insert campaigns;
	}
    
    static testMethod void testErrorFreeExecution() {
        Campaign c = [SELECT
                      Id,
                      Name,
                      Type,
                      Owner_Name__c,
                      Status,
                      Batch_Finished__c,
                      Total_Members__c,
                      CreatedDate
                      FROM Campaign
                      LIMIT 1];
        
        Test.startTest();
        
        BMSUtils bmsUtilsInstance = new BMSUtils();
        
        System.debug(BMSUtils.campaignStatusList);
        System.debug(BMSUtils.campaignTypeList);
        
        BMSUtils.getFilterFieldOptionWrapper();
        BMSUtils.getAllStaffOptionWrapper();
        BMSUtils.getUOfferingOptionWrapper();
        BMSUtils.getEmailOptions();
        BMSUtils.getCohortOptions();
        
        BMSUtils.TableDataWrapper tableDataWrapperInstance = new BMSUtils.TableDataWrapper(c);
        
        BMSUtils.FilterWrapper filterWrapperInstance = new BMSUtils.FilterWrapper();
        System.debug(filterWrapperInstance.cohort);
        System.debug(filterWrapperInstance.isIncludeInactive);
        System.debug(filterWrapperInstance.filters);
        System.debug(filterWrapperInstance.filterLogic);
        
        BMSUtils.FilterRowWrapper filterRowWrapperInstance = new BMSUtils.FilterRowWrapper();
        System.debug(filterRowWrapperInstance.field);
        System.debug(filterRowWrapperInstance.criteria);
        System.debug(filterRowWrapperInstance.value);
        
        BMSUtils.NewEmailSaveWrapper newEmailSaveWrapperInstance = new BMSUtils.NewEmailSaveWrapper();
        System.debug(newEmailSaveWrapperInstance.audienceType);
        System.debug(newEmailSaveWrapperInstance.fileUpload);
        System.debug(newEmailSaveWrapperInstance.fileName);
        System.debug(newEmailSaveWrapperInstance.attachmentContent);
        System.debug(newEmailSaveWrapperInstance.finalQueryString);
        System.debug(newEmailSaveWrapperInstance.massEmailRecord);
        
        BMSUtils.BuildPreviewEmailWrapper buildPreviewEmailWrapperInstance = new BMSUtils.BuildPreviewEmailWrapper();
        System.debug(buildPreviewEmailWrapperInstance.emailTemplate);
        System.debug(buildPreviewEmailWrapperInstance.name);
        System.debug(buildPreviewEmailWrapperInstance.messageHeader);
        System.debug(buildPreviewEmailWrapperInstance.customMessage);
        System.debug(buildPreviewEmailWrapperInstance.isAddCricos);
        System.debug(buildPreviewEmailWrapperInstance.isAddBaseSignature);
        
        Test.stopTest();
    }
}