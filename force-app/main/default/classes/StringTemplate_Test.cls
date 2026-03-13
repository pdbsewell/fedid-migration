/**
 * @description Test class for StringTemplate
 */
@isTest(isParallel=true)
public class StringTemplate_Test {
    
    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenConstructorTemplateIsEmpty() {

        try {
            StringTemplate template = new StringTemplate('');
            System.assert(false, 
                'Expected IllegalArgumentException due to blank constructor input');
        } catch(IllegalArgumentException e) {
            System.assert(true, 
                'Expected IllegalArgumentException due to blank constructor input');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException due to blank constructor input');
        }

    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenPlaceholderIsBlank() {
        try {
            StringTemplate template = new StringTemplate('hello {{name}}');
            template.substitute('', 'John Smith');
            System.assert(false, 
                'Expected IllegalArgumentException due to blank placeholder input');
        } catch(IllegalArgumentException e) {
            System.assert(true, 
                'Expected IllegalArgumentException due to blank placeholder input');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException due to blank placeholder input');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenPlaceholderDoesNotExistInTemplate() {
        try {
            StringTemplate template = new StringTemplate('hello {{name}}');
            template.substitute('lastName', 'John Smith');
            System.assert(false, 
                'Expected IllegalArgumentException because placeholder does not exist in template');
        } catch(IllegalArgumentException e) {
            System.assert(true, 
                'Expected IllegalArgumentException because placeholder does not exist in template');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException because placeholder does not exist in template');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenValueForSubstituteIsEmpty() {
        try {
            StringTemplate template = new StringTemplate('hello {{name}}');
            template.substitute('name', '');
            System.assert(false, 
                'Expected IllegalArgumentException because value for substitute is empty');
        } catch(IllegalArgumentException e) {
            System.assert(true, 
                'Expected IllegalArgumentException because value for substitute is empty');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException because value for substitute is empty');
        }
    }

    @isTest
    static void shouldSubstituteValueWhenThereNoTextAfterPlaceholder() {
        StringTemplate template = new StringTemplate('hello {{name}}');
        template.substitute('name', 'world');
        String result = template.render();

        System.assertEquals('hello world'
            , result, 'Expected template to render message correctly');
    }

    @isTest
    static void shouldSubstituteValueWhenThereNoTextBeforePlaceholder() {
        StringTemplate template = new StringTemplate('{{greeting}} world');
        template.substitute('greeting', 'hello');
        String result = template.render();

        System.assertEquals('hello world'
            , result, 'Expected template to render message correctly');
    }

    @isTest
    static void shouldSubstituteValueWhenThereIsWhiteSpaceAroundPlaceholder() {
        StringTemplate template = new StringTemplate('hello {{name}} - how are you?');
        template.substitute('name', 'John');
        String result = template.render();

        System.assertEquals('hello John - how are you?'
            , result, 'Expected template to render message correctly');
    }

    @isTest
    static void shouldSubstituteValueWhenThereIsNoWhiteSpaceAroundPlaceholder() {
        StringTemplate template = new StringTemplate('mailto:{{username}}@test.com');
        template.substitute('username', 'support');
        String result = template.render();

        System.assertEquals('mailto:support@test.com'
            , result, 'Expected template to render message correctly');
    }

    @isTest
    static void shouldSubstituteValuesWhenTwoPlaceholdersExistInTemplate() {
        StringTemplate template = new StringTemplate('Dear {{name}}, we need you {{name}} to contact us.');
        template.substitute('name', 'John Smith');
        String result = template.render();

        System.assertEquals('Dear John Smith, we need you John Smith to contact us.'
            , result, 'Expected template to render message correctly');
    }

    @isTest
    static void shouldSubstituteValuesWhenTwoDifferentPlaceholdersExistInTemplate() {
        StringTemplate template = new StringTemplate('Dear {{name}}, we need you to call {{phone}}.');
        template.substitute('name', 'John Smith');
        template.substitute('phone', '131000');
        String result = template.render();

        System.assertEquals('Dear John Smith, we need you to call 131000.'
            , result, 'Expected template to render message correctly');
    }

    @isTest
    static void shouldSubstituteOneValueWhenOneOfTwoPlaceholderBracketIsWrong() {
        StringTemplate template = new StringTemplate('hello {{name}} {name}}');
        template.substitute('name', 'world');
        String result = template.render();

        System.assertEquals('hello world {name}}'
            , result, 'Expected template to render message correctly');
    }

    @isTest
    static void shouldSubstituteValueWhenThereAreExtraBrackets() {
        StringTemplate template = new StringTemplate('hello {{{name}}}');
        template.substitute('name', 'world');
        String result = template.render();

        System.assertEquals('hello {world}'
            , result, 'Expected template to render message correctly');
    }
}