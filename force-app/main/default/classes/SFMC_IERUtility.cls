/**
 * @author       : Ibrahim Rumi
 * @date         : 03-07-2023
 * @group        : SFMC
 * @description  : Individual Email Result Utility/Helper methods
**/
public class SFMC_IERUtility {  
    
    //Fetching the default SFMC custom setting
    public static et4ae5__ET4AE_Config__c defaultSettings {
        get {
            if(defaultSettings == null) {
                defaultSettings = et4ae5__ET4AE_Config__c.getOrgDefaults();
            }
            return defaultSettings;
        } set;
    }
    
    //header containing the algorythm and the type of token passed
    private static final Map<String, Object> header = new Map<String, Object>{
            'typ' => 'JWT',
            'alg' => 'HS256'
        };
            
    //method to generate the email preview url
    //@param: et4ae5__IndividualEmailResult__c(Individual Email Result Record)
    public static String generateEmailPreviewUrl(et4ae5__IndividualEmailResult__c ier){
        
        //fetch the sfmc cloudpage url stored in the sfmc custom setting
        String emailPreviewUrl = String.valueof(defaultSettings.get('IER_Util_URL__c'));
        String encodedJWT = generateJWT(ier);

        String finalURL = emailPreviewUrl+'?id='+encodedJWT;
		system.debug('efrgt---'+finalURL);
        return finalURL;
    }

    //method to generate the email the JWT
    public static string generateJWT(et4ae5__IndividualEmailResult__c ier) {
        
        //fetch the private key stored in the sfmc custom setting 
        String secretKey = String.valueof(defaultSettings.get('IER_Util_Key__c'));
        
        String encodedHeader = encode(blob.valueof(toJson(header)));
      	String encodedPayload = generateEncodedIERPayload(ier);
        String encodedSignature = generateEncodedSignature(encodedHeader,encodedPayload,secretKey);
       
        String encodedJWT = generateEncodedJWT(encodedHeader,encodedPayload,encodedSignature);
        
        return encodedJWT;
    }
    
    //Wrapper class to generate the parameters passed to SFMC
    public class IERWrapper{
        public String jobid {get; set;}
        public String subId {get; set;}
        public String listId {get; set;}
        public String batchId {get; set;}
        
        public IERWrapper(et4ae5__IndividualEmailResult__c ier){
            jobid = String.valueOf(ier.et4ae5__JobId__c);
            subId = String.valueOf(ier.et4ae5__SubscriberId__c);
            listId = String.valueOf(ier.et4ae5__ListId__c);
            batchId = String.valueOf(ier.et4ae5__BatchId__c);
        }
        
    }
    
    //method to convert an object to string
    //@param: object
    public static string toJson(Object obj){
        return JSON.serialize(obj);
    }
    
    //method to base64 encode the passed string and remove junk characters
    //@param: blob
    public static string encode(Blob b){
        String encodedStr = EncodingUtil.base64Encode(b).replace('+', '-').replace('/', '_').replace('=', '');
        return encodedStr;
    }
    
	//Method to generate the encoded ier payload
	@testVisible
    private static String generateEncodedIERPayload(et4ae5__IndividualEmailResult__c ier){

        IERWrapper ierwrap = new IERWrapper(ier);
        String encodedIer = encode(Blob.valueOf(toJson(ierwrap)));

        return encodedIer;
    }
    
    //Method to generate an encoded signature
    @testVisible
    private static String generateEncodedSignature(String encodedHeader, String encodedPayload, String secretKey){
        
        Blob signatureBlob = Crypto.generateMac('hmacSHA256', Blob.valueOf(encodedHeader + '.' + encodedPayload), Blob.valueOf(secretKey));
        String signature = encode(signatureBlob);
        
        return signature;
    }
    
    //method to generate an encoded jwt
    @testVisible
    private static String generateEncodedJWT(String encodedHeader, String encodedPayload, String encodedSignature){
        String JWT = encodedHeader + '.' + encodedPayload + '.' + encodedSignature;
        String encodedJWT = EncodingUtil.base64Encode(Blob.valueOf(JWT));
        
        return encodedJWT;
    }
    
}