/*******************************************************************************
* @author       Ant Custodio
* @date         3.Oct.2017
* @description  converts the string to a 7Bit ACII accepted string
				this replaces non 7Bit to a desired replacement character
* @revision     By Majid 15/12/2017 replaces line breaks with space
				Suman Gunaganti(2019-07-05): Removed Application Document provided object reference
*******************************************************************************/
public with sharing class StudFirst_Utilities {
	public static String convertTo7BitAcceptedString(String stringToUpdate, String replacementStr) {
		String convertedString = '';
		if(stringToUpdate != null)
		{
			// remove the invalid chars anything aside from ASCII printable characters 
			// and enter
			convertedString = stringToUpdate.replaceAll('[^ -~\n]', replacementStr);
			// remove the line breaks
			convertedString = convertedString.replace('\\r\\n', ' ');
			//ExLog.add('exceptionLog test majid', 'StudFirst_Utilities', 'convertTo7BitAcceptedString' , 'testtttt: ' + convertedString);
		}
		return convertedString;
	}
}