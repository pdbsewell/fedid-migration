/**
* @author Ven Vairavan
* @date 05.09.19
* @group Test Class
* @description Test Class of EnquiryUtil
* @revision 05.12.19 - Initial Create <br/>
*/
@isTest(isParallel=true)
public class EnquiryUtil_Test {
    @isTest
	static void testEnquiryUtil() {
		Test.startTest();
			Id standardenquiryId = EnquiryUtil.CASE_RECTYPE_STANDARDENQUIRY;
		Test.stopTest();
		System.assert(standardenquiryId != null);
	}

}