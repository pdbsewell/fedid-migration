/****************************************************************************
@Name: GOEDResponse_Test
@Author: Kevin Evasco (GrowthOps)
********************************************************************************/
@isTest(isParallel=true)
public class GOEDResponse_Test {

    static testmethod void mainTest(){
        GOEDResponse res = new GOEDResponse();
        res.status = GOEDResponse.SUCCESS;
        res.msg = 'Successful!';         
        system.assertEquals(res.msg, 'Successful!');
    }
    
}