/**
 * @description       : Test methods for SBQQ_Quote_AU_Scheduled_Doc_Gen_Failure_Alert and SBQQ_Quote_Sub_Send_Error_Message
 * @author            : Ben Greenland
 * @group             : Admissions
 * @last modified on  : 2024-08-29
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-07-30   Ben Greenland   Initial Version
 **/

@isTest(isParallel=false) // cannot call  Test.getStandardPricebookId when true
private class SBQQ_QuoteAUSchedDocGenFailureAlert_FT {
  @testSetup
  static void setupTestData() {
    //Account Creation
    Account acc1 = (Account) TestDataFactory.createSObject(
      new Account(Name = 'Test Accnt 1'),
      true
    );

    //Contact Creation
    Contact contact1 = (Contact) TestDataFactory.createSObject(
      new Contact(
        AccountId = acc1.Id,
        Email = 'contact1@email.com',
        Firstname = 'firstname',
        LastName = 'lastname'
      ),
      true
    );

    Opportunity opp = (Opportunity) TestDataFactory.createSObject(
      new Opportunity(
        AccountId = acc1.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        CloseDate = Date.today().addDays(15)
      ),
      true
    );
    SBQQ.TriggerControl.disable();
    TriggerCommon.disableTrigger('SBQQ__Quote__c');
    TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
    QuoteTriggerHandler.lockUserCreation = true;
    SBQQ__Quote__c quote1 = (SBQQ__Quote__c) TestDataFactory.createSObject(
      new SBQQ__Quote__c(
        SBQQ__Account__c = acc1.Id,
        SBQQ__PricebookId__c = Test.getStandardPricebookId(),
        SBQQ__PrimaryContact__c = contact1.Id,
        SBQQ__Status__c = 'Created',
        Sub_Status__c = 'In Progress',
        SBQQ__Opportunity2__c = opp.Id,
        SBQQ__ExpirationDate__c = opp.CloseDate,
        SBQQ__Primary__c = true
      ),
      true
    );
    TestDataFactory.createSObject(
      new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id),
      true
    );

    //create custom settings
    FlowSBQQQuoteAUScheduledDocGen__c flowSetting = new FlowSBQQQuoteAUScheduledDocGen__c(
        To_Address__c = 'testbenchannnel-aaaanqitw5zzofetkouzolvndy@monash-esol.slack.com',
      From_Address__c = 'admissions.unit@f.e.monash.edu'
    );
    insert flowSetting;
  }
  /**
  * @description There is nothing on the immediate path on this flow and it will throw an exception
  * @author Ben Greenland | 2024-07-30 
  **/
  @isTest
  static void testFlowDoesntRun() {
    //GIVEN an SBQQ__Quote__c record
    SBQQ__Quote__c quote = [
      SELECT Id, SBQQ__Status__c
      FROM SBQQ__Quote__c
      LIMIT 1
    ][0];
    Test.startTest();
    ////WHEN an SBQQ__Quote__c status approved
    quote.SBQQ__Status__c = 'Approved';
    update quote;
    Map<String, Object> Params = new Map<String, Object>();
    Params.put('recordId', quote.Id);
    //create instance of Interview
    try {
      Flow.Interview.SBQQ_Quote_AU_Scheduled_Doc_Gen_Failure_Alert qflow = new Flow.Interview.SBQQ_Quote_AU_Scheduled_Doc_Gen_Failure_Alert(
        Params
      );
      //Invoke start method
      qflow.start();
      Test.stopTest();
    } catch (FlowException ex) {
      //THEN FLOW will execute the empty path
      Assert.areEqual(
        'The flow can\'t run because nothing is connected to the Start element.',
        ex.getMessage(),
        'Flow should throw an error for this path'
      );
    }
  }

  @isTest
  static void testFlowRunsOnSuccess() {
     //GIVEN an SBQQ__Quote__c record
    SBQQ__Quote__c quote = [
      SELECT
        Id,
        SBQQ__Status__c,
        Latest_Preview_Generated_Date__c,
        Sub_status__c
      FROM SBQQ__Quote__c
      LIMIT 1
    ][0];
    test.startTest();
     //WHEN  updated to meet entry 
    quote.Latest_Preview_Generated_Date__c = Datetime.now();
    update quote;
    test.stopTest();
    //THEN flow should have run - !! can't test async
    Assert.isNotNull([SELECT
    Id,
    Sub_status__c
    FROM SBQQ__Quote__c
    LIMIT 1].Sub_Status__c, 'Sub status should have error');
  }

  /**
  * @description Error log is created for null quite id
  * @author Ben Greenland | 2024-07-30 
  **/
  @isTest
  static void testSubflowDoesntRunWhenQuiteIdNull() {
    test.startTest();
    //GIVEN Sub flow with error conditon 
    Map<String, Object> Params = new Map<String, Object>();
    Params.put('QuoteId', null);
    Flow.Interview.SBQQ_Quote_Sub_Send_Error_Message qflow = new Flow.Interview.SBQQ_Quote_Sub_Send_Error_Message(
      Params
    );
    //WHEN flow starts
    qflow.start();

    test.stopTest();
    //THEN and error should be in the logs
    Assert.areEqual(
      'Flow.SBQQ_Quote_Sub_Send_Error_Message',
      [SELECT Id, Nebula__Origin__c FROM Nebula__LogEntry__c LIMIT 1][0]
      .Nebula__Origin__c,
      'Error log should have been generated'
    );
  }

  /**
  * @description Test Error is thrown for bad quote id 
  * @author Ben Greenland | 2024-07-30 
  **/
  @isTest
  static void testSubflowCreatesErrorWithBadId() {
     //GIVEN Ssub flow with error conditon 
    test.startTest();
    Map<String, Object> Params = new Map<String, Object>();
    Params.put('QuoteId', 'xxxxxx1234xxxxxxwe');
    Flow.Interview.SBQQ_Quote_Sub_Send_Error_Message qflow = new Flow.Interview.SBQQ_Quote_Sub_Send_Error_Message(
      Params
    );
     //WHEN flow starts
    qflow.start();

    test.stopTest();
    //THEN and error should be in the logs
    Assert.areEqual(
      'Flow.SBQQ_Quote_Sub_Send_Error_Message',
      [SELECT Id, Nebula__Origin__c FROM Nebula__LogEntry__c LIMIT 1][0]
      .Nebula__Origin__c,
      'Error log should have been generated'
    );
  }

  /**
  * @description Test mail message is created 
  * @author Ben Greenland | 2024-07-30 
  **/
  @isTest
  static void testSubflowCreatesMailMessage() {
    //GIVEN a quote
    SBQQ__Quote__c quote = [
      SELECT Id, SBQQ__Status__c
      FROM SBQQ__Quote__c
      LIMIT 1
    ][0];
    test.startTest();

    //WHEN FLOW STarts
    Map<String, Object> Params = new Map<String, Object>();
    Params.put('QuoteId', quote.Id);
    Flow.Interview.SBQQ_Quote_Sub_Send_Error_Message qflow = new Flow.Interview.SBQQ_Quote_Sub_Send_Error_Message(
      Params
    );
    qflow.start();
    Boolean emailsent = (Boolean)qflow.getVariableValue('emailSent');

    test.stopTest();
   //THEN the emailSent variable should be set
    Assert.isTrue(emailsent, 'An Email message should have been created');
  }
}