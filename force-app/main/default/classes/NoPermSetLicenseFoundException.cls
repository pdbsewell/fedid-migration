/**
 * @description Exception when Permission Set Licenses cannot be found 
 * @group Permission Set Licenses
 * @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added a default method
 */
public class NoPermSetLicenseFoundException extends Exception {
    public static String getDefaultMessage() {
        return 'NoPermSetLicenseFoundException';
    }
}