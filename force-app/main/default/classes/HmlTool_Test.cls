/**
 * Unit tests for HmlTool
 *
 * @author Tom Gangemi
 * @date 2023-06-09
 * @group Test
 * @revision
 *     2023-06-09 - Tom Gangemi - Initial Version
 **/
@IsTest(IsParallel=true)
private class HmlTool_Test {

    /**
     * Test rendering a broken template - Validates error handling and consistency in rendering
     */
    @IsTest
    static void testBrokenTemplate() {
        // arrange template
        String text = '{{TopSection}}\n' +
            '{{#if False1}}Will Render This {{MidSection}}\n'+
            '{{#unless False1}}Also This{{/unless}}';

        // arrange context
        HmlTool.Context cont = new HmlTool.Context(new Map<String, Object>{
            'TopSection' => 'TOP',
            'MidSection' => 'MID',
            'False1' => false
        });

        // act - attempt a validation
        String[] errors = HmlTool.validateTemplate(text);

        // assert
        Assert.areEqual(1, errors.size(), 'Expected 1 error');
        Assert.isTrue(errors[0].startsWith(HmlTool.ERR_MISSING_END_BLOCK), 'Expected missing end block error');

        // act - render
        String result = cont.render(text);

        // assert
        Assert.isTrue(result.startsWith('TOP\n'), result);
        Assert.isTrue(result.contains('Will Render This MID\n'), result);
        Assert.isFalse(result.contains('{{#if False1}}'), result);
        Assert.isTrue(result.endsWith('Also This'), result);
    }

    /**
     * Test a mix of conditionals and merge fields - Renders a template and compares it with expected output
     */
    @IsTest
    static void testMixed() {
        // arrange template
        String text = 'Some text to test {{{Apex.TopSection}}}\nLine After\n' +
            '{{#if Contact.DSS_Registered__c}}Contact <strong>is</strong> DSS registered\n{{Apex.obc}}{{/if}}' +
            '{{#if Apex.False1}}THIS_IS_NOT_EXPECTED{{else}}--{{Contact.Birthdate}}--{{/if}}' +
            '{{#if Apex.True1}}THIS_IS_EXPECTED{{/if}}\n' +
            'End: {{Apex.Wot}}';

        // arrange context
        Map<String, Object> apexVals = new Map<String, Object>{
            'TopSection' => 'THIS IS & TOP',
            'Wot' => 'Wot & Val',
            'obc' => 'Newlines\npreserved\n',
            'True1' => true,
            'False1' => false
        };
        Date birthdate = Date.newInstance(1989, 12, 04);
        Map<String, Object> context = new Map<String, Object>{
            'Contact' => new Contact(
                DSS_Registered__c=true, Birthdate=birthdate
            ).getPopulatedFieldsAsMap(),
            'Apex' => apexVals
        };
        HmlTool.Context cont = new HmlTool.Context(context);

        // act - render
        String result = cont.render(text, true);

        // assert
        Assert.isTrue(result.startsWith('Some text to test THIS IS & TOP\nLine After\n'), result);
        Assert.isTrue(result.contains('Contact <strong>is</strong> DSS registered\n'+apexVals.get('obc')), result);
        Assert.isTrue(result.contains('--'+String.valueOf(birthdate)+'--'), result);
        Assert.isTrue(result.contains('THIS_IS_EXPECTED'), result);
        Assert.isFalse(result.contains('THIS_IS_NOT_EXPECTED'), result);
        Assert.isTrue(result.endsWith('End: Wot &amp; Val'), result);
    }

    /**
     * Test merge fields - Renders a template and compares it with expected output (includes a nested template)
     */
    @IsTest
    static void testMergeFields() {
        // arrange template
        String template =
            'Hello {{Recipient.FirstName}} {{Recipient.LastName}}, {{Apex.SpiderPreference}}' +
            '{{Apex.SpiderPreference}} {{Apex.BankPensStolen}} {{Apex.EnrollmentDate}} {{Apex.NotMerged}}' +
            ', {{Apex.Nested.Context}}, {{NestedTemplate}} {{{Recipient.FirstName}}}';

        // arrange context
        HmlTool.Context cont = new HmlTool.Context();
        cont.addMergeVar('Recipient', new Contact(
            FirstName = 'Troy', LastName = 'Barnes', Birthdate = Date.newInstance(1989, 12, 04))
        );
        cont.addMergeVar('Apex', new Map<String, Object>{
            'SpiderPreference' => 'hate',
            'BankPensStolen' => 1,
            'EnrollmentDate' => Date.newInstance(2009, 02, 20),
            'Nested' => new Map<String, Object>{'Context' => 'NestedThing'},
            'Foo' => 'Bar'
        });
        cont.addMergeVar('NestedTemplate', 'Foo=={{Apex.Foo}}');

        // act - render
        String result = cont.render(template, true);

        // assert
        Assert.areEqual('Hello Troy Barnes, hatehate 1 2009-02-20 {{Apex.NotMerged}}, NestedThing, Foo==Bar Troy', result);
    }

