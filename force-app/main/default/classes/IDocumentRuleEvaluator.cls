/*
 *    IOperand : Interface that describes how the document rule checker should act
 *    @group Interfaces
 */
public interface IDocumentRuleEvaluator {
    Boolean evaluateCriteria(SObject evaluatedObject);
}