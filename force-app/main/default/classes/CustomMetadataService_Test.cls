@isTest
public class CustomMetadataService_Test {
    @isTest static void test_getAllWithDeveloperName(){
        Map<String,Fee_Category_Pricebook_Mapping__mdt>  ex1 = (Map<String,Fee_Category_Pricebook_Mapping__mdt>) CustomMetadataService.getAll(Fee_Category_Pricebook_Mapping__mdt.sObjectType);
        System.assert(ex1 != null && ex1.isEmpty() == false, 'Returned a map of all Fee_Category_Pricebook_Mapping__mdt in the system using developer name as key.');
    }
    @isTest static void test_getInstanceWithDeveloperName(){
        Fee_Category_Pricebook_Mapping__mdt  ex2 = (Fee_Category_Pricebook_Mapping__mdt) CustomMetadataService.getInstance(Fee_Category_Pricebook_Mapping__mdt.sObjectType,'AU_DOM');
        System.assert(ex2 != null, 'Returned a Offers instance of Fee_Category_Pricebook_Mapping__mdt');
    }
    @isTest static void test_getInstanceWithCustomKey(){    
        Fee_Category_Pricebook_Mapping__mdt  ex3 = (Fee_Category_Pricebook_Mapping__mdt) CustomMetadataService.getInstance(Fee_Category_Pricebook_Mapping__mdt.sObjectType,Fee_Category_Pricebook_Mapping__mdt.DeveloperName,'AU_DOM');
        System.assert(ex3 != null, 'Returned a Offers instance of Fee_Category_Pricebook_Mapping__mdt.');
    }

    @isTest static void testgetDocusignEnvelopSettings(){    
        SystemSettingWrapper.DocusignEnvelopSetting envelopSetting = CustomMetadataService.getDocusignEnvelopSettings('DOCUSIGN_ENVELOP_SETTING', 'Offers');
        System.assert(envelopSetting != null , 'Expected a parsed envelop settings to be returned');
    }
    @isTest static void testgetDocusignTabs(){    
        Map<String,SystemSettingWrapper.DocusignTab> returnMap = CustomMetadataService.getDocusignTabs('DOCUSIGN_TAB_OFFERS');
        System.assert(returnMap != null && returnMap.isEmpty() == false, 'Expected a parsed docusign tab map to be returned');
    }
}