/**
 * @description Exception that is thrown when an operation requested is not 
 * supported
 * @group Exceptions
 * @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added a default method
 */
public class UnsupportedOperationException extends Exception {
    public static String getDefaultMessage() {
        return 'UnsupportedOperationException';
    }
}