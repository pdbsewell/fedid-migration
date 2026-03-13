@IsTest
private class PAG_Persona_Test {
    @IsTest static void ingestApplicantLifecycle_Test(){
        PAG_Events.lastPublished = null;

        String j1 = '{"messageType":"persona.state","producer":"banner","version":"v1",' +
            '"subject":{"sor":"banner","sorPersonId":"987654","moid":null},' +
            '"persona":{"type":"Applicant","subType":"cw","context":"BSCI"},' +
            '"occurredAt":"2025-02-01T10:12:00.000+10:00","recordedAt":"2025-02-01T10:12:05.000+10:00",' +
            '"state":{"value":"inReview","startDate":"2025-02-01T00:00:00.000+10:00","endDate":null,"reason":null,"ruleId":null},' +
            '"sequence":"banner:987654:2301","idempotencyKey":"k1"}';
        Test.startTest();
        PAG_PersonaService.Result r1 = PAG_PersonaService.ingest(j1);
        Test.stopTest();
        System.assertNotEquals(null, r1.personaId);
        System.assertNotEquals(null, PAG_Events.lastPublished, 'Expected MoID minted event to be published');
        System.assertEquals('banner', PAG_Events.lastPublished.PAG_SoR__c);
        System.assertEquals('987654', PAG_Events.lastPublished.PAG_SoRPersonId__c);
        System.assert(PAG_Events.lastPublished.PAG_MoID__c != null && PAG_Events.lastPublished.PAG_MoID__c.startsWith('MOID-'));

        String j2 = j1.replace('"inReview"','"offered"').replace('"k1"','"k2"').replace(':2301',':2401').replace('"2025-02-01"','"2025-02-15"');
        PAG_Events.lastPublished = null;
        PAG_PersonaService.Result r2 = PAG_PersonaService.ingest(j2);
        System.assertEquals(null, PAG_Events.lastPublished, 'No event expected (MoID not minted)');

        String j3 = j1.replace('"inReview"','"accepted"').replace('"k1"','"k3"').replace(':2301',':2450').replace('"2025-02-01"','"2025-02-20"');
        PAG_PersonaService.Result r3 = PAG_PersonaService.ingest(j3);

        String j4 = j1.replace('"inReview"','"closed"').replace('"k1"','"k4"').replace(':2301',':2500').replace('"2025-02-01"','"2025-03-01"');
        PAG_PersonaService.Result r4 = PAG_PersonaService.ingest(j4);

        String j5 = '{"messageType":"persona.state","producer":"banner","version":"v1",' +
            '"subject":{"sor":"banner","sorPersonId":"987654","moid":null},' +
            '"persona":{"type":"Student","subType":"cw","context":"BSCI"},' +
            '"occurredAt":"2025-03-01T09:00:00.000+10:00","recordedAt":"2025-03-01T09:00:05.000+10:00",' +
            '"state":{"value":"active","startDate":"2025-03-01T00:00:00.000+10:00","endDate":null,"reason":"enrolmentEffective","ruleId":"ENR-001"},' +
            '"sequence":"banner:987654:2501","idempotencyKey":"k5"}';
        PAG_PersonaService.Result r5 = PAG_PersonaService.ingest(j5);
        PAG_PersonaService.Result r5b = PAG_PersonaService.ingest(j5);
        System.assertEquals(null, r5b.personaId);

        PAG_Persona_Aggregation__c cur = [SELECT PAG_State__c FROM PAG_Persona_Aggregation__c WHERE PAG_Type__c='Applicant' LIMIT 1];
        System.assertEquals('closed', cur.PAG_State__c);
    }
}