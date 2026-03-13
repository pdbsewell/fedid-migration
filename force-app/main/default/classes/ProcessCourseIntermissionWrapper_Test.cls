/**
 * @description       : Test class for ProcessCourseIntermissionWrapper
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 2021-05-05
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-05-05 - Angelo Rivera - Initial Creation 
 * 1.1   2021-06-24 - Inderpal Dhanoa - Add Risk Category, caseNumber to payload
**/

@isTest(isParallel=true)
private class ProcessCourseIntermissionWrapper_Test {
    @IsTest
    static void testParse() {
        ProcessCourseIntermissionWrapper processCourseIntermissionWrapper = new ProcessCourseIntermissionWrapper();
        ProcessCourseIntermissionWrapper.SpecificContent contentWrapper = new  ProcessCourseIntermissionWrapper.SpecificContent(
                '32437110' ,
                'A2000',
                '16/12/2020',
                '15/12/2020',
                true,
                '5005O000001Rg9oQAC',
                '2020|24|24',
                'James Citizen',
                'Family Support',
                '0075400');
        ProcessCourseIntermissionWrapper.ItemData itemData = new ProcessCourseIntermissionWrapper.ItemData();
        itemData.Name = Label.Process_Intermission_Name;
        itemData.SpecificContent = contentWrapper;
        itemData.Reference = '26262320-MTH1030';

        processCourseIntermissionWrapper.itemData = itemData;

        System.assert(processCourseIntermissionWrapper.itemData != null);
    }
}