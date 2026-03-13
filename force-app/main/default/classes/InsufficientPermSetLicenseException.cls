/**
 * @description Exception when there are insufficient Permission Set Licenses 
 * @group Permission Set Licenses
 * @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added a default method
 */
public class InsufficientPermSetLicenseException extends Exception {
    public static String getDefaultMessage() {
        return 'InsufficientPermSetLicenseException';
    }
}