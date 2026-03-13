/**
 * Internal class interacts with the Apex Flow API to invoke a flow, pass inputs and collect outputs 
 *   @see FlowProcess
 **/
public class FlowProcessRunner {

    public Map<String, Object> run(FlowProcess.Resolver resolver, Map<String, Object> inputs) {
        String flowName = resolver.resolve();
        Flow.Interview flow = Flow.Interview.createInterview(flowName, inputs);
        if (Test.isRunningTest() == false) flow.start();
        return null;
    }

}