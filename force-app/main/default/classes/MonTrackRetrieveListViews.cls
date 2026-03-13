/**
 * @author          Angelo Rivera
 * @description     Apex controller class for MonTrackTaskListView lightning component
 * @history         03/12/2018
 */
public class MonTrackRetrieveListViews {
    
	@AuraEnabled
    public static ThisWrapper doInit(){
        ThisWrapper thisWrapper = new ThisWrapper();
        getMonTrackListViewMetadata(thisWrapper);
        return thisWrapper;
    }
    
	@AuraEnabled
    public static String getMonTrackListViewId(String ListViewName){
        String listViewId = [SELECT Id, Name FROM ListView WHERE SobjectType = 'Task' and Name =: ListViewName].Id;
        System.debug('listViewId: '+listViewId);
        return listViewId;
    }
    
    public static void getMonTrackListViewMetadata(ThisWrapper thisWrapper){
        List<MonTrack_Console_List_View__mdt> lstmclv = [Select MasterLabel, Order__c from MonTrack_Console_List_View__mdt order by Order__c Asc];
        thisWrapper.lstMonTrackListViews = new List<MonTrack_Console_List_View__mdt>();
        thisWrapper.lstMonTrackListViews.addAll(lstmclv); 
    }
    
    public class ThisWrapper{
        @AuraEnabled public List<MonTrack_Console_List_View__mdt> lstMonTrackListViews {get; set;}
    }
    
}