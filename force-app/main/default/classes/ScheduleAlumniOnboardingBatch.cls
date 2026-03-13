/*
 * @author          Ajitabh
 * @date            13/02/2020
 * @description     Scheduler to schedule BatchAlumniPortalOnboarding 
 * @Revision History Initial version
 */
global class ScheduleAlumniOnboardingBatch implements Schedulable {
	
    global void execute(SchedulableContext ctx)
    {
       
        Database.executeBatch(new BatchAlumniPortalOnboarding() , 200);
        
    }
}