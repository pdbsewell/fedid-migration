/**
* @description Invalidate User Email
*
* @author M. Maramot
* @date 25/01/2021
*
*
**/
public class UserEmailUpdateBatch implements Database.Batchable<sObject> {
    /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        String query = 'SELECT UserType, Email, Id FROM User ' + 
        'Where UserType In (\'Standard\', \'PowerPartner\', \'CspLitePortal\')' +
        'AND  Monash_User_Type__c = null ' + 'AND (NOT(Profile.Name LIKE \'System Administrator\'))' + 
        'AND (NOT(Email LIKE \'%.invalid\' OR Email LIKE \'%@00d280000016gq6eam%\')) AND isactive = True';

        System.debug(LoggingLevel.DEBUG, String.valueOf(UserEmailUpdateBatch.class)+': Running query '+query);

        //return results to process only if the current instance is a sandbox or a test is running
        Boolean sandbox;
        for(Organization o:[SELECT isSandbox FROM Organization LIMIT 1]) {
            sandbox = o.isSandbox;
        }
        if(sandbox || Test.isRunningTest()) {
            //Limit to 1
            if(Test.isRunningTest()){
                query += ' AND Email = \'testuser@test.com\'  LIMIT 1';
                return Database.getQueryLocator(query);
            }
            return Database.getQueryLocator(query);
        } else {
            // avoid running in production environment
            return Database.getQueryLocator(query + ' LIMIT 0');
        }
    }

    /**
    * Implement execute method (from interface) to run the business logic
    */
    public void execute(Database.BatchableContext bc, List<Sobject> scope) {
        List<User> updateUserList = new List<User>();
        
        // Append .invalid to Email
        for(User oUser: (List<User>) scope) {
            oUser.Email = oUser.Email + '.invalid';
            System.debug(LoggingLevel.FINEST, String.valueOf(UserEmailUpdateBatch.class)+': Added invalid to email : ' + oUser.Email);
            updateUserList.add(oUser);      
        }
        
        if(updateUserList.size()>0) {
            update updateUserList;
        }
    }

    /**
    * Implement finsh method (from interface) to wrap up processing.
    */
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.FINEST, String.valueOf(EmailUpdateBatch.class)+': Invalidation of User email addresses completed.');
    }
}