/**
 * @author      Sachin Shetty
 * @description Class with invocable method to sync jira stories
 * @group       Copado Integration
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2023-10-31   Sachin Shetty   Initial Version
 *              
**/
public class CopadoJiraSync {
    
    @InvocableMethod(Label='Call Factory for Third Party Update' Description='Calls Integration Factory to make callout')
    public static List<String> SyncJiraStories(List<ProjectRecord> projectRecords) {
        Id pId = projectRecords.get(0).recordId;
        system.debug('pId:'+pId);
        copadoccmint.ScheduleUserStoryFetch susf = new copadoccmint.ScheduleUserStoryFetch(pId, false);
        
        String sch = Datetime.now().addSeconds(3).format('s m H d M ? yyyy');
        if(test.isRunningTest()){
            return new List<String>{'Test Message'};
        }
        String jobId = System.schedule('ScheduleUserStoryFetch - ' + DateTime.now() + '.' + Math.mod(DateTime.now().getTime(), 1000), sch, susf);
        
        return new List<String>{jobId};
    } 
    
    /**
    * @description Data structure to contain required fields to invoke Jira Sync callout
    **/    
    public class ProjectRecord
    {
        @InvocableVariable(required=true)
        public Id recordId;     
    }
}