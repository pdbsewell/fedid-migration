/**
 * Created by Ajitabh
 */
@isTest(isParallel=true)
public class ScheduleAlumniOnboardingBatch_Test {
    @isTest
    public static void testSchedulableTest()
    {
        Test.startTest();
        System.schedule('One Time Pr',  '00 54 12 8 5 ?', new ScheduleAlumniOnboardingBatch());
        Test.stopTest();
        System.assert([select id , JobType,CompletedDate from AsyncApexJob where CompletedDate=null].size()>0);
    }
}