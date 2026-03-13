/**
 * @description Test class for DocuSignGetSignUrlReqFailException
 */
@isTest(isParallel=true)
public class DocuSignGetSignUrlReqFailException_Test {
    
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
            throw new DocuSignGetSignUrlReqFailException(DocuSignGetSignUrlReqFailException.getDefaultMessage());
        } catch (DocuSignGetSignUrlReqFailException ex) {
            Assert.areEqual('DocuSign signing URL request failed', ex.getMessage());
        }
    }
}