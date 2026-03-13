/**
* @author Angelo Rivera
* @description Serves as utility class for creating test data for test classes
* @group Monash Connect
**/

@isTest
public with sharing class MonConTestDataFactory {
	/**
	* @description Default field for a new instance of an object. The test data factory will pick default fields base on object name.
	* @author Angelo Rivera
	* @param sObj any sobject
	* @return SObject
	* @example
	* Account account = (Account)MonConTestDataFactory.createSObject(new Account());
	*/
	public static SObject createSObject(SObject sObj) {
		// Check what type of object we are creating and add any defaults that are needed.
		String objectName = String.valueOf(sObj.getSObjectType());
		// Construct the default values class. Salesforce doesn't allow '__' in class names
		String defaultClassName = 'MonConTestDataFactorySettings.' + objectName.replaceAll('__(c|C)$|_', '') + 'Defaults';
		// If there is a class that exists for the default values, then use them
		if (Type.forName(defaultClassName) != null) {
			sObj = createSObject(sObj, defaultClassName);
		}
		return sObj;
	}
	/**
	* @description Default field for a new instance of an object with option to insert. The test data factory will pick default fields base on object name.
	* @author Angelo Rivera
	* @param sObj any sobject
	* @param doInsert insert record if option is true
	* @return SObject
	* @example
	* Account account = (Account)MonConTestDataFactory.createSObject(new Account(), true);
	*/
	public static SObject createSObject(SObject sObj, Boolean doInsert) {
		SObject retObject = createSObject(sObj);
		if (doInsert) {
			insert retObject;
		}
		return retObject;
	}
	/**
	* @description Override default field for a new instance of an object.
	* @author Angelo Rivera
	* @param sObj any sobject
	* @param defaultClassName name of the overrride default class
	* @return SObject
	* @example
	* Account account = (Account)MonConTestDataFactory.createSObject(new Account(), 'MyPartnerAccountDefault');
	*/
	public static SObject createSObject(SObject sObj, String defaultClassName) {
		// Create an instance of the defaults class so we can get the Map of field defaults
		Type t = Type.forName(defaultClassName);
		if (t == null) {
			throw new TestFactoryException('Invalid defaults class.');
		}
		MonConTestDataFactorySettings.FieldDefaults defaults = (MonConTestDataFactorySettings.FieldDefaults)t.newInstance();
		addFieldDefaults(sObj, defaults.getFieldDefaults());
		return sObj;
	}
	/**
	* @description Override default field for a new instance of an object with insert.
	* @author Angelo Rivera
	* @param sObj any sobject
	* @param defaultClassName name of the overrride default class
	* @param doInsert insert record if option is true
	* @return SObject
	* @example
	* Account account = (Account)MonConTestDataFactory.createSObject(new Account(), 'MyPartnerAccountDefault');
	*/
	public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
		SObject retObject = createSObject(sObj, defaultClassName);
		if (doInsert) {
			insert retObject;
		}
		return retObject;
	}
	/**
	* @description Default fields for list of records. The test data factory will pick default fields base on object name.
	* @author Angelo Rivera
	* @param sObj any sobject
	* @param numberOfObjects number of instances if that object type to create
	* @return SObject[]
	* @example
	* Account[] accounts = (Account[])MonConTestDataFactory.createSObjectList(new Account(), 200);
	*/
	public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects) {
		return createSObjectList(sObj, numberOfObjects, (String)null);
	}
	/**
	* @description Default fields for list of records with insert option. The test data factory will pick default fields base on object name.
	* @author Angelo Rivera
	* @param sObj any sobject
	* @param numberOfObjects number of instances if that object type to create
	* @param doInsert insert record if option is true
	* @return SObject[]
	* @example
	* Account[] accounts = (Account[])MonConTestDataFactory.createSObjectList(new Account(), 200,true);
	*/
	public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
		SObject[] retList = createSObjectList(sObj, numberOfObjects, (String)null);
		if (doInsert) {
			insert retList;
		}
		return retList;
	}
	/**
	* @description Override default fields for list of records with insert option.
	* @author Angelo Rivera
	* @param sObj any sobject
	* @param numberOfObjects number of instances if that object type to create
	* @param defaultClassName name of the overrride default class
	* @param doInsert insert record if option is true
	* @return SObject[]
	* @example
	* Account[] accounts = (Account[])MonConTestDataFactory.createSObjectList(new Account(), 200, 'MyPartnerAccountDefault', true);
	*/
	public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
		SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
		if (doInsert) {
			insert retList;
		}
		return retList;
	}
	/**
	* @description Override default fields for list of records.
	* @author Angelo Rivera
	* @param sObj any sobject
	* @param numberOfObjects number of instances if that object type to create
	* @param defaultClassName name of the overrride default class
	* @return SObject[]
	* @example
	* Account[] accounts = (Account[])MonConTestDataFactory.createSObjectList(new Account(), 200, 'MyPartnerAccountDefault');
	*/
	public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
		SObject[] sObjs = new SObject[] {};

		// Get one copy of the object
		SObject newObj = defaultClassName == null ? createSObject(sObj) : createSObject(sObj, defaultClassName);

		// Get the name field for the object
		String nameField = MonConTestDataFactorySettings.nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
		if (nameField == null) {
			nameField = 'Name';
		}
		Boolean nameIsAutoNumber = sObj.getSObjectType().getDescribe().fields.getMap().get(nameField).getDescribe().isAutoNumber();
		// Clone the object the number of times requested. Increment the name field so each record is unique
		for (Integer i = 0; i < numberOfObjects; i++) {
			SObject clonedSObj = newObj.clone(false, true);
			if (nameIsAutoNumber == false){ //if auto number don't set field, i.e.: Name
				clonedSObj.put(nameField, (String)clonedSObj.get(nameField) + ' ' + i);
			}
			sObjs.add(clonedSObj);
		}
		return sObjs;
	}

	private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
		// Loop through the map of fields and if they weren't specifically assigned, fill them.
		for (Schema.SObjectField field : defaults.keySet()) {
			if (sObj.isSet(field) == false) {
				sObj.put(field, defaults.get(field));
			}
		}
	}

	public class TestFactoryException extends Exception {}
}