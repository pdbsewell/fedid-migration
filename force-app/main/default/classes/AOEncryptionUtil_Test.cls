/**
 * @author : [Babyshark]
 * @description : Test class for AOEncryptionUtil
 * @group : Abroad Outbound
 * @date : 16/08/2024
 * @rev
 * 
 */ 
@isTest(isParallel=true)
private class AOEncryptionUtil_Test {
    /*
     * test encryption and decryption
	*/
	@isTest
    static void testencryptdecrypt256(){
        //Given - Key and data is presewnt for encryption
        Blob keyb = Crypto.generateAesKey(256);
        String key = EncodingUtil.base64Encode(keyb);
        String data = 'This is data for 256 encryption';
        String encrypteddata = AOEncryptionUtil.encrypt256(key, data);
        //When - Encryption happens teh data is 256 encrypted
        Assert.isNotNull(encrypteddata, 'Encryption was not successful');
        //Then - Post decrypting the data actual data is retrieved
        String decryptedData = AOEncryptionUtil.decrypt256(key, encrypteddata);
        Assert.areEqual(data, decryptedData, 'Encrypted Data mismatch post decryption');
    }

}