@isTest (seeAllData= true)
private class RoleServices_Test {

    static testMethod void validateRoleServices() {

        // Create container objects
        Account aAcc = new Account(Name = 'Acc');
        insert aAcc;
        Contact aCnt = new Contact(lastname = 'Cnt', Accountid = aAcc.id);
        insert aCnt;

        // COO record type is not the default
        Roles__c aRole = new Roles__c(Contact__c = aCnt.id, Account__c = aAcc.id);
        insert aRole;

        aAcc = [Select Id, is_coo_account__c from Account where Id = :aAcc.Id];
        aCnt = [Select Id, is_coo_contact__c from Contact where Id = :aCnt.Id];
        Assert.isFalse(aAcc.is_coo_account__c, 'Account should not be COO. Check default role record type for user running test.'); 
        Assert.isFalse(aCnt.is_coo_contact__c, 'Contact should not be COO. Check default role record type for user running test.'); 

        aRole.status__c = 'Current';
        update aRole;
            
        aAcc = [Select Id, is_coo_account__c from Account where Id = :aAcc.Id];
        aCnt = [Select Id, is_coo_contact__c from Contact where Id = :aCnt.Id];
        Assert.isFalse(aAcc.is_coo_account__c,'Role update messed something up'); 
        Assert.isFalse(aCnt.is_coo_contact__c,'Role update messed something up'); 

        List<RecordType> rTypes = [Select Id From RecordType where sObjectType='Roles__c' and isActive=true and developerName = 'COO'];
        aRole.recordtypeid = rtypes[0].id;
        update aRole;

        aAcc = [Select Id, is_coo_account__c from Account where Id = :aAcc.Id];
        aCnt = [Select Id, is_coo_contact__c from Contact where Id = :aCnt.Id];
        //system.assertEquals(true, aAcc.is_coo_account__c,'Role has changed RT so now Account should have flag set'); 
        //system.assertEquals(true, aCnt.is_coo_contact__c,'Role has changed RT so now Contact should have flag set'); 
        
        Account bAcc = new Account(Name = 'bAcc');
        insert bAcc;
        Contact bCnt = new Contact(lastname = 'bCnt', Accountid = bAcc.id);
        insert bCnt;

        aRole.Account__c = bAcc.id;
        aRole.Contact__c = bCnt.id;
        update aRole;        

        aAcc = [Select Id, is_coo_account__c from Account where Id = :aAcc.Id];
        aCnt = [Select Id, is_coo_contact__c from Contact where Id = :aCnt.Id];
        bAcc = [Select Id, is_coo_account__c from Account where Id = :bAcc.Id];
        bCnt = [Select Id, is_coo_contact__c from Contact where Id = :bCnt.Id];
        //system.assertEquals(false, aAcc.is_coo_account__c,'Reparenting role should have turned off flag'); 
        //system.assertEquals(false, aCnt.is_coo_contact__c,'Reparenting role should have turned off flag'); 
        //system.assertEquals(true, bAcc.is_coo_account__c,'Attaching COO role should have turned on flag'); 
        //system.assertEquals(true, bCnt.is_coo_contact__c,'Attaching COO role should have turned on flag'); 

    }
}