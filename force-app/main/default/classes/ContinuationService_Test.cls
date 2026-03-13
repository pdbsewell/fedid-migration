/**
 * @author          Kristian Vegerano
 * @description     Test class for ContinuationService
 * @group           Service
 * @history         18/08/2020
 */
@isTest(isParallel=true)
public with sharing class ContinuationService_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
    }

    /**
      * @description Tests setupContinuation method
      */ 
    @isTest 
    static void test_SetupContinuation() {
        ContinuationService continuationItem = new ContinuationService('IP07_Callista_ACP_Update');
        Test.startTest();
        continuationItem.setupContinuation(30, 'test', 'processRequest', 'test');
        continuationItem.retrieveContinuation();
        System.assertNotEquals(continuationItem.getContinuationLabel(((Continuation)continuationItem.retrieveContinuation()).getRequests()), 'test');
        Test.stopTest();
    }
}