/**
 * @description A simple String templating processor
 * The templating processor uses {{placeholder}} to process placeholders into 
 * values
 * @group Templating
 */
public class StringTemplate {
    
    private String template;
    
    /**
     * @description Cosntructor which will setup the template
     * @param template The template string that requires processing
     */
    public StringTemplate(String template) {
        if (String.isBlank(template)) {
            throw new IllegalArgumentException('Template is required');
        } else {
            this.template = template;
        }
    }

    /**
     * @description Substitutes placeholders in the template with actual values
     * @param placeholder The placeholder that will be substituted. 
     * It should not start with {{ or end in }}. If the placeholder in the 
     * template is "{{name}}", this parameter should be "name"
     * @param value The value that should be substituted for the placeholder
     */
    public void substitute(String placeholder, String value) {
        
        if (String.isBlank(placeholder)) {
            throw new IllegalArgumentException(
                'Placeholder for templating is mandatory'
            );
        }

        if (!isPlaceHolderInTemplate(placeholder)) {
            throw new IllegalArgumentException(
                'Placeholder does not exist in template, cannot substitute'
            );
        }

        if (String.isBlank(value)) {
            throw new IllegalArgumentException(
                'Value must be provided'
            );
        }

        this.template = this.template.replace('{{' + placeholder + '}}', value);
    }

    /**
     * @description Renders the template with substitutions applied
     */
    public String render() {
        return this.template;
    }

    private boolean isPlaceHolderInTemplate(String placeholder) {
        if (this.template.contains('{{' + placeholder + '}}')) {
            return true;
        } else {
            return false;
        }
    }

}