/**
 * @author Trent De Laney
 * @date 21 Feb 2019 at 11:17:41 am
 * @group Test Class
 * @description Test class to cover Credit Card Controller
 */

@IsTest
public with sharing class CreditCardController_Test {

    /**
    * @author Trent De Laney
    * @description Test setup for Process Card Test Methods
    * @date 21 Feb 2019 at 11:51:41 am
    */
    @TestSetup
    static void setup(){
        //Create user
        User u = StudFirst_TestHelper.createCommunityUser();

        //Create Application
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.Fee_Amount__c = 125;
        insert app;

        // create chargent gateway
        ChargentBase__Gateway__c gtwy = new ChargentBase__Gateway__c(
            Name = 'MyApp Braintree Test',
            ChargentBase__Merchant_ID__c = '8dwwvsmjbgrbk5j5',
            ChargentBase__Security_Key__c = '03b06f01cb3ace608b94d577e0184bf4',
            ChargentBase__Merchant_Reference__c = 'vrjpfq4nw8m5gjb7',
            ChargentBase__Username__c = 'Fees_Admissions',
            ChargentBase__Available_Card_Types__c = 'Visa; Mastercard',
            ChargentBase__Active__c = true,
            ChargentBase__Test_Mode__c = true,
            ChargentBase__Use_Tokenization__c = true,
            ChargentBase__Debug__c = true,
            ChargentBase__Credit_Card_Data_Handling__c = 'Clear After All Transactions',
//            ChargentBase__Clear_CCV2_Code__c = true,
            ChargentBase__Available_Payment_Methods__c = 'Credit Card',
            ChargentBase__Show_Charge_Button__c = true,
            ChargentBase__Show_Authorize_Button__c = true,
            ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card'
        );
        insert gtwy;
    }
    
    /**
    * @author Trent De Laney
    * @description Tests the validation of the ValidateCard function in Credit Card Controller
    * @date 21 Feb 2019 at 11:18:26 am
    */
    @IsTest
    public static void test_ValidateCard(){
		
        User u = [SELECT Id, ContactId FROM User WHERE LastName = 'TestingUser' LIMIT 1];
        system.runAs(u) {
            Application__c app = [SELECT Status__c FROM Application__c WHERE Applicant__c = :u.ContactId];
            system.debug('!@#$% app.Status__c = ' + app.Status__c);
            
            Date currentDate = date.today();
            Date derivedErpiryDate = currentDate.addYears(5);
            String yearInString = String.valueOf(derivedErpiryDate.year()).right(2);

            //Credit Card
            PaymentUtils.CreditCard c = new PaymentUtils.CreditCard();
            c.CardType = 'Mastercard';
            c.ExpiryDate = '02/' + yearInString;
            c.CardNumber = '4012000033330026';
            c.CCV = '123';
            c.CardHolderName = 'Test User';
    
            String value = JSON.serialize(c);
    
            //SUCCESS - MasterCard
            CreditCardController.Response resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,app.id), CreditCardController.Response.class);
            System.assertEquals('SUCCESS', resp.Result);
    
            //SUCCESS - Visa
            c.CardType = 'Visa';
            value = JSON.serialize(c);
            resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,app.id), CreditCardController.Response.class);
            System.assertEquals('SUCCESS', resp.Result);
    
            //Bad Type Validation
            c.CardType = 'Bad Type';
            value = JSON.serialize(c);
            resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,app.id), CreditCardController.Response.class);
            System.assertEquals('FORM_ERROR', resp.Result);
    
            //Bad Expiry Validation
            c.ExpiryDate = 'Bad Expiry';
            value = JSON.serialize(c);
            resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,app.id), CreditCardController.Response.class);
            System.assertEquals('FORM_ERROR', resp.Result);
    
            //Old Expiry
            c.ExpiryDate = '02/15';
            value = JSON.serialize(c);
            resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,app.id), CreditCardController.Response.class);
            System.assertEquals('FORM_ERROR', resp.Result);
    
            //Bad Card Validation
            c.CardNumber = 'B156fd4sa53';
            value = JSON.serialize(c);
            resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,app.id), CreditCardController.Response.class);
            System.assertEquals('FORM_ERROR', resp.Result);
            //Bad CCV Validation
            c.CCV = '12222';
            value = JSON.serialize(c);
            resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,app.id), CreditCardController.Response.class);
            System.assertEquals('FORM_ERROR', resp.Result);
        }
    }

    /**
    * @author       K Liew
    * @description  Tests the ChargeOrder function.  See https://chargent.desk.com/customer/portal/articles/2913349 for
    *               more details, specifically how you'd be unable to make the managed package perform a mock callout, and expects
    *               simulating creation of chargent related records during normal processing.
    * @date         06 Mar 2019
    */
    @IsTest
    public static void test_ChargeOrder(){

        User u = [SELECT Id, ContactId FROM User WHERE LastName = 'TestingUser' LIMIT 1];
        system.runAs(u) {

            Date currentDate = date.today();
            Date derivedErpiryDate = currentDate.addYears(5);
            String yearInString = String.valueOf(derivedErpiryDate.year()).right(2);

			// scenario 1: positive testing
            // step 1, call CreditCardController.ValidateCard and store OrderId
            PaymentUtils.CreditCard c = new PaymentUtils.CreditCard();
            c.CardType = 'Mastercard';
            c.ExpiryDate = '02/' + yearInString;
            c.CardNumber = '4012000033330026';
            c.CCV = '123';
            c.CardHolderName = 'Test User';
            String value = JSON.serialize(c);
            
                    List<Application__c> activeApplications =   
            [SELECT Id, Fee_Amount__c, Fee_Payment__c, Fee_Payment_Mode__c
            FROM Application__c
            WHERE Status__c = 'Draft'
            LIMIT 1];
            
            CreditCardController.Response resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,activeApplications[0].id), CreditCardController.Response.class);
    
            // step 2, retrieve order id and call CreditCardController.ChargeOrder(...)
            CreditCardController.Response resp2 = (CreditCardController.Response)JSON.deserialize(CreditCardController.ChargeOrder(value, resp.OrderId, 125,activeApplications[0].id), CreditCardController.Response.class);
    
            // since chargent records are simulated per successful gateway callout, check that application record is updated accorindgly
            ChargentOrders__ChargentOrder__c order = [SELECT Application__c
                                                    FROM ChargentOrders__ChargentOrder__c
                                                      WHERE Id = :resp.OrderId
                                                     ];
            
            Application__c app = [SELECT
                                    Fee_Payment__c
                                  FROM Application__c
                                  WHERE Id = :order.Application__c
                                 ];
    
            System.assertEquals(true, app.Fee_Payment__c);

			// scenario 2: negative testing, based on "no charge", meaning an existing "approved" transaction record's found
            ChargentOrders__ChargentOrder__c[] orderRec = [SELECT Id
                                                                    , ChargentOrders__Gateway__c
                                                                FROM ChargentOrders__ChargentOrder__c
                                                                WHERE Id = :resp.OrderId
                                                                LIMIT 1];

            ChargentOrders__Transaction__c testTrx = new ChargentOrders__Transaction__c (
                ChargentOrders__Order__c = resp.OrderId,
                ChargentOrders__Gateway__c = orderRec[0].ChargentOrders__Gateway__c,
                ChargentOrders__Gateway_Date__c = system.today(),
                ChargentOrders__Gateway_ID__c = 'testing',
                ChargentOrders__Response_Status__c = 'Approved',
                ChargentOrders__Response_Message__c = 'Approved',
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Reason_Code__c = 201,
                ChargentOrders__Reason_Text__c = 'settling',
                ChargentOrders__Response__c = '1000',
                ChargentOrders__Authorization__c = 'W17ND2',
                ChargentOrders__Tokenization__c = 'jcjrqc',
                ChargentOrders__Credit_Card_Type__c = 'Mastercard',
                ChargentOrders__Card_Last_4__c = '0026',
                ChargentOrders__Amount__c = 100,
                ChargentOrders__Payment_Method__c = 'Credit Card'
            );
            insert testTrx;

            CreditCardController.Response resp3 = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,activeApplications[0].id), CreditCardController.Response.class);
            System.assertEquals('ERROR', resp3.Result);

        }
    }

    /**
    * @author       Shalini Mendu
    * @description  Verify that fee amount value received from the front end matches with the server Fee amount 
    * and throw an error if there is a mismatch
    * @date 20/01/2025
    */
    @IsTest
    public static void test_ChargeOrderForFeeParity(){
        //GIVEN - A user logs in as Customer community user after the data setup
        User u = [SELECT Id, ContactId FROM User WHERE LastName = 'TestingUser' LIMIT 1];
        System.runAs(u) {

            Date currentDate = date.today();
            Date derivedErpiryDate = currentDate.addYears(5);
            String yearInString = String.valueOf(derivedErpiryDate.year()).right(2);

            // step 1, call CreditCardController.ValidateCard and store OrderId
            PaymentUtils.CreditCard c = new PaymentUtils.CreditCard();
            c.CardType = 'Mastercard';
            c.ExpiryDate = '02/' + yearInString;
            c.CardNumber = '4012000033330026';
            c.CCV = '123';
            c.CardHolderName = 'Test User';
            String value = JSON.serialize(c);
            
            List<Application__c> activeApplications =   
                [SELECT Id, Fee_Amount__c, Fee_Payment__c, Fee_Payment_Mode__c
                FROM Application__c
                WHERE Status__c = 'Draft'
                LIMIT 1];
            Test.startTest();
                CreditCardController.Response resp = (CreditCardController.Response)JSON.deserialize(CreditCardController.ValidateCard(value,activeApplications[0].id), CreditCardController.Response.class);
                //WHEN - Server method is invoked with tampered fee value
                // step 2, retrieve order id and call CreditCardController.ChargeOrder(...)
                CreditCardController.Response resp2 = (CreditCardController.Response)JSON.deserialize(CreditCardController.ChargeOrder(value, resp.OrderId, 1 ,activeApplications[0].id), CreditCardController.Response.class);
        
                // since chargent records are simulated per successful gateway callout, check that application record is updated accorindgly
                ChargentOrders__ChargentOrder__c order = [SELECT Application__c
                FROM ChargentOrders__ChargentOrder__c
                WHERE Id = :resp.OrderId
                ];

                Application__c app = [SELECT
                Fee_Payment__c
                FROM Application__c
                WHERE Id = :order.Application__c
                ];
            Test.stopTest();
            //THEN - Fee_Payment__c value should not be marked to true
            Assert.areEqual(false, app.Fee_Payment__c, 'Fee payment should not be true');
        }
       

    }
}