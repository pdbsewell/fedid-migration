/*
 * @author Ajitabh
 * @date 24/01/2020
 * @group PORTAL_UCIN
 * @description Test class for portal payment
 */
@isTest(isParallel=true)
public class PORTAL_TRIG_Transaction_Test {
 @testSetup static void setup(){
     	
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        Transaction__c  tran = new Transaction__c();
     	tran.Assigned_Gift_Processor__c =usr.id;
        tran.Status__c='Unassigned';
        insert tran;
     	//tran.Status__c='Unassigned';
        //update tran;
     	
    }    
    @IsTest
    public static void test_first_methods()
    {
       
        List<Transaction__c> paymentList = [select id, Status__c,Assigned_Gift_Processor__c  from Transaction__c];
        system.debug('ooo'+paymentList);
        test.startTest();
        PORTAL_TRIG_Transaction.run(true,false,false,true,false,false,paymentList,paymentList);
        test.stopTest();
        System.assertEquals(paymentList[0].Status__c,'In Progress' );

    }
	@IsTest
    public static void test_second_methods()
    {
        
        List<Transaction__c> paymentList = [select id,name,Transaction_Name_Auto_Number__c  from Transaction__c];
        system.debug('n'+paymentList);
        test.startTest();
        PORTAL_TRIG_Transaction.run(false,true,true,false,false,false,paymentList,paymentList);
        system.debug('nnn'+paymentList);
        test.stopTest();
        //System.assertEquals(paymentList[0].name,paymentList[0].Transaction_Name_Auto_Number__c );

        
    }
    @IsTest
    public static void test_third_methods()
    {
        
        List<Transaction__c> paymentList = [select id from Transaction__c];
        delete paymentList[0];
        test.startTest();
        PORTAL_TRIG_Transaction.run(false,true,false,false,true,true,paymentList,paymentList);
        undelete paymentList[0];
        test.stopTest();
        
    }
}