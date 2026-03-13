/**
 * This class chain a list of promises
 * @revision
 *  AUG.31.2022     Nick Guia   - Renamed Promise interface to IPromise 
 */ 
public virtual inherited sharing class PromiseChain{
    @TestVisible Map<Type,SObject[]> promises = new Map<Type,SObject[]>();

    /**
     * Add a sobject to a promise
     * @param  className type fo the classes
     * @param  record    target sobject to add to promise
     * @return           this promise chain
     */
    public virtual PromiseChain then(Type className, SObject record){
        if (className != null){
            if (this.promises.get(className) == null){
                this.promises.put(className, new SObject[0]);
            }
            this.promises.get(className).add(record);
        }
        return this;
    }
    /**
     * This method execute all promises in the chain.
     * @return   this primise chain
     */
    public virtual PromiseChain execute(){
        for (Type t : this.promises.keySet()){
            ((IPromise)t.newInstance()).init().execute(this.promises.get(t));
        }
        return this;
    }
}