/*
 * @author Ajitabh
 * @date 30/01/2020
 * @group
 * @description Test class for portal payment
 */
@isTest(isParallel=true)
public class EngageDedupeWrapper_Test {
	@IsTest
    public static void test_first_methods()
    {
       EngageDedupeWrapper wp = new EngageDedupeWrapper();
       EngageDedupeWrapper.ConstituentWrapper wp1 = new EngageDedupeWrapper.ConstituentWrapper();
       wp1.generateConstituent();
       EngageDedupeWrapper.InterimEmailWrapper wp2 = new EngageDedupeWrapper.InterimEmailWrapper('abc','abc',true,true,true,'abc',system.today(),'abc');
       EngageDedupeWrapper.InterimPhoneWrapper  wp3= new EngageDedupeWrapper.InterimPhoneWrapper('abc','abc',true,true,true,'abc',system.today(),'abc','abc');
	   EngageDedupeWrapper.InterimAddressWrapper wp4 = new EngageDedupeWrapper.InterimAddressWrapper('abc','abc','abc','abc','abc','abc',
                                                                                                     true,true,true,'abc',system.today(),system.today(),
                                                                                                    system.today(),system.today(),'abc','abc');
       EngageDedupeWrapper.InterimConstituentWrapper wp5 = new EngageDedupeWrapper.InterimConstituentWrapper();


    }
}