/**
 * @author          Mark Johnson - UC Innovation
 * @description     For coverage on the update market segment scheduler. This is solely for coverage, as this is a scheduler batch.
 * 
 * @revision        07/10/2019 - Mark Johnson - Initial version
 * @revision        28/01/2020 - Shalini Mendu - Changed reference to the renamed class
 */

@isTest(isParallel=true)
public class EngageUpdateMarketSegmentSch_Test {

    @IsTest
    private static void testEngageUpdateMarketSegmentScheduler()
    {
        test.startTest();
        EngageUpdateMarketSegmentSch scheduler;

        //Can use custom query.
        scheduler = new EngageUpdateMarketSegmentSch('SELECT  ID, Name, Age__c, Contact_Profile__c,Market_Segment__c, ' +
                                                                    '(SELECT ID,Date_Achieved__c FROM Contact_Qualifications__r ' +
                                                                    'ORDER BY Date_Achieved__c ASC LIMIT 1) FROM Contact WHERE Contact_Profile__c INCLUDES (\'Alumni\')', 10);
        
        String schTime = '0 0 12 * * ?';
        System.schedule('TestEngageUpdateMarketSegmentScheduler', schTime, scheduler);
        
        test.stopTest();
    }
    
    @IsTest
    private static void testEngageUpdateMarketSegmentSchedulerWithoutQuery()
    {
        test.startTest();
        EngageUpdateMarketSegmentSch scheduler;

        //Can use default query.
        scheduler = new EngageUpdateMarketSegmentSch(10);
        
        String schTime = '0 0 12 * * ?';
        System.schedule('TestEngageUpdateMarketSegmentScheduler', schTime, scheduler);
        
        test.stopTest();
    }
    
}