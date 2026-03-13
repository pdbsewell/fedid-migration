/*******************************************************************************
* @author:      K Liew
* @date:        15.Nov.2018
* @description: Test class for AM_Utilities
* @revision:
*               15.Nov.2018 KL > Initial class creation.
*******************************************************************************/

@isTest(isParallel=true)
public class AM_Utilities_Test {

    @isTest static void test_AMUtilities_formatContactName() {
        
        List<String> inStringList = new List<String>();
        inStringList.add('ALL UPPER CASE WITH THE DIGIT8 OR EIGHT');
        
        List<String> outStringList = new List<String>();
        outStringList = AM_Utilities.formatContactName(inStringList);
        
        System.assertEquals('All Upper Case With The Digit Or Eight', outStringList.get(0));
        
    }

}