@IsTest(IsParallel=true)
private class ChannelCountryCleanupBatch_Test {
    private static final String UK_ISO_NAME = 'United Kingdom';
    private static final String INDIA_ISO_NAME = 'India';

    @TestSetup
    private static void dataSetup() {
        List<Country_Attribute__c> countryAttributes = new List<Country_Attribute__c>();
        Country_Attribute__c wales = new Country_Attribute__c();
        wales.Name = 'Wales';
        wales.Callista_Code__c = '2106';
        wales.Callista_Country__c = 'Wales';
        wales.Country__c = UK_ISO_NAME;
        wales.GTE_Risk_Rating__c = '1';
        wales.ISO_Alpha_2__c = 'GB';
        wales.ISO_Alpha_3__c = 'GBR';
        wales.Numeric_Country_Code__c = '826';
        countryAttributes.add(wales);

        Country_Attribute__c india = new Country_Attribute__c();
        india.Name = 'India';
        india.Callista_Code__c = '7103';
        india.Callista_Country__c = 'India';
        india.Country__c = INDIA_ISO_NAME;
        india.GTE_Risk_Rating__c = '2';
        india.ISO_Alpha_2__c = 'IN';
        india.ISO_Alpha_3__c = 'IND';
        india.Numeric_Country_Code__c = '356';
        countryAttributes.add(india);

        insert countryAttributes;
    }

    /**
     * Scenario:
     * GIVEN the Line 4 values are found matches Callista_Country__c values in Country_Attribute__c records
     * WHEN the batch runs, it should find the corresponding Country__c values
     * THEN update the Country__c picklist
     */
    @IsTest
    private static void testCountryCleanup() {
        List<Channel__c> channelsToInsert = new List<Channel__c>();
        Channel__c channelIndia = new Channel__c();
        channelIndia.Email__c = 'example3234534@example.com';
        channelIndia.Street__c = '101 Some LANE';
        channelIndia.City__c = 'KOLKATA';
        channelIndia.State__c = 'WEST BENGAL';
        channelIndia.Post_Code__c = '700073';
        channelIndia.Country__c = null;
        channelIndia.Line_1__c = '101 Some LANE';
        channelIndia.Line_2__c = 'KOLKATA';
        channelIndia.Line_3__c = 'WEST BENGAL';
        channelIndia.Line_4__c = 'INDIA';
        channelIndia.Line_5__c = '';
        channelIndia.Start_Date__c = System.today();
        channelIndia.Is_Processed__c = true;
        channelIndia.Source_System__c = 'callista';
        channelIndia.Type__c = 'OS-HOME';
        channelsToInsert.add(channelIndia);

        Channel__c channelUK = new Channel__c();
        channelUK.Email__c = 'example4234234@example.com';
        channelUK.Street__c = '102 Some LANE';
        channelUK.City__c = 'SKEWEN';
        channelUK.State__c = 'NEATH PORT TALBOT';
        channelUK.Post_Code__c = 'SA10';
        channelUK.Country__c = null;
        channelUK.Line_1__c = '102 Some LANE';
        channelUK.Line_2__c = 'SKEWEN';
        channelUK.Line_3__c = 'NEATH PORT TALBOT';
        channelUK.Line_4__c = 'WALES';
        channelUK.Line_5__c = '';
        channelUK.Start_Date__c = System.today();
        channelUK.Is_Processed__c = true;
        channelUK.Source_System__c = 'callista';
        channelUK.Type__c = 'OS-HOME';
        channelsToInsert.add(channelUK);

        insert channelsToInsert;

        for (Channel__c channel : [SELECT Id, Name, Line_4__c, Country__c, Is_Processed__c FROM Channel__c]) {
            if (channel.Line_4__c.equals('INDIA') || channel.Line_4__c.equals('WALES')) {
                System.assert(channel.Country__c == null, 'Unexpected Country values inserted when setting up test data');
            }
            System.assert(channel.Is_Processed__c, 'Unexpected Is_Processed__c values inserted when setting up test data');
        }

        Test.startTest();
        ChannelCountryCleanupBatch batch = new ChannelCountryCleanupBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        for (Channel__c channel : [SELECT Id, Name, Line_4__c, Country__c, Is_Processed__c FROM Channel__c]) {
            if (channel.Line_4__c.equals('INDIA')) {
                System.assertEquals(INDIA_ISO_NAME, channel.Country__c, 'Failed to match country value: Line4 value of INDIA should translate to Country Picklist value of India');
            } else if (channel.Line_4__c.equals('WALES')) {
                System.assertEquals(UK_ISO_NAME, channel.Country__c, 'Failed to match country value: Line4 value of WALES should translate to Country Picklist value of United Kingdom');
            }
            System.assert(!channel.Is_Processed__c, 'Failed to update Is_Processed__c value');
        }
    }
}