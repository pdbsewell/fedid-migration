/**
 * @description Test class for the ExLog class
 */
@isTest(isParallel=true)
private class ExLog_Test {

    static testMethod void exLogTest() {
        
        String sourceType = 'pw_TaskUtilities';
        String objName = 'Email';
        String funcName = 'sendFacultyActionEmail';
        Exception e;
        List<recordtype>  rt = [select id,developername from recordtype]; 
        Id recordID = rt[0].Id;
        
        String Msg = '';
        String StatusCode = '';
        
        Account[] accts = new List<Account>{
        new Account(Name='Account1'),
        new Account()};
        
        Database.SaveResult[] srList = Database.insert(accts, false);
        
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted account. Account ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    StatusCode  = 'Status Code: ' + err.getStatusCode();
                    Msg = 'Error Message: ' + ': ' + err.getMessage();
                    System.debug('Account fields that affected this error: ' + err.getFields());
                    ExLog.write('account', 'Account', 'insert', err);
                    Exception_Log__c ex = ExLog.writeExlog('account', 'Account', 'insert', err);
                    Exception_Log__c ex2 = ExLog.writeExlog('account', 'Account', 'insert','', Msg);
                    Exception_Log__c ex3 = ExLog.writeExlog('account', 'Account', 'insert','', err);
                }
            }
        }
        
        ExLog.add(sourceType, objName, funcName, e, recordID);
        ExLog.add(sourceType, objName, funcName, e);
        ExLog.add(sourceType, objName, funcName, Msg);
        
        system.assertNotEquals(0,
                           [select count() from Exception_Log__c ],
                           'exlog records didnt get created as expected');
        
    }
    static testMethod void testaddIntegrationLog(){
        integrationlog intlog = new integrationlog();
        Test.startTest();
        ID jobID = System.enqueueJob(intlog);
        Test.stopTest();
        system.assertEquals(1,
                            [select count() from Exception_Log__c ],
                            'exlog record did get created as expected');
        
    }
    static testMethod void testwriteExlogException(){
        Account a = new Account();
        try {
            insert a;
        }
        catch(exception e){
            ExLog.writeExlog('Test Class', 'Account', 'testwriteExlogException', Null, e);
        }
    }
    public class integrationlog implements Queueable { 
        public void execute(QueueableContext context) {
			ExLog.addIntegrationLog(Null, Null, new HttpRequest(), null, Null, new HttpResponse(), context);
        }
    }
}