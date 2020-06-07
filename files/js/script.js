window.FOS = window.FOS || {};
FOS.region = FOS.region || {};
FOS.region.staticContent = FOS.region.staticContent || {};

/*
 * Initialization function for the dynamic content region.
 * This function must be run for the region to subscribe to the refresh event
 * Expects as parameter an object with the following attributes:
 *
 * @param {Object}  daContext               The context Object passed by APEX to dynamic actions
 * @param {Object}  config                  Configuration object holding all attributes
 * @param {string}  config.regionId         The main region ID. The region on which "refresh" can be triggered
 * @param {string}  config.regionWrapperId  ID of wrapper element. The contents of this element will be replaced with the new content
 * @param {string}  config.rawContent       The raw content string
 * @param {boolean} config.escape           Whether to escape the values of referenced items
*/

FOS.region.staticContent.init = function(daContext, config){

    apex.debug.info('FOS - Static Content', config);

    var elem$ = $('#' + config.regionWrapperId);
    var rawContent = config.rawContent;
    var escape = config.escape;

    // implementing the apex.region interface in order to respond to refresh events
    apex.region.create(config.regionId, {
        type: 'fos-region-static-content-content',
        refresh: function(){
            elem$.html(apex.util.applyTemplate(rawContent, {
                defaultEscapeFilter: escape ? 'HTML' : 'RAW'
            }));
        }
    });
};


