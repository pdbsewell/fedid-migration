/**
 * @description GRScholarshipRoundPublishScheduler class to process the release offer batch
                we need this scheduler to publish the offer and send the email in system admin user context 
                so that we dont see the staff's predefined email signature in the email
 * @author      Vishal Gupta
 * @since       11.6.2025
 * @revision
 */
public with sharing class GRScholarshipRoundPublishScheduler implements Schedulable {
    /**
     * @description executing the scheduler 
     * @param       sc
     */
    public void execute(SchedulableContext sc) {
        try{
            // Check if there's already a batch job GRScholarshipRoundPublishBatch running 
            List<AsyncApexJob> existingJobs = [
                SELECT Id, Status, JobType, ApexClass.Name
                FROM AsyncApexJob
                WHERE ApexClass.Name = 'GRScholarshipRoundPublishBatch'
                AND Status IN ('Queued', 'Processing', 'Preparing')
                LIMIT 1
            ];

            if (!existingJobs.isEmpty()) {
                Nebula.logger.info('GRScholarshipRoundPublishBatch already running').addTag('Graduate Research');
                return;
            }
            
            List<GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound> lstCalendarRound = new List<GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound>();
            for(Calendar__c cal : [SELECT Id, Inter_schol_round_publish_in_progress__c, Domes_schol_round_publish_in_progress__c FROM Calendar__c WHERE 
                                                            (Inter_schol_round_publish_in_progress__c = TRUE OR Domes_schol_round_publish_in_progress__c = TRUE) AND 
                                                            (Published_Date_for_Domes_ScholarRound__c >= LAST_N_DAYS:2 OR Published_Date_for_Inter_ScholarRound__c >= LAST_N_DAYS:2)
                                                            LIMIT 1]) {//if you increase limit please test this scenario:
                                                                        //If you have 2 rounds (in progress) then you first run the 1st complete that in the batch, 
                                                                        //before calling a 2nd batch (from the first one) for the 2nd round
                
                if(cal.Domes_schol_round_publish_in_progress__c && cal.Inter_schol_round_publish_in_progress__c) {
                    lstCalendarRound.add(new GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound(cal.Id, 'Domestic'));
                    lstCalendarRound.add(new GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound(cal.Id, 'International'));
                } else if(cal.Domes_schol_round_publish_in_progress__c && !cal.Inter_schol_round_publish_in_progress__c) {
                    lstCalendarRound.add(new GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound(cal.Id, 'Domestic'));
                } else if(!cal.Domes_schol_round_publish_in_progress__c && cal.Inter_schol_round_publish_in_progress__c) {
                    lstCalendarRound.add(new GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound(cal.Id, 'International'));
                }
            }
            
            if(!lstCalendarRound.isEmpty()) {
                Id calendar1 = lstCalendarRound[0].calendarId;
                String round1 = lstCalendarRound[0].round;
                lstCalendarRound.remove(0);//removing the 1st element since we are sending them as separate items
                
                //fire the 1st batch and then chain it in the future method of batch
                Database.executeBatch(new GRScholarshipRoundPublishBatch(calendar1, round1, lstCalendarRound), 10);
            }            
        }
        catch(Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }
}