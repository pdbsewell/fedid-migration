/**
 * @author Trent De Laney
 * @date 21 Feb 2019 at 10:19:44 am
 * @group Lightning Web Component Controller
 * @description Used to call the server side controls into Chargent from the Credit Card LWC.
 * Changelog
 * 2022-12-01 - populate additional applicaiton transaction fields upon payment
 * 2023-05-04 - improve error logging.
 * 2023-08-02 - remove credit card details from error logs.
 * 2025-01-20 - Fee value verification and Nebula error logging
 * 
 */
public with sharing class CreditCardController {

    /**
     * @author Trent De Laney
     * @date 21 Feb 2019 at 10:33:00 am
     * @group Struct Class
     * @description Used to pass a message back from the various touch points for CC
     */
    public class Response{

        //Constructor
        public Response(){
            message = new List<String>();
        }

        public String result {get; set;}
        public List<String> message {get;set;}
        public String orderId {get; set;}
        public Decimal amount {get;set;}
    }

    /**
    * @author Trent De Laney
    * @description Used to validate the card information on the server side to ensure that there is the right data being passed through
    * @date 21 Feb 2019 at 10:23:09 am
    * @param String payload (CreditCard)
    * @param String context (appId)
    * @return Response (message)
    */
    @AuraEnabled
    public static String validateCard(String payload, String context){
        Response reply = new Response();
        try{
            PaymentUtils.CreditCard cardDetails = (PaymentUtils.CreditCard)JSON.deserialize(payload, PaymentUtils.CreditCard.class);
            if(cardDetails != null){
                //TODO -- PROCESS VALIDATION OF CARD HERE AGAINST CHARGENT

                //Strip whitespace
                cardDetails.CardNumber = cardDetails.CardNumber.replaceAll( '\\s+', '');
                if(cardDetails.CardNumber.length() != 16 || !cardDetails.CardNumber.isNumeric()){
                    reply.result = 'FORM_ERROR';
                    reply.message.add('Invalid card number - Please ensure that your card has 16 digits');
                }
                if(cardDetails.CCV.length() != 3 || !cardDetails.CCV.isNumeric()){
                    reply.result = 'FORM_ERROR';
                    reply.message.add('Invalid CCV - Please ensure that you enter in a valid 3 digit CCV number');
                }
                try{
                    if(Date.parse('01/' + cardDetails.ExpiryDate) < Date.today()){
                        reply.result = 'FORM_ERROR';
                        reply.message.add('Invalid Expiry Date = Please ensure that the date of the card expiry is valid');
                    }
                }catch(Exception e){
                    reply.result = 'FORM_ERROR';
                    reply.message.add('Invalid Expiry Date = Please ensure that the date of the card expiry is valid');
                }

                if(cardDetails.CardType != 'Visa' && cardDetails.CardType != 'Mastercard'){
                    reply.result = 'FORM_ERROR';
                    reply.message.add('Invalid Card Type - Only Visa or Mastercard are accepted');
                }
            }

            // if above card details validation passes, proceed with chargent order creation / update, and return Chargent Order Id
            if(reply.result != 'FORM_ERROR'){
                Response reply2 = createOrder(reply,context);
                reply = reply2;
            }

        }
        catch(Exception e){
            Nebula.logger.error('Deserialization error::CreditCardController::ValidateCard for '+context, e.getMessage());
            reply.result = 'ERROR';
            //reply.Message.add('An Unexpected Error has occurred. Please contact Monash Connect');
            reply.message.add(e.getMessage());
        }finally{
            Nebula.logger.saveLog();
        }

        return JSON.serialize(reply);
    }

    /**
    * @author Ken
    * @description Used to retrieve an active application given applicationId
    * @date  Sep 2022 
    * @param String applicationId
    * @return Application__c 
    */
    private static Application__c getActiveApplication(String applicationId) {
        List<Application__c> activeApplications =   
            [SELECT Id, Fee_Amount__c, Fee_Payment__c, Fee_Payment_Mode__c
            FROM Application__c
            WHERE Status__c = 'Draft'
            AND Id = :applicationId
            LIMIT 1];
        return activeApplications.size() == 0 ? null : activeApplications[0];
    }

     /**
    * @author Ken
    * @description Used to retrieve ChargentOrders__ChargentOrder__c  given applicationId
    * @date  Sep 2022 
    * @param String applicationId 
    * @return ChargentOrders__ChargentOrder__c 
    */
    private static ChargentOrders__ChargentOrder__c getActiveOrder(String applicationId) {
        List<ChargentOrders__ChargentOrder__c> existingOrders = 
            [SELECT Id,Application__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Application__c = :applicationId
            LIMIT 1];
        return existingOrders.size() == 0 ? null : existingOrders[0];
    }

    /**
    * @author       K Liew
    * @description  Private method to either retrieve an existing Chargent Order if one exists under an Application,
    *               or create one if there's none.  Returns Id of Order record in instance of Response class.  Logic
    *               assumes that it runs in the context of a community user, picks up Contact.Id using UserInfo.
    * @date         25 Feb 2019
    * @param        PaymentUtils.Response
    * @param String context (appId)
    * @return       PaymentUtils.Response
    */
    private static Response createOrder(Response resp, String context){

        try {
            // SOQL to get values needed for Chargent Order from Application + Contact
            Application__c app = getActiveApplication(context);

            if(app == null) {
                resp.result = 'ERROR';
                resp.message.add('No applicaiton exists for this transaction.');
                Nebula.logger.error('ERROR::'+context , ' No applicaiton exists for this transaction.');
                return resp;
            }

             resp.amount = app.Fee_Amount__c;

            // pick up Chargent Gateway record, used to associate with Order.  Assumes 1 active Gateway cofigured.  If there are future requirements
            // to support multiple payment gateways, this should be externalised to a configurable parameter.
            ChargentBase__Gateway__c[] gtwy = [SELECT Id
                                               FROM ChargentBase__Gateway__c
                                               WHERE ChargentBase__Active__c = TRUE
                                               LIMIT 1];

            // Check for existing Chargent Order 
            ChargentOrders__ChargentOrder__c existingOrder = getActiveOrder (app.id);

            // if existing order exists, get transactions, check for prior approved transactions to prevent overcharge
            if (existingOrder != null) {
                ChargentOrders__Transaction__c[] trx = [SELECT Id
                                                            , ChargentOrders__Response_Status__c
                                                        FROM ChargentOrders__Transaction__c
                                                        WHERE ChargentOrders__Order__c = :existingOrder.Id
                                                        AND ChargentOrders__Response_Status__c = 'Approved'
                                                        LIMIT 1];
                // if record found, return error.  this order's been processed prior and payment was successful.
                if (trx.size() > 0) {
                    resp.result = 'ERROR';
                    resp.message.add('There is an existing payment already made for your application');
                } else {
                    // just pass back order id
                    resp.orderId = existingOrder.Id;
                    resp.result = 'SUCCESS';
                }
            } else {
                ChargentOrders__ChargentOrder__c newOrder = new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Gateway__c = gtwy[0].Id,
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    ChargentOrders__Billing_Country__c = '',
                    Application__c = app.Id
                );

                insert newOrder;
                resp.orderId = newOrder.Id;
                resp.result = 'SUCCESS';
            }
        } catch (Exception e) {
            Nebula.logger.error('Chargent Order creation error::CreditCardController::CreateOrder for '+context, e.getMessage());
            resp.result = 'ERROR';
            resp.message.add(e.getMessage());
        }finally{
            Nebula.logger.saveLog();
        }
        return resp;
    }

    /**
    * @author       K Liew
    * @description  Method to actually invoke Chargent to perform a charge against an Order.  Uses card details, order id and
    *               charge amount passed in from front-end.
    * @date         25 Feb 2019
    * @param        String card (JSON format of PaymentUtils.CreditCard)
    *               String orderId (Id of Chargent Order record)
    *               Decimal ChargeAmount (amount to be charged against card)
    *               String context (appId)

    * @return       PaymentUtils.Response
    * @revision     S Mendu - 20/01/2025 - Updated to fix the security loophole
    *                         of chargeAmount being editable from the front end
    */
    @AuraEnabled
    public static String chargeOrder(String card, String orderId, Decimal chargeAmount, String context){
        // initialise response to be returned
        Response reply = new Response();
        ChargentOrders__Transaction__c[] trx;
        ChargentOrders.TChargentOperations.TChargentResult result;
        try {
            // Retrieve Application
            Application__c appRec = getActiveApplication(context);
            // Compare the  chargeAmount received from the front end with the actual backnend value Fee_Amount__c
            // to verify the fee amount has not been tampered with
            if(appRec.Fee_Amount__c !=chargeAmount)
            {
                reply.result = 'ERROR';
                reply.message.add('Application fee amount has been tampered. Please ');
                return JSON.serialize(reply);
            }

            // Retrieve order
            ChargentOrders__ChargentOrder__c orderRec = getActiveOrder(context); 
            if(orderRec == null || appRec == null || orderRec.id != orderId) {
                reply.result = 'ERROR';
                reply.message.add('Unable to retrieve order');
                String errorMessage = String.format('CreditCardController.chargeOrder(Order ID: {0}, Charge Amount: {1}, Context: {2}) Unable to retrieve order',
                                                    new List<String> {orderId,String.valueOf(chargeAmount),context});
                Nebula.logger.error('Error retrieving order', errorMessage);

                return JSON.serialize(reply);
            }


            // convert card from JSON to object
            PaymentUtils.CreditCard cardDetails = (PaymentUtils.CreditCard)JSON.deserialize(card, PaymentUtils.CreditCard.class);

            // split card expiry from front-end in mm/yy format into 2 string tokens
            List<String> expiryDateTokens = cardDetails.ExpiryDate.split('/');

            //  create new ObdChargentRequest object and convert to JSON
            ObdChargentRequest req = new ObdChargentRequest();
            req.PaymentMethod = 'Credit Card';
            req.CardNumber = cardDetails.CardNumber;
            req.CardSecurity = cardDetails.CCV;
            req.CardType = cardDetails.CardType;
            req.CardMonth = expiryDateTokens.get(0);
            req.CardYear = expiryDateTokens.get(1);
            req.ChargeAmount = chargeAmount;
            req.ObjectId = orderId;
            String reqJSON = JSON.serialize(req);        

            // invoke Chargent's class + method to perform charge.  NOTE: Behind the scenes callout to Braintree.
            if (!Test.isRunningTest()) {
                // invoke Chargent's class + method to perform charge.  NOTE: Behind the scenes callout to Braintree.
                result = ChargentOrders.TChargentOperations.ChargeOrder_ClickJSON(reqJSON);
                trx = [SELECT
                       Id,
                       ChargentOrders__Response_Status__c,
                       ChargentOrders__Response_Message__c
                       FROM ChargentOrders__Transaction__c
                       WHERE Id = :result.TransactID
                       LIMIT 1
                      ];
            } else {
                // simulate transaction record created by Chargent on a successful gateway callout
                ChargentOrders__ChargentOrder__c[] testOrderRec = [SELECT Id
                                                                       , ChargentOrders__Gateway__c
                                                                    FROM ChargentOrders__ChargentOrder__c
                                                                    WHERE Id = :orderId
                                                                    LIMIT 1];

                ChargentOrders__Transaction__c testTrx = new ChargentOrders__Transaction__c (
                    ChargentOrders__Order__c = orderId,
                    ChargentOrders__Gateway__c = testOrderRec[0].ChargentOrders__Gateway__c,
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
                trx = [SELECT
                       Id,
                       ChargentOrders__Response_Status__c,
                       ChargentOrders__Response_Message__c
                       FROM ChargentOrders__Transaction__c
                       WHERE Id = :testTrx.Id
                       LIMIT 1
                      ];            
            }
            
            // evaluate result from chargent call, if transaction is approved, perform updates to application record to update payment related fields 
            // and return SUCCESS to front-end.  else return ERROR.
            if (trx.size() > 0 && trx[0].ChargentOrders__Response_Status__c == 'Approved') {
                reply.result = 'SUCCESS';
                appRec.Fee_Payment__c = true;
            	appRec.Transaction_Source__c = 'Chargent';
 				appRec.Transaction_Reference__c = trx[0].id;
 				appRec.Transaction_Date__c = system.today();
 				appRec.Transaction_Amount__c  = chargeAmount;                  
                update appRec;
            } else {
                reply.result = 'ERROR';
                string responseMessage = trx.size() > 0 ? trx[0].ChargentOrders__Response_Message__c : 'null';
                reply.message.add(responseMessage);
                String errorMessage = String.format('CreditCardController.chargeOrder(Order ID: {0}, Charge Amount: {1}, Context: {2}) trxMessage: {3}',
                                                    new List<String> {orderId,String.valueOf(chargeAmount),context,responseMessage});
                Nebula.logger.error('ERROR',  errorMessage);

            }
        } catch (Exception e) {
            Nebula.logger.error('Chargent Order charge error::CreditCardController::ChargeOrder for '+context, e.getMessage());
            reply.result = 'ERROR';
            reply.message.add(e.getMessage());
        }finally{
            Nebula.logger.saveLog();
        }

        return JSON.serialize(reply);
    }
}