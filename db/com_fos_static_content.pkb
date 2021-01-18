create or replace package body com_fos_static_content
as

-- =============================================================================
--
--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)
--
--  This is a refreshable version of the Static Content Region.
--
--  License: MIT
--
--  GitHub: https://github.com/foex-open-source/fos-static-content
--
-- =============================================================================

--------------------------------------------------------------------------------
-- local function to expand shortcuts of static regions
-- if p_string contains "SHORTCUT_NAME" it will be replaced by its value.
--------------------------------------------------------------------------------
function expand_shortcuts
  ( p_string in varchar2
  )
return varchar2
is
    l_result     varchar2(32000) := p_string;
    l_shortcut   varchar2(32000);
    l_authorized boolean;
begin
    for cSC in
      ( select '"'||shortcut_name||'"' as shortcut_name
             , shortcut_type
             , shortcut
             , build_option
             , condition_type
             , condition_expression1
             , condition_expression2
          from apex_application_shortcuts
         where application_id = :APP_ID
      )
    loop

        if instr(l_result,cSC.shortcut_name) > 0
        then
            -- we found a shortcut, now process its value according to its type
            l_authorized :=
               apex_plugin_util.is_component_used
                 ( p_build_option_id         => cSC.build_option
                 , p_condition_type          => cSC.condition_type
                 , p_condition_expression1   => cSC.condition_expression1
                 , p_condition_expression2   => cSC.condition_expression2
                 , p_authorization_scheme_id => null
                 );

            if l_authorized
            then
                l_shortcut := case cSC.shortcut_type
                                  when 'HTML_TEXT'           then cSC.shortcut
                                  when 'HTML_TEXT_ESCAPE_SC' then apex_escape.html(cSC.shortcut)
                                  when 'IMAGE'               then sys.htf.img(cSC.shortcut)
                                  -- single quote becomes escaped single quote
                                  when 'TEXT_ESCAPE_JS'      then replace(cSC.shortcut, chr(39), chr(92) || chr(39))
                                  when 'MESSAGE'             then apex_lang.message(cSC.shortcut)
                                  when 'MESSAGE_ESCAPE_JS'   then replace(apex_lang.message(cSC.shortcut), chr(39), chr(92) || chr(39))
                                  when 'FUNCTION_BODY'       then apex_plugin_util.get_plsql_function_result(cSC.shortcut)
                              end
                ;
            else
                l_shortcut := null;
            end if;
        end if;
        --
        l_result := replace(l_result,cSC.shortcut_name,l_shortcut);
    end loop;
    --
    return l_result;
end expand_shortcuts;

--------------------------------------------------------------------------------
-- process the static region, print out its content and pass a json config
-- object to the client (necessary for refresh)
--------------------------------------------------------------------------------
function render
  ( p_region              apex_plugin.t_region
  , p_plugin              apex_plugin.t_plugin
  , p_is_printer_friendly boolean
  )
return apex_plugin.t_region_render_result
as
    l_return apex_plugin.t_region_render_result;

    -- read plugin parameters and store in local variables
    l_region_id            varchar2(4000)             := p_region.static_id;
    l_wrapper_id           varchar2(4000)             := l_region_id || '_FOS_WRAPPER';
    l_ajax_identifier      varchar2(4000)             := apex_plugin.get_ajax_identifier;
    l_raw_content          p_region.attribute_01%type := p_region.attribute_01;
    l_escape_item_values   boolean                    := p_region.attribute_06 = 'Y';
    l_local_refresh        boolean                    := p_region.attribute_07 = 'Y';

    c_options              apex_t_varchar2            := apex_string.split(p_region.attribute_15, ':');
    l_expand_shortcuts     boolean                    := 'expand-shortcuts'             member of c_options;
    l_exec_plsql           boolean                    := 'execute-plsql-before-refresh' member of c_options;
    l_sanitize_content     boolean                    := 'sanitize-content'             member of c_options;

    l_skip_substitutions   boolean                    := nvl(p_region.attribute_08, 'N') = 'Y';
    l_lazy_load            boolean                    := nvl(p_region.attribute_11, 'N') = 'Y';
    l_lazy_refresh         boolean                    := nvl(p_region.attribute_12, 'N') = 'Y';
    l_escape_content       boolean                    := nvl(p_region.attribute_14, 'N') = 'Y';

    -- Javascript Initialization Code
    l_init_js_fn           varchar2(32767)            := nvl(apex_plugin_util.replace_substitutions(p_region.init_javascript_code), 'undefined');

    -- page items to submit settings
    l_items_to_submit       varchar2(4000)            := apex_plugin_util.page_item_names_to_jquery(p_region.attribute_02);

    -- spinner settings
    l_show_spinner          boolean                   := p_region.attribute_05 != 'N';
    l_show_spinner_overlay  boolean                   := p_region.attribute_05 like '%_OVERLAY';
    l_spinner_position      varchar2(4000)            :=
        case
            when p_region.attribute_05 like 'ON_PAGE%'   then 'body'
            when p_region.attribute_05 like 'ON_REGION%' then '#' || l_region_id
            else null
        end;

    l_content               varchar2(32767);
