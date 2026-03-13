/**
 * @description AgentCommissionFile_Test test the creation and seriaslisation of the Agent Commission File value object.
 *
 * @author Vinothraja
 * @date 2021-07-30
 * @revision 1.0
 **/
 @isTest(isParallel=true)
public with sharing class AgentCommissionFile_Test {

    @isTest
    public static void testAgentCommissionFileLogic() {
        /* GIVEN */
        AgentCommissionFile acf = new AgentCommissionFile();
        // create record
        AgentCommissionFile.Record record = new AgentCommissionFile.Record();
        // create header
        AgentCommissionFile.Header header = new AgentCommissionFile.Header();
        header.sh03 = 'KD';
        header.sh07 = 'M-M2021072';
        header.sh09 = '20210630';
        header.sh14 = '83986';
        header.sh15 = String.valueOf(10.00);
        header.sh16 = '*' + 'M-M2021072' + ' ' + 'SUPER-GAD';
        // create line item
        AgentCommissionFile.LineItem lineItem = new AgentCommissionFile.LineItem();
        // debitLineItem.sl01 = '2'; // cannot be set, defaulted in AgentCommissionFile.LineItem
        lineItem.sl02 = String.valueOf(10.00);
        lineItem.sl03 = ''; // leave blank, credit amount
        lineitem.sl04 = '4980032';
        lineitem.sl05 = 'W06016';
        lineitem.sl06 = '735123';
        lineitem.sl07 = 'M-M2021072' + ' ' + 'SUPER-GAD' + ' ' + 'PRI-000109837';
        lineitem.sl11 = 'P0';
        
        // add to AgentCommissionFile
        record.addHeader(header);
        record.addLineItem(lineitem);
        acf.addRecord(record);
        /* WHEN */
        Test.startTest();
            String fixedLengthString = acf.toStringFixedLength();
        Test.stopTest();
        /* THEN */
        // Fixed Length file
        System.assert(fixedLengthString.length()>0, 'AgentCommission file (fixed length) is not in an expected format.');
        System.assert(fixedLengthString.contains('\n'), 'AgentCommission file (fixed length) does not contain any line breaks.');
    }
}