/*
 * @author          Matthew Maramot
 * @description     Batch for creating Score Records when Alumni Campaign Members register to an event
 * @history         08/04/2025 - Matthew Maramot - Initial version
 */
public class EngageBatchRegisterScoring implements Database.Batchable<sObject>{
    //Get custom setting
    Score_Batch_Settings__c scoreSettings = Score_Batch_Settings__c.getInstance();

    /**
     * @description Gets campaign members that have a 'Confirmed' status within an ERDA event.
     *              CreatedDate filter is to ensure we only process records going forwards - Records prior to 2025 are out of scope.
     *              Event End Date filter is to ensure we aren't creating score records that would be expired as Campaign Members can be loaded months later
    */
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        Integer monthsTilExpiry = scoreSettings.Registration_Expiry__c.intValue();

        // Get RecordTypeIds using getDescribe - deferred as only needing recordtypes
        Schema.DescribeSObjectResult campaignDescribe = Campaign.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
        Map<String, Schema.RecordTypeInfo> rtMap = campaignDescribe.getRecordTypeInfosByDeveloperName();

        Id erdaEventRT = rtMap.get('ERDA_Event').getRecordTypeId();
        Id zkipsterEventRT = rtMap.get('ERDA_Zkipster_Event').getRecordTypeId();
        Id erdaGuestRT = rtMap.get('ERDA_Guest_List').getRecordTypeId();

        // Query
        String query =  'SELECT  Id, ' +
                                'CampaignId, ' + 
                                'ContactId,' +
                                'Event_End_Date__c, ' + 
                                'Event_Start_Date__c, ' +
                                'CreatedDate ' +
                        'FROM CampaignMember ' + 
                        'WHERE (Registration_Scoring_Applied__c = false ' + 
                        'AND Status = \'Confirmed\' ' +
                        'AND CreatedDate > 2025-01-05T00:00:00.000+10:00 ' +
                        'AND Event_End_Date__c > N_MONTHS_AGO:' + monthsTilExpiry + ' ' +
                        'AND Campaign.RecordTypeId = \'' + erdaGuestRT + '\' ' +
                        'AND Campaign.Parent_ERDA_Event__r.RecordTypeId IN (\'' + erdaEventRT + '\', \'' + zkipsterEventRT + '\') ' + 
                        'AND Campaign.Parent_ERDA_Event__r.Status = \'Completed\')';
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
        Date expiryDateFrom;
        
        try{
            for (CampaignMember campaignMemberRecord : listOfCampaignMembersToCreateScoresFor) {
                //Compare campaign member created date and event date to determine expiration
                if(campaignMemberRecord.createdDate < campaignMemberRecord.Event_Start_Date__c){
                    //Before event start date
                    expiryDateFrom = campaignMemberRecord.Event_Start_Date__c.date();
                } else if(campaignMemberRecord.createdDate > campaignMemberRecord.Event_End_Date__c){
                    //After event end date 
                    expiryDateFrom = campaignMemberRecord.Event_End_Date__c.date();
                }
                else{
                    //During event
                    expiryDateFrom = campaignMemberRecord.createdDate.date();
                }

                //Create a Score Record
                Score__c sc = new Score__c(   Constituent__c = campaignMemberRecord.ContactId, 
                                                    Event__c = campaignMemberRecord.CampaignId, 
                                                    Expiration_Date__c = expiryDateFrom.addMonths(scoreSettings.Registration_Expiry__c.intValue()),
                                                    Points_Description__c = scoreSettings.Registration_Description__c,
                                                    Point_Value__c = scoreSettings.Registration_Score__c,
                                                    Status__c = 'Active');
                scoresToInsert.add(sc);

                //Mark campaign members
                campaignMemberRecord.Registration_Scoring_Applied__c = true;
                campaignMembersToUpdate.add(campaignMemberRecord);
            }

            //Insert Score records and update Campaign Members
            if(!scoresToInsert.isEmpty()){
                insert scoresToInsert;
                update campaignMembersToUpdate; //If there is a score, then there is a campaign member to update
            }
        }
        catch(Exception e){
            Nebula.Logger.error('EngageBatchRegisterScoring.cls Line number ' + e.getLineNumber() + ' - ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
        // Log the exceptions
        Nebula.Logger.saveLog();
    }

    public void finish(Database.BatchableContext batchableContext) {
    }
}