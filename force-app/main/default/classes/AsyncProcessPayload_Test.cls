/**
 * @File Name          : AsyncProcessPayload_Test.cls
 * @Description        : Test class for AsyncProcessPayload
 * @Author             : Nick Guia
 * @Group              : Commons
 **/
@IsTest(isParallel=true)
private class AsyncProcessPayload_Test {

    /**
     * @description test method for putting map of parameters
     *  in the payload <key> : parameter name <value> : parameter value
     */
	@IsTest
	static void testPutMap() {
		AsyncProcessPayload payload;
		//initialise a map of string which contains the key, and parameter value
		Map<String, String> paramMap = new Map<String, String> {
			'param1' => 'class parameter value1',
			'param2' => 'class parameter value2'
		};

		Test.startTest();

		payload = new AsyncProcessPayload();
		payload.put(paramMap);

		Test.stopTest();

		Assert.isNotNull (payload.args, 'Null value found for payload args');
		Assert.isTrue (!payload.args.isEmpty(), 'Empty value found for payload args');
	}

    /**
     * @description test method for adding a single 
     *  value (key and value) to payload args 
     */
	@IsTest
	static void testPut() {
		AsyncProcessPayload payload;

		Test.startTest();

		payload = new AsyncProcessPayload();
		payload.put('paramKey', 'paramValue');

		Test.stopTest();

		Assert.isNotNull (payload.args, 'Null value found for payload args');
		Assert.isTrue (!payload.args.isEmpty(), 'Empty value found for payload args');
	}

    /**
     * @description get map of existing
     *  payload args
     */
	@IsTest
	static void testGetArgs() {
		AsyncProcessPayload payload;
		Map<String, Object> payloadArgs = new Map<String, Object>();
		String key = 'paramKey';
		String val = 'paramValue';

		Test.startTest();

		payload = new AsyncProcessPayload();
		payload.put(key, val);
		payloadArgs = payload.getArgs();

		Test.stopTest();

		String argVal = (String) payloadArgs.get('paramKey');
		Assert.areEqual(val, argVal, 'Received an unexpected value from AsyncProcessPayload.getArgs()');
	}

    /**
     * @description get value of existing payload
     *  args based on key
     */
	@IsTest
	static void testGet() {
		AsyncProcessPayload payload;
		String key = 'paramKey';
		String val = 'paramValue';
		String argVal;

		Test.startTest();

		payload = new AsyncProcessPayload();
		payload.put(key, val);
		argVal = (String) payload.get(key);

		Test.stopTest();

		Assert.areEqual(val, argVal, 'Received an unexpected value from AsyncProcessPayload.get()');
	}

    /**
     * @description test serialize the payload args.
     *  assert by deserializing untyped
     */
	@IsTest
	static void testSerialize() {
		AsyncProcessPayload payload;
		String key = 'paramKey';
		String val = 'paramValue';
		String sJson;

		Test.startTest();

		payload = new AsyncProcessPayload();
		payload.put(key, val);
		sJson = payload.serialize();

		Test.stopTest();

		Map<String, Object> args = new Map<String, Object>();
		try {
			args = (Map<String, Object>) JSON.deserializeUntyped(sJson);
			Assert.isNotNull (args, 'Null value found for deserialized JSON');
			Assert.isTrue (!args.isEmpty(), 'Empty value found for deserialized JSON');
		} catch(Exception e) {
			Assert.isFalse (false, 'Something went wrong while trying to deserialize JSON');
		}
	}

    /**
     * @description test deserialize the payload args.
     *  assert by making sure payload args are intact
     *  after deserializing
     */
	@IsTest
	static void testDeserialize() {
		AsyncProcessPayload payload;
		AsyncProcessPayload newPayloadDeserialized;
		String key = 'paramKey';
		String val = 'paramValue';
		String sJson;

		Test.startTest();

		payload = new AsyncProcessPayload();
		payload.put(key, val);
		sJson = payload.serialize();
		newPayloadDeserialized = AsyncProcessPayload.deserialize(sJson);

		Test.stopTest();

		Assert.isNotNull (newPayloadDeserialized.args, 'Payload args was not deserialized');
        Assert.isTrue (!newPayloadDeserialized.args.isEmpty(), 'Payload args was not deserialized');
    }
}