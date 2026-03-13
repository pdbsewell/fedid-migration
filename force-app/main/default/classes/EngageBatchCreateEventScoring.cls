/**
 * Batch for creating scores for ERDA Event attendance
 * 
 * @author Mark Johnson - UC Innovation
 * @date         14/03/2019    
 * @revision
 */
public class EngageBatchCreateEventScoring implements Database.Batchable<sObject> {
    /**
     * @description Currently gets constituents and related records where the Engagement_Last_Updated flag 
     */
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        //MARK TBD: Should we run this every day? What if it fails, or batches are unscheduled for a period of time? 
        //          Should we catch contacts with Engagement Last Updated for whole week, in order to make sure?
        Date yesterdayDate = Date.today().addDays(-1);

        String query =  'SELECT  Id, ' +
                                'CampaignId, ' + 
                                'ContactId,' +
                                'Premium_Event__c, ' + 
                                'Event_End_Date__c ' + 
                        'FROM CampaignMember ' + 
                        'WHERE (Engagement_Scoring_Applied__c = false ' + 
                        'AND Campaign.Parent_ERDA_Event__r.Status = \'Completed\' ' +
                        'AND Status = \'CheckedIn\' ' + 
                        'AND RecordType.DeveloperName = \'ERDA_Campaign_Member\')';

        return Database.getQueryLocator(query);
    }

    /**
     * @descrption For each campaign member that has not been scored, create a scoring object.
     *
     * @param batchableContext                  The batchable context for this batch job
     * @param listOfContactsToCreateScoresFor   The list of SObject that this batch job runs on
     */
    public void execute(Database.BatchableContext batchableContext, List<CampaignMember> listOfCampaignMembersToCreateScoresFor) {

        List<Score__c> scoresToInsert = new List<Score__c>();
        List<CampaignMember> campaignMembersToUpdate = new List<CampaignMember>();
  
        //Get custom setting
        Score_Batch_Settings__c scoreSettings = Score_Batch_Settings__c.getInstance();
        
        try{
            for (CampaignMember campaignMemberRecord : listOfCampaignMembersToCreateScoresFor) {
                if (campaignMemberRecord.Premium_Event__c) {
                    scoresToInsert.add( new Score__c(   Constituent__c = campaignMemberRecord.ContactId, 
                                                        Event__c = campaignMemberRecord.CampaignId, 
                                                        Expiration_Date__c = campaignMemberRecord.Event_End_Date__c.addMonths(scoreSettings.Premium_Attended_Expiry__c.intValue()).date(),
                                                        Points_Description__c = scoreSettings.Premium_Attended_Description__c,
                                                        Point_Value__c = scoreSettings.Premium_Attended_Score__c,
                                                        Status__c = 'Active'
                                                    )
                                        );
                } else {
                    scoresToInsert.add( new Score__c(   Constituent__c = campaignMemberRecord.ContactId, 
                                                        Event__c = campaignMemberRecord.CampaignId, 
                                                        Expiration_Date__c = campaignMemberRecord.Event_End_Date__c.addMonths(scoreSettings.Attended_Expiry__c.intValue()).date(),
                                                        Points_Description__c = scoreSettings.Attended_Description__c,
                                                        Point_Value__c = scoreSettings.Attended_Score__c,
                                                        Status__c = 'Active'
                                                    )
                                        );
                }
    
                campaignMemberRecord.Engagement_Scoring_Applied__c = true;
                campaignMembersToUpdate.add(campaignMemberRecord);
            }
    
            //Insert Score records and update Campaign Members
            if(!scoresToInsert.isEmpty()){
                insert scoresToInsert;
                update campaignMembersToUpdate; //If there is a score, then there is a campaign member to update
            }

        }
        catch(Exception e){
            Nebula.Logger.error('EngageBatchCreateEventScoring.cls Line number ' + e.getLineNumber() + ' - ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
        // Log the exceptions
        Nebula.Logger.saveLog();      
    }

    /**
     * @description Finish, currently don't have anything
     *
     * @param BatchableContext  The batchable context for this batch job
     */
    public void finish(Database.BatchableContext batchableContext) {
    }
}