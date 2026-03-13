/**
 * @author : [Babyshark]
 * @description : Utility class for AES256 encryption for Abroad portal Urls
 * @group : Abroad Outbound
 * @date : 16/08/2024
 * @rev
 * 
 */ 
public with sharing class AOEncryptionUtil {
    /**
     * @description - Method returns encoded data for URL parameter
     * @revision    
     */
    public static String encrypt256(String key, String dataToEncrypt){
        Blob data = Blob.valueOf(dataToEncrypt);
        Blob encrypted = Crypto.encryptWithManagedIV ('AES256', EncodingUtil.base64Decode(key), data);
        String encodedDataText = EncodingUtil.convertToHex(encrypted);
        return encodedDataText;
    
    }
    /**
     * @description - Method returns decoded data for URL parameter
     * @revision    
     */
    public static String decrypt256(String key,String encryptedData){
        Blob decodedData = EncodingUtil.convertFromHex(encryptedData);
        Blob decrypted = Crypto.decryptWithManagedIV('AES256', EncodingUtil.base64Decode(key), decodedData);
        String decryptedString = decrypted.toString();
        return decryptedString;
    }
}