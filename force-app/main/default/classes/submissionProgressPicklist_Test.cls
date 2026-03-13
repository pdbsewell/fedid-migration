@isTest(isParallel=true)
public class submissionProgressPicklist_Test {

    TestMethod
       static void test_getValues()
    {
        Test.startTest();
        
        submissionProgressPicklist objSPP = new submissionProgressPicklist();
        VisualEditor.DynamicPickListRows listResults = objSPP.getValues();
        
        Schema.DescribeFieldResult fieldResult = Application__c.Submission_Progress__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        System.assertEquals(ple.size(), listResults.size(), 'All values should be returned');
        Test.stopTest();   
    }
    
    TestMethod
        static void test_getDefaultValue()
    {
     
        Test.startTest();
        
        submissionProgressPicklist objSPP = new submissionProgressPicklist();
        VisualEditor.DataRow rowResult = objSPP.getDefaultValue();
        System.assertNotEquals(null, rowResult, 'default should be returned');
        Test.stopTest();   
    }
}