/**
 * @File Name          : AsyncProcessPayload.cls
 * @Description        : Class Payload for Platform Event Invocable classes (Async_Process__e)
 * @Author             : Nick Guia
 * @Group              : Commons
 * @Usage
 * 	AsyncProcessPayload payload = new AsyncProcessPayload();
 * 			Set<Id> contactIds = new Set<Id>{[VALUES]}
 *			payload.put('contactIds', contactIds);
 *			Async_Process__e ap = new Async_Process__e (
 *				Process_Name__c = 'EmailServices.CalculatePrimary',
 *				Parameter__c = payload.serialize()
 *				);
 *           EventBus.publish(ap);
 * 	This example will execute EmailServices.CalculatePrimary class
 * 	and providing the contactIds parameter in the payload
 **/
public virtual class AsyncProcessPayload {
    @TestVisible
    protected Map<String, Object> args;

    public AsyncProcessPayload() {
        this.args = new Map<String,Object>();
    }

    /**
     * @description add a map collection of args in the current map
     * 	WHERE:
     * 		key = key of the class parameter
     * 		param = any primitive data type as a value
     */
    public void put(Map<String, Object> params) {
        for(String key : params.keySet()) {
            this.put(key, params.get(key));
        }
    }

    /**
     * @description add a value in the args map
     * 	WHERE:
     * 		key = key of the class parameter
     * 		param = any primitive data type as a value
     */
    public void put(String key, Object param) {
        this.args.put(key, param);
    }

    /**
     * @description returns all the captured args
     * 	in this class instance as a map
     */
    public Map<String, Object> getArgs() {
        return this.args;
    }

    /**
     * @description get the value of the args
     * 	expectation for key value is the name of
     * 	the parameter variable of the client class
     */
    public Object get(String key) {
        return this.args.get(key);
    }

    /**
     * @description serialize and return all the captured
     * 	args in this class instance.
     */
    public String serialize() {
        return JSON.serialize(this.args);
    }

    /**
     * @description provided that generic objects i.e. Map<String, Object> args
     * 	could not be deserialized into strict types, we're gonna have to reinitialize
     * 	this class with a deserialized untyped args, then return the new instance of
     * 	AsyncProcessPayload class instead.
     */
    public static AsyncProcessPayload deserialize(String serialized) {
        AsyncProcessPayload payload = new AsyncProcessPayload();
        payload.args = (Map<String, Object>) JSON.deserializeUntyped(serialized);
        return payload;
    }
}