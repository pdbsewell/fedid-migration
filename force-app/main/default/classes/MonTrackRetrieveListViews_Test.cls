/**
 * @author          Angelo Rivera
 * @description     Test class for MonTrackRetrieveListViews
 * @history         03/12/2018
 */
@isTest(isParallel=true)
public class MonTrackRetrieveListViews_Test {
    
    @IsTest(SeeAllData=false) 
    public static void testBehaviour() {  	
    	
        Test.startTest();
        	MonTrackRetrieveListViews.doInit();
        	String listViewName = [SELECT Id, Name FROM ListView WHERE SobjectType = 'Task' and Name like 'Montrack%' limit 1].name;
        	MonTrackRetrieveListViews.getMonTrackListViewId(listViewName);
        Test.stopTest();
        
        System.assert(listViewName.contains('Montrack'));
    }

}