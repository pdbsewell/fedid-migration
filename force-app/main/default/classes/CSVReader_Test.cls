/**
* @author Nadula Karunaratna
* @date 21-01-2020
* @group Professional Development
* @description Test class for CSVReader
*/
@isTest 
private class CSVReader_Test {
    @istest
    static void CSVReader_Test() {
        String data = 'abc,"def","g""h""i"' + CSVParser.CRLF + '"j' + CSVParser.CRLF
             + 'kl","m' + CSVParser.CRLF + 'n""o""",';
      
          List<List<String>> fileValues = CSVReader.readIETFRFC4180CSVFile(data);
    }
}