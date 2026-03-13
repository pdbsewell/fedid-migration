/**
 * @author          mac.domingo@monash.edu
 * @description		EPCP-2899 - Enquiry Archiving Framework. This is the wrapper class that will hold the records information and custom metadata information
 * @date            18-08-2023
 * @group			Platforms
 * @revision
 *		2023-17-08	-	Mac Domingo		-	Created
 *		2025-12-03	-	Jackie Ho 		-	Added readyToArchive
 *		2025-17-08	-	Sachin Shetty	-	Added Constructor
*/
public class IterableWrapper {
    //The actual record obtained from the SOQL
    public SObject objRecord;
    //The sObject name 
    public String objectName;
    //Value from the Archiving Settings custom metadata - no of years to archive
    public Integer yrsToArchive;
    //Value from the Archiving Settings custom metadata - no of years to purge
    public Integer yrsToPurge;   
    //Value for Archive status
    public Boolean readyToArchive;
    
    // Default constructor
    public IterableWrapper() {} //NOPMD
}