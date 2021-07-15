/* globals apex,$ */

var FOS = window.FOS || {};
FOS.region = FOS.region || {};

/**
 * Initialization function for the static content region.
 * This function must be run for the region to subscribe to the refresh event
 * Expects as parameter an object with the following attributes:
 *
 * @param {object}  daContext                      The context Object passed by APEX to dynamic actions
 * @param {object}  config                         Configuration object holding all attributes
 * @param {string}  config.regionId                The main region ID. The region on which "refresh" can be triggered
 * @param {string}  config.regionWrapperId         ID of wrapper element. The contents of this element will be replaced with the new content
 * @param {string}  [config.itemsToSubmit]         Comma-separated page item names in jQuery selector format
 * @param {boolean} [config.suppressChangeEvent]   If there are page items to be returned, this decides whether to trigger a change event or not
 * @param {boolean} [config.showSpinner]           Shows a spinner or not
 * @param {boolean} [config.showSpinnerOverlay]    Depends on showSpinner. Adds a translucent overlay behind the spinner
 * @param {string}  [config.spinnerPosition]       Depends on showSpinner. A jQuery selector unto which the spinner will be shown
 * @param {string}  config.rawContent              The raw content string
 * @param {boolean} config.escape                  Whether to escape the values of referenced items
 * @param {boolean} config.localRefresh            Fetch the new content from the DB, or replace substitutions locally?
 * @param {boolean} [config.sanitizeContent]       Whether to pass the content through DOMPurify
 * @param {object}  [config.DOMPurifyConfig]       Additional options to be passed to DOMPurify. Sanitize Content must be enabled.
 * @param {string}  [config.initialContent]        The initial content to be applied shown if sanitizeContent is enabled and lazyLoad is disabled
 */
FOS.region.staticContent = function (daContext, config, initFn) {
    var context = daContext || this,
        el$;

    var pluginName = 'FOS - Static Content';
    apex.debug.info(pluginName, config, initFn);

    // Allow the developer to perform any last (centralized) changes using Javascript Initialization Code setting
    if (initFn instanceof Function) {
        initFn.call(context, config);
    }

    el$ = config.el$ = $('#' + config.regionId);

    // implementing the apex.region interface in order to respond to refresh events
    apex.region.create(config.regionId, {
        type: 'fos-region-static-content',
        refresh: function () {
            if (config.isVisible || !config.lazyRefresh) {
                FOS.region.staticContent.refresh.call(context, config);
            } else {
                config.needsRefresh = true;
            }
        },
        option: function (name, value) {
            var whiteListOptions = ['showSpinner'];
            var argCount = arguments.length;
            if (argCount === 1) {
                return config[name];
            } else if (argCount > 1) {
                if (name && value && whiteListOptions.includes(name)) {
                    config[name] = value;
                } else if (name && !whiteListOptions.includes(name)) {
                    apex.debug.warn('you are trying to set an option that is not allowed: ' + name);
                }
            }
        }
    });

    // apply sanitized content
    if(config.sanitizeContent && config.initialContent){
        var content = DOMPurify.sanitize(config.initialContent, config.DOMPurifyConfig || {});
        $('#' + config.regionWrapperId).html(content);
    }

    // if we refresh locally then we need to substitute them on page render
    if (config.localRefresh) {
        apex.region(config.regionId).refresh();
    }
    // check if we need to lazy load the region
    else if (config.lazyLoad) {
        apex.widget.util.onVisibilityChange(el$[0], function (isVisible) {
            config.isVisible = isVisible;
            if (isVisible && (!config.loaded || config.needsRefresh)) {
                apex.region(config.regionId).refresh();
                config.loaded = true;
                config.needsRefresh = false;
            }
        });
        apex.jQuery(window).on('apexreadyend', function () {
            // we add avariable reference to avoid loss of scope
            var el = el$[0];
            // we have to add a slight delay to make sure apex widgets have initialized since (surprisingly) "apexreadyend" is not enough
            setTimeout(function () {
                apex.widget.util.visibilityChange(el, true);
            }, config.visibilityCheckDelay || 1000);
        });
    }
};

FOS.region.staticContent.refresh = function (config) {
    var elem$ = $('#' + config.regionWrapperId);
    var rawContent = config.rawContent;
    var escape = config.escape;
    var loadingIndicatorFn;

    //configures the showing and hiding of a possible spinner
    if (config.showSpinner) {
        loadingIndicatorFn = (function (position, showOverlay) {
            var fixedOnBody = position == 'body';
            return function (pLoadingIndicator) {
                var overlay$;
                var spinner$ = apex.util.showSpinner(position, { fixed: fixedOnBody });
                if (showOverlay) {
                    overlay$ = $('<div class="fos-region-overlay' + (fixedOnBody ? '-fixed' : '') + '"></div>').prependTo(position);
                }
                function removeSpinner() {
                    if (overlay$) {
                        overlay$.remove();
                    }
                    spinner$.remove();
                }
                //this function must return a function which handles the removing of the spinner
                return removeSpinner;
            };
        })(config.spinnerPosition, config.showSpinnerOverlay);
    }
    // trigger our before refresh event(s)
    var eventCancelled = apex.event.trigger('apexbeforerefresh', '#' + config.regionId, config);
    if (eventCancelled) {
        apex.debug.warn('the refresh action has been cancelled by the "apexbeforerefresh" event!');
        return false;
    }
    // we can either replace the substitution strings locally (but only with items on this page or the global page)
    // or fetch the updated content from the database
    if (config.localRefresh) {
        elem$.html(apex.util.applyTemplate(rawContent, {
            defaultEscapeFilter: escape ? 'HTML' : 'RAW'
        }));
        // trigger our after refresh event(s)
        apex.event.trigger('apexafterrefresh', '#' + config.regionId, config);
    } else {
        apex.server.plugin(config.ajaxIdentifier, {
            pageItems: config.itemsToSubmit
        }, {
            //needed to trigger before and after refresh events on the region
            refreshObject: '#' + config.regionId,
            //this function is reponsible for showing a spinner
            loadingIndicator: loadingIndicatorFn,
            success: function (data) {
                //setting page item values
                if (data.items) {
                    for (var i = 0; i < data.items.length; i++) {
                        apex.item(data.items[i].id).setValue(data.items[i].value, null, config.suppressChangeEvent);
                    }
                }
                //replacing the old content with the new
                var content = data.content;
                if(config.sanitizeContent){
                    content = DOMPurify.sanitize(content, config.DOMPurifyConfig || {});
                }
                $('#' + config.regionWrapperId).html(content);
                // trigger our after refresh event(s)
                apex.event.trigger('apexafterrefresh', '#' + config.regionId, config);
            },
            //omitting an error handler lets apex.server use the default one
            dataType: 'json'
        });
    }
};

