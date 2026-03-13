/**
 * Promise interface that can be use in Promise chain context
 */ 
public interface IPromise {
    /**
     * This method replace a constructor as Type newInstance doesn't callempty constructor. 
     * @return this Promise
     */
    IPromise init();
    /**
     * Main execute method for a promise
     * @param list of sobject record to execute. 
     */
    void execute(SObject[] records);
}