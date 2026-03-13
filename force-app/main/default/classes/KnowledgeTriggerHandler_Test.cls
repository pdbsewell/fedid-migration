/**
 * @Class              : KnowledgeTriggerHandler_Test.cls
 * @Description        : Trigger class for handling Knowledge Articles 
 * @Author             : Inderpal Dhanoa
 * @Group              : Monash COnnect
 * @Revision           : 2024-05-14     Inderpal Dhanoa   Created 
 */
@isTest(isParallel=true)
public class KnowledgeTriggerHandler_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         14/05/2024
    * @description  Test Method for MapDataCategories. 
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void MapDataCategoriesTest(){   
        
        //GIVEN: If the mapping record type exists 
        Id mc_recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Knowledge_Article__kav' AND DeveloperName = 'Monash_Connect' LIMIT 1].Id;
        
        // WHEN: An Article is created 
        Test.startTest();
        Knowledge_Article__kav testKnowledgeArticle = (Knowledge_Article__kav)TestDataFactory.createSObject(new Knowledge_Article__kav(Title = 'Test Title', 
        UrlName = 'TestURL', Language = 'en_US', recordTypeId = mc_recordTypeId), true);
        Test.stopTest();

        //THEN: The Data Catg mapping is created
        Knowledge_Article__DataCategorySelection mapping = [SELECT Id,DataCategoryName 
                                                            FROM Knowledge_Article__DataCategorySelection 
                                                            WHERE ParentId = :testKnowledgeArticle.Id];
        Assert.areEqual(mapping.DataCategoryName, 'Monash_Connect', 'Category not mapped');
    }
}