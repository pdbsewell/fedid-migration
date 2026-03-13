/**
* @author idha0002
* @date 12 Mar 2021
* @group Test Class
* @description Test class to cover the OpportunityCollaboratorController Class
*/
@isTest(isParallel=True) 
public class OpportunityCollaboratorController_Test { 
    
    @isTest 
    static void test_getAccountDetails(){
        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        Account getAccount = OpportunityCollaboratorController.getAccountDetails(accountRecord.Id);
        system.assertequals(accountRecord.Id,getAccount.Id); 

    }
}