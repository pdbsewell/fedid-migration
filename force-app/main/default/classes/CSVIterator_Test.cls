/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
public class CSVIterator_Test {
	static testMethod void testErrorFreeExecution() {
        Test.startTest();
        
        CSVIterator instance = new CSVIterator('a,b', 'a');
        instance.hasNext();
        instance.next();
        instance.Iterator();

        Test.stopTest();
    }
}