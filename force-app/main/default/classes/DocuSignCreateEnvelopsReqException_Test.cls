/**
 * @description Test class for DocuSignCreateEnvelopsReqException_Test
 * @revision
 * 		2025-17-08 - Sachin Shetty	- 	Formatting
 */
@isTest(isParallel=true)
public class DocuSignCreateEnvelopsReqException_Test {

    /**************************************************************************
     * NOTE: THE ASSOCIATED CLASS DOES NOT HAVE ANYTHING TO TEST AND DOES NOT * 
     * HAVE ANY LINES TO BE COVERED BY UNIT TESTS.                            *
     * THIS TEST CLASS ONLY EXISTS TO SATISFY MONASH'S REQUIREMENT TO HAVE A  *
     * SIBLING TEST FOR EVERY CLASS. THIS TEST CLASS SERVES NO OTHER PURPOSE. *
     *************************************************************************/

    // Seriously, it's not possible to unit test an Exception on its own
    @isTest
    static void testException() {
        try {
            throw new DocuSignCreateEnvelopsReqException(DocuSignCreateEnvelopsReqException.getDefaultMessage());
        } catch (DocuSignCreateEnvelopsReqException ex) {
            Assert.areEqual('DocuSignCreateEnvelopsReqException', ex.getMessage());
        }
    }
}