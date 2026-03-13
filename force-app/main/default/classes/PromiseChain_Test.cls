/**
 * Test Class for PromiseChain
 * @author David Browaeys
 * @revision
 *  AUG.31.2022     Nick Guia   - Renamed Promise interface to IPromise 
 */
@isTest
public with sharing class PromiseChain_Test {
    @isTest
    public static void testChain(){
        PromiseChain chain = new PromiseChain();
        chain.then(TestMockService.class, new Account());
        chain.execute();
        System.assert(chain.promises.get(TestMockService.class).size() > 0, 'Test Mock should have one record');
    }
    public with sharing class TestMockService implements IPromise {
        public IPromise init(){
            return this;
        }
    
        public void execute(SObject[] records){
            System.debug(records);
        }
    }
}