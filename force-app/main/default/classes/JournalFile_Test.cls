/**
 * @description JournalFile_Test test the creation and seriaslisation of the Journal File value object.
 *
 * @author Stefan Scheit
 * @date 2019-12-17
 * @revision 1.0
 **/
 @isTest(isParallel=true)
public with sharing class JournalFile_Test {

    @isTest
    public static void testJournalFileLogic() {
        /* GIVEN */
        JournalFile jf = new JournalFile();
        // create debit line item
        JournalFile.LineItem debitLineItem = new JournalFile.LineItem();
        // debitLineItem.sl01 = '2'; // cannot be set, defaulted in JournalFile.LineItem
        debitLineItem.sl02 = String.valueOf(10.00);
        debitLineItem.sl03 = ''; // leave blank, credit amount
        debitLineItem.sl04 = ''; // leave blank
        debitLineItem.sl05 = ''; // leave blank
        debitLineItem.sl06 = '101004';
        debitLineItem.sl07 = 'dummy-receipt-text';
        debitLineItem.sl08 = ''; // leave blank
        debitLineItem.sl09 = ''; // leave blank
        debitLineItem.sl10 = ''; // leave blank
        debitLineItem.sl11 = ''; // leave blank
        debitLineItem.sl12 = ''; // leave blank
        debitLineItem.sl13 = ''; // leave blank
        debitLineItem.sl14 = ''; // leave blank
        // create credit line item per record in result set
        JournalFile.LineItem creditLineItem = new JournalFile.LineItem();
        // creditLineItem.sl01 = '2'; // cannot be set, defaulted in JournalFile.LineItem
        creditLineItem.sl02 = ''; // debit amount
        creditLineItem.sl03 = String.valueOf(10.00);
        creditLineItem.sl04 = '123456789'; // SAP fund number
        creditLineItem.sl05 = 'Cost_C'; // cost centre
        creditLineItem.sl06 = '123456'; // SAP general ledger account number
        creditLineItem.sl07 = 'Receipt Number free text';
        creditLineItem.sl08 = 'PRAX-081821-082411849'; // prax number
        creditLineItem.sl09 = ''; // leave blank
        creditLineItem.sl10 = ''; // leave blank
        creditLineItem.sl11 = ''; // leave blank
        creditLineItem.sl12 = ''; // leave blank
        creditLineItem.sl13 = 'S0';
        creditLineItem.sl14 = ''; // leave blank
        // add to JournalFile
        jf.addCreditLineItem(debitLineItem);
        jf.addDebitLineItem(creditLineItem);
        /* WHEN */
        Test.startTest();
        String csvStr = jf.toStringCsv();
        String jsonStr = jf.toStringJson();
        String fixedLengthString = jf.toStringFixedLength();
        Test.stopTest();
        /* THEN */
        // CSV file
        System.assert(csvStr.length()>0, 'Journal file (CSV) is not in an expected format.');
        System.assert(csvStr.contains(','), 'Journal file (CSV) does not contain any "," characters used as separator.');
        // JSON file
        System.assert(jsonStr.length()>0, 'Journal file (JSON) is not in an expected format.');
        System.assert(jsonStr.contains('{'), 'Journal file (JSON) does not contain any "{" characters used as expected in JSON.');
        // Fixed Length file
        System.assert(fixedLengthString.length()>0, 'Journal file (fixed length) is not in an expected format.');
        System.assert(fixedLengthString.contains('\n'), 'Journal file (fixed length) does not contain any line breaks.');
        // Formatting
        System.assertEquals('Receipt Number free text', creditLineItem.sl07);
    }
}