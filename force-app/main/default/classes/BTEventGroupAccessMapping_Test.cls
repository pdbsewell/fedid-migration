/**
 * @author       : Ibrahim Rumi
 * @date         : 14-06-2022
 * @group        : Event Management
 * @description  : Test class for BTEventGroupAccessMapping
**/
@isTest(isParallel=true)
private class BTEventGroupAccessMapping_Test {

    
    /**
    * @description test retrieving public group ids
    **/
    @isTest
    static void getPublicGroupIdsTest(){
        
        group g = [SELECT Id,Name,RelatedId,Type,developername 
                   FROM Group 
                   WHERE developername = 'ACCESS_BT_Faculty_Arts'];
        
        List<BTEventGroupAccessMapping.Request> reqList = new List<BTEventGroupAccessMapping.Request>();
        List<BTEventGroupAccessMapping.Result> resList = new List<BTEventGroupAccessMapping.Result>();
        
        BTEventGroupAccessMapping.Request req1 = new BTEventGroupAccessMapping.Request();
        req1.faculty = 'Faculty of Arts';
        req1.campus = 'Caulfield';
        
        reqList.add(req1);
        
        Test.startTest();
        resList = BTEventGroupAccessMapping.getPublicGroupIds(reqList);
        
        Test.stopTest();
        
        system.assertEquals(g.Id,resList[0].publicGroupId, 'returned public group ids did not match the expected public group ids');
    }
    
    /**
    * @description negative test retrieving public group ids
    **/
    @isTest
    static void negativeGetPublicGroupIdsTest(){
        
        List<BTEventGroupAccessMapping.Request> reqList = new List<BTEventGroupAccessMapping.Request>();
        List<BTEventGroupAccessMapping.Result> resList = new List<BTEventGroupAccessMapping.Result>();
        
        BTEventGroupAccessMapping.Request req1 = new BTEventGroupAccessMapping.Request();
        
        reqList.add(req1);
        
        Test.startTest();
        resList = BTEventGroupAccessMapping.getPublicGroupIds(reqList);
        
        Test.stopTest();
        
        system.assert(resList[0].publicGroupId == null);
        
    }
    
    /**
    * @description test retrieving public group ids when campus details are provided
    **/
    @isTest
    static void getPublicGroupIdsTestWithCampusDetails(){
        
        List<BTEventGroupAccessMapping.Request> reqList = new List<BTEventGroupAccessMapping.Request>();
        List<BTEventGroupAccessMapping.Result> resList = new List<BTEventGroupAccessMapping.Result>();
        
        BTEventGroupAccessMapping.Request req1 = new BTEventGroupAccessMapping.Request();
        req1.faculty = 'Faculty';
		req1.campus = 'Caulfield';
        
        BTEventGroupAccessMapping.Request req2 = new BTEventGroupAccessMapping.Request();
        req2.campus = 'Caulfield';
        
        reqList.add(req1);
        reqList.add(req2);
        
        Test.startTest();
        resList = BTEventGroupAccessMapping.getPublicGroupIds(reqList);
        
        Test.stopTest();
        
        system.assertEquals(resList[0].groupType,BTEventGroupAccessMapping.BT_CAMPUS,'group type is incorrect');
        
    }
}