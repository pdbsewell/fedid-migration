@isTest(isParallel=true)
public class AskMonash_JITHandler_Test{
    static testMethod void testCreateAndUpdateUser() {
          AskMonash_JITHandler handler = new AskMonash_JITHandler();
         map<String, string> values = new map<String, string>();
         values.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname','testLast');
         values.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname','testFirst');
         values.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress','test@test.com.sds');
         values.put('http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname','rtes');
         User u = handler.createUser(null, null, null,'FedId', values,null );
         
         
         system.assertEquals(u.email,'test@test.com.sds');
         
         map<String, string> values2 = new map<String, string>();
         values2.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname','testLast');
         values2.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname','testFirst');
         values2.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress','test@test.com.sds');
         values2.put('http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname','rtes2');
         
        Account myAccount = new Account();
        myAccount.Name = 'first last'; 
        insert myAccount ;
         
        Contact myContact = new Contact();
        myContact.firstName = 'firstName';
        myContact.lastName = 'lastName';
        myContact.email = 'email@gmail.com' ;
        myContact.accountid = myAccount.Id;
        myContact.Authcate__c  = 'rtes2';
        insert myContact;
        User u2 = handler.createUser(null, null, null,'FedId', values2,null );
        system.assertEquals(u2.email,'test@test.com.sds');
        
        handler.updateUser(null, null, null,null, null,values2,null );
    }
}