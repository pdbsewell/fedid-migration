/*
 * @author Ajitabh
 * @date 23/01/2020
 * @group PORTAL_UCIN
 * @description Test class for portal payment
 */
@isTest(isParallel=true)
public class PORTAL_TRIG_PaymentPortal_Test {
    
    @testSetup static void setup(){
        Transaction__c  tran = new Transaction__c();
        insert tran;
     	List<Payment_Portal__c> paymentList = new List<Payment_Portal__c>();
        Payment_Portal__c payment = new Payment_Portal__c();
        payment.Transaction__c = tran.Id;
        payment.Amount__c=848;
        paymentList.add(payment);
        insert paymentList;   
    }    
    @IsTest
    public static void test_first_methods()
    {
        
        List<Payment_Portal__c> paymentList = [select id from Payment_Portal__c];
        test.startTest();
        delete paymentList;
        test.stopTest();
        
    }
	@IsTest
    public static void test_second_methods()
    {
        
        List<Payment_Portal__c> paymentList = [select id,name,Payment_Name_Auto_Number__c from Payment_Portal__c];
        test.startTest();
        PORTAL_TRIG_PaymentPortal.run(false,true,true,false,false,false,paymentList,paymentList);
        test.stopTest();
        System.assertEquals(paymentList[0].name,paymentList[0].Payment_Name_Auto_Number__c);

        
    }
    @IsTest
    public static void test_third_methods()
    {
        
        List<Payment_Portal__c> paymentList = [select id from Payment_Portal__c];
        delete paymentList;
        test.startTest();
        undelete paymentList;
        test.stopTest();
        
    }
}