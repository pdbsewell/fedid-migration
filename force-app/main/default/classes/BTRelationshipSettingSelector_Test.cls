/**
 * @author Ibrahim Rumi
 * @date 19-10-2020
 * @group Event Management
 * @description Test class for BTRelationshipSettingSelector.
 **/
@IsTest(isParallel=true)
private class BTRelationshipSettingSelector_Test {
	/**
     * @author Ibrahim Rumi
     * @description exception testing of the method getDefaultRelationshipSetting
     **/
    @isTest
    static void getDefaultRelationshipSettingExceptionTest() {
    	BTRelationshipSettingSelector Selector = new BTRelationshipSettingSelector();
        
        bt_stripe__Relationship_Settings__c relationshipSetting = Selector.getDefaultRelationshipSetting();
        
        system.assertEquals(null, relationshipSetting.id, 'relationship setting not available');
    }
    
    @isTest
    static void getDefaultRelationshipSettingTest() {
    //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
        relSetting.bt_stripe__Default__c = true;
        insert relSetting;
        
        BTRelationshipSettingSelector Selector = new BTRelationshipSettingSelector();
        
        bt_stripe__Relationship_Settings__c relationshipSetting = Selector.getDefaultRelationshipSetting();
        
        system.assertNotEquals(null, relationshipSetting.id, 'default relationship setting available');
    }
}