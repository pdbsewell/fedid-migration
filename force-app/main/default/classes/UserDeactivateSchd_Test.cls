@IsTest(isParallel = false)
private class UserDeactivateSchd_Test {
    @isTest
    static void executeTest() {
        //GIVEN - runs executebatch on UserDeactivateBatch
        UserDeactivateSchd scdClass;
        //WHEN - performs execute
        Test.startTest();
        scdClass = new UserDeactivateSchd();
        scdClass.execute(null);
        Test.stopTest();
        //THEN - asyncapexjob created
        System.assertEquals(true,scdClass.hasExecuted,'Batch Running');
    }

    @isTest
    static void addRemoveSchedulesTest() {
        //GIVEN - test for adding and removing schedule
        String className = UserDeactivateBatch.class.getName();
        //WHEN - performs execute
        Test.startTest();
        UserDeactivateSchd.addSchedule();
        //THEN - asyncapexjob added
        System.assertEquals(1,
                            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name =: className],
                            'Schedule not created');
        UserDeactivateSchd.removeSchedule();
        //THEN - asyncapexjob cleared
        System.assertEquals(0,
                            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name =: className],
                            'Schedule not cleared');
        Test.stopTest();
    }
}