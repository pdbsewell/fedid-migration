/**
 * @author          Stefan Scheit
 * @description     Test class to sanitise the email fields on queues
 * @group			Sandbox Refresh  
 * @revision        13/12/2018 - Stefan Scheit - Initial version
 *                  03/01/2024 - Maritn cadman - Check fields for monash and non-monash address handling
 */

@isTest(isParallel=false) // Can not be parallel because of operation against Group/Queue
public class GroupEmailsUpdateBatch_Test 
{
    /**
     * Test method to test all groups' emails are changed with a masking prefix.
     * 
     * Note that ALL queues are accessible form the test class, not just the dummy queue created below. There is provision for this in groupemailupdatebatch. 
     */
    @isTest
    static void testGeneralEmail() 
    {        
        Group testQueue = new Group(name='Testing Queue', DeveloperName='Testing_Queue', email='general.queue@test.com', Type='Queue');
        insert testQueue;
        System.assert(testQueue.id!=null, 'Test queue could not be inserted.');
        
        Test.startTest();
        GroupEmailsUpdateBatch groupBatch = new GroupEmailsUpdateBatch();
        Database.executeBatch(groupBatch);
        Test.stopTest();
        
        Group grp = [SELECT Id, Email FROM Group WHERE Id=:testQueue.Id];
        System.assert(null==grp.Email || grp.Email.startsWithIgnoreCase(GroupEmailsUpdateBatch.MASKED_EMAIL_PREFIX), 'Group.Email field was not sanitised. The value is: '+grp.Email);
    }

    /**
     * Note that ALL queues are accessible form the test class, not just the dummy queue created below. There is provision for this in groupemailupdatebatch. 
     */
    @isTest
    static void testMonashEmail() 
    {        
        Group testQueue = new Group(name='Testing Queue', DeveloperName='Testing_Queue', email='monash.queue@monash.edu', Type='Queue');
        insert testQueue;
        System.assert(testQueue.id!=null, 'Test queue could not be inserted.');
        
        Test.startTest();
        GroupEmailsUpdateBatch groupBatch = new GroupEmailsUpdateBatch();
        Database.executeBatch(groupBatch);
        Test.stopTest();
        
        Group grp = [SELECT Id, Email FROM Group WHERE Id=:testQueue.Id];
        System.assert(null==grp.Email || grp.Email.endsWithIgnoreCase(GroupEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Group.Email field was not sanitised. The value is: '+grp.Email);
    }

}