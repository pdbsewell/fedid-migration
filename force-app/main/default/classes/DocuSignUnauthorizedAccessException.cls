/**
 * @description Exception that is thrown when DocuSign denies access
 * @group DocuSign Exceptions
 * @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added a default method
 */
public class DocuSignUnauthorizedAccessException extends Exception {
    public static String getDefaultMessage() {
        return 'DocuSignUnauthorizedAccessException';
    }
}