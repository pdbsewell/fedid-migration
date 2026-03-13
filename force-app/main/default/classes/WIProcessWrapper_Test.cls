/**
 * @description       : Wrapper Class for WI Process Data Items
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 2021-01-21
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-01-21 - Angelo Rivera - Initial Creation
**/

@IsTest
public class WIProcessWrapper_Test {
    static testMethod void testParse() {
        WIProcessWrapper wiProcessWrapper = new WIProcessWrapper();
        WIProcessWrapper.SpecificContent contentWrapper = new  WIProcessWrapper.SpecificContent(
                '26262320' ,
                '2021',
                'FY-32',
                'MTH1030',
                'DG6000',
                '123124324235325');

        WIProcessWrapper.ItemData itemData = new WIProcessWrapper.ItemData();
        itemData.Name = Label.WIProcessAutomation;
        itemData.SpecificContent = contentWrapper;
        itemData.Reference = '26262320-MTH1030';

        wiProcessWrapper.itemData = itemData;

        System.assert(wiProcessWrapper.itemData != null);
    }
}