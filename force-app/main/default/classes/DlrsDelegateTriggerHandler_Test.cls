/**
 * @description       : Test class for the trigger handler delegate for DLRS (declrarative lookup rollup summaries)
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2020-09-17
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-09-17   Stefan Scheit   Initial Version
**/
@isTest(isParallel=true)
public class DlrsDelegateTriggerHandler_Test {

    /* Dummy test to cover all parts of the delegation trigger handler.
     * Actual test are to be done in the respective DLRS tests.
     */
    @isTest
    public static void invokeTest() {
        try {
            // constructors
            DlrsDelegateTriggerHandler myHandler = new DlrsDelegateTriggerHandler(); // just for test coverage
            myHandler = new DlrsDelegateTriggerHandler(Account.SObjectType);
            
            // Triggers.bind()
            try {
                myHandler.run(); // will fail without data from actual trigger.new
            } catch (Exception e1) {
                // ignore
            }
        	
            // Triggers.bindExtended()
        	try {
                myHandler.execute(); // will fail without data from actual trigger.new
            } catch (Exception e1) {
                // ignore
            }
        } catch (Exception exc) {
            System.assert(false, 'Test invocation of the trigger handler delegation failed: ' + exc.getMessage());
        }
    } 
}