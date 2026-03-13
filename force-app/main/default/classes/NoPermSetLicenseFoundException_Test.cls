/**
 * @description Test class for NoPermSetLicenseFoundException
 * @revision
 * 		2025-17-08 - Sachin Shetty	- 	Formatting
 */
@isTest(isParallel=true)
public class NoPermSetLicenseFoundException_Test {
    /**************************************************************************
     * NOTE: THE ASSOCIATED CLASS DOES NOT HAVE ANYTHING TO TEST AND DOES NOT * 
     * HAVE ANY LINES TO BE COVERED BY UNIT TESTS.                            *
     * THIS TEST CLASS ONLY EXISTS TO SATISFY MONASH'S REQUIREMENT TO HAVE A  *
     * SIBLING TEST FOR EVERY CLASS. THIS TEST CLASS SERVES NO OTHER PURPOSE. *
     *************************************************************************/

    // It's not possible to unit test an Exception on its own
    @isTest
    static void testException() {
        try {
            throw new NoPermSetLicenseFoundException(NoPermSetLicenseFoundException.getDefaultMessage());
        } catch (NoPermSetLicenseFoundException ex) {
            Assert.areEqual('NoPermSetLicenseFoundException', ex.getMessage());
        }
    }
}