    /**
     * Test conditional expressions - Includes if, else, unless. Also tests implicit boolean conversion
     */
    @IsTest
    static void testConditionalsExpressions() {
        // arrange context for use across multiple renders
        HmlTool.Context cont = new HmlTool.Context();
        cont.addMergeVar('Recipient', new Contact(DSS_Registered__c = true));
        cont.addMergeVar('Case_Unit_Attempt__c', new Case_Unit_Attempt__c(Complex_Assignment_Indicator__c = false));
        cont.addMergeVar('Apex', new Map<String, Boolean>{
            'OlderThan10Days' => true,
            'FalseVal' => false
        });
        cont.addMergeVar('NumCondTrue', 1);
        cont.addMergeVar('NumCondFalse', 0);
        cont.addMergeVar('StringCondTrue', 'Hiya');
        cont.addMergeVar('StringCondFalse', '');
        cont.addMergeVar('DateTrue', Date.today());

        // arrange template (if)
        String templateStr1 =
            'FirstLine\nStartStuff{{#if Recipient.DSS_Registered__c}}DSS=True{{/if}}' +
            '{{#if Recipient.Some_Other_Field__c}}OtherField=True{{/if}}' +
            '{{#if Contact.FirstName}}NoName{{/if}}';
        // act - render
        String result1 = cont.render(templateStr1);
        // assert
        Assert.areEqual('FirstLine\nStartStuffDSS=True', result1);

        // arrange template (if & unless)
        String templateStr2 =
            'FirstLine\nStartStuff{{#if Apex.OlderThan10Days}}<b>This is old</b>.\n{{/if}}'+
            '{{#unless Apex.FalseVal}}Expected{{/unless}}';
        // act - render
        String result2 = cont.render(templateStr2);
        // assert
        Assert.isTrue(result2.contains('<b>This is old</b>.\n'), result2);
        Assert.isTrue(result2.endsWith('Expected'), result2);

        // arrange template (if & else)
        String templateStr3 =
            'FirstLine\nStartStuff{{#if Recipient.DSS_Registered__c}}DSS=True{{/if}}' +
            '{{#if Apex.OlderThan10Days}}This is old{{/if}}--' +
            '{{#if Apex.OlderThan10Days}}Again{{/if}}--' +
            '{{#if Case_Unit_Attempt__c.Complex_Assignment_Indicator__c}}Is Complex{{else}}Not Complex{{{Merge.Field}}}{{/if}}';
        // act - render
        String result3 = cont.render(templateStr3, true);
        // assert
        Assert.areEqual('FirstLine\nStartStuffDSS=TrueThis is old--Again--Not Complex{{{Merge.Field}}}', result3);

        // arrange template (if with implicit boolean conversion)
        String templateStr4 =
            '{{#if NumCondTrue}}A{{/if}}-' +
            '{{#if NumCondFalse}}B{{/if}}-' +
            '{{#if StringCondTrue}}{{{StringCondTrue}}}{{/if}}-' +
            '{{#if StringCondFalse}}Nope{{/if}}-' +
            '{{#if DateTrue}}Z{{/if}}';
        // act - render
        String result4 = cont.render(templateStr4, true);
        // assert
        Assert.areEqual('A--Hiya--Z', result4);
    }

    /**
     * Test each (loop) expressions - Including 'this' keyword
     */
    @IsTest
    static void testEachExpressions() {
        // arrange template
        String templateStr =
            'Start of output---\n' +
            'People:\n{{#each People}}' +
            '{{this.Name}} ({{this.Age}}){{{NL}}}' +
            '{{/each}}\n' +
            'Numbers:{{#each Apex.Numbers}} {{this}}{{/each}}\n' +
            '---End of output';

        // arrange context
        HmlTool.Context cont = new HmlTool.Context();
        List<Map<String,Object>> people = new List<Map<String,Object>>{
            new Map<String,Object>{'Name' => 'Troy', 'Age' => 20},
            new Map<String,Object>{'Name' => 'Abed', 'Age' => 21},
            new Map<String,Object>{'Name' => 'Annie', 'Age' => 19}
        };
        cont.addMergeVar('People', people);
        cont.addMergeVar('Apex', new Map<String,Object>{'Numbers' => new Integer[]{0,1,1,2,3,5,8,13}});
        cont.addMergeVar('NL', '\n');

        // act - render
        String result = cont.render(templateStr);

        // assert
        Assert.isTrue(result.contains('Troy (20)\nAbed (21)\nAnnie (19)'), result);
        Assert.isTrue(result.endsWith('Numbers: 0 1 1 2 3 5 8 13\n---End of output'), result);
    }

    /**
     * Test nested context values - i.e. that dot notation works
     */
    @IsTest
    static void testContextData() {
        // arrange
        Contact cont = new Contact(FirstName='Troy', LastName='Barnes');
        Case cse = new Case(Subject='Test Case');
        HmlTool.Context context = new HmlTool.Context(cont);
        context.addMergeVar('Case', cse);
        context.addMergeVar('Nested', new Map<String, Object>{
            'Level1' => new Map<String,Object>{'Level2'=>'NestedThing'}
        });

        // act/assert
        Assert.areEqual(cont.FirstName, context.getValue('FirstName'));
        Assert.areEqual(cse.Subject, context.getValue('Case.Subject'));
        Assert.areEqual('NestedThing', context.getValue('Nested.Level1.Level2'));
        Assert.isNull(context.getValue('Nested.Level1.NotFound'));
    }
}