/**
 * @author Trent De Laney
 * @date 29 Nov 2019 at 12:18:20 pm
 * @group Test Class
 * @description Covers the response message for the Chargent Submission. Needs to be covered line by line for Salesforce to pick up the coverage
 */
@IsTest
public with sharing class ObdChargentRequest_Test {
    @IsTest
    public static void test_AssignPropertyValues(){
        ObdChargentRequest request = new ObdChargentRequest();
        System.assertNotEquals(null, request, 'Unable to create the chargent request');
        request.ObjectId = '111';
        request.CardSecurity = '111';
        request.CardMonth = '12';
        request.CardYear = '22';
        request.PaymentMethod = 'CreditCard';
        request.CardType = 'Visa';
        request.CardNumber = '4444444444444444';
        request.ChargeAmount = 100.00;
    }
}