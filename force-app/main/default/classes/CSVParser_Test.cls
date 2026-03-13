/*******************************************************************************
* @author       Ryan Wilson
* @date         12.Jan.2017
* @description  test class for CSVReader and CSVParser
*******************************************************************************/
@isTest(isParallel=true)
private class CSVParser_Test {
	
	static testMethod void CSVReaderTest() {
		String data = 'abc,"def","g""h""i"' + CSVParser.CRLF + '"j' + CSVParser.CRLF
             + 'kl","m' + CSVParser.CRLF + 'n""o""",';
      
	      List<List<String>> fileValues = CSVReader.readIETFRFC4180CSVFile(data);
	}

	static testMethod void CSVValueTest() {
		String data = null;  // Placeholder for data to use in testing.
        
        System.debug(data = CSVParser.CRLF);
        new CSVReader.CSVValue('', false, CSVParser.CRLF)
                .assertEquals(CSVReader.readIETFRFC4180CSVValue(data));
        
        System.debug(data = '""' + CSVParser.CRLF);
        new CSVReader.CSVValue('', true, CSVParser.CRLF)
                .assertEquals(CSVReader.readIETFRFC4180CSVValue(data));
        
        System.debug(data = '"",asdf' + CSVParser.CRLF);
        new CSVReader.CSVValue('', true, CSVParser.COMMA)
                .assertEquals(CSVReader.readIETFRFC4180CSVValue(data));
        
        System.debug(data = ',asdf' + CSVParser.CRLF);
        new CSVReader.CSVValue('', false, CSVParser.COMMA)
                .assertEquals(CSVReader.readIETFRFC4180CSVValue(data));
        
        System.debug(data = '"' + CSVParser.CRLF + '",blah' + CSVParser.CRLF);
        new CSVReader.CSVValue(CSVParser.CRLF, true, CSVParser.COMMA)
                .assertEquals(CSVReader.readIETFRFC4180CSVValue(data));
        
        System.debug(data = '"""marty""","""chang"""' + CSVParser.CRLF);
        new CSVReader.CSVValue('"marty"', true, CSVParser.COMMA)
                .assertEquals(CSVReader.readIETFRFC4180CSVValue(data));
        
        System.debug(data = '"com""pli""cate' + CSVParser.CRLF + 'd"'
                + CSVParser.CRLF);
        new CSVReader.CSVValue('com"pli"cate' + CSVParser.CRLF + 'd', true, CSVParser.CRLF)
                .assertEquals(CSVReader.readIETFRFC4180CSVValue(data));
        
        System.debug(data = 'asdf' + CSVParser.CRLF);
        new CSVReader.CSVValue('asdf', false, CSVParser.CRLF)
                .assertEquals(CSVReader.readIETFRFC4180CSVValue(data));
        
	}
	
}