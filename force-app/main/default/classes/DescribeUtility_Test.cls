@isTest(isParallel=true)
private class DescribeUtility_Test {

    /*
     * Tests describing object's child relationships - useful for composing dynamic sub-selects  
     */
	@isTest 
	static void testGetChildRelationshipMap() {
        //SObject to describe relationships
        String sObjectTypeName = 'Account';
        
        //Execute test
        Test.startTest();
            //Describe Standard Object Account
            Map<String, Map<String, String>> testDescribedRelationships = DescribeUtility.getChildRelationshipMap(sObjectTypeName);
        Test.stopTest();
        
        //Check that the utility retrieved more than one Account's child relationship
        System.assert(testDescribedRelationships.size() > 0);
        
        //Check Account's relationship to contact is present - Contact's AccountId field is a lookup to the Account Object
        System.assertEquals('Contacts', testDescribedRelationships.get('Contact').get('AccountId'));
    }
    
    /*
     * Tests describing object's field's data type
     */
	@isTest 
	static void testGetFieldDataType() {
        //SObject to describe
        String sObjectTypeName = 'Account';
        //SObject field to describe
        String sObjectFieldName = 'CreatedDate';
        
        //Execute test
        Test.startTest();
            //Describe Standard Object Account's CreatedDate field
            Schema.DisplayType fieldType = DescribeUtility.getFieldDataType(sObjectTypeName, sObjectFieldName);
        Test.stopTest();
        
        //Check that the describe correctly returned the field's data type
        System.assert(fieldType == Schema.DisplayType.DATETIME);
    }

}