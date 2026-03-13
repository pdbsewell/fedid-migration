public class TSP_EventsToBlockAsync implements TxnSecurity.EventCondition, TxnSecurity.AsyncCondition {
    public boolean evaluate(SObject event) {
        return new TSP_EventsToBlock().evaluate(event);
    }
}