/* Use the following template to add new format helpers.
 *
 * The example adds a helper called upper that make the value all caps.

window.Em.Application.initializer({
    name: "oxi-localconfig",
    initialize: function(container, application) {
        var formatHelper = application.OxivalueFormatComponent;

        formatHelper.reopen({
            addHelpers: function() {
                this.set("types.upper", function(v) {
                    return v.toUpperCase();
                });
            }.on("init")
        });
    }
});

 */