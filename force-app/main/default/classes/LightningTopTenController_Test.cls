@isTest(isParallel=true)
public class LightningTopTenController_Test {
    @testSetup
    public static void createData() {
        TestUtil.createArticles();
        TestUtil.createCustomSettings();
    }
    public static testmethod void testLightningTopTen() {        
        LightningTopTenController.getTopTenArticles();             
    }
}