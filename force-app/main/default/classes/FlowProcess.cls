/**
 * Manages the execution and interfacing of runtime resolved Flows in Apex
 *   - Fluent syntax for configuration and self documenting usage (output parameter expectations)
 *   - Resolution of the named Flow to execute as expressed via Custom Metadata (Admin configurable)
 *   - Required Flow output parameter checking
 **/
public class FlowProcess {

    private Resolver resolver = null;

    private Map<String, Object> inputs = new Map<String, Object>();
    public FlowProcess() { }

    /**
     * Run the given Flow
     **/
    public FlowProcess named(String flowName) {
        resolver = new ResolveByName(flowName);
        return this;
    }

    /**
     * Pass the following parameter to the Flow
     **/
    public FlowProcess with(String variableName, Object variableValue) {
        inputs.put(variableName, variableValue);
        return this;
    }

    /**
     * Runs the Flow configured by this process
     **/
    public void run() {
        if(resolver==null) {
            throw new FlowProcessException('You must call the named method before calling the run method.');
        } 
        runner.run(resolver, inputs);
    }

    /**
     * Default runner used to create and execute Flows in memory
     **/
    private static FlowProcessRunner runner = new FlowProcessRunner();

    /**
     * Enable the ability to mock Flow executions, by mocking the Runner class via Apex Stub API
     **/
    @TestVisible
    private static void setMock(FlowProcessRunner mockRunner) {
        runner = mockRunner;
    }

    /**
     * Encapsulates the act of resolving the Flow to use for this process
     **/
    public abstract class Resolver {
        public abstract String resolve();
    }

    /**
     * Resolves a given Flow by name
     **/
    public class ResolveByName extends Resolver {
        public String flowName {get; private set;}
        private ResolveByName(String flowName) { this.flowName = flowName; }
        public override String resolve() { return flowName; }
    }

    public class FlowProcessException extends Exception {}
}