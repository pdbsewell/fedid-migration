/**
 * @description Test class for DocuSignGetSigningUrlRequestBody
 * @revision
 * 		17-08-2025	Sachin Shetty	Formatting
 */
@isTest(isParallel=true)
public class DocuSignGetSigningUrlRequestBody_Test {

    /**************************************************************************
     * NOTE: THE ASSOCIATED CLASS DOES NOT HAVE ANYTHING TO TEST AND DOES NOT * 
     * HAVE ANY LINES TO BE COVERED BY UNIT TESTS.                            *
     * THIS TEST CLASS ONLY EXISTS TO SATISFY MONASH'S REQUIREMENT TO HAVE A  *
     * SIBLING TEST FOR EVERY CLASS. THIS TEST CLASS SERVES NO OTHER PURPOSE. *
     *************************************************************************/

	@IsTest
    static void testDefaultConstructor() {
        // GIVEN a new instance created with the default constructor
        DocuSignGetSigningUrlRequestBody req;

        // WHEN instantiating without parameters
        req = new DocuSignGetSigningUrlRequestBody();

        // THEN all fields should be null initially
        Assert.isNull(req.authenticationMethod);
        Assert.isNull(req.clientUserId);
        Assert.isNull(req.email);
        Assert.isNull(req.recipientId);
        Assert.isNull(req.returnUrl);
        Assert.isNull(req.securityDomain);
        Assert.isNull(req.userName);
        Assert.isNull(req.xFrameOptions);
    }
}