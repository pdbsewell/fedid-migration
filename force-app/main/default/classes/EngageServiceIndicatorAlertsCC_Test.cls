/**
 * @author          James Seto - UC Innovation
 * @description     For testing the EngageServiceIndicatorAlertsCC Simply grabs custom metadata types from the controller.
 * 
 * @revision        07/10/2019 - James Seto - Initial version
 * @revision        07/10/2019 - Mark Johnson - Add assert, clean up.
 * @revision        07/10/2024 - PENGAGE-2758 Bequestor functionality
 */

@isTest(isParallel=true)
public class EngageServiceIndicatorAlertsCC_Test {
    @TestSetup
    static void setup(){
        // Create a Content Document link based on the title present in the Custom metaData icon
        String iconTitle = [SELECT Icon__c FROM Engage_Service_Indicator_Alerts__mdt WHERE SObject_Name__c = 'Contact' AND Type__c = 'ContentAsset' LIMIT 1].Icon__c;
        ContentVersion cv1 = (ContentVersion)TestDataFactory.createSObject(new ContentVersion(Title = iconTitle, PathOnClient = 'TestDocument1.txt', 
                                                                                                      VersionData = Blob.valueOf('Test Document 1')), true);

        ContentDocumentLink cdl1 = new ContentDocumentLink(ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id LIMIT 1].ContentDocumentId,
                                                                                                        LinkedEntityId = cv1.Id,
                                                                                                        ShareType = 'V'
                                                                                                    );
    }
    @IsTest
    static void run_simple_test()
    {   
        Contact c = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert c;
        
        List<Contact> contacts = [Select Id from Contact];
        List<Engage_Service_Indicator_Alerts__mdt> serviceIndicatorAlertCustomMetadata = [  SELECT  Field_API_Name__c, 
                                                                                                    Label, 
                                                                                                    Text_Background_Color__c, 
                                                                                                    Icon_Variant__c, 
                                                                                                    Icon__c, 
                                                                                                    Type__c, 
                                                                                                    SObject_Name__c 
                                                                                            FROM Engage_Service_Indicator_Alerts__mdt 
                                                                                            WHERE SObject_Name__c =: 'Contact'];
        // GIVEN: MetaData entries exists
        test.startTest();

        //WHEN: the method is invoked
        String metadataItemsSerialized = EngageServiceIndicatorAlertsCC.getCustomMetadataItems(contacts[0].Id);

        test.stopTest();
        //THEN: The Content Asset is mapped with the ContentDoc Id 
        System.assertEquals(serviceIndicatorAlertCustomMetadata.isEmpty(), String.isBlank(metadataItemsSerialized), 'If there are service indicator alerts associated with contact they should have been retrieved by this function');
        
        List<EngageServiceIndicatorAlertsCC.AlertIndicatorWrapper> selectedClauses = (List<EngageServiceIndicatorAlertsCC.AlertIndicatorWrapper>) JSON.deserialize(metadataItemsSerialized, List<EngageServiceIndicatorAlertsCC.AlertIndicatorWrapper>.class);

        for(EngageServiceIndicatorAlertsCC.AlertIndicatorWrapper obj : selectedClauses){
            if(obj.type == 'ContentAsset'){
                Assert.isNotNull(obj.imageURL, 'Invalid Content Asset Name');
            }
        }
    }     
    
}