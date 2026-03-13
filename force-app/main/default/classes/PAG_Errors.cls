public with sharing class PAG_Errors {
    // Must end with 'Exception' per Apex rules
    public class ValidationException extends Exception {}

    private class ApiError { public String error; public String message; }
    public static String toJson(String code, String msg){
        ApiError e = new ApiError(); e.error = code; e.message = msg;
        return JSON.serialize(e);
    }
}