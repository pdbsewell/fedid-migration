/**
 * @description       : Common Utility Class - ERDA
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 05-05-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class CommonUtilityERDA {
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}