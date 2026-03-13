/**
 * @description       : Test class for ChangeOfResidencyWrapper
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 2021-01-21
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-01-21 - Angelo Rivera - Initial Creation
**/
@isTest(isParallel=true)
public with sharing class ChangeOfResidencyWrapper_Test {
    static testMethod void testParse() {
        ChangeOfResidencyWrapper changeOfResidencyWrapper = new ChangeOfResidencyWrapper();
        ChangeOfResidencyWrapper.SpecificContent contentWrapper = new  ChangeOfResidencyWrapper.SpecificContent(
                '32437110' ,
                'A2000',
                'CLAYTON',
                '16/12/2020',
                '15/12/2020',
                '2120',
                '15/12/2020',
                '5005O000001Rg9oQAC',
                'Subclass 189',
                '302',
                'Jane Doe',
                'James Citizen');
        ChangeOfResidencyWrapper.ItemData itemData = new ChangeOfResidencyWrapper.ItemData();
        itemData.Name = Label.ChangeOfResidency_Name;
        itemData.SpecificContent = contentWrapper;
        itemData.Reference = '26262320-MTH1030';

        changeOfResidencyWrapper.itemData = itemData;

        System.assert(changeOfResidencyWrapper.itemData != null);
    }
}