begin
    -- standard debugging intro, but only if necessary
    if apex_application.g_debug
    then
        apex_plugin_util.debug_region
          ( p_plugin => p_plugin
          , p_region => p_region
          );
    end if;

    -- conditionally load the DOMPurify library
    if l_sanitize_content then
        apex_javascript.add_library
          ( p_name       => 'purify#MIN#'
          , p_directory  => p_plugin.file_prefix || 'js/dompurify/2.2.6/'
          , p_key        => 'fos-purify'
          );
    end if;

    -- a wrapper is needed to properly identify and replace the content in case of a refresh
    htp.p('<div id="' || apex_escape.html_attribute(l_wrapper_id) || '">');

    -- if required, we expand shortcuts in the raw-content
    if l_expand_shortcuts
    then
        l_raw_content := expand_shortcuts(l_raw_content);
    end if;

    -- ouput the static content, unless lazy-loading or clientside-refresh is activated
    if not l_local_refresh and
       not l_lazy_load
    then
        if l_skip_substitutions
        then
            l_content := l_raw_content;
        else
            -- output the static region content and make sure all substitution variables are replaced
            l_content := apex_plugin_util.replace_substitutions
                 ( p_value  => l_raw_content
                 , p_escape => l_escape_item_values
                 );
        end if;

        l_content := case when l_escape_content then apex_escape.html(l_content) else l_content end;

        if not l_sanitize_content then
            sys.htp.p(l_content);
        end if;
    end if;

    --closing the wrapper
    sys.htp.p('</div>');

    -- create a json object holding the region configuration
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write('ajaxIdentifier'     , l_ajax_identifier      );
    apex_json.write('regionId'           , l_region_id            );
    apex_json.write('regionWrapperId'    , l_wrapper_id           );
    apex_json.write('itemsToSubmit'      , l_items_to_submit      );
    apex_json.write('showSpinner'        , l_show_spinner         );
    apex_json.write('showSpinnerOverlay' , l_show_spinner_overlay );
    apex_json.write('spinnerPosition'    , l_spinner_position     );
    apex_json.write('rawContent'         , l_raw_content          );
    apex_json.write('escape'             , l_escape_item_values   );
    apex_json.write('localRefresh'       , l_local_refresh        );
    apex_json.write('lazyLoad'           , l_lazy_load            );
    apex_json.write('lazyRefresh'        , l_lazy_refresh         );
    apex_json.write('sanitizeContent'    , l_sanitize_content     );
    if not l_local_refresh and not l_lazy_load and l_sanitize_content then
        apex_json.write_raw('DOMPurifyConfig', '{}');
        apex_json.write('initialContent' , l_content              );
    end if;
    apex_json.close_object;

    -- initialization code for the region widget. needed to handle the refresh event
    apex_javascript.add_onload_code('FOS.region.staticContent(this, ' || apex_json.get_clob_output|| ', '|| l_init_js_fn || ');');

    apex_json.free_output;

    return l_return;
end render;

--------------------------------------------------------------------------------
-- called when region should be refreshed and returns the static content.
-- additionally it is possible to run some plsql code before the static content
-- is evaluated
--------------------------------------------------------------------------------
function ajax
  ( p_region apex_plugin.t_region
  , p_plugin apex_plugin.t_plugin
  )
return apex_plugin.t_region_ajax_result
as
    -- plug-in attributes
    l_raw_content          p_region.attribute_01%type := p_region.attribute_01;
    l_escape_item_values   boolean                    := p_region.attribute_06 = 'Y';

    c_options              apex_t_varchar2            := apex_string.split(p_region.attribute_15, ':');
    l_expand_shortcuts     boolean                    := 'expand-shortcuts'             member of c_options;
    l_exec_plsql           boolean                    := 'execute-plsql-before-refresh' member of c_options;
    l_sanitize_content     boolean                    := 'sanitize-content'             member of c_options;

    l_skip_substitutions   boolean                    := nvl(p_region.attribute_08, 'N') = 'Y';
    l_exec_plsql_code      p_region.attribute_09%type := p_region.attribute_09;

    l_items_to_return      p_region.attribute_13%type := p_region.attribute_13;
    l_escape_content       boolean                    := p_region.attribute_14 = 'Y';
    l_item_names           apex_t_varchar2;

    -- resulting content
    l_content              clob                       := '';

    l_return               apex_plugin.t_region_ajax_result;
begin
    -- standard debugging intro, but only if necessary
    if apex_application.g_debug
    then
        apex_plugin_util.debug_region
          ( p_plugin => p_plugin
          , p_region => p_region
          );
    end if;

    -- if required, execute plsql to perform some page item calculations
    if l_exec_plsql
    then
        apex_exec.execute_plsql(p_plsql_code => l_exec_plsql_code);
    end if;

    -- if required, we expand shortcuts in the raw-content
    if l_expand_shortcuts
    then
        l_raw_content := expand_shortcuts(l_raw_content);
    end if;

    -- generate content
    l_content :=
         case
             when l_skip_substitutions then
                 l_raw_content
             else
                 apex_plugin_util.replace_substitutions
                   ( p_value  => l_raw_content
                   , p_escape => l_escape_item_values
                   )
         end;

    l_content := case when l_escape_content then apex_escape.html(l_content) else l_content end;

    apex_json.open_object;
    apex_json.write('status' , 'success');
    apex_json.write('content', l_content);

    -- adding info about the page items to return
    if l_items_to_return is not null
    then
        l_item_names := apex_string.split(l_items_to_return,',');

        apex_json.open_array('items');

        for l_idx in 1 .. l_item_names.count
        loop
            apex_json.open_object;
            apex_json.write
              ( p_name  => 'id'
              , p_value => l_item_names(l_idx)
              );
            apex_json.write
              ( p_name  => 'value'
              , p_value => apex_util.get_session_state(l_item_names(l_idx))
              );
            apex_json.close_object;
        end loop;

        apex_json.close_array;
    end if;
    apex_json.close_object;

    return l_return;
end ajax;

end;
/


