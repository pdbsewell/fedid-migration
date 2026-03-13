/**
 * @description Test class for DocuSignUpdateEnvelopsReqBody
 * @revision
 * 		17-08-2025	Sachin Shetty	Formatting
 */
@isTest(isParallel=true)
public class DocuSignUpdateEnvelopsReqBody_Test {

    /**************************************************************************
     * NOTE: THE ASSOCIATED CLASS DOES NOT HAVE ANYTHING TO TEST AND DOES NOT * 
     * HAVE ANY LINES TO BE COVERED BY UNIT TESTS.                            *
     * THIS TEST CLASS ONLY EXISTS TO SATISFY MONASH'S REQUIREMENT TO HAVE A  *
     * SIBLING TEST FOR EVERY CLASS. THIS TEST CLASS SERVES NO OTHER PURPOSE. *
     *************************************************************************/

    @isTest
	static void testDefaultConstructorAndFieldAssignment() {
        // GIVEN a new instance created with the default constructor
        DocuSignUpdateEnvelopsReqBody req = new DocuSignUpdateEnvelopsReqBody();

        // WHEN setting field values
        req.status = 'Voided';
        req.voidedReason = 'Signer requested cancellation';

        // THEN the values should be correctly stored
        Assert.areEqual('Voided', req.status);
        Assert.areEqual('Signer requested cancellation', req.voidedReason);
    }

}