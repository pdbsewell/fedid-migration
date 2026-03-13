/*
 * @author Martin Cadman
 * @date   23-09-2019
 * @description Subscribed trigger to the IbdEncumbrance__e platform event
 *
 * @revision
 * 24.09.2019 Martin Cadman - Initial version <br/>
 * 25.05.2020 Martin Cadman - Added try catch <br/>
 *
 */
trigger IbdEncumbranceTrigger on IbdEncumbrance__e (after insert) {
    
    new Triggers() 
        .bindExtended(Triggers.Evnt.afterInsert, new IbdEncumbranceServices.EventHandler())
        .execute();
    
}