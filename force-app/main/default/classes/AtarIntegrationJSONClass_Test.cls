/*****************************************************************************************************************
* @author      : Sethu Venna
* @date        : 12/03/2025
* @description : Test class for AtarIntegrationJSONClass
* @revision    : 12/03/2025 - Initial Version
*****************************************************************************************************************/
@IsTest(isParallel=true)
public class AtarIntegrationJSONClass_Test {
    
    @IsTest
    public static void testParse() {
        String json = '{'+
        '  \"qualifications\": {'+
        '    \"verificationStatus\": \"string\",'+
        '    \"score\": {'+
        '      \"value\": 20'+
        '    },'+
        '    \"institution\": {'+
        '      \"institutionCode\": \"string\",'+
        '      \"institutionName\": \"string\"'+
        '    },'+
        '    \"statusKey\": \"string\",'+
        '    \"conferredYear\": 2020,'+
        '    \"type\": {'+
        '      \"state\": \"string\",'+
        '      \"name\": \"string\",'+
        '      \"type\": \"string\"'+
        '    }'+
        '  }'+
        '}';
        AtarIntegrationJSONClass obj = AtarIntegrationJSONClass.parse(json);
        Assert.areNotEqual(null, obj);
    }
}