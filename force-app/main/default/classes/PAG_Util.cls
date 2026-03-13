public with sharing class PAG_Util {
    public static String compositeKey(String moid, String type, String subType, String context){
        return String.join(new List<String>{
            (moid==null?'':moid.trim().toUpperCase()),
            (type==null?'':type.trim()),
            (subType==null?'':subType.trim()),
            (context==null?'':context.trim().toUpperCase())
        }, '|');
    }
    public static String mintMoID(){
        Blob b = Crypto.generateAesKey(128);
        return 'MOID-' + EncodingUtil.convertToHex(b).substring(0,24).toUpperCase();
    }
}