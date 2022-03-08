prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_190200 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2019.10.04'
,p_release=>'19.2.0.00.18'
,p_default_workspace_id=>1620873114056663
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'FOS_MASTER_WS'
);
end;
/

prompt APPLICATION 102 - FOS Dev - Plugin Master
--
-- Application Export:
--   Application:     102
--   Name:            FOS Dev - Plugin Master
--   Exported By:     FOS_MASTER_WS
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 61118001090994374
--     PLUGIN: 134108205512926532
--     PLUGIN: 1039471776506160903
--     PLUGIN: 547902228942303344
--     PLUGIN: 217651153971039957
--     PLUGIN: 412155278231616931
--     PLUGIN: 1389837954374630576
--     PLUGIN: 461352325906078083
--     PLUGIN: 13235263798301758
--     PLUGIN: 216426771609128043
--     PLUGIN: 37441962356114799
--     PLUGIN: 1846579882179407086
--     PLUGIN: 8354320589762683
--     PLUGIN: 50031193176975232
--     PLUGIN: 106296184223956059
--     PLUGIN: 35822631205839510
--     PLUGIN: 2674568769566617
--     PLUGIN: 183507938916453268
--     PLUGIN: 14934236679644451
--     PLUGIN: 2600618193722136
--     PLUGIN: 2657630155025963
--     PLUGIN: 284978227819945411
--     PLUGIN: 56714461465893111
--     PLUGIN: 98648032013264649
--     PLUGIN: 455014954654760331
--     PLUGIN: 98504124924145200
--     PLUGIN: 212503470416800524
--   Manifest End
--   Version:         19.2.0.00.18
--   Instance ID:     250144500186934
--

begin
  -- replace components
  wwv_flow_api.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/region_type/com_fos_static_content
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(14934236679644451)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.FOS.STATIC_CONTENT'
,p_display_name=>'FOS - Static Content'
,p_supported_ui_types=>'DESKTOP:JQM_SMARTPHONE'
,p_javascript_file_urls=>'#PLUGIN_FILES#js/script#MIN#.js'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- =============================================================================',
'--',
'--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)',
'--',
'--  This is a refreshable version of the Static Content Region.',
'--',
'--  License: MIT',
'--',
'--  GitHub: https://github.com/foex-open-source/fos-static-content',
'--',
'-- =============================================================================',
'',
'--------------------------------------------------------------------------------',
'-- local function to expand shortcuts of static regions',
'-- if p_string contains "SHORTCUT_NAME" it will be replaced by its value.',
'--------------------------------------------------------------------------------',
'function expand_shortcuts',
'  ( p_string in varchar2',
'  )',
'return varchar2',
'is',
'    l_result     varchar2(32000) := p_string;',
'    l_shortcut   varchar2(32000);',
'    l_authorized boolean;',
'begin',
'    for cSC in',
'      ( select ''"''||shortcut_name||''"'' as shortcut_name',
'             , shortcut_type',
'             , shortcut',
'             , build_option',
'             , condition_type',
'             , condition_expression1',
'             , condition_expression2',
'          from apex_application_shortcuts',
'         where application_id = :APP_ID',
'      )',
'    loop',
'',
'        if instr(l_result,cSC.shortcut_name) > 0',
'        then',
'            -- we found a shortcut, now process its value according to its type',
'            l_authorized :=  ',
'               apex_plugin_util.is_component_used',
'                 ( p_build_option_id         => cSC.build_option',
'                 , p_condition_type          => cSC.condition_type',
'                 , p_condition_expression1   => cSC.condition_expression1',
'                 , p_condition_expression2   => cSC.condition_expression2',
'                 , p_authorization_scheme_id => null',
'                 );',
'                 ',
'            if l_authorized ',
'            then',
'                l_shortcut := case cSC.shortcut_type',
'                                  when ''HTML_TEXT''           then cSC.shortcut',
'                                  when ''HTML_TEXT_ESCAPE_SC'' then apex_escape.html(cSC.shortcut)',
'                                  when ''IMAGE''               then sys.htf.img(cSC.shortcut)',
'                                  -- single quote becomes escaped single quote',
'                                  when ''TEXT_ESCAPE_JS''      then replace(cSC.shortcut, chr(39), chr(92) || chr(39))',
'                                  when ''MESSAGE''             then apex_lang.message(cSC.shortcut)',
'                                  when ''MESSAGE_ESCAPE_JS''   then replace(apex_lang.message(cSC.shortcut), chr(39), chr(92) || chr(39))',
'                                  when ''FUNCTION_BODY''       then apex_plugin_util.get_plsql_function_result(cSC.shortcut)',
'                              end',
'                ;',
'            else',
'                l_shortcut := null;',
'            end if;',
'        end if;',
'        --',
'        l_result := replace(l_result,cSC.shortcut_name,l_shortcut);',
'    end loop;',
'    --',
'    return l_result;',
'end expand_shortcuts;',
'',
'--------------------------------------------------------------------------------',
'-- process the static region, print out its content and pass a json config',
'-- object to the client (necessary for refresh)',
'--------------------------------------------------------------------------------',
'function render',
'  ( p_region              apex_plugin.t_region',
'  , p_plugin              apex_plugin.t_plugin',
'  , p_is_printer_friendly boolean',
'  )',
'return apex_plugin.t_region_render_result',
'as',
'    l_return apex_plugin.t_region_render_result;',
'',
'    -- read plugin parameters and store in local variables',
'    l_region_id            varchar2(4000)             := p_region.static_id;',
'    l_wrapper_id           varchar2(4000)             := l_region_id || ''_FOS_WRAPPER'';',
'    l_ajax_identifier      varchar2(4000)             := apex_plugin.get_ajax_identifier;',
'    l_source               p_region.source%type       := p_region.source;',
'    l_text                 p_region.attribute_01%type := p_region.attribute_01;',
'    l_escape_item_values   boolean                    := p_region.attribute_06 = ''Y'';',
'    l_local_refresh        boolean                    := p_region.attribute_07 = ''Y'';',
'    ',
'    c_options              apex_t_varchar2            := apex_string.split(p_region.attribute_15, '':'');',
'    l_expand_shortcuts     boolean                    := ''expand-shortcuts''             member of c_options;',
'    l_exec_plsql           boolean                    := ''execute-plsql-before-refresh'' member of c_options;',
'    l_sanitize_content     boolean                    := ''sanitize-content''             member of c_options;',
'',
'    l_skip_substitutions   boolean                    := nvl(p_region.attribute_08, ''N'') = ''Y'';',
'    l_lazy_load            boolean                    := nvl(p_region.attribute_11, ''N'') = ''Y'';',
'    l_lazy_refresh         boolean                    := nvl(p_region.attribute_12, ''N'') = ''Y'';   ',
'    l_escape_content       boolean                    := nvl(p_region.attribute_14, ''N'') = ''Y'';   ',
'',
'    -- Javascript Initialization Code',
'    l_init_js_fn           varchar2(32767)            := nvl(apex_plugin_util.replace_substitutions(p_region.init_javascript_code), ''undefined'');',
'    ',
'    -- page items to submit settings',
'    l_items_to_submit       varchar2(4000)            := apex_plugin_util.page_item_names_to_jquery(p_region.attribute_02);',
'    ',
'    -- spinner settings',
'    l_show_spinner          boolean                   := p_region.attribute_05 != ''N'';',
'    l_show_spinner_overlay  boolean                   := p_region.attribute_05 like ''%_OVERLAY'';',
'    l_spinner_position      varchar2(4000)            :=',
'        case ',
'            when p_region.attribute_05 like ''ON_PAGE%''   then ''body'' ',
'            when p_region.attribute_05 like ''ON_REGION%'' then ''#'' || l_region_id',
'            else null',
'        end;',
'        ',
'    -- preparing for moving the region-source into the native attribute',
'    -- the plug-in attribute will be removed in 22.0',
'    -- for now, both is available',
'    l_raw_content           varchar2(32767)           := case when l_source is null then l_text else l_source end;',
'    l_content               varchar2(32767);',
'begin',
'    -- standard debugging intro, but only if necessary',
'    if apex_application.g_debug and substr(:DEBUG,6) >= 6',
'    then',
'        apex_plugin_util.debug_region',
'          ( p_plugin => p_plugin',
'          , p_region => p_region',
'          );',
'    end if;',
'',
'    -- conditionally load the DOMPurify library',
'    if l_sanitize_content then',
'        apex_javascript.add_library ',
'          ( p_name       => ''purify#MIN#''',
'          , p_directory  => p_plugin.file_prefix || ''js/dompurify/2.2.6/''',
'          , p_key        => ''fos-purify''',
'          );',
'    end if;',
'',
'    -- a wrapper is needed to properly identify and replace the content in case of a refresh',
'    htp.p(''<div id="'' || apex_escape.html_attribute(l_wrapper_id) || ''">'');',
'    ',
'    -- if required, we expand shortcuts in the raw-content',
'    if l_expand_shortcuts',
'    then',
'        l_raw_content := expand_shortcuts(l_raw_content);',
'    end if;',
'',
'    -- ouput the static content, unless lazy-loading or clientside-refresh is activated',
'    if not l_local_refresh and ',
'       not l_lazy_load ',
'    then',
'        if l_skip_substitutions ',
'        then',
'            l_content := l_raw_content;',
'        else',
'            -- output the static region content and make sure all substitution variables are replaced',
'            l_content := apex_plugin_util.replace_substitutions',
'                 ( p_value  => l_raw_content',
'                 , p_escape => l_escape_item_values',
'                 );',
'        end if;',
'        ',
'        l_content := case when l_escape_content then apex_escape.html(l_content) else l_content end;',
'',
'        if not l_sanitize_content then ',
'            sys.htp.p(l_content);',
'        end if;',
'    end if;',
'                                                                          ',
'    --closing the wrapper',
'    sys.htp.p(''</div>'');',
'    ',
'    -- create a json object holding the region configuration',
'    apex_json.initialize_clob_output;',
'',
'    apex_json.open_object;',
'    apex_json.write(''ajaxIdentifier''     , l_ajax_identifier      );',
'    apex_json.write(''regionId''           , l_region_id            );',
'    apex_json.write(''regionWrapperId''    , l_wrapper_id           );',
'    apex_json.write(''itemsToSubmit''      , l_items_to_submit      );',
'    apex_json.write(''showSpinner''        , l_show_spinner         );',
'    apex_json.write(''showSpinnerOverlay'' , l_show_spinner_overlay );',
'    apex_json.write(''spinnerPosition''    , l_spinner_position     );',
'    apex_json.write(''rawContent''         , l_raw_content          );',
'    apex_json.write(''escape''             , l_escape_item_values   );',
'    apex_json.write(''localRefresh''       , l_local_refresh        );',
'    apex_json.write(''lazyLoad''           , l_lazy_load            );',
'    apex_json.write(''lazyRefresh''        , l_lazy_refresh         );',
'    apex_json.write(''sanitizeContent''    , l_sanitize_content     );',
'    if not l_local_refresh and not l_lazy_load and l_sanitize_content then',
'        apex_json.write_raw(''DOMPurifyConfig'', ''{}'');',
'        apex_json.write(''initialContent'' , l_content              );',
'    end if;',
'    apex_json.close_object;',
'    ',
'    -- initialization code for the region widget. needed to handle the refresh event',
'    apex_javascript.add_onload_code(''FOS.region.staticContent(this, '' || apex_json.get_clob_output|| '', ''|| l_init_js_fn || '');'');',
'    ',
'    apex_json.free_output;',
'',
'    return l_return;',
'end render;',
'',
'--------------------------------------------------------------------------------',
'-- called when region should be refreshed and returns the static content.',
'-- additionally it is possible to run some plsql code before the static content ',
'-- is evaluated',
'--------------------------------------------------------------------------------',
'function ajax',
'  ( p_region apex_plugin.t_region',
'  , p_plugin apex_plugin.t_plugin',
'  )',
'return apex_plugin.t_region_ajax_result',
'as',
'    -- plug-in attributes',
'    l_source               p_region.source%type       := p_region.source;',
'    l_text                 p_region.attribute_01%type := p_region.attribute_01;',
'    l_escape_item_values   boolean                    := p_region.attribute_06 = ''Y'';',
'    ',
'    c_options              apex_t_varchar2            := apex_string.split(p_region.attribute_15, '':'');',
'    l_expand_shortcuts     boolean                    := ''expand-shortcuts''             member of c_options;',
'    l_exec_plsql           boolean                    := ''execute-plsql-before-refresh'' member of c_options;',
'    l_sanitize_content     boolean                    := ''sanitize-content''             member of c_options;',
'',
'    l_skip_substitutions   boolean                    := nvl(p_region.attribute_08, ''N'') = ''Y'';',
'    l_exec_plsql_code      p_region.attribute_09%type := p_region.attribute_09;',
'    ',
'    l_items_to_return      p_region.attribute_13%type := p_region.attribute_13;',
'    l_escape_content       boolean                    := p_region.attribute_14 = ''Y'';',
'    l_item_names           apex_t_varchar2;',
'    ',
'    l_raw_content          varchar2(32767)            := case when l_source is null then l_text else l_source end;',
'    -- resulting content',
'    l_content              clob                       := '''';',
'',
'    l_return               apex_plugin.t_region_ajax_result;',
'begin',
'    -- standard debugging intro, but only if necessary',
'    if apex_application.g_debug and substr(:DEBUG,6) >= 6',
'    then',
'        apex_plugin_util.debug_region',
'          ( p_plugin => p_plugin',
'          , p_region => p_region',
'          );',
'    end if;',
'    ',
'    -- if required, execute plsql to perform some page item calculations',
'    if l_exec_plsql ',
'    then',
'        apex_exec.execute_plsql(p_plsql_code => l_exec_plsql_code);',
'    end if;',
'',
'    -- if required, we expand shortcuts in the raw-content',
'    if l_expand_shortcuts',
'    then',
'        l_raw_content := expand_shortcuts(l_raw_content);',
'    end if;',
'',
'    -- generate content',
'    l_content := ',
'         case ',
'             when l_skip_substitutions then',
'                 l_raw_content',
'             else',
'                 apex_plugin_util.replace_substitutions',
'                   ( p_value  => l_raw_content',
'                   , p_escape => l_escape_item_values',
'                   )',
'         end;',
'    ',
'    l_content := case when l_escape_content then apex_escape.html(l_content) else l_content end;',
'',
'    apex_json.open_object;',
'    apex_json.write(''status'' , ''success'');',
'    apex_json.write(''content'', l_content);',
'                                                                          ',
'    -- adding info about the page items to return',
'    if l_items_to_return is not null ',
'    then',
'        l_item_names := apex_string.split(l_items_to_return,'','');',
'        ',
'        apex_json.open_array(''items'');',
'        ',
'        for l_idx in 1 .. l_item_names.count ',
'        loop',
'            apex_json.open_object;',
'            apex_json.write',
'              ( p_name  => ''id''',
'              , p_value => l_item_names(l_idx)',
'              );',
'            apex_json.write',
'              ( p_name  => ''value''',
'              , p_value => apex_util.get_session_state(l_item_names(l_idx))',
'              );',
'            apex_json.close_object;',
'        end loop;',
'',
'        apex_json.close_array;',
'    end if;',
'    apex_json.close_object;',
'',
'    return l_return;',
'end ajax;'))
,p_api_version=>2
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'SOURCE_PLAIN:INIT_JAVASCRIPT_CODE'
,p_substitute_attributes=>false
,p_subscribe_plugin_settings=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>The <strong>FOS - Static Region</strong> plug-in has been created to honour the "everything refreshable" principle. The plug-in allows you to refresh the static content client-side or server-side. It also supports shortcuts, Lazy Loading, Lazy Ref'
||'reshing, HTML Sanitization and showing a loading spinner and mask.',
'</p>',
'<p>',
'    Why would I want to refresh static content when it is static content after all? ...the reason is in the situations when you have used substitutions in your content. ',
'</p>'))
,p_version_identifier=>'21.2.0'
,p_about_url=>'https://fos.world'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// Settings for the FOS browser extension',
'@fos-auto-return-to-page',
'@fos-auto-open-files:js/script.js'))
,p_files_version=>168
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(14934465811644455)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Text'
,p_attribute_type=>'HTML'
,p_is_required=>true
,p_is_translatable=>true
,p_examples=>'&lt;h1&gt;Welcome &amp;APP_USER. to the application &amp;APP_NAME!HTML.&lt;/h1&gt;'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p><strong>Deprecated. Attribute will be removed in the future, use the native <i>"Region Source"</i> attribute instead.</strong></p>',
'',
'<p>This is the static region source. You can enter HTML code or just text and you can use any kind of substitution strings in here:</p><ul>',
'<li>Reference page or application items using &amp;ITEM. syntax</li>',
'<li>Use built-in substitution strings</li>',
'</ul>',
'<p>From a security perspective, when using substitution strings you can escape special characters in the substitution value by appending an exclamation mark (!) followed by a predefined filter name to a page or application item name, report column, o'
||'r other substitution string. Output escaping is an important security technique to avoid Cross Site Scripting (XSS) attacks in the browser. Oracle Application Express already makes a best effort to automatically escape characters in a HTML or JavaScr'
||'ipt context. With this extended syntax, developers have fine grained control over the output.</p>',
'<ul>',
'<li> HTML escapes reserved HTML characters - &amp;P1_DEPTNO!HTML.</li>',
'<li> ATTR escapes reserved characters in a HTML attribute context - &amp;P1_DEPTNO!ATTR.</li>',
'<li> JS escapes reserved characters in a JavaScript context - &amp;P1_DEPTNO!JS.</li>',
'<li> RAW preserves the original item value and does not escape characters - &amp;P1_DEPTNO!RAW.</li>',
'<li> STRIPHTML removes HTML tags from the output and escapes reserved HTML characters - &amp;P1_DEPTNO!STRIPHTML.</li>',
'</ul>',
'<p>See the Oracle documentation for more information on "Using Substitution Strings"</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(15667582511810463)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Items to Submit'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(15686016748039307)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'N'
,p_help_text=>'<p>Use this setting to submit page item values to the server and update session state prior to the refresh. You would list any page items here for the current page which you are referencing within your PL/SQL Code.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(15667843898810463)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Show Spinner'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(15686016748039307)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'N'
,p_lov_type=>'STATIC'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Show a spinner icon while the refresh request is taking place. This will give the end users a visual indication that some processing is occurring.</p>',
'<p><b>Note:</b>&nbsp;the spinner will not be shown if the request returns very quickly, in order to avoid flickering.</p>'))
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(15680754715925352)
,p_plugin_attribute_id=>wwv_flow_api.id(15667843898810463)
,p_display_sequence=>10
,p_display_value=>'No'
,p_return_value=>'N'
,p_help_text=>'<p>This option will disable the use of a spinner icon i.e. it won''t be shown.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(15680872128925353)
,p_plugin_attribute_id=>wwv_flow_api.id(15667843898810463)
,p_display_sequence=>20
,p_display_value=>'On Region'
,p_return_value=>'ON_REGION'
,p_help_text=>'<p>This option will show the spinner in the center of the region. The content within the region can still be interacted with e.g. clicking buttons etc.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(15680927342925353)
,p_plugin_attribute_id=>wwv_flow_api.id(15667843898810463)
,p_display_sequence=>30
,p_display_value=>'On Region with Overlay'
,p_return_value=>'ON_REGION_WITH_OVERLAY'
,p_help_text=>'<p>This option will show the spinner in the center of the region.&nbsp; It will also add a translucent mask overlay on the region which prohibits mouse/keyboard input.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(15681091696925353)
,p_plugin_attribute_id=>wwv_flow_api.id(15667843898810463)
,p_display_sequence=>40
,p_display_value=>'On Page'
,p_return_value=>'ON_PAGE'
,p_help_text=>'<p>This option will show the spinner in the center of the page. The content within the page can still be interacted with e.g. clicking buttons, entering information into input items etc.<br></p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(15681184121925353)
,p_plugin_attribute_id=>wwv_flow_api.id(15667843898810463)
,p_display_sequence=>50
,p_display_value=>'On Page with Overlay'
,p_return_value=>'ON_PAGE_WITH_OVERLAY'
,p_help_text=>'<p>This option will show the spinner in the center of the page.&nbsp; It will also add a translucent mask overlay on the page which prohibits mouse/keyboard input. Use this option when you don''t want the user to interact with the page whilst the cont'
||'ent is being refreshed.<br></p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(14949404962846770)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>20
,p_prompt=>'Escape Item Values'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(15686016748039307)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'Y'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Escape any special characters contained in the values of referenced items.</p>',
'<p>For more control, this setting can be turned off, and individual items can be escaped via the <code>&amp;P1_ITEM!HTML.</code> syntax.</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(15686016748039307)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>15
,p_prompt=>'Local Refresh'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>We can refresh the region content locally (clientside) by replacing any mentioned page-items in the region text with their current value, or send a request to the database to fetch the content with all updated session state. You have the option of'
||' executing some PLSQL code prior to the template being refreshed on the server.&nbsp;</p>',
'<p><b>Note:</b> local refresh mode is very fast, but it is limited to using page-item values of this page or the global page. Application items or other substitution types won''t work, so be sure to check what you are referencing in your template as t'
||'o what method to choose. If you only reference local page items then for performance reasons we would strongly recommend using a "Local Refresh"</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(31616565635404956)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>17
,p_prompt=>'Skip Server Substitutions'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(15686016748039307)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'N'
,p_help_text=>'<p>In most cases you will not use this setting. However you can use this option to skip substituting values on the server when local refresh is disabled. If local refresh is enabled then this setting is ignored as server substitutions are already ski'
||'pped and substitutions occur in the browser using local page items.</p><p>When would you skip server substitutions when local refresh is disabled? Only in the case when you want to show the template exactly how it is. We use this option in our plug-i'
||'n demo to show you the actual template in use.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(28518202256608479)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>160
,p_prompt=>'Execute PL/SQL Code'
,p_attribute_type=>'PLSQL'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(28517285506587462)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'execute-plsql-before-refresh'
,p_help_text=>'<p>Enter the PL/SQL Code you would like to execute before refreshing the Static Region. In most cases this is used to update the page item values with calculations performed on the server just prior to refresh.</p><p><b>Note: </b>we do not support an'
||'y HTP calls in the PL/SQL to output additional information. If you do this you will break the AJAX response and an error will be raised.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(31206613148468911)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>110
,p_prompt=>'Lazy Load'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(15686016748039307)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'N'
,p_help_text=>'<p>Use this option to control loading the region only when it is visible to the user i.e. shown/expanded/tab activated etc.</p><p><strong>Note: </strong>this setting only applies when "Local Refresh" is not enabled</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(30911601345142096)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>120
,p_prompt=>'Lazy Refresh'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(31206613148468911)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'Y'
,p_help_text=>'<p>Enable this option to lazily refresh the region i.e. only when it is visible.&nbsp;</p><p><b>Note: </b>this setting can greatly help with performance on pages with many regions that are hidden behind tabs or within region display selectors. If you'
||' issue multiple refreshes whilst the content is hidden you will only have one refresh occur when it becomes visible. On pages that have a high page view count, this can greatly reduce the overhead on the database if you use several of these regions o'
||'n the page.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(28971924595440562)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>13
,p_display_sequence=>170
,p_prompt=>'Items to Return'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false

,p_depending_on_attribute_id=>wwv_flow_api.id(28517285506587462)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'execute-plsql-before-refresh'
,p_help_text=>'<p>When you execute PL/SQL Code before performing the refresh, you have the option to return any page item values you updated in that code. You can use this setting to define the list of page items you wish to return their updated values back to brow'
||'ser/HTML page.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(28899400944379194)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>14
,p_display_sequence=>180
,p_prompt=>'Escape Special Characters'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(15686016748039307)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'N'
,p_help_text=>'<p>Enable this option to escape the static content i.e. HTML tags will be escaped. You would use this setting either for security reasons, the text should not have any HTML markup or in the rare occurrences when you want to display the actual HTML ma'
||'rkup to the user.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(28517285506587462)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>15
,p_display_sequence=>150
,p_prompt=>'Extra Options'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(15686016748039307)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'N'
,p_lov_type=>'STATIC'
,p_help_text=>'<p>Choose from a number of extra options for more advanced usage of the plugin.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(29025218572500985)
,p_plugin_attribute_id=>wwv_flow_api.id(28517285506587462)
,p_display_sequence=>5
,p_display_value=>'Expand Shortcuts'
,p_return_value=>'expand-shortcuts'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Specify whether shortcuts should be expanded in the Region source/text. A shortcut name needs to be wrapped in double-quotes, e.g. "SHORTCUT_NAME"</p>',
'<p>We support build options too, so there shouldn''t be anything stopping you from using them.</p>',
'<h3>What are shortcuts?</h3>',
'<p>Most people really don''t know, but they are very similar to substitutions but have a different syntax i.e. you specify the shortcut name in enclosed double quotes e.g. "SHORTCUT_NAME". You would use them when you want to centralize repeating Javas'
||'cript or HTML or other text. They provide more functionality than a regular substitution as they can be dynamically generated using PLSQL for every individual substitution, meaning you don''t need to have session state set when the substitution is bei'
||'ng performed. It can dynamically execute your PLSQL code to return the value at the time of substitution. They are pretty powerful!</p>'))
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(28517872160595603)
,p_plugin_attribute_id=>wwv_flow_api.id(28517285506587462)
,p_display_sequence=>10
,p_display_value=>'Execute PL/SQL Code Before Refresh'
,p_return_value=>'execute-plsql-before-refresh'
,p_help_text=>'<p>In some situations you want to perform some serverside calculations on the page items prior to them being substituted. This option allows you to do just that! This code will be executed after any page items to submit have been set in session state'
||', and prior to the refresh of the static content.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(106604440796391387)
,p_plugin_attribute_id=>wwv_flow_api.id(28517285506587462)
,p_display_sequence=>20
,p_display_value=>'Sanitize Content'
,p_return_value=>'sanitize-content'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Sanitize the content via the DOMPurify JavaScript library. This allows you to output valid HTML, while stripping away any possible Cross-Site-Scripting content.</p>',
'<p>The sanitization happens on page load, as well as after each subsequent region refresh.</p>',
'<p>The sanitization happens client-side which means you might notice a quick flash on page load, depending on the size of the region content.</p>'))
);
end;
/
begin
wwv_flow_api.create_plugin_std_attribute(
 p_id=>wwv_flow_api.id(31426296251824071)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_name=>'INIT_JAVASCRIPT_CODE'
,p_is_required=>false
,p_depending_on_has_to_exist=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Using this setting you can centralize any changes using a Javascript function e.g.</p>',
'<pre>',
'function(options) {',
'   // when lazy loading we can customize how long after the "apexreadyend" we wait before checking if the region is visible',
'   options.visibilityCheckDelay = 2000; // milliseconds',
'}',
'</pre>'))
);
wwv_flow_api.create_plugin_std_attribute(
 p_id=>wwv_flow_api.id(224167550983472207)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_name=>'SOURCE_PLAIN'
,p_is_required=>false
,p_depending_on_has_to_exist=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>This is the static region source. You can enter HTML code or just text and you can use any kind of substitution strings in here:</p><ul>',
'<li>Reference page or application items using &amp;ITEM. syntax</li>',
'<li>Use built-in substitution strings</li>',
'',
'</ul>',
'<p>From a security perspective, when using substitution strings you can escape special characters in the substitution value by appending an exclamation mark (!) followed by a predefined filter name to a page or application item name, report column, o'
||'r other substitution string. Output escaping is an important security technique to avoid Cross Site Scripting (XSS) attacks in the browser. Oracle Application Express already makes a best effort to automatically escape characters in a HTML or JavaScr'
||'ipt context. With this extended syntax, developers have fine grained control over the output.</p>',
'<ul>',
'<li> HTML escapes reserved HTML characters - &amp;P1_DEPTNO!HTML.</li>',
'<li> ATTR escapes reserved characters in a HTML attribute context - &amp;P1_DEPTNO!ATTR.</li>',
'<li> JS escapes reserved characters in a JavaScript context - &amp;P1_DEPTNO!JS.</li>',
'<li> RAW preserves the original item value and does not escape characters - &amp;P1_DEPTNO!RAW.</li>',
'<li> STRIPHTML removes HTML tags from the output and escapes reserved HTML characters - &amp;P1_DEPTNO!STRIPHTML.</li>',
'</ul>',
'<p>See the Oracle documentation for more information on "Using Substitution Strings"</p>'))
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A20676C6F62616C7320617065782C24202A2F0A0A76617220464F53203D2077696E646F772E464F53207C7C207B7D3B0A464F532E726567696F6E203D20464F532E726567696F6E207C7C207B7D3B0A0A2F2A2A0A202A20496E697469616C697A6174';
wwv_flow_api.g_varchar2_table(2) := '696F6E2066756E6374696F6E20666F72207468652073746174696320636F6E74656E7420726567696F6E2E0A202A20546869732066756E6374696F6E206D7573742062652072756E20666F722074686520726567696F6E20746F20737562736372696265';
wwv_flow_api.g_varchar2_table(3) := '20746F207468652072656672657368206576656E740A202A204578706563747320617320706172616D6574657220616E206F626A65637420776974682074686520666F6C6C6F77696E6720617474726962757465733A0A202A0A202A2040706172616D20';
wwv_flow_api.g_varchar2_table(4) := '7B6F626A6563747D20206461436F6E746578742020202020202020202020202020202020202020202054686520636F6E74657874204F626A65637420706173736564206279204150455820746F2064796E616D696320616374696F6E730A202A20407061';
wwv_flow_api.g_varchar2_table(5) := '72616D207B6F626A6563747D2020636F6E66696720202020202020202020202020202020202020202020202020436F6E66696775726174696F6E206F626A65637420686F6C64696E6720616C6C20617474726962757465730A202A2040706172616D207B';
wwv_flow_api.g_varchar2_table(6) := '737472696E677D2020636F6E6669672E726567696F6E496420202020202020202020202020202020546865206D61696E20726567696F6E2049442E2054686520726567696F6E206F6E207768696368202272656672657368222063616E20626520747269';
wwv_flow_api.g_varchar2_table(7) := '6767657265640A202A2040706172616D207B737472696E677D2020636F6E6669672E726567696F6E5772617070657249642020202020202020204944206F66207772617070657220656C656D656E742E2054686520636F6E74656E7473206F6620746869';
wwv_flow_api.g_varchar2_table(8) := '7320656C656D656E742077696C6C206265207265706C61636564207769746820746865206E657720636F6E74656E740A202A2040706172616D207B737472696E677D20205B636F6E6669672E6974656D73546F5375626D69745D20202020202020202043';
wwv_flow_api.g_varchar2_table(9) := '6F6D6D612D7365706172617465642070616765206974656D206E616D657320696E206A51756572792073656C6563746F7220666F726D61740A202A2040706172616D207B626F6F6C65616E7D205B636F6E6669672E73757070726573734368616E676545';
wwv_flow_api.g_varchar2_table(10) := '76656E745D2020204966207468657265206172652070616765206974656D7320746F2062652072657475726E65642C20746869732064656369646573207768657468657220746F20747269676765722061206368616E6765206576656E74206F72206E6F';
wwv_flow_api.g_varchar2_table(11) := '740A202A2040706172616D207B626F6F6C65616E7D205B636F6E6669672E73686F775370696E6E65725D202020202020202020202053686F77732061207370696E6E6572206F72206E6F740A202A2040706172616D207B626F6F6C65616E7D205B636F6E';
wwv_flow_api.g_varchar2_table(12) := '6669672E73686F775370696E6E65724F7665726C61795D20202020446570656E6473206F6E2073686F775370696E6E65722E20416464732061207472616E736C7563656E74206F7665726C617920626568696E6420746865207370696E6E65720A202A20';
wwv_flow_api.g_varchar2_table(13) := '40706172616D207B737472696E677D20205B636F6E6669672E7370696E6E6572506F736974696F6E5D20202020202020446570656E6473206F6E2073686F775370696E6E65722E2041206A51756572792073656C6563746F7220756E746F207768696368';
wwv_flow_api.g_varchar2_table(14) := '20746865207370696E6E65722077696C6C2062652073686F776E0A202A2040706172616D207B737472696E677D2020636F6E6669672E726177436F6E74656E7420202020202020202020202020205468652072617720636F6E74656E7420737472696E67';
wwv_flow_api.g_varchar2_table(15) := '0A202A2040706172616D207B626F6F6C65616E7D20636F6E6669672E6573636170652020202020202020202020202020202020205768657468657220746F20657363617065207468652076616C756573206F66207265666572656E636564206974656D73';
wwv_flow_api.g_varchar2_table(16) := '0A202A2040706172616D207B626F6F6C65616E7D20636F6E6669672E6C6F63616C52656672657368202020202020202020202020466574636820746865206E657720636F6E74656E742066726F6D207468652044422C206F72207265706C616365207375';
wwv_flow_api.g_varchar2_table(17) := '62737469747574696F6E73206C6F63616C6C793F0A202A2040706172616D207B626F6F6C65616E7D205B636F6E6669672E73616E6974697A65436F6E74656E745D202020202020205768657468657220746F20706173732074686520636F6E74656E7420';
wwv_flow_api.g_varchar2_table(18) := '7468726F75676820444F4D5075726966790A202A2040706172616D207B6F626A6563747D20205B636F6E6669672E444F4D507572696679436F6E6669675D202020202020204164646974696F6E616C206F7074696F6E7320746F20626520706173736564';
wwv_flow_api.g_varchar2_table(19) := '20746F20444F4D5075726966792E2053616E6974697A6520436F6E74656E74206D75737420626520656E61626C65642E0A202A2040706172616D207B737472696E677D20205B636F6E6669672E696E697469616C436F6E74656E745D2020202020202020';
wwv_flow_api.g_varchar2_table(20) := '54686520696E697469616C20636F6E74656E7420746F206265206170706C6965642073686F776E2069662073616E6974697A65436F6E74656E7420697320656E61626C656420616E64206C617A794C6F61642069732064697361626C65640A202A2F0A46';
wwv_flow_api.g_varchar2_table(21) := '4F532E726567696F6E2E737461746963436F6E74656E74203D2066756E6374696F6E20286461436F6E746578742C20636F6E6669672C20696E6974466E29207B0A2020202076617220636F6E74657874203D206461436F6E74657874207C7C2074686973';
wwv_flow_api.g_varchar2_table(22) := '2C0A2020202020202020656C243B0A0A2020202076617220706C7567696E4E616D65203D2027464F53202D2053746174696320436F6E74656E74273B0A20202020617065782E64656275672E696E666F28706C7567696E4E616D652C20636F6E6669672C';
wwv_flow_api.g_varchar2_table(23) := '20696E6974466E293B0A0A202020202F2F20416C6C6F772074686520646576656C6F70657220746F20706572666F726D20616E79206C617374202863656E7472616C697A656429206368616E676573207573696E67204A61766173637269707420496E69';
wwv_flow_api.g_varchar2_table(24) := '7469616C697A6174696F6E20436F64652073657474696E670A2020202069662028696E6974466E20696E7374616E63656F662046756E6374696F6E29207B0A2020202020202020696E6974466E2E63616C6C28636F6E746578742C20636F6E666967293B';
wwv_flow_api.g_varchar2_table(25) := '0A202020207D0A0A20202020656C24203D20636F6E6669672E656C24203D202428272327202B20636F6E6669672E726567696F6E4964293B0A0A202020202F2F20696D706C656D656E74696E672074686520617065782E726567696F6E20696E74657266';
wwv_flow_api.g_varchar2_table(26) := '61636520696E206F7264657220746F20726573706F6E6420746F2072656672657368206576656E74730A20202020617065782E726567696F6E2E63726561746528636F6E6669672E726567696F6E49642C207B0A2020202020202020747970653A202766';
wwv_flow_api.g_varchar2_table(27) := '6F732D726567696F6E2D7374617469632D636F6E74656E74272C0A2020202020202020726566726573683A2066756E6374696F6E202829207B0A20202020202020202020202069662028636F6E6669672E697356697369626C65207C7C2021636F6E6669';
wwv_flow_api.g_varchar2_table(28) := '672E6C617A795265667265736829207B0A20202020202020202020202020202020464F532E726567696F6E2E737461746963436F6E74656E742E726566726573682E63616C6C28636F6E746578742C20636F6E666967293B0A2020202020202020202020';
wwv_flow_api.g_varchar2_table(29) := '207D20656C7365207B0A20202020202020202020202020202020636F6E6669672E6E6565647352656672657368203D20747275653B0A2020202020202020202020207D0A20202020202020207D2C0A20202020202020206F7074696F6E3A2066756E6374';
wwv_flow_api.g_varchar2_table(30) := '696F6E20286E616D652C2076616C756529207B0A2020202020202020202020207661722077686974654C6973744F7074696F6E73203D205B2773686F775370696E6E6572275D3B0A20202020202020202020202076617220617267436F756E74203D2061';
wwv_flow_api.g_varchar2_table(31) := '7267756D656E74732E6C656E6774683B0A20202020202020202020202069662028617267436F756E74203D3D3D203129207B0A2020202020202020202020202020202072657475726E20636F6E6669675B6E616D655D3B0A202020202020202020202020';
wwv_flow_api.g_varchar2_table(32) := '7D20656C73652069662028617267436F756E74203E203129207B0A20202020202020202020202020202020696620286E616D652026262076616C75652026262077686974654C6973744F7074696F6E732E696E636C75646573286E616D652929207B0A20';
wwv_flow_api.g_varchar2_table(33) := '20202020202020202020202020202020202020636F6E6669675B6E616D655D203D2076616C75653B0A202020202020202020202020202020207D20656C736520696620286E616D65202626202177686974654C6973744F7074696F6E732E696E636C7564';
wwv_flow_api.g_varchar2_table(34) := '6573286E616D652929207B0A2020202020202020202020202020202020202020617065782E64656275672E7761726E2827796F752061726520747279696E6720746F2073657420616E206F7074696F6E2074686174206973206E6F7420616C6C6F776564';
wwv_flow_api.g_varchar2_table(35) := '3A2027202B206E616D65293B0A202020202020202020202020202020207D0A2020202020202020202020207D0A20202020202020207D0A202020207D293B0A0A202020202F2F206170706C792073616E6974697A656420636F6E74656E740A2020202069';
wwv_flow_api.g_varchar2_table(36) := '6628636F6E6669672E73616E6974697A65436F6E74656E7420262620636F6E6669672E696E697469616C436F6E74656E74297B0A202020202020202076617220636F6E74656E74203D20444F4D5075726966792E73616E6974697A6528636F6E6669672E';
wwv_flow_api.g_varchar2_table(37) := '696E697469616C436F6E74656E742C20636F6E6669672E444F4D507572696679436F6E666967207C7C207B7D293B0A20202020202020202428272327202B20636F6E6669672E726567696F6E577261707065724964292E68746D6C28636F6E74656E7429';
wwv_flow_api.g_varchar2_table(38) := '3B0A202020207D0A0A202020202F2F2069662077652072656672657368206C6F63616C6C79207468656E207765206E65656420746F2073756273746974757465207468656D206F6E20706167652072656E6465720A2020202069662028636F6E6669672E';
wwv_flow_api.g_varchar2_table(39) := '6C6F63616C5265667265736829207B0A2020202020202020617065782E726567696F6E28636F6E6669672E726567696F6E4964292E7265667265736828293B0A202020207D0A202020202F2F20636865636B206966207765206E65656420746F206C617A';
wwv_flow_api.g_varchar2_table(40) := '79206C6F61642074686520726567696F6E0A20202020656C73652069662028636F6E6669672E6C617A794C6F616429207B0A2020202020202020617065782E7769646765742E7574696C2E6F6E5669736962696C6974794368616E676528656C245B305D';
wwv_flow_api.g_varchar2_table(41) := '2C2066756E6374696F6E2028697356697369626C6529207B0A202020202020202020202020636F6E6669672E697356697369626C65203D20697356697369626C653B0A20202020202020202020202069662028697356697369626C65202626202821636F';
wwv_flow_api.g_varchar2_table(42) := '6E6669672E6C6F61646564207C7C20636F6E6669672E6E65656473526566726573682929207B0A20202020202020202020202020202020617065782E726567696F6E28636F6E6669672E726567696F6E4964292E7265667265736828293B0A2020202020';
wwv_flow_api.g_varchar2_table(43) := '2020202020202020202020636F6E6669672E6C6F61646564203D20747275653B0A20202020202020202020202020202020636F6E6669672E6E6565647352656672657368203D2066616C73653B0A2020202020202020202020207D0A2020202020202020';
wwv_flow_api.g_varchar2_table(44) := '7D293B0A2020202020202020617065782E6A51756572792877696E646F77292E6F6E2827617065787265616479656E64272C2066756E6374696F6E202829207B0A2020202020202020202020202F2F2077652061646420617661726961626C6520726566';
wwv_flow_api.g_varchar2_table(45) := '6572656E636520746F2061766F6964206C6F7373206F662073636F70650A20202020202020202020202076617220656C203D20656C245B305D3B0A2020202020202020202020202F2F207765206861766520746F20616464206120736C69676874206465';
wwv_flow_api.g_varchar2_table(46) := '6C617920746F206D616B65207375726520617065782077696467657473206861766520696E697469616C697A65642073696E6365202873757270726973696E676C79292022617065787265616479656E6422206973206E6F7420656E6F7567680A202020';
wwv_flow_api.g_varchar2_table(47) := '20202020202020202073657454696D656F75742866756E6374696F6E202829207B0A20202020202020202020202020202020617065782E7769646765742E7574696C2E7669736962696C6974794368616E676528656C2C2074727565293B0A2020202020';
wwv_flow_api.g_varchar2_table(48) := '202020202020207D2C20636F6E6669672E7669736962696C697479436865636B44656C6179207C7C2031303030293B0A20202020202020207D293B0A202020207D0A7D3B0A0A464F532E726567696F6E2E737461746963436F6E74656E742E7265667265';
wwv_flow_api.g_varchar2_table(49) := '7368203D2066756E6374696F6E2028636F6E66696729207B0A2020202076617220656C656D24203D202428272327202B20636F6E6669672E726567696F6E577261707065724964293B0A2020202076617220726177436F6E74656E74203D20636F6E6669';
wwv_flow_api.g_varchar2_table(50) := '672E726177436F6E74656E743B0A2020202076617220657363617065203D20636F6E6669672E6573636170653B0A20202020766172206C6F6164696E67496E64696361746F72466E3B0A0A202020202F2F636F6E66696775726573207468652073686F77';
wwv_flow_api.g_varchar2_table(51) := '696E6720616E6420686964696E67206F66206120706F737369626C65207370696E6E65720A2020202069662028636F6E6669672E73686F775370696E6E657229207B0A20202020202020206C6F6164696E67496E64696361746F72466E203D202866756E';
wwv_flow_api.g_varchar2_table(52) := '6374696F6E2028706F736974696F6E2C2073686F774F7665726C617929207B0A2020202020202020202020207661722066697865644F6E426F6479203D20706F736974696F6E203D3D2027626F6479273B0A20202020202020202020202072657475726E';
wwv_flow_api.g_varchar2_table(53) := '2066756E6374696F6E2028704C6F6164696E67496E64696361746F7229207B0A20202020202020202020202020202020766172206F7665726C6179243B0A20202020202020202020202020202020766172207370696E6E657224203D20617065782E7574';
wwv_flow_api.g_varchar2_table(54) := '696C2E73686F775370696E6E657228706F736974696F6E2C207B2066697865643A2066697865644F6E426F6479207D293B0A202020202020202020202020202020206966202873686F774F7665726C617929207B0A202020202020202020202020202020';
wwv_flow_api.g_varchar2_table(55) := '20202020206F7665726C617924203D202428273C64697620636C6173733D22666F732D726567696F6E2D6F7665726C617927202B202866697865644F6E426F6479203F20272D666978656427203A20272729202B2027223E3C2F6469763E27292E707265';
wwv_flow_api.g_varchar2_table(56) := '70656E64546F28706F736974696F6E293B0A202020202020202020202020202020207D0A2020202020202020202020202020202066756E6374696F6E2072656D6F76655370696E6E65722829207B0A202020202020202020202020202020202020202069';
wwv_flow_api.g_varchar2_table(57) := '6620286F7665726C61792429207B0A2020202020202020202020202020202020202020202020206F7665726C6179242E72656D6F766528293B0A20202020202020202020202020202020202020207D0A2020202020202020202020202020202020202020';
wwv_flow_api.g_varchar2_table(58) := '7370696E6E6572242E72656D6F766528293B0A202020202020202020202020202020207D0A202020202020202020202020202020202F2F746869732066756E6374696F6E206D7573742072657475726E20612066756E6374696F6E207768696368206861';
wwv_flow_api.g_varchar2_table(59) := '6E646C6573207468652072656D6F76696E67206F6620746865207370696E6E65720A2020202020202020202020202020202072657475726E2072656D6F76655370696E6E65723B0A2020202020202020202020207D3B0A20202020202020207D2928636F';
wwv_flow_api.g_varchar2_table(60) := '6E6669672E7370696E6E6572506F736974696F6E2C20636F6E6669672E73686F775370696E6E65724F7665726C6179293B0A202020207D0A202020202F2F2074726967676572206F7572206265666F72652072656672657368206576656E742873290A20';
wwv_flow_api.g_varchar2_table(61) := '202020766172206576656E7443616E63656C6C6564203D20617065782E6576656E742E747269676765722827617065786265666F726572656672657368272C20272327202B20636F6E6669672E726567696F6E49642C20636F6E666967293B0A20202020';
wwv_flow_api.g_varchar2_table(62) := '696620286576656E7443616E63656C6C656429207B0A2020202020202020617065782E64656275672E7761726E2827746865207265667265736820616374696F6E20686173206265656E2063616E63656C6C656420627920746865202261706578626566';
wwv_flow_api.g_varchar2_table(63) := '6F72657265667265736822206576656E742127293B0A202020202020202072657475726E2066616C73653B0A202020207D0A202020202F2F2077652063616E20656974686572207265706C6163652074686520737562737469747574696F6E2073747269';
wwv_flow_api.g_varchar2_table(64) := '6E6773206C6F63616C6C792028627574206F6E6C792077697468206974656D73206F6E20746869732070616765206F722074686520676C6F62616C2070616765290A202020202F2F206F7220666574636820746865207570646174656420636F6E74656E';
wwv_flow_api.g_varchar2_table(65) := '742066726F6D207468652064617461626173650A2020202069662028636F6E6669672E6C6F63616C5265667265736829207B0A2020202020202020656C656D242E68746D6C28617065782E7574696C2E6170706C7954656D706C61746528726177436F6E';
wwv_flow_api.g_varchar2_table(66) := '74656E742C207B0A20202020202020202020202064656661756C7445736361706546696C7465723A20657363617065203F202748544D4C27203A2027524157270A20202020202020207D29293B0A20202020202020202F2F2074726967676572206F7572';
wwv_flow_api.g_varchar2_table(67) := '2061667465722072656672657368206576656E742873290A2020202020202020617065782E6576656E742E74726967676572282761706578616674657272656672657368272C20272327202B20636F6E6669672E726567696F6E49642C20636F6E666967';
wwv_flow_api.g_varchar2_table(68) := '293B0A202020207D20656C7365207B0A2020202020202020617065782E7365727665722E706C7567696E28636F6E6669672E616A61784964656E7469666965722C207B0A202020202020202020202020706167654974656D733A20636F6E6669672E6974';
wwv_flow_api.g_varchar2_table(69) := '656D73546F5375626D69740A20202020202020207D2C207B0A2020202020202020202020202F2F6E656564656420746F2074726967676572206265666F726520616E642061667465722072656672657368206576656E7473206F6E207468652072656769';
wwv_flow_api.g_varchar2_table(70) := '6F6E0A202020202020202020202020726566726573684F626A6563743A20272327202B20636F6E6669672E726567696F6E49642C0A2020202020202020202020202F2F746869732066756E6374696F6E206973207265706F6E7369626C6520666F722073';
wwv_flow_api.g_varchar2_table(71) := '686F77696E672061207370696E6E65720A2020202020202020202020206C6F6164696E67496E64696361746F723A206C6F6164696E67496E64696361746F72466E2C0A202020202020202020202020737563636573733A2066756E6374696F6E20286461';
wwv_flow_api.g_varchar2_table(72) := '746129207B0A202020202020202020202020202020202F2F73657474696E672070616765206974656D2076616C7565730A2020202020202020202020202020202069662028646174612E6974656D7329207B0A2020202020202020202020202020202020';
wwv_flow_api.g_varchar2_table(73) := '202020666F7220287661722069203D20303B2069203C20646174612E6974656D732E6C656E6774683B20692B2B29207B0A202020202020202020202020202020202020202020202020617065782E6974656D28646174612E6974656D735B695D2E696429';
wwv_flow_api.g_varchar2_table(74) := '2E73657456616C756528646174612E6974656D735B695D2E76616C75652C206E756C6C2C20636F6E6669672E73757070726573734368616E67654576656E74293B0A20202020202020202020202020202020202020207D0A202020202020202020202020';
wwv_flow_api.g_varchar2_table(75) := '202020207D0A202020202020202020202020202020202F2F7265706C6163696E6720746865206F6C6420636F6E74656E74207769746820746865206E65770A2020202020202020202020202020202076617220636F6E74656E74203D20646174612E636F';
wwv_flow_api.g_varchar2_table(76) := '6E74656E743B0A20202020202020202020202020202020696628636F6E6669672E73616E6974697A65436F6E74656E74297B0A2020202020202020202020202020202020202020636F6E74656E74203D20444F4D5075726966792E73616E6974697A6528';
wwv_flow_api.g_varchar2_table(77) := '636F6E74656E742C20636F6E6669672E444F4D507572696679436F6E666967207C7C207B7D293B0A202020202020202020202020202020207D0A202020202020202020202020202020202428272327202B20636F6E6669672E726567696F6E5772617070';
wwv_flow_api.g_varchar2_table(78) := '65724964292E68746D6C28636F6E74656E74293B0A202020202020202020202020202020202F2F2074726967676572206F75722061667465722072656672657368206576656E742873290A20202020202020202020202020202020617065782E6576656E';
wwv_flow_api.g_varchar2_table(79) := '742E74726967676572282761706578616674657272656672657368272C20272327202B20636F6E6669672E726567696F6E49642C20636F6E666967293B0A2020202020202020202020207D2C0A2020202020202020202020202F2F6F6D697474696E6720';
wwv_flow_api.g_varchar2_table(80) := '616E206572726F722068616E646C6572206C65747320617065782E73657276657220757365207468652064656661756C74206F6E650A20202020202020202020202064617461547970653A20276A736F6E270A20202020202020207D293B0A202020207D';
wwv_flow_api.g_varchar2_table(81) := '0A7D3B';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(14940628687644466)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_file_name=>'js/script.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '7B2276657273696F6E223A332C22736F7572636573223A5B227363726970742E6A73225D2C226E616D6573223A5B22464F53222C2277696E646F77222C22726567696F6E222C22737461746963436F6E74656E74222C226461436F6E74657874222C2263';
wwv_flow_api.g_varchar2_table(2) := '6F6E666967222C22696E6974466E222C22656C24222C22636F6E74657874222C2274686973222C2261706578222C226465627567222C22696E666F222C2246756E6374696F6E222C2263616C6C222C2224222C22726567696F6E4964222C226372656174';
wwv_flow_api.g_varchar2_table(3) := '65222C2274797065222C2272656672657368222C22697356697369626C65222C226C617A7952656672657368222C226E6565647352656672657368222C226F7074696F6E222C226E616D65222C2276616C7565222C2277686974654C6973744F7074696F';
wwv_flow_api.g_varchar2_table(4) := '6E73222C22617267436F756E74222C22617267756D656E7473222C226C656E677468222C22696E636C75646573222C227761726E222C2273616E6974697A65436F6E74656E74222C22696E697469616C436F6E74656E74222C22636F6E74656E74222C22';
wwv_flow_api.g_varchar2_table(5) := '444F4D507572696679222C2273616E6974697A65222C22444F4D507572696679436F6E666967222C22726567696F6E577261707065724964222C2268746D6C222C226C6F63616C52656672657368222C226C617A794C6F6164222C22776964676574222C';
wwv_flow_api.g_varchar2_table(6) := '227574696C222C226F6E5669736962696C6974794368616E6765222C226C6F61646564222C226A5175657279222C226F6E222C22656C222C2273657454696D656F7574222C227669736962696C6974794368616E6765222C227669736962696C69747943';
wwv_flow_api.g_varchar2_table(7) := '6865636B44656C6179222C226C6F6164696E67496E64696361746F72466E222C22706F736974696F6E222C2273686F774F7665726C6179222C2266697865644F6E426F6479222C22656C656D24222C22726177436F6E74656E74222C2265736361706522';
wwv_flow_api.g_varchar2_table(8) := '2C2273686F775370696E6E6572222C227370696E6E6572506F736974696F6E222C2273686F775370696E6E65724F7665726C6179222C22704C6F6164696E67496E64696361746F72222C226F7665726C617924222C227370696E6E657224222C22666978';
wwv_flow_api.g_varchar2_table(9) := '6564222C2270726570656E64546F222C2272656D6F7665222C226576656E74222C2274726967676572222C226170706C7954656D706C617465222C2264656661756C7445736361706546696C746572222C22736572766572222C22706C7567696E222C22';
wwv_flow_api.g_varchar2_table(10) := '616A61784964656E746966696572222C22706167654974656D73222C226974656D73546F5375626D6974222C22726566726573684F626A656374222C226C6F6164696E67496E64696361746F72222C2273756363657373222C2264617461222C22697465';
wwv_flow_api.g_varchar2_table(11) := '6D73222C2269222C226974656D222C226964222C2273657456616C7565222C2273757070726573734368616E67654576656E74222C226461746154797065225D2C226D617070696E6773223A22414145412C49414149412C4941414D432C4F41414F442C';
wwv_flow_api.g_varchar2_table(12) := '4B41414F2C4741437842412C49414149452C4F414153462C49414149452C514141552C474175423342462C49414149452C4F41414F432C63414167422C53414155432C45414157432C45414151432C47414370442C49414349432C45414441432C454141';
wwv_flow_api.g_varchar2_table(13) := '554A2C474141614B2C4B41754333422C47416E4341432C4B41414B432C4D41414D432C4B41444D2C7542414357502C45414151432C4741476843412C6141416B424F2C5541436C42502C4541414F512C4B41414B4E2C45414153482C4741477A42452C45';
wwv_flow_api.g_varchar2_table(14) := '41414D462C4541414F452C4941414D512C454141452C4941414D562C4541414F572C5541476C434E2C4B41414B522C4F41414F652C4F41414F5A2C4541414F572C534141552C4341436843452C4B41414D2C344241434E432C514141532C57414344642C';

wwv_flow_api.g_varchar2_table(15) := '4541414F652C59414163662C4541414F67422C594143354272422C49414149452C4F41414F432C6341416367422C514141514C2C4B41414B4E2C45414153482C4741452F43412C4541414F69422C634141652C4741473942432C4F4141512C5341415543';
wwv_flow_api.g_varchar2_table(16) := '2C4541414D432C47414370422C49414149432C4541416D422C434141432C6541437042432C45414157432C55414155432C4F41437A422C47414169422C49414162462C454143412C4F41414F74422C4541414F6D422C47414350472C454141572C494143';
wwv_flow_api.g_varchar2_table(17) := '64482C47414151432C47414153432C4541416942492C534141534E2C47414333436E422C4541414F6D422C47414151432C45414352442C49414153452C4541416942492C534141534E2C4941433143642C4B41414B432C4D41414D6F422C4B41414B2C77';
wwv_flow_api.g_varchar2_table(18) := '4441413044502C4F414F76466E422C4541414F32422C694241416D4233422C4541414F34422C654141652C4341432F432C49414149432C45414155432C55414155432C534141532F422C4541414F34422C654141674235422C4541414F67432C69424141';
wwv_flow_api.g_varchar2_table(19) := '6D422C4941436C4674422C454141452C4941414D562C4541414F69432C694241416942432C4B41414B4C2C474149724337422C4541414F6D432C6141435039422C4B41414B522C4F41414F472C4541414F572C55414155472C5541477842642C4541414F';
wwv_flow_api.g_varchar2_table(20) := '6F432C5741435A2F422C4B41414B67432C4F41414F432C4B41414B432C6D4241416D4272432C454141492C494141492C53414155612C4741436C44662C4541414F652C55414159412C47414366412C47414165662C4541414F77432C5341415578432C45';
wwv_flow_api.g_varchar2_table(21) := '41414F69422C65414376435A2C4B41414B522C4F41414F472C4541414F572C55414155472C5541433742642C4541414F77432C514141532C454143684278432C4541414F69422C634141652C4D414739425A2C4B41414B6F432C4F41414F37432C514141';
wwv_flow_api.g_varchar2_table(22) := '5138432C474141472C6742414167422C5741456E432C49414149432C4541414B7A432C454141492C4741456230432C594141572C5741435076432C4B41414B67432C4F41414F432C4B41414B4F2C694241416942462C474141492C4B4143764333432C45';
wwv_flow_api.g_varchar2_table(23) := '41414F38432C7342414177422C55414B39436E442C49414149452C4F41414F432C6341416367422C514141552C53414155642C4741437A432C494147492B432C4541496743432C45414155432C4541436C43432C45415252432C454141517A432C454141';
wwv_flow_api.g_varchar2_table(24) := '452C4941414D562C4541414F69432C6942414376426D422C4541416170442C4541414F6F442C5741437042432C4541415372442C4541414F71442C4F41304270422C474174424972442C4541414F73442C63414379424E2C45416942374268442C454141';
wwv_flow_api.g_varchar2_table(25) := '4F75442C6742416A4267434E2C45416942666A442C4541414F77442C6D4241684231424E2C45414130422C5141415A462C4541447442442C454145572C53414155552C474143622C49414149432C45414341432C4541415774442C4B41414B69432C4B41';
wwv_flow_api.g_varchar2_table(26) := '414B67422C594141594E2C454141552C43414145592C4D41414F562C49415778442C4F415649442C49414341532C4541415768442C454141452C6B4341416F4377432C454141632C534141572C4941414D2C59414159572C55414155622C49414531472C';
wwv_flow_api.g_varchar2_table(27) := '57414351552C47414341412C45414153492C53414562482C45414153472C5941514A7A442C4B41414B30442C4D41414D432C514141512C6F42414171422C4941414D68452C4541414F572C53414155582C47414768462C4F4144414B2C4B41414B432C4D';
wwv_flow_api.g_varchar2_table(28) := '41414D6F422C4B41414B2C34454143542C4541495031422C4541414F6D432C6341435067422C4541414D6A422C4B41414B37422C4B41414B69432C4B41414B32422C63414163622C454141592C4341433343632C6F4241417142622C454141532C4F4141';
wwv_flow_api.g_varchar2_table(29) := '532C534147334368442C4B41414B30442C4D41414D432C514141512C6D4241416F422C4941414D68452C4541414F572C53414155582C49414539444B2C4B41414B38442C4F41414F432C4F41414F70452C4541414F71452C65414167422C434143744343';
wwv_flow_api.g_varchar2_table(30) := '2C5541415774452C4541414F75452C6541436E422C43414543432C634141652C4941414D78452C4541414F572C534145354238442C694241416B4231422C4541436C4232422C514141532C53414155432C474145662C47414149412C4541414B432C4D41';
wwv_flow_api.g_varchar2_table(31) := '434C2C4941414B2C49414149432C454141492C45414147412C45414149462C4541414B432C4D41414D70442C4F41415171442C4941436E4378452C4B41414B79452C4B41414B482C4541414B432C4D41414D432C47414147452C49414149432C53414153';
wwv_flow_api.g_varchar2_table(32) := '4C2C4541414B432C4D41414D432C474141477A442C4D41414F2C4B41414D70422C4541414F69462C714241492F452C4941414970442C4541415538432C4541414B39432C514143684237422C4541414F32422C6B4241434E452C45414155432C55414155';
wwv_flow_api.g_varchar2_table(33) := '432C53414153462C4541415337422C4541414F67432C694241416D422C4B4145704574422C454141452C4941414D562C4541414F69432C694241416942432C4B41414B4C2C474145724378422C4B41414B30442C4D41414D432C514141512C6D4241416F';
wwv_flow_api.g_varchar2_table(34) := '422C4941414D68452C4541414F572C53414155582C4941476C456B462C53414155222C2266696C65223A227363726970742E6A73227D';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(14941071112644466)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_file_name=>'js/script.js.map'
,p_mime_type=>'application/json'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '76617220464F533D77696E646F772E464F537C7C7B7D3B464F532E726567696F6E3D464F532E726567696F6E7C7C7B7D2C464F532E726567696F6E2E737461746963436F6E74656E743D66756E6374696F6E28652C6E2C69297B76617220742C723D657C';
wwv_flow_api.g_varchar2_table(2) := '7C746869733B696628617065782E64656275672E696E666F2822464F53202D2053746174696320436F6E74656E74222C6E2C69292C6920696E7374616E63656F662046756E6374696F6E2626692E63616C6C28722C6E292C743D6E2E656C243D24282223';
wwv_flow_api.g_varchar2_table(3) := '222B6E2E726567696F6E4964292C617065782E726567696F6E2E637265617465286E2E726567696F6E49642C7B747970653A22666F732D726567696F6E2D7374617469632D636F6E74656E74222C726566726573683A66756E6374696F6E28297B6E2E69';
wwv_flow_api.g_varchar2_table(4) := '7356697369626C657C7C216E2E6C617A79526566726573683F464F532E726567696F6E2E737461746963436F6E74656E742E726566726573682E63616C6C28722C6E293A6E2E6E65656473526566726573683D21307D2C6F7074696F6E3A66756E637469';
wwv_flow_api.g_varchar2_table(5) := '6F6E28652C69297B76617220743D5B2273686F775370696E6E6572225D2C723D617267756D656E74732E6C656E6774683B696628313D3D3D722972657475726E206E5B655D3B723E31262628652626692626742E696E636C756465732865293F6E5B655D';
wwv_flow_api.g_varchar2_table(6) := '3D693A65262621742E696E636C756465732865292626617065782E64656275672E7761726E2822796F752061726520747279696E6720746F2073657420616E206F7074696F6E2074686174206973206E6F7420616C6C6F7765643A20222B6529297D7D29';
wwv_flow_api.g_varchar2_table(7) := '2C6E2E73616E6974697A65436F6E74656E7426266E2E696E697469616C436F6E74656E74297B76617220613D444F4D5075726966792E73616E6974697A65286E2E696E697469616C436F6E74656E742C6E2E444F4D507572696679436F6E6669677C7C7B';
wwv_flow_api.g_varchar2_table(8) := '7D293B24282223222B6E2E726567696F6E577261707065724964292E68746D6C2861297D6E2E6C6F63616C526566726573683F617065782E726567696F6E286E2E726567696F6E4964292E7265667265736828293A6E2E6C617A794C6F61642626286170';
wwv_flow_api.g_varchar2_table(9) := '65782E7769646765742E7574696C2E6F6E5669736962696C6974794368616E676528745B305D2C2866756E6374696F6E2865297B6E2E697356697369626C653D652C21657C7C6E2E6C6F616465642626216E2E6E65656473526566726573687C7C286170';
wwv_flow_api.g_varchar2_table(10) := '65782E726567696F6E286E2E726567696F6E4964292E7265667265736828292C6E2E6C6F616465643D21302C6E2E6E65656473526566726573683D2131297D29292C617065782E6A51756572792877696E646F77292E6F6E282261706578726561647965';
wwv_flow_api.g_varchar2_table(11) := '6E64222C2866756E6374696F6E28297B76617220653D745B305D3B73657454696D656F7574282866756E6374696F6E28297B617065782E7769646765742E7574696C2E7669736962696C6974794368616E676528652C2130297D292C6E2E766973696269';
wwv_flow_api.g_varchar2_table(12) := '6C697479436865636B44656C61797C7C316533297D2929297D2C464F532E726567696F6E2E737461746963436F6E74656E742E726566726573683D66756E6374696F6E2865297B766172206E2C692C742C722C613D24282223222B652E726567696F6E57';
wwv_flow_api.g_varchar2_table(13) := '7261707065724964292C6F3D652E726177436F6E74656E742C733D652E6573636170653B696628652E73686F775370696E6E6572262628693D652E7370696E6E6572506F736974696F6E2C743D652E73686F775370696E6E65724F7665726C61792C723D';
wwv_flow_api.g_varchar2_table(14) := '22626F6479223D3D692C6E3D66756E6374696F6E2865297B766172206E2C613D617065782E7574696C2E73686F775370696E6E657228692C7B66697865643A727D293B72657475726E20742626286E3D2428273C64697620636C6173733D22666F732D72';
wwv_flow_api.g_varchar2_table(15) := '6567696F6E2D6F7665726C6179272B28723F222D6669786564223A2222292B27223E3C2F6469763E27292E70726570656E64546F286929292C66756E6374696F6E28297B6E26266E2E72656D6F766528292C612E72656D6F766528297D7D292C61706578';
wwv_flow_api.g_varchar2_table(16) := '2E6576656E742E747269676765722822617065786265666F726572656672657368222C2223222B652E726567696F6E49642C65292972657475726E20617065782E64656275672E7761726E2827746865207265667265736820616374696F6E2068617320';
wwv_flow_api.g_varchar2_table(17) := '6265656E2063616E63656C6C6564206279207468652022617065786265666F72657265667265736822206576656E742127292C21313B652E6C6F63616C526566726573683F28612E68746D6C28617065782E7574696C2E6170706C7954656D706C617465';
wwv_flow_api.g_varchar2_table(18) := '286F2C7B64656661756C7445736361706546696C7465723A733F2248544D4C223A22524157227D29292C617065782E6576656E742E74726967676572282261706578616674657272656672657368222C2223222B652E726567696F6E49642C6529293A61';
wwv_flow_api.g_varchar2_table(19) := '7065782E7365727665722E706C7567696E28652E616A61784964656E7469666965722C7B706167654974656D733A652E6974656D73546F5375626D69747D2C7B726566726573684F626A6563743A2223222B652E726567696F6E49642C6C6F6164696E67';
wwv_flow_api.g_varchar2_table(20) := '496E64696361746F723A6E2C737563636573733A66756E6374696F6E286E297B6966286E2E6974656D7329666F722876617220693D303B693C6E2E6974656D732E6C656E6774683B692B2B29617065782E6974656D286E2E6974656D735B695D2E696429';
wwv_flow_api.g_varchar2_table(21) := '2E73657456616C7565286E2E6974656D735B695D2E76616C75652C6E756C6C2C652E73757070726573734368616E67654576656E74293B76617220743D6E2E636F6E74656E743B652E73616E6974697A65436F6E74656E74262628743D444F4D50757269';
wwv_flow_api.g_varchar2_table(22) := '66792E73616E6974697A6528742C652E444F4D507572696679436F6E6669677C7C7B7D29292C24282223222B652E726567696F6E577261707065724964292E68746D6C2874292C617065782E6576656E742E747269676765722822617065786166746572';
wwv_flow_api.g_varchar2_table(23) := '72656672657368222C2223222B652E726567696F6E49642C65297D2C64617461547970653A226A736F6E227D297D3B0A2F2F2320736F757263654D617070696E6755524C3D7363726970742E6A732E6D6170';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(14941461739644466)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_file_name=>'js/script.min.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A2120406C6963656E736520444F4D507572696679207C202863292043757265353320616E64206F7468657220636F6E7472696275746F7273207C2052656C656173656420756E6465722074686520417061636865206C6963656E736520322E302061';
wwv_flow_api.g_varchar2_table(2) := '6E64204D6F7A696C6C61205075626C6963204C6963656E736520322E30207C206769746875622E636F6D2F6375726535332F444F4D5075726966792F626C6F622F322E322E322F4C4943454E5345202A2F0A2166756E6374696F6E28652C74297B226F62';
wwv_flow_api.g_varchar2_table(3) := '6A656374223D3D747970656F66206578706F727473262622756E646566696E656422213D747970656F66206D6F64756C653F6D6F64756C652E6578706F7274733D7428293A2266756E6374696F6E223D3D747970656F6620646566696E65262664656669';
wwv_flow_api.g_varchar2_table(4) := '6E652E616D643F646566696E652874293A28653D657C7C73656C66292E444F4D5075726966793D7428297D28746869732C2866756E6374696F6E28297B2275736520737472696374223B76617220653D4F626A6563742E6861734F776E50726F70657274';
wwv_flow_api.g_varchar2_table(5) := '792C743D4F626A6563742E73657450726F746F747970654F662C6E3D4F626A6563742E697346726F7A656E2C723D4F626A6563742E67657450726F746F747970654F662C6F3D4F626A6563742E6765744F776E50726F706572747944657363726970746F';
wwv_flow_api.g_varchar2_table(6) := '722C693D4F626A6563742E667265657A652C613D4F626A6563742E7365616C2C6C3D4F626A6563742E6372656174652C633D22756E646566696E656422213D747970656F66205265666C65637426265265666C6563742C733D632E6170706C792C753D63';
wwv_flow_api.g_varchar2_table(7) := '2E636F6E7374727563743B737C7C28733D66756E6374696F6E28652C742C6E297B72657475726E20652E6170706C7928742C6E297D292C697C7C28693D66756E6374696F6E2865297B72657475726E20657D292C617C7C28613D66756E6374696F6E2865';
wwv_flow_api.g_varchar2_table(8) := '297B72657475726E20657D292C757C7C28753D66756E6374696F6E28652C74297B72657475726E206E65772846756E6374696F6E2E70726F746F747970652E62696E642E6170706C7928652C5B6E756C6C5D2E636F6E6361742866756E6374696F6E2865';
wwv_flow_api.g_varchar2_table(9) := '297B69662841727261792E69734172726179286529297B666F722876617220743D302C6E3D417272617928652E6C656E677468293B743C652E6C656E6774683B742B2B296E5B745D3D655B745D3B72657475726E206E7D72657475726E2041727261792E';
wwv_flow_api.g_varchar2_table(10) := '66726F6D2865297D2874292929297D293B76617220662C6D3D782841727261792E70726F746F747970652E666F7245616368292C643D782841727261792E70726F746F747970652E706F70292C703D782841727261792E70726F746F747970652E707573';
wwv_flow_api.g_varchar2_table(11) := '68292C673D7828537472696E672E70726F746F747970652E746F4C6F77657243617365292C683D7828537472696E672E70726F746F747970652E6D61746368292C793D7828537472696E672E70726F746F747970652E7265706C616365292C763D782853';
wwv_flow_api.g_varchar2_table(12) := '7472696E672E70726F746F747970652E696E6465784F66292C623D7828537472696E672E70726F746F747970652E7472696D292C543D78285265674578702E70726F746F747970652E74657374292C413D28663D547970654572726F722C66756E637469';
wwv_flow_api.g_varchar2_table(13) := '6F6E28297B666F722876617220653D617267756D656E74732E6C656E6774682C743D41727261792865292C6E3D303B6E3C653B6E2B2B29745B6E5D3D617267756D656E74735B6E5D3B72657475726E207528662C74297D293B66756E6374696F6E207828';
wwv_flow_api.g_varchar2_table(14) := '65297B72657475726E2066756E6374696F6E2874297B666F7228766172206E3D617267756D656E74732E6C656E6774682C723D4172726179286E3E313F6E2D313A30292C6F3D313B6F3C6E3B6F2B2B29725B6F2D315D3D617267756D656E74735B6F5D3B';
wwv_flow_api.g_varchar2_table(15) := '72657475726E207328652C742C72297D7D66756E6374696F6E207728652C72297B7426267428652C6E756C6C293B666F7228766172206F3D722E6C656E6774683B6F2D2D3B297B76617220693D725B6F5D3B69662822737472696E67223D3D747970656F';
wwv_flow_api.g_varchar2_table(16) := '662069297B76617220613D672869293B61213D3D692626286E2872297C7C28725B6F5D3D61292C693D61297D655B695D3D21307D72657475726E20657D66756E6374696F6E20532874297B766172206E3D6C286E756C6C292C723D766F696420303B666F';
wwv_flow_api.g_varchar2_table(17) := '72287220696E2074297328652C742C5B725D292626286E5B725D3D745B725D293B72657475726E206E7D66756E6374696F6E206B28652C74297B666F72283B6E756C6C213D3D653B297B766172206E3D6F28652C74293B6966286E297B6966286E2E6765';
wwv_flow_api.g_varchar2_table(18) := '742972657475726E2078286E2E676574293B6966282266756E6374696F6E223D3D747970656F66206E2E76616C75652972657475726E2078286E2E76616C7565297D653D722865297D72657475726E206E756C6C7D76617220523D69285B2261222C2261';
wwv_flow_api.g_varchar2_table(19) := '626272222C226163726F6E796D222C2261646472657373222C2261726561222C2261727469636C65222C226173696465222C22617564696F222C2262222C22626469222C2262646F222C22626967222C22626C696E6B222C22626C6F636B71756F746522';
wwv_flow_api.g_varchar2_table(20) := '2C22626F6479222C226272222C22627574746F6E222C2263616E766173222C2263617074696F6E222C2263656E746572222C2263697465222C22636F6465222C22636F6C222C22636F6C67726F7570222C22636F6E74656E74222C2264617461222C2264';
wwv_flow_api.g_varchar2_table(21) := '6174616C697374222C226464222C226465636F7261746F72222C2264656C222C2264657461696C73222C2264666E222C226469616C6F67222C22646972222C22646976222C22646C222C226474222C22656C656D656E74222C22656D222C226669656C64';
wwv_flow_api.g_varchar2_table(22) := '736574222C2266696763617074696F6E222C22666967757265222C22666F6E74222C22666F6F746572222C22666F726D222C226831222C226832222C226833222C226834222C226835222C226836222C2268656164222C22686561646572222C22686772';
wwv_flow_api.g_varchar2_table(23) := '6F7570222C226872222C2268746D6C222C2269222C22696D67222C22696E707574222C22696E73222C226B6264222C226C6162656C222C226C6567656E64222C226C69222C226D61696E222C226D6170222C226D61726B222C226D617271756565222C22';
wwv_flow_api.g_varchar2_table(24) := '6D656E75222C226D656E756974656D222C226D65746572222C226E6176222C226E6F6272222C226F6C222C226F707467726F7570222C226F7074696F6E222C226F7574707574222C2270222C2270696374757265222C22707265222C2270726F67726573';
wwv_flow_api.g_varchar2_table(25) := '73222C2271222C227270222C227274222C2272756279222C2273222C2273616D70222C2273656374696F6E222C2273656C656374222C22736861646F77222C22736D616C6C222C22736F75726365222C22737061636572222C227370616E222C22737472';
wwv_flow_api.g_varchar2_table(26) := '696B65222C227374726F6E67222C227374796C65222C22737562222C2273756D6D617279222C22737570222C227461626C65222C2274626F6479222C227464222C2274656D706C617465222C227465787461726561222C2274666F6F74222C227468222C';
wwv_flow_api.g_varchar2_table(27) := '227468656164222C2274696D65222C227472222C22747261636B222C227474222C2275222C22756C222C22766172222C22766964656F222C22776272225D292C5F3D69285B22737667222C2261222C22616C74676C797068222C22616C74676C79706864';
wwv_flow_api.g_varchar2_table(28) := '6566222C22616C74676C7970686974656D222C22616E696D617465636F6C6F72222C22616E696D6174656D6F74696F6E222C22616E696D6174657472616E73666F726D222C22636972636C65222C22636C697070617468222C2264656673222C22646573';
wwv_flow_api.g_varchar2_table(29) := '63222C22656C6C69707365222C2266696C746572222C22666F6E74222C2267222C22676C797068222C22676C797068726566222C22686B65726E222C22696D616765222C226C696E65222C226C696E6561726772616469656E74222C226D61726B657222';
wwv_flow_api.g_varchar2_table(30) := '2C226D61736B222C226D65746164617461222C226D70617468222C2270617468222C227061747465726E222C22706F6C79676F6E222C22706F6C796C696E65222C2272616469616C6772616469656E74222C2272656374222C2273746F70222C22737479';
wwv_flow_api.g_varchar2_table(31) := '6C65222C22737769746368222C2273796D626F6C222C2274657874222C227465787470617468222C227469746C65222C2274726566222C22747370616E222C2276696577222C22766B65726E225D292C443D69285B226665426C656E64222C226665436F';
wwv_flow_api.g_varchar2_table(32) := '6C6F724D6174726978222C226665436F6D706F6E656E745472616E73666572222C226665436F6D706F73697465222C226665436F6E766F6C76654D6174726978222C226665446966667573654C69676874696E67222C226665446973706C6163656D656E';
wwv_flow_api.g_varchar2_table(33) := '744D6170222C22666544697374616E744C69676874222C226665466C6F6F64222C22666546756E6341222C22666546756E6342222C22666546756E6347222C22666546756E6352222C226665476175737369616E426C7572222C2266654D65726765222C';
wwv_flow_api.g_varchar2_table(34) := '2266654D657267654E6F6465222C2266654D6F7270686F6C6F6779222C2266654F6666736574222C226665506F696E744C69676874222C22666553706563756C61724C69676874696E67222C22666553706F744C69676874222C22666554696C65222C22';
wwv_flow_api.g_varchar2_table(35) := '666554757262756C656E6365225D292C453D69285B22616E696D617465222C22636F6C6F722D70726F66696C65222C22637572736F72222C2264697363617264222C22666564726F70736861646F77222C226665696D616765222C22666F6E742D666163';
wwv_flow_api.g_varchar2_table(36) := '65222C22666F6E742D666163652D666F726D6174222C22666F6E742D666163652D6E616D65222C22666F6E742D666163652D737263222C22666F6E742D666163652D757269222C22666F726569676E6F626A656374222C226861746368222C2268617463';
wwv_flow_api.g_varchar2_table(37) := '6870617468222C226D657368222C226D6573686772616469656E74222C226D6573687061746368222C226D657368726F77222C226D697373696E672D676C797068222C22736372697074222C22736574222C22736F6C6964636F6C6F72222C22756E6B6E';
wwv_flow_api.g_varchar2_table(38) := '6F776E222C22757365225D292C4E3D69285B226D617468222C226D656E636C6F7365222C226D6572726F72222C226D66656E636564222C226D66726163222C226D676C797068222C226D69222C226D6C6162656C65647472222C226D6D756C7469736372';
wwv_flow_api.g_varchar2_table(39) := '69707473222C226D6E222C226D6F222C226D6F766572222C226D706164646564222C226D7068616E746F6D222C226D726F6F74222C226D726F77222C226D73222C226D7370616365222C226D73717274222C226D7374796C65222C226D737562222C226D';
wwv_flow_api.g_varchar2_table(40) := '737570222C226D737562737570222C226D7461626C65222C226D7464222C226D74657874222C226D7472222C226D756E646572222C226D756E6465726F766572225D292C4F3D69285B226D616374696F6E222C226D616C69676E67726F7570222C226D61';
wwv_flow_api.g_varchar2_table(41) := '6C69676E6D61726B222C226D6C6F6E67646976222C226D7363617272696573222C226D736361727279222C226D7367726F7570222C226D737461636B222C226D736C696E65222C226D73726F77222C2273656D616E74696373222C22616E6E6F74617469';
wwv_flow_api.g_varchar2_table(42) := '6F6E222C22616E6E6F746174696F6E2D786D6C222C226D70726573637269707473222C226E6F6E65225D292C4C3D69285B222374657874225D292C4D3D69285B22616363657074222C22616374696F6E222C22616C69676E222C22616C74222C22617574';
wwv_flow_api.g_varchar2_table(43) := '6F6361706974616C697A65222C226175746F636F6D706C657465222C226175746F70696374757265696E70696374757265222C226175746F706C6179222C226261636B67726F756E64222C226267636F6C6F72222C22626F72646572222C226361707475';
wwv_flow_api.g_varchar2_table(44) := '7265222C2263656C6C70616464696E67222C2263656C6C73706163696E67222C22636865636B6564222C2263697465222C22636C617373222C22636C656172222C22636F6C6F72222C22636F6C73222C22636F6C7370616E222C22636F6E74726F6C7322';
wwv_flow_api.g_varchar2_table(45) := '2C22636F6E74726F6C736C697374222C22636F6F726473222C2263726F73736F726967696E222C226461746574696D65222C226465636F64696E67222C2264656661756C74222C22646972222C2264697361626C6564222C2264697361626C6570696374';
wwv_flow_api.g_varchar2_table(46) := '757265696E70696374757265222C2264697361626C6572656D6F7465706C61796261636B222C22646F776E6C6F6164222C22647261676761626C65222C22656E6374797065222C22656E7465726B657968696E74222C2266616365222C22666F72222C22';
wwv_flow_api.g_varchar2_table(47) := '68656164657273222C22686569676874222C2268696464656E222C2268696768222C2268726566222C22687265666C616E67222C226964222C22696E7075746D6F6465222C22696E74656772697479222C2269736D6170222C226B696E64222C226C6162';
wwv_flow_api.g_varchar2_table(48) := '656C222C226C616E67222C226C697374222C226C6F6164696E67222C226C6F6F70222C226C6F77222C226D6178222C226D61786C656E677468222C226D65646961222C226D6574686F64222C226D696E222C226D696E6C656E677468222C226D756C7469';
wwv_flow_api.g_varchar2_table(49) := '706C65222C226D75746564222C226E616D65222C226E6F7368616465222C226E6F76616C6964617465222C226E6F77726170222C226F70656E222C226F7074696D756D222C227061747465726E222C22706C616365686F6C646572222C22706C61797369';
wwv_flow_api.g_varchar2_table(50) := '6E6C696E65222C22706F73746572222C227072656C6F6164222C2270756264617465222C22726164696F67726F7570222C22726561646F6E6C79222C2272656C222C227265717569726564222C22726576222C227265766572736564222C22726F6C6522';
wwv_flow_api.g_varchar2_table(51) := '2C22726F7773222C22726F777370616E222C227370656C6C636865636B222C2273636F7065222C2273656C6563746564222C227368617065222C2273697A65222C2273697A6573222C227370616E222C227372636C616E67222C227374617274222C2273';
wwv_flow_api.g_varchar2_table(52) := '7263222C22737263736574222C2273746570222C227374796C65222C2273756D6D617279222C22746162696E646578222C227469746C65222C227472616E736C617465222C2274797065222C227573656D6170222C2276616C69676E222C2276616C7565';
wwv_flow_api.g_varchar2_table(53) := '222C227769647468222C22786D6C6E73225D292C463D69285B22616363656E742D686569676874222C22616363756D756C617465222C226164646974697665222C22616C69676E6D656E742D626173656C696E65222C22617363656E74222C2261747472';
wwv_flow_api.g_varchar2_table(54) := '69627574656E616D65222C2261747472696275746574797065222C22617A696D757468222C22626173656672657175656E6379222C22626173656C696E652D7368696674222C22626567696E222C2262696173222C226279222C22636C617373222C2263';
wwv_flow_api.g_varchar2_table(55) := '6C6970222C22636C697070617468756E697473222C22636C69702D70617468222C22636C69702D72756C65222C22636F6C6F72222C22636F6C6F722D696E746572706F6C6174696F6E222C22636F6C6F722D696E746572706F6C6174696F6E2D66696C74';
wwv_flow_api.g_varchar2_table(56) := '657273222C22636F6C6F722D70726F66696C65222C22636F6C6F722D72656E646572696E67222C226378222C226379222C2264222C226478222C226479222C2264696666757365636F6E7374616E74222C22646972656374696F6E222C22646973706C61';
wwv_flow_api.g_varchar2_table(57) := '79222C2264697669736F72222C22647572222C22656467656D6F6465222C22656C65766174696F6E222C22656E64222C2266696C6C222C2266696C6C2D6F706163697479222C2266696C6C2D72756C65222C2266696C746572222C2266696C746572756E';
wwv_flow_api.g_varchar2_table(58) := '697473222C22666C6F6F642D636F6C6F72222C22666C6F6F642D6F706163697479222C22666F6E742D66616D696C79222C22666F6E742D73697A65222C22666F6E742D73697A652D61646A757374222C22666F6E742D73747265746368222C22666F6E74';
wwv_flow_api.g_varchar2_table(59) := '2D7374796C65222C22666F6E742D76617269616E74222C22666F6E742D776569676874222C226678222C226679222C226731222C226732222C22676C7970682D6E616D65222C22676C797068726566222C226772616469656E74756E697473222C226772';
wwv_flow_api.g_varchar2_table(60) := '616469656E747472616E73666F726D222C22686569676874222C2268726566222C226964222C22696D6167652D72656E646572696E67222C22696E222C22696E32222C226B222C226B31222C226B32222C226B33222C226B34222C226B65726E696E6722';
wwv_flow_api.g_varchar2_table(61) := '2C226B6579706F696E7473222C226B657973706C696E6573222C226B657974696D6573222C226C616E67222C226C656E67746861646A757374222C226C65747465722D73706163696E67222C226B65726E656C6D6174726978222C226B65726E656C756E';
wwv_flow_api.g_varchar2_table(62) := '69746C656E677468222C226C69676874696E672D636F6C6F72222C226C6F63616C222C226D61726B65722D656E64222C226D61726B65722D6D6964222C226D61726B65722D7374617274222C226D61726B6572686569676874222C226D61726B6572756E';
wwv_flow_api.g_varchar2_table(63) := '697473222C226D61726B65727769647468222C226D61736B636F6E74656E74756E697473222C226D61736B756E697473222C226D6178222C226D61736B222C226D65646961222C226D6574686F64222C226D6F6465222C226D696E222C226E616D65222C';
wwv_flow_api.g_varchar2_table(64) := '226E756D6F637461766573222C226F6666736574222C226F70657261746F72222C226F706163697479222C226F72646572222C226F7269656E74222C226F7269656E746174696F6E222C226F726967696E222C226F766572666C6F77222C227061696E74';
wwv_flow_api.g_varchar2_table(65) := '2D6F72646572222C2270617468222C22706174686C656E677468222C227061747465726E636F6E74656E74756E697473222C227061747465726E7472616E73666F726D222C227061747465726E756E697473222C22706F696E7473222C22707265736572';
wwv_flow_api.g_varchar2_table(66) := '7665616C706861222C227072657365727665617370656374726174696F222C227072696D6974697665756E697473222C2272222C227278222C227279222C22726164697573222C2272656678222C2272656679222C22726570656174636F756E74222C22';
wwv_flow_api.g_varchar2_table(67) := '726570656174647572222C2272657374617274222C22726573756C74222C22726F74617465222C227363616C65222C2273656564222C2273686170652D72656E646572696E67222C2273706563756C6172636F6E7374616E74222C2273706563756C6172';
wwv_flow_api.g_varchar2_table(68) := '6578706F6E656E74222C227370726561646D6574686F64222C2273746172746F6666736574222C22737464646576696174696F6E222C2273746974636874696C6573222C2273746F702D636F6C6F72222C2273746F702D6F706163697479222C22737472';
wwv_flow_api.g_varchar2_table(69) := '6F6B652D646173686172726179222C227374726F6B652D646173686F6666736574222C227374726F6B652D6C696E65636170222C227374726F6B652D6C696E656A6F696E222C227374726F6B652D6D697465726C696D6974222C227374726F6B652D6F70';
wwv_flow_api.g_varchar2_table(70) := '6163697479222C227374726F6B65222C227374726F6B652D7769647468222C227374796C65222C22737572666163657363616C65222C2273797374656D6C616E6775616765222C22746162696E646578222C2274617267657478222C2274617267657479';
wwv_flow_api.g_varchar2_table(71) := '222C227472616E73666F726D222C22746578742D616E63686F72222C22746578742D6465636F726174696F6E222C22746578742D72656E646572696E67222C22746578746C656E677468222C2274797065222C227531222C227532222C22756E69636F64';
wwv_flow_api.g_varchar2_table(72) := '65222C2276616C756573222C2276696577626F78222C227669736962696C697479222C2276657273696F6E222C22766572742D6164762D79222C22766572742D6F726967696E2D78222C22766572742D6F726967696E2D79222C227769647468222C2277';
wwv_flow_api.g_varchar2_table(73) := '6F72642D73706163696E67222C2277726170222C2277726974696E672D6D6F6465222C22786368616E6E656C73656C6563746F72222C22796368616E6E656C73656C6563746F72222C2278222C227831222C227832222C22786D6C6E73222C2279222C22';
wwv_flow_api.g_varchar2_table(74) := '7931222C227932222C227A222C227A6F6F6D616E6470616E225D292C433D69285B22616363656E74222C22616363656E74756E646572222C22616C69676E222C22626576656C6C6564222C22636C6F7365222C22636F6C756D6E73616C69676E222C2263';
wwv_flow_api.g_varchar2_table(75) := '6F6C756D6E6C696E6573222C22636F6C756D6E7370616E222C2264656E6F6D616C69676E222C226465707468222C22646972222C22646973706C6179222C22646973706C61797374796C65222C22656E636F64696E67222C2266656E6365222C22667261';
wwv_flow_api.g_varchar2_table(76) := '6D65222C22686569676874222C2268726566222C226964222C226C617267656F70222C226C656E677468222C226C696E65746869636B6E657373222C226C7370616365222C226C71756F7465222C226D6174686261636B67726F756E64222C226D617468';
wwv_flow_api.g_varchar2_table(77) := '636F6C6F72222C226D61746873697A65222C226D61746876617269616E74222C226D617873697A65222C226D696E73697A65222C226D6F7661626C656C696D697473222C226E6F746174696F6E222C226E756D616C69676E222C226F70656E222C22726F';
wwv_flow_api.g_varchar2_table(78) := '77616C69676E222C22726F776C696E6573222C22726F7773706163696E67222C22726F777370616E222C22727370616365222C227271756F7465222C227363726970746C6576656C222C227363726970746D696E73697A65222C2273637269707473697A';

wwv_flow_api.g_varchar2_table(79) := '656D756C7469706C696572222C2273656C656374696F6E222C22736570617261746F72222C22736570617261746F7273222C227374726574636879222C227375627363726970747368696674222C227375707363726970747368696674222C2273796D6D';
wwv_flow_api.g_varchar2_table(80) := '6574726963222C22766F6666736574222C227769647468222C22786D6C6E73225D292C493D69285B22786C696E6B3A68726566222C22786D6C3A6964222C22786C696E6B3A7469746C65222C22786D6C3A7370616365222C22786D6C6E733A786C696E6B';
wwv_flow_api.g_varchar2_table(81) := '225D292C7A3D61282F5C7B5C7B5B5C735C535D2A7C5B5C735C535D2A5C7D5C7D2F676D292C483D61282F3C255B5C735C535D2A7C5B5C735C535D2A253E2F676D292C553D61282F5E646174612D5B5C2D5C772E5C75303042372D5C75464646465D2F292C';
wwv_flow_api.g_varchar2_table(82) := '6A3D61282F5E617269612D5B5C2D5C775D2B242F292C503D61282F5E283F3A283F3A283F3A667C6874297470733F7C6D61696C746F7C74656C7C63616C6C746F7C6369647C786D7070293A7C5B5E612D7A5D7C5B612D7A2B2E5C2D5D2B283F3A5B5E612D';
wwv_flow_api.g_varchar2_table(83) := '7A2B2E5C2D3A5D7C2429292F69292C423D61282F5E283F3A5C772B7363726970747C64617461293A2F69292C573D61282F5B5C75303030302D5C75303032305C75303041305C75313638305C75313830455C75323030302D5C75323032395C7532303546';
wwv_flow_api.g_varchar2_table(84) := '5C75333030305D2F67292C473D2266756E6374696F6E223D3D747970656F662053796D626F6C26262273796D626F6C223D3D747970656F662053796D626F6C2E6974657261746F723F66756E6374696F6E2865297B72657475726E20747970656F662065';
wwv_flow_api.g_varchar2_table(85) := '7D3A66756E6374696F6E2865297B72657475726E206526262266756E6374696F6E223D3D747970656F662053796D626F6C2626652E636F6E7374727563746F723D3D3D53796D626F6C262665213D3D53796D626F6C2E70726F746F747970653F2273796D';
wwv_flow_api.g_varchar2_table(86) := '626F6C223A747970656F6620657D3B66756E6374696F6E20712865297B69662841727261792E69734172726179286529297B666F722876617220743D302C6E3D417272617928652E6C656E677468293B743C652E6C656E6774683B742B2B296E5B745D3D';
wwv_flow_api.g_varchar2_table(87) := '655B745D3B72657475726E206E7D72657475726E2041727261792E66726F6D2865297D766172204B3D66756E6374696F6E28297B72657475726E22756E646566696E6564223D3D747970656F662077696E646F773F6E756C6C3A77696E646F777D2C563D';
wwv_flow_api.g_varchar2_table(88) := '66756E6374696F6E28652C74297B696628226F626A65637422213D3D28766F696420303D3D3D653F22756E646566696E6564223A47286529297C7C2266756E6374696F6E22213D747970656F6620652E637265617465506F6C6963792972657475726E20';
wwv_flow_api.g_varchar2_table(89) := '6E756C6C3B766172206E3D6E756C6C2C723D22646174612D74742D706F6C6963792D737566666978223B742E63757272656E745363726970742626742E63757272656E745363726970742E6861734174747269627574652872292626286E3D742E637572';
wwv_flow_api.g_varchar2_table(90) := '72656E745363726970742E676574417474726962757465287229293B766172206F3D22646F6D707572696679222B286E3F2223222B6E3A2222293B7472797B72657475726E20652E637265617465506F6C696379286F2C7B63726561746548544D4C3A66';
wwv_flow_api.g_varchar2_table(91) := '756E6374696F6E2865297B72657475726E20657D7D297D63617463682865297B72657475726E20636F6E736F6C652E7761726E282254727573746564547970657320706F6C69637920222B6F2B2220636F756C64206E6F7420626520637265617465642E';
wwv_flow_api.g_varchar2_table(92) := '22292C6E756C6C7D7D3B72657475726E2066756E6374696F6E206528297B76617220743D617267756D656E74732E6C656E6774683E302626766F69642030213D3D617267756D656E74735B305D3F617267756D656E74735B305D3A4B28292C6E3D66756E';
wwv_flow_api.g_varchar2_table(93) := '6374696F6E2874297B72657475726E20652874297D3B6966286E2E76657273696F6E3D22322E322E36222C6E2E72656D6F7665643D5B5D2C21747C7C21742E646F63756D656E747C7C39213D3D742E646F63756D656E742E6E6F64655479706529726574';
wwv_flow_api.g_varchar2_table(94) := '75726E206E2E6973537570706F727465643D21312C6E3B76617220723D742E646F63756D656E742C6F3D742E646F63756D656E742C613D742E446F63756D656E74467261676D656E742C6C3D742E48544D4C54656D706C617465456C656D656E742C633D';
wwv_flow_api.g_varchar2_table(95) := '742E4E6F64652C733D742E456C656D656E742C753D742E4E6F646546696C7465722C663D742E4E616D65644E6F64654D61702C783D766F696420303D3D3D663F742E4E616D65644E6F64654D61707C7C742E4D6F7A4E616D6564417474724D61703A662C';
wwv_flow_api.g_varchar2_table(96) := '593D742E546578742C583D742E436F6D6D656E742C243D742E444F4D5061727365722C5A3D742E7472757374656454797065732C4A3D732E70726F746F747970652C513D6B284A2C22636C6F6E654E6F646522292C65653D6B284A2C226E657874536962';
wwv_flow_api.g_varchar2_table(97) := '6C696E6722292C74653D6B284A2C226368696C644E6F64657322292C6E653D6B284A2C22706172656E744E6F646522293B6966282266756E6374696F6E223D3D747970656F66206C297B7661722072653D6F2E637265617465456C656D656E7428227465';
wwv_flow_api.g_varchar2_table(98) := '6D706C61746522293B72652E636F6E74656E74262672652E636F6E74656E742E6F776E6572446F63756D656E742626286F3D72652E636F6E74656E742E6F776E6572446F63756D656E74297D766172206F653D56285A2C72292C69653D6F6526267A653F';
wwv_flow_api.g_varchar2_table(99) := '6F652E63726561746548544D4C282222293A22222C61653D6F2C6C653D61652E696D706C656D656E746174696F6E2C63653D61652E6372656174654E6F64654974657261746F722C73653D61652E676574456C656D656E747342795461674E616D652C75';
wwv_flow_api.g_varchar2_table(100) := '653D61652E637265617465446F63756D656E74467261676D656E742C66653D722E696D706F72744E6F64652C6D653D7B7D3B7472797B6D653D53286F292E646F63756D656E744D6F64653F6F2E646F63756D656E744D6F64653A7B7D7D63617463682865';
wwv_flow_api.g_varchar2_table(101) := '297B7D7661722064653D7B7D3B6E2E6973537570706F727465643D6C652626766F69642030213D3D6C652E63726561746548544D4C446F63756D656E74262639213D3D6D653B7661722070653D7A2C67653D482C68653D552C79653D6A2C76653D422C62';
wwv_flow_api.g_varchar2_table(102) := '653D572C54653D502C41653D6E756C6C2C78653D77287B7D2C5B5D2E636F6E63617428712852292C71285F292C712844292C71284E292C71284C2929292C77653D6E756C6C2C53653D77287B7D2C5B5D2E636F6E6361742871284D292C712846292C7128';
wwv_flow_api.g_varchar2_table(103) := '43292C7128492929292C6B653D6E756C6C2C52653D6E756C6C2C5F653D21302C44653D21302C45653D21312C4E653D21312C4F653D21312C4C653D21312C4D653D21312C46653D21312C43653D21312C49653D21302C7A653D21312C48653D21302C5565';
wwv_flow_api.g_varchar2_table(104) := '3D21302C6A653D21312C50653D7B7D2C42653D77287B7D2C5B22616E6E6F746174696F6E2D786D6C222C22617564696F222C22636F6C67726F7570222C2264657363222C22666F726569676E6F626A656374222C2268656164222C22696672616D65222C';
wwv_flow_api.g_varchar2_table(105) := '226D617468222C226D69222C226D6E222C226D6F222C226D73222C226D74657874222C226E6F656D626564222C226E6F6672616D6573222C226E6F736372697074222C22706C61696E74657874222C22736372697074222C227374796C65222C22737667';
wwv_flow_api.g_varchar2_table(106) := '222C2274656D706C617465222C227468656164222C227469746C65222C22766964656F222C22786D70225D292C57653D6E756C6C2C47653D77287B7D2C5B22617564696F222C22766964656F222C22696D67222C22736F75726365222C22696D61676522';
wwv_flow_api.g_varchar2_table(107) := '2C22747261636B225D292C71653D6E756C6C2C4B653D77287B7D2C5B22616C74222C22636C617373222C22666F72222C226964222C226C6162656C222C226E616D65222C227061747465726E222C22706C616365686F6C646572222C2273756D6D617279';
wwv_flow_api.g_varchar2_table(108) := '222C227469746C65222C2276616C7565222C227374796C65222C22786D6C6E73225D292C56653D6E756C6C2C59653D6F2E637265617465456C656D656E742822666F726D22292C58653D66756E6374696F6E2865297B5665262656653D3D3D657C7C2865';
wwv_flow_api.g_varchar2_table(109) := '2626226F626A656374223D3D3D28766F696420303D3D3D653F22756E646566696E6564223A47286529297C7C28653D7B7D292C653D532865292C41653D22414C4C4F5745445F5441475322696E20653F77287B7D2C652E414C4C4F5745445F5441475329';
wwv_flow_api.g_varchar2_table(110) := '3A78652C77653D22414C4C4F5745445F4154545222696E20653F77287B7D2C652E414C4C4F5745445F41545452293A53652C71653D224144445F5552495F534146455F4154545222696E20653F772853284B65292C652E4144445F5552495F534146455F';
wwv_flow_api.g_varchar2_table(111) := '41545452293A4B652C57653D224144445F444154415F5552495F5441475322696E20653F772853284765292C652E4144445F444154415F5552495F54414753293A47652C6B653D22464F524249445F5441475322696E20653F77287B7D2C652E464F5242';
wwv_flow_api.g_varchar2_table(112) := '49445F54414753293A7B7D2C52653D22464F524249445F4154545222696E20653F77287B7D2C652E464F524249445F41545452293A7B7D2C50653D225553455F50524F46494C455322696E20652626652E5553455F50524F46494C45532C5F653D213121';
wwv_flow_api.g_varchar2_table(113) := '3D3D652E414C4C4F575F415249415F415454522C44653D2131213D3D652E414C4C4F575F444154415F415454522C45653D652E414C4C4F575F554E4B4E4F574E5F50524F544F434F4C537C7C21312C4E653D652E534146455F464F525F54454D504C4154';
wwv_flow_api.g_varchar2_table(114) := '45537C7C21312C4F653D652E57484F4C455F444F43554D454E547C7C21312C46653D652E52455455524E5F444F4D7C7C21312C43653D652E52455455524E5F444F4D5F465241474D454E547C7C21312C49653D2131213D3D652E52455455524E5F444F4D';
wwv_flow_api.g_varchar2_table(115) := '5F494D504F52542C7A653D652E52455455524E5F545255535445445F545950457C7C21312C4D653D652E464F5243455F424F44597C7C21312C48653D2131213D3D652E53414E4954495A455F444F4D2C55653D2131213D3D652E4B4545505F434F4E5445';
wwv_flow_api.g_varchar2_table(116) := '4E542C6A653D652E494E5F504C4143457C7C21312C54653D652E414C4C4F5745445F5552495F5245474558507C7C54652C4E6526262844653D2131292C436526262846653D2130292C506526262841653D77287B7D2C5B5D2E636F6E6361742871284C29';
wwv_flow_api.g_varchar2_table(117) := '29292C77653D5B5D2C21303D3D3D50652E68746D6C262628772841652C52292C772877652C4D29292C21303D3D3D50652E737667262628772841652C5F292C772877652C46292C772877652C4929292C21303D3D3D50652E73766746696C746572732626';
wwv_flow_api.g_varchar2_table(118) := '28772841652C44292C772877652C46292C772877652C4929292C21303D3D3D50652E6D6174684D6C262628772841652C4E292C772877652C43292C772877652C492929292C652E4144445F5441475326262841653D3D3D786526262841653D5328416529';
wwv_flow_api.g_varchar2_table(119) := '292C772841652C652E4144445F5441475329292C652E4144445F4154545226262877653D3D3D536526262877653D5328776529292C772877652C652E4144445F4154545229292C652E4144445F5552495F534146455F415454522626772871652C652E41';
wwv_flow_api.g_varchar2_table(120) := '44445F5552495F534146455F41545452292C556526262841655B222374657874225D3D2130292C4F652626772841652C5B2268746D6C222C2268656164222C22626F6479225D292C41652E7461626C65262628772841652C5B2274626F6479225D292C64';
wwv_flow_api.g_varchar2_table(121) := '656C657465206B652E74626F6479292C692626692865292C56653D65297D2C24653D77287B7D2C5B226D69222C226D6F222C226D6E222C226D73222C226D74657874225D292C5A653D77287B7D2C5B22666F726569676E6F626A656374222C2264657363';
wwv_flow_api.g_varchar2_table(122) := '222C227469746C65222C22616E6E6F746174696F6E2D786D6C225D292C4A653D77287B7D2C5F293B77284A652C44292C77284A652C45293B7661722051653D77287B7D2C4E293B772851652C4F293B7661722065743D22687474703A2F2F7777772E7733';
wwv_flow_api.g_varchar2_table(123) := '2E6F72672F313939382F4D6174682F4D6174684D4C222C74743D22687474703A2F2F7777772E77332E6F72672F323030302F737667222C6E743D22687474703A2F2F7777772E77332E6F72672F313939392F7868746D6C222C72743D66756E6374696F6E';
wwv_flow_api.g_varchar2_table(124) := '2865297B76617220743D6E652865293B742626742E7461674E616D657C7C28743D7B6E616D6573706163655552493A6E742C7461674E616D653A2274656D706C617465227D293B766172206E3D6728652E7461674E616D65292C723D6728742E7461674E';
wwv_flow_api.g_varchar2_table(125) := '616D65293B696628652E6E616D6573706163655552493D3D3D74742972657475726E20742E6E616D6573706163655552493D3D3D6E743F22737667223D3D3D6E3A742E6E616D6573706163655552493D3D3D65743F22737667223D3D3D6E26262822616E';
wwv_flow_api.g_varchar2_table(126) := '6E6F746174696F6E2D786D6C223D3D3D727C7C24655B725D293A426F6F6C65616E284A655B6E5D293B696628652E6E616D6573706163655552493D3D3D65742972657475726E20742E6E616D6573706163655552493D3D3D6E743F226D617468223D3D3D';
wwv_flow_api.g_varchar2_table(127) := '6E3A742E6E616D6573706163655552493D3D3D74743F226D617468223D3D3D6E26265A655B725D3A426F6F6C65616E2851655B6E5D293B696628652E6E616D6573706163655552493D3D3D6E74297B696628742E6E616D6573706163655552493D3D3D74';
wwv_flow_api.g_varchar2_table(128) := '742626215A655B725D2972657475726E21313B696628742E6E616D6573706163655552493D3D3D657426262124655B725D2972657475726E21313B766172206F3D77287B7D2C5B227469746C65222C227374796C65222C22666F6E74222C2261222C2273';
wwv_flow_api.g_varchar2_table(129) := '6372697074225D293B72657475726E2151655B6E5D2626286F5B6E5D7C7C214A655B6E5D297D72657475726E21317D2C6F743D66756E6374696F6E2865297B70286E2E72656D6F7665642C7B656C656D656E743A657D293B7472797B652E706172656E74';
wwv_flow_api.g_varchar2_table(130) := '4E6F64652E72656D6F76654368696C642865297D63617463682874297B7472797B652E6F7574657248544D4C3D69657D63617463682874297B652E72656D6F766528297D7D7D2C69743D66756E6374696F6E28652C74297B7472797B70286E2E72656D6F';
wwv_flow_api.g_varchar2_table(131) := '7665642C7B6174747269627574653A742E6765744174747269627574654E6F64652865292C66726F6D3A747D297D63617463682865297B70286E2E72656D6F7665642C7B6174747269627574653A6E756C6C2C66726F6D3A747D297D742E72656D6F7665';
wwv_flow_api.g_varchar2_table(132) := '4174747269627574652865297D2C61743D66756E6374696F6E2865297B76617220743D766F696420302C6E3D766F696420303B6966284D6529653D223C72656D6F76653E3C2F72656D6F76653E222B653B656C73657B76617220723D6828652C2F5E5B5C';
wwv_flow_api.g_varchar2_table(133) := '725C6E5C74205D2B2F293B6E3D722626725B305D7D76617220693D6F653F6F652E63726561746548544D4C2865293A653B7472797B743D286E65772024292E706172736546726F6D537472696E6728692C22746578742F68746D6C22297D636174636828';
wwv_flow_api.g_varchar2_table(134) := '65297B7D69662821747C7C21742E646F63756D656E74456C656D656E74297B76617220613D28743D6C652E63726561746548544D4C446F63756D656E7428222229292E626F64793B612E706172656E744E6F64652E72656D6F76654368696C6428612E70';
wwv_flow_api.g_varchar2_table(135) := '6172656E744E6F64652E6669727374456C656D656E744368696C64292C612E6F7574657248544D4C3D697D72657475726E206526266E2626742E626F64792E696E736572744265666F7265286F2E637265617465546578744E6F6465286E292C742E626F';
wwv_flow_api.g_varchar2_table(136) := '64792E6368696C644E6F6465735B305D7C7C6E756C6C292C73652E63616C6C28742C4F653F2268746D6C223A22626F647922295B305D7D2C6C743D66756E6374696F6E2865297B72657475726E2063652E63616C6C28652E6F776E6572446F63756D656E';
wwv_flow_api.g_varchar2_table(137) := '747C7C652C652C752E53484F575F454C454D454E547C752E53484F575F434F4D4D454E547C752E53484F575F544558542C2866756E6374696F6E28297B72657475726E20752E46494C5445525F4143434550547D292C2131297D2C63743D66756E637469';
wwv_flow_api.g_varchar2_table(138) := '6F6E2865297B72657475726E21286520696E7374616E63656F6620597C7C6520696E7374616E63656F662058292626212822737472696E67223D3D747970656F6620652E6E6F64654E616D65262622737472696E67223D3D747970656F6620652E746578';
wwv_flow_api.g_varchar2_table(139) := '74436F6E74656E7426262266756E6374696F6E223D3D747970656F6620652E72656D6F76654368696C642626652E6174747269627574657320696E7374616E63656F66207826262266756E6374696F6E223D3D747970656F6620652E72656D6F76654174';
wwv_flow_api.g_varchar2_table(140) := '7472696275746526262266756E6374696F6E223D3D747970656F6620652E736574417474726962757465262622737472696E67223D3D747970656F6620652E6E616D65737061636555524926262266756E6374696F6E223D3D747970656F6620652E696E';
wwv_flow_api.g_varchar2_table(141) := '736572744265666F7265297D2C73743D66756E6374696F6E2865297B72657475726E226F626A656374223D3D3D28766F696420303D3D3D633F22756E646566696E6564223A47286329293F6520696E7374616E63656F6620633A652626226F626A656374';
wwv_flow_api.g_varchar2_table(142) := '223D3D3D28766F696420303D3D3D653F22756E646566696E6564223A47286529292626226E756D626572223D3D747970656F6620652E6E6F646554797065262622737472696E67223D3D747970656F6620652E6E6F64654E616D657D2C75743D66756E63';
wwv_flow_api.g_varchar2_table(143) := '74696F6E28652C742C72297B64655B655D26266D2864655B655D2C2866756E6374696F6E2865297B652E63616C6C286E2C742C722C5665297D29297D2C66743D66756E6374696F6E2865297B76617220743D766F696420303B696628757428226265666F';
wwv_flow_api.g_varchar2_table(144) := '726553616E6974697A65456C656D656E7473222C652C6E756C6C292C63742865292972657475726E206F742865292C21303B6966286828652E6E6F64654E616D652C2F5B5C75303038302D5C75464646465D2F292972657475726E206F742865292C2130';
wwv_flow_api.g_varchar2_table(145) := '3B76617220723D6728652E6E6F64654E616D65293B6966287574282275706F6E53616E6974697A65456C656D656E74222C652C7B7461674E616D653A722C616C6C6F776564546167733A41657D292C21737428652E6669727374456C656D656E74436869';
wwv_flow_api.g_varchar2_table(146) := '6C642926262821737428652E636F6E74656E74297C7C21737428652E636F6E74656E742E6669727374456C656D656E744368696C642929262654282F3C5B2F5C775D2F672C652E696E6E657248544D4C29262654282F3C5B2F5C775D2F672C652E746578';
wwv_flow_api.g_varchar2_table(147) := '74436F6E74656E74292972657475726E206F742865292C21303B6966282141655B725D7C7C6B655B725D297B696628556526262142655B725D29666F7228766172206F3D6E652865292C693D74652865292C613D692E6C656E6774682D313B613E3D303B';
wwv_flow_api.g_varchar2_table(148) := '2D2D61296F2E696E736572744265666F7265285128695B615D2C2130292C6565286529293B72657475726E206F742865292C21307D72657475726E206520696E7374616E63656F66207326262172742865293F286F742865292C2130293A226E6F736372';
wwv_flow_api.g_varchar2_table(149) := '69707422213D3D722626226E6F656D62656422213D3D727C7C2154282F3C5C2F6E6F287363726970747C656D626564292F692C652E696E6E657248544D4C293F284E652626333D3D3D652E6E6F646554797065262628743D652E74657874436F6E74656E';
wwv_flow_api.g_varchar2_table(150) := '742C743D7928742C70652C222022292C743D7928742C67652C222022292C652E74657874436F6E74656E74213D3D7426262870286E2E72656D6F7665642C7B656C656D656E743A652E636C6F6E654E6F646528297D292C652E74657874436F6E74656E74';
wwv_flow_api.g_varchar2_table(151) := '3D7429292C75742822616674657253616E6974697A65456C656D656E7473222C652C6E756C6C292C2131293A286F742865292C2130297D2C6D743D66756E6374696F6E28652C742C6E297B6966284865262628226964223D3D3D747C7C226E616D65223D';
wwv_flow_api.g_varchar2_table(152) := '3D3D74292626286E20696E206F7C7C6E20696E205965292972657475726E21313B69662844652626542868652C7429293B656C7365206966285F652626542879652C7429293B656C73657B6966282177655B745D7C7C52655B745D2972657475726E2131';
wwv_flow_api.g_varchar2_table(153) := '3B69662871655B745D293B656C736520696628542854652C79286E2C62652C22222929293B656C7365206966282273726322213D3D74262622786C696E6B3A6872656622213D3D742626226872656622213D3D747C7C22736372697074223D3D3D657C7C';
wwv_flow_api.g_varchar2_table(154) := '30213D3D76286E2C22646174613A22297C7C2157655B655D297B6966284565262621542876652C79286E2C62652C22222929293B656C7365206966286E2972657475726E21317D656C73653B7D72657475726E21307D2C64743D66756E6374696F6E2865';
wwv_flow_api.g_varchar2_table(155) := '297B76617220743D766F696420302C723D766F696420302C6F3D766F696420302C693D766F696420303B757428226265666F726553616E6974697A6541747472696275746573222C652C6E756C6C293B76617220613D652E617474726962757465733B69';
wwv_flow_api.g_varchar2_table(156) := '662861297B766172206C3D7B617474724E616D653A22222C6174747256616C75653A22222C6B656570417474723A21302C616C6C6F776564417474726962757465733A77657D3B666F7228693D612E6C656E6774683B692D2D3B297B76617220633D743D';
wwv_flow_api.g_varchar2_table(157) := '615B695D2C733D632E6E616D652C753D632E6E616D6573706163655552493B696628723D6228742E76616C7565292C6F3D672873292C6C2E617474724E616D653D6F2C6C2E6174747256616C75653D722C6C2E6B656570417474723D21302C6C2E666F72';
wwv_flow_api.g_varchar2_table(158) := '63654B656570417474723D766F696420302C7574282275706F6E53616E6974697A65417474726962757465222C652C6C292C723D6C2E6174747256616C75652C216C2E666F7263654B65657041747472262628697428732C65292C6C2E6B656570417474';
wwv_flow_api.g_varchar2_table(159) := '72292969662854282F5C2F3E2F692C722929697428732C65293B656C73657B4E65262628723D7928722C70652C222022292C723D7928722C67652C22202229293B76617220663D652E6E6F64654E616D652E746F4C6F7765724361736528293B6966286D';
wwv_flow_api.g_varchar2_table(160) := '7428662C6F2C7229297472797B753F652E7365744174747269627574654E5328752C732C72293A652E73657441747472696275746528732C72292C64286E2E72656D6F766564297D63617463682865297B7D7D7D75742822616674657253616E6974697A';
wwv_flow_api.g_varchar2_table(161) := '6541747472696275746573222C652C6E756C6C297D7D2C70743D66756E6374696F6E20652874297B766172206E3D766F696420302C723D6C742874293B666F7228757428226265666F726553616E6974697A65536861646F77444F4D222C742C6E756C6C';
wwv_flow_api.g_varchar2_table(162) := '293B6E3D722E6E6578744E6F646528293B297574282275706F6E53616E6974697A65536861646F774E6F6465222C6E2C6E756C6C292C6674286E297C7C286E2E636F6E74656E7420696E7374616E63656F662061262665286E2E636F6E74656E74292C64';
wwv_flow_api.g_varchar2_table(163) := '74286E29293B75742822616674657253616E6974697A65536861646F77444F4D222C742C6E756C6C297D3B72657475726E206E2E73616E6974697A653D66756E6374696F6E28652C6F297B76617220693D766F696420302C6C3D766F696420302C733D76';
wwv_flow_api.g_varchar2_table(164) := '6F696420302C753D766F696420302C663D766F696420303B696628657C7C28653D225C783363212D2D5C78336522292C22737472696E6722213D747970656F6620652626217374286529297B6966282266756E6374696F6E22213D747970656F6620652E';
wwv_flow_api.g_varchar2_table(165) := '746F537472696E67297468726F7720412822746F537472696E67206973206E6F7420612066756E6374696F6E22293B69662822737472696E6722213D747970656F6628653D652E746F537472696E67282929297468726F77204128226469727479206973';
wwv_flow_api.g_varchar2_table(166) := '206E6F74206120737472696E672C2061626F7274696E6722297D696628216E2E6973537570706F72746564297B696628226F626A656374223D3D3D4728742E746F53746174696348544D4C297C7C2266756E6374696F6E223D3D747970656F6620742E74';
wwv_flow_api.g_varchar2_table(167) := '6F53746174696348544D4C297B69662822737472696E67223D3D747970656F6620652972657475726E20742E746F53746174696348544D4C2865293B69662873742865292972657475726E20742E746F53746174696348544D4C28652E6F757465724854';
wwv_flow_api.g_varchar2_table(168) := '4D4C297D72657475726E20657D6966284C657C7C5865286F292C6E2E72656D6F7665643D5B5D2C22737472696E67223D3D747970656F6620652626286A653D2131292C6A65293B656C7365206966286520696E7374616E63656F66206329313D3D3D286C';
wwv_flow_api.g_varchar2_table(169) := '3D28693D617428225C783363212D2D2D2D5C7833652229292E6F776E6572446F63756D656E742E696D706F72744E6F646528652C213029292E6E6F646554797065262622424F4459223D3D3D6C2E6E6F64654E616D657C7C2248544D4C223D3D3D6C2E6E';
wwv_flow_api.g_varchar2_table(170) := '6F64654E616D653F693D6C3A692E617070656E644368696C64286C293B656C73657B6966282146652626214E652626214F6526262D313D3D3D652E696E6465784F6628223C22292972657475726E206F6526267A653F6F652E63726561746548544D4C28';
wwv_flow_api.g_varchar2_table(171) := '65293A653B6966282128693D6174286529292972657475726E2046653F6E756C6C3A69657D6926264D6526266F7428692E66697273744368696C64293B666F7228766172206D3D6C74286A653F653A69293B733D6D2E6E6578744E6F646528293B29333D';
wwv_flow_api.g_varchar2_table(172) := '3D3D732E6E6F6465547970652626733D3D3D757C7C66742873297C7C28732E636F6E74656E7420696E7374616E63656F6620612626707428732E636F6E74656E74292C64742873292C753D73293B696628753D6E756C6C2C6A652972657475726E20653B';
wwv_flow_api.g_varchar2_table(173) := '6966284665297B696628436529666F7228663D75652E63616C6C28692E6F776E6572446F63756D656E74293B692E66697273744368696C643B29662E617070656E644368696C6428692E66697273744368696C64293B656C736520663D693B7265747572';
wwv_flow_api.g_varchar2_table(174) := '6E204965262628663D66652E63616C6C28722C662C213029292C667D76617220643D4F653F692E6F7574657248544D4C3A692E696E6E657248544D4C3B72657475726E204E65262628643D7928642C70652C222022292C643D7928642C67652C22202229';
wwv_flow_api.g_varchar2_table(175) := '292C6F6526267A653F6F652E63726561746548544D4C2864293A647D2C6E2E736574436F6E6669673D66756E6374696F6E2865297B58652865292C4C653D21307D2C6E2E636C656172436F6E6669673D66756E6374696F6E28297B56653D6E756C6C2C4C';
wwv_flow_api.g_varchar2_table(176) := '653D21317D2C6E2E697356616C69644174747269627574653D66756E6374696F6E28652C742C6E297B56657C7C5865287B7D293B76617220723D672865292C6F3D672874293B72657475726E206D7428722C6F2C6E297D2C6E2E616464486F6F6B3D6675';
wwv_flow_api.g_varchar2_table(177) := '6E6374696F6E28652C74297B2266756E6374696F6E223D3D747970656F66207426262864655B655D3D64655B655D7C7C5B5D2C702864655B655D2C7429297D2C6E2E72656D6F7665486F6F6B3D66756E6374696F6E2865297B64655B655D262664286465';
wwv_flow_api.g_varchar2_table(178) := '5B655D297D2C6E2E72656D6F7665486F6F6B733D66756E6374696F6E2865297B64655B655D26262864655B655D3D5B5D297D2C6E2E72656D6F7665416C6C486F6F6B733D66756E6374696F6E28297B64653D7B7D7D2C6E7D28297D29293B0A2F2F232073';
wwv_flow_api.g_varchar2_table(179) := '6F757263654D617070696E6755524C3D7075726966792E6D696E2E6A732E6D61700A';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(106689985163525312)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_file_name=>'js/dompurify/2.2.6/purify.min.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A2120406C6963656E736520444F4D507572696679207C202863292043757265353320616E64206F7468657220636F6E7472696275746F7273207C2052656C656173656420756E6465722074686520417061636865206C6963656E736520322E302061';
wwv_flow_api.g_varchar2_table(2) := '6E64204D6F7A696C6C61205075626C6963204C6963656E736520322E30207C206769746875622E636F6D2F6375726535332F444F4D5075726966792F626C6F622F322E322E322F4C4943454E5345202A2F0A0A2866756E6374696F6E2028676C6F62616C';
wwv_flow_api.g_varchar2_table(3) := '2C20666163746F727929207B0A2020747970656F66206578706F727473203D3D3D20276F626A6563742720262620747970656F66206D6F64756C6520213D3D2027756E646566696E656427203F206D6F64756C652E6578706F727473203D20666163746F';
wwv_flow_api.g_varchar2_table(4) := '72792829203A0A2020747970656F6620646566696E65203D3D3D202766756E6374696F6E2720262620646566696E652E616D64203F20646566696E6528666163746F727929203A0A202028676C6F62616C203D20676C6F62616C207C7C2073656C662C20';
wwv_flow_api.g_varchar2_table(5) := '676C6F62616C2E444F4D507572696679203D20666163746F72792829293B0A7D28746869732C2066756E6374696F6E202829207B202775736520737472696374273B0A0A202066756E6374696F6E205F746F436F6E73756D61626C654172726179286172';
wwv_flow_api.g_varchar2_table(6) := '7229207B206966202841727261792E69734172726179286172722929207B20666F7220287661722069203D20302C2061727232203D204172726179286172722E6C656E677468293B2069203C206172722E6C656E6774683B20692B2B29207B2061727232';
wwv_flow_api.g_varchar2_table(7) := '5B695D203D206172725B695D3B207D2072657475726E20617272323B207D20656C7365207B2072657475726E2041727261792E66726F6D28617272293B207D207D0A0A2020766172206861734F776E50726F7065727479203D204F626A6563742E686173';
wwv_flow_api.g_varchar2_table(8) := '4F776E50726F70657274792C0A20202020202073657450726F746F747970654F66203D204F626A6563742E73657450726F746F747970654F662C0A202020202020697346726F7A656E203D204F626A6563742E697346726F7A656E2C0A20202020202067';
wwv_flow_api.g_varchar2_table(9) := '657450726F746F747970654F66203D204F626A6563742E67657450726F746F747970654F662C0A2020202020206765744F776E50726F706572747944657363726970746F72203D204F626A6563742E6765744F776E50726F706572747944657363726970';
wwv_flow_api.g_varchar2_table(10) := '746F723B0A202076617220667265657A65203D204F626A6563742E667265657A652C0A2020202020207365616C203D204F626A6563742E7365616C2C0A202020202020637265617465203D204F626A6563742E6372656174653B202F2F2065736C696E74';
wwv_flow_api.g_varchar2_table(11) := '2D64697361626C652D6C696E6520696D706F72742F6E6F2D6D757461626C652D6578706F7274730A0A2020766172205F726566203D20747970656F66205265666C65637420213D3D2027756E646566696E656427202626205265666C6563742C0A202020';
wwv_flow_api.g_varchar2_table(12) := '2020206170706C79203D205F7265662E6170706C792C0A202020202020636F6E737472756374203D205F7265662E636F6E7374727563743B0A0A202069662028216170706C7929207B0A202020206170706C79203D2066756E6374696F6E206170706C79';
wwv_flow_api.g_varchar2_table(13) := '2866756E2C207468697356616C75652C206172677329207B0A20202020202072657475726E2066756E2E6170706C79287468697356616C75652C2061726773293B0A202020207D3B0A20207D0A0A20206966202821667265657A6529207B0A2020202066';
wwv_flow_api.g_varchar2_table(14) := '7265657A65203D2066756E6374696F6E20667265657A65287829207B0A20202020202072657475726E20783B0A202020207D3B0A20207D0A0A202069662028217365616C29207B0A202020207365616C203D2066756E6374696F6E207365616C28782920';
wwv_flow_api.g_varchar2_table(15) := '7B0A20202020202072657475726E20783B0A202020207D3B0A20207D0A0A20206966202821636F6E73747275637429207B0A20202020636F6E737472756374203D2066756E6374696F6E20636F6E7374727563742846756E632C206172677329207B0A20';
wwv_flow_api.g_varchar2_table(16) := '202020202072657475726E206E6577202846756E6374696F6E2E70726F746F747970652E62696E642E6170706C792846756E632C205B6E756C6C5D2E636F6E636174285F746F436F6E73756D61626C65417272617928617267732929292928293B0A2020';
wwv_flow_api.g_varchar2_table(17) := '20207D3B0A20207D0A0A2020766172206172726179466F7245616368203D20756E6170706C792841727261792E70726F746F747970652E666F7245616368293B0A2020766172206172726179506F70203D20756E6170706C792841727261792E70726F74';
wwv_flow_api.g_varchar2_table(18) := '6F747970652E706F70293B0A202076617220617272617950757368203D20756E6170706C792841727261792E70726F746F747970652E70757368293B0A0A202076617220737472696E67546F4C6F77657243617365203D20756E6170706C792853747269';
wwv_flow_api.g_varchar2_table(19) := '6E672E70726F746F747970652E746F4C6F77657243617365293B0A202076617220737472696E674D61746368203D20756E6170706C7928537472696E672E70726F746F747970652E6D61746368293B0A202076617220737472696E675265706C61636520';
wwv_flow_api.g_varchar2_table(20) := '3D20756E6170706C7928537472696E672E70726F746F747970652E7265706C616365293B0A202076617220737472696E67496E6465784F66203D20756E6170706C7928537472696E672E70726F746F747970652E696E6465784F66293B0A202076617220';
wwv_flow_api.g_varchar2_table(21) := '737472696E675472696D203D20756E6170706C7928537472696E672E70726F746F747970652E7472696D293B0A0A20207661722072656745787054657374203D20756E6170706C79285265674578702E70726F746F747970652E74657374293B0A0A2020';
wwv_flow_api.g_varchar2_table(22) := '76617220747970654572726F72437265617465203D20756E636F6E73747275637428547970654572726F72293B0A0A202066756E6374696F6E20756E6170706C792866756E6329207B0A2020202072657475726E2066756E6374696F6E20287468697341';

wwv_flow_api.g_varchar2_table(23) := '726729207B0A202020202020666F722028766172205F6C656E203D20617267756D656E74732E6C656E6774682C2061726773203D204172726179285F6C656E203E2031203F205F6C656E202D2031203A2030292C205F6B6579203D20313B205F6B657920';
wwv_flow_api.g_varchar2_table(24) := '3C205F6C656E3B205F6B65792B2B29207B0A2020202020202020617267735B5F6B6579202D20315D203D20617267756D656E74735B5F6B65795D3B0A2020202020207D0A0A20202020202072657475726E206170706C792866756E632C20746869734172';
wwv_flow_api.g_varchar2_table(25) := '672C2061726773293B0A202020207D3B0A20207D0A0A202066756E6374696F6E20756E636F6E7374727563742866756E6329207B0A2020202072657475726E2066756E6374696F6E202829207B0A202020202020666F722028766172205F6C656E32203D';
wwv_flow_api.g_varchar2_table(26) := '20617267756D656E74732E6C656E6774682C2061726773203D204172726179285F6C656E32292C205F6B657932203D20303B205F6B657932203C205F6C656E323B205F6B6579322B2B29207B0A2020202020202020617267735B5F6B6579325D203D2061';
wwv_flow_api.g_varchar2_table(27) := '7267756D656E74735B5F6B6579325D3B0A2020202020207D0A0A20202020202072657475726E20636F6E7374727563742866756E632C2061726773293B0A202020207D3B0A20207D0A0A20202F2A204164642070726F7065727469657320746F2061206C';
wwv_flow_api.g_varchar2_table(28) := '6F6F6B7570207461626C65202A2F0A202066756E6374696F6E20616464546F536574287365742C20617272617929207B0A202020206966202873657450726F746F747970654F6629207B0A2020202020202F2F204D616B652027696E2720616E64207472';
wwv_flow_api.g_varchar2_table(29) := '7574687920636865636B73206C696B6520426F6F6C65616E287365742E636F6E7374727563746F72290A2020202020202F2F20696E646570656E64656E74206F6620616E792070726F7065727469657320646566696E6564206F6E204F626A6563742E70';
wwv_flow_api.g_varchar2_table(30) := '726F746F747970652E0A2020202020202F2F2050726576656E742070726F746F7479706520736574746572732066726F6D20696E74657263657074696E6720736574206173206120746869732076616C75652E0A20202020202073657450726F746F7479';
wwv_flow_api.g_varchar2_table(31) := '70654F66287365742C206E756C6C293B0A202020207D0A0A20202020766172206C203D2061727261792E6C656E6774683B0A202020207768696C6520286C2D2D29207B0A20202020202076617220656C656D656E74203D2061727261795B6C5D3B0A2020';
wwv_flow_api.g_varchar2_table(32) := '2020202069662028747970656F6620656C656D656E74203D3D3D2027737472696E672729207B0A2020202020202020766172206C63456C656D656E74203D20737472696E67546F4C6F7765724361736528656C656D656E74293B0A202020202020202069';
wwv_flow_api.g_varchar2_table(33) := '6620286C63456C656D656E7420213D3D20656C656D656E7429207B0A202020202020202020202F2F20436F6E66696720707265736574732028652E672E20746167732E6A732C2061747472732E6A73292061726520696D6D757461626C652E0A20202020';
wwv_flow_api.g_varchar2_table(34) := '2020202020206966202821697346726F7A656E2861727261792929207B0A20202020202020202020202061727261795B6C5D203D206C63456C656D656E743B0A202020202020202020207D0A0A20202020202020202020656C656D656E74203D206C6345';
wwv_flow_api.g_varchar2_table(35) := '6C656D656E743B0A20202020202020207D0A2020202020207D0A0A2020202020207365745B656C656D656E745D203D20747275653B0A202020207D0A0A2020202072657475726E207365743B0A20207D0A0A20202F2A205368616C6C6F7720636C6F6E65';
wwv_flow_api.g_varchar2_table(36) := '20616E206F626A656374202A2F0A202066756E6374696F6E20636C6F6E65286F626A65637429207B0A20202020766172206E65774F626A656374203D20637265617465286E756C6C293B0A0A202020207661722070726F7065727479203D20766F696420';
wwv_flow_api.g_varchar2_table(37) := '303B0A20202020666F72202870726F706572747920696E206F626A65637429207B0A202020202020696620286170706C79286861734F776E50726F70657274792C206F626A6563742C205B70726F70657274795D2929207B0A20202020202020206E6577';
wwv_flow_api.g_varchar2_table(38) := '4F626A6563745B70726F70657274795D203D206F626A6563745B70726F70657274795D3B0A2020202020207D0A202020207D0A0A2020202072657475726E206E65774F626A6563743B0A20207D0A0A20202F2A204945313020646F65736E277420737570';
wwv_flow_api.g_varchar2_table(39) := '706F7274205F5F6C6F6F6B75704765747465725F5F20736F206C657473270A2020202A2073696D756C6174652069742E20497420616C736F206175746F6D61746963616C6C7920636865636B730A2020202A206966207468652070726F70206973206675';
wwv_flow_api.g_varchar2_table(40) := '6E6374696F6E206F722067657474657220616E6420626568617665730A2020202A206163636F7264696E676C792E202A2F0A202066756E6374696F6E206C6F6F6B7570476574746572286F626A6563742C2070726F7029207B0A202020207768696C6520';
wwv_flow_api.g_varchar2_table(41) := '286F626A65637420213D3D206E756C6C29207B0A2020202020207661722064657363203D206765744F776E50726F706572747944657363726970746F72286F626A6563742C2070726F70293B0A202020202020696620286465736329207B0A2020202020';
wwv_flow_api.g_varchar2_table(42) := '20202069662028646573632E67657429207B0A2020202020202020202072657475726E20756E6170706C7928646573632E676574293B0A20202020202020207D0A0A202020202020202069662028747970656F6620646573632E76616C7565203D3D3D20';
wwv_flow_api.g_varchar2_table(43) := '2766756E6374696F6E2729207B0A2020202020202020202072657475726E20756E6170706C7928646573632E76616C7565293B0A20202020202020207D0A2020202020207D0A0A2020202020206F626A656374203D2067657450726F746F747970654F66';
wwv_flow_api.g_varchar2_table(44) := '286F626A656374293B0A202020207D0A0A2020202072657475726E206E756C6C3B0A20207D0A0A20207661722068746D6C203D20667265657A65285B2761272C202761626272272C20276163726F6E796D272C202761646472657373272C202761726561';
wwv_flow_api.g_varchar2_table(45) := '272C202761727469636C65272C20276173696465272C2027617564696F272C202762272C2027626469272C202762646F272C2027626967272C2027626C696E6B272C2027626C6F636B71756F7465272C2027626F6479272C20276272272C202762757474';
wwv_flow_api.g_varchar2_table(46) := '6F6E272C202763616E766173272C202763617074696F6E272C202763656E746572272C202763697465272C2027636F6465272C2027636F6C272C2027636F6C67726F7570272C2027636F6E74656E74272C202764617461272C2027646174616C69737427';
wwv_flow_api.g_varchar2_table(47) := '2C20276464272C20276465636F7261746F72272C202764656C272C202764657461696C73272C202764666E272C20276469616C6F67272C2027646972272C2027646976272C2027646C272C20276474272C2027656C656D656E74272C2027656D272C2027';
wwv_flow_api.g_varchar2_table(48) := '6669656C64736574272C202766696763617074696F6E272C2027666967757265272C2027666F6E74272C2027666F6F746572272C2027666F726D272C20276831272C20276832272C20276833272C20276834272C20276835272C20276836272C20276865';
wwv_flow_api.g_varchar2_table(49) := '6164272C2027686561646572272C20276867726F7570272C20276872272C202768746D6C272C202769272C2027696D67272C2027696E707574272C2027696E73272C20276B6264272C20276C6162656C272C20276C6567656E64272C20276C69272C2027';
wwv_flow_api.g_varchar2_table(50) := '6D61696E272C20276D6170272C20276D61726B272C20276D617271756565272C20276D656E75272C20276D656E756974656D272C20276D65746572272C20276E6176272C20276E6F6272272C20276F6C272C20276F707467726F7570272C20276F707469';
wwv_flow_api.g_varchar2_table(51) := '6F6E272C20276F7574707574272C202770272C202770696374757265272C2027707265272C202770726F6772657373272C202771272C20277270272C20277274272C202772756279272C202773272C202773616D70272C202773656374696F6E272C2027';
wwv_flow_api.g_varchar2_table(52) := '73656C656374272C2027736861646F77272C2027736D616C6C272C2027736F75726365272C2027737061636572272C20277370616E272C2027737472696B65272C20277374726F6E67272C20277374796C65272C2027737562272C202773756D6D617279';
wwv_flow_api.g_varchar2_table(53) := '272C2027737570272C20277461626C65272C202774626F6479272C20277464272C202774656D706C617465272C20277465787461726561272C202774666F6F74272C20277468272C20277468656164272C202774696D65272C20277472272C2027747261';
wwv_flow_api.g_varchar2_table(54) := '636B272C20277474272C202775272C2027756C272C2027766172272C2027766964656F272C2027776272275D293B0A0A20202F2F205356470A202076617220737667203D20667265657A65285B27737667272C202761272C2027616C74676C797068272C';
wwv_flow_api.g_varchar2_table(55) := '2027616C74676C797068646566272C2027616C74676C7970686974656D272C2027616E696D617465636F6C6F72272C2027616E696D6174656D6F74696F6E272C2027616E696D6174657472616E73666F726D272C2027636972636C65272C2027636C6970';
wwv_flow_api.g_varchar2_table(56) := '70617468272C202764656673272C202764657363272C2027656C6C69707365272C202766696C746572272C2027666F6E74272C202767272C2027676C797068272C2027676C797068726566272C2027686B65726E272C2027696D616765272C20276C696E';
wwv_flow_api.g_varchar2_table(57) := '65272C20276C696E6561726772616469656E74272C20276D61726B6572272C20276D61736B272C20276D65746164617461272C20276D70617468272C202770617468272C20277061747465726E272C2027706F6C79676F6E272C2027706F6C796C696E65';
wwv_flow_api.g_varchar2_table(58) := '272C202772616469616C6772616469656E74272C202772656374272C202773746F70272C20277374796C65272C2027737769746368272C202773796D626F6C272C202774657874272C20277465787470617468272C20277469746C65272C202774726566';
wwv_flow_api.g_varchar2_table(59) := '272C2027747370616E272C202776696577272C2027766B65726E275D293B0A0A20207661722073766746696C74657273203D20667265657A65285B276665426C656E64272C20276665436F6C6F724D6174726978272C20276665436F6D706F6E656E7454';
wwv_flow_api.g_varchar2_table(60) := '72616E73666572272C20276665436F6D706F73697465272C20276665436F6E766F6C76654D6174726978272C20276665446966667573654C69676874696E67272C20276665446973706C6163656D656E744D6170272C2027666544697374616E744C6967';
wwv_flow_api.g_varchar2_table(61) := '6874272C20276665466C6F6F64272C2027666546756E6341272C2027666546756E6342272C2027666546756E6347272C2027666546756E6352272C20276665476175737369616E426C7572272C202766654D65726765272C202766654D657267654E6F64';
wwv_flow_api.g_varchar2_table(62) := '65272C202766654D6F7270686F6C6F6779272C202766654F6666736574272C20276665506F696E744C69676874272C2027666553706563756C61724C69676874696E67272C2027666553706F744C69676874272C2027666554696C65272C202766655475';
wwv_flow_api.g_varchar2_table(63) := '7262756C656E6365275D293B0A0A20202F2F204C697374206F662053564720656C656D656E747320746861742061726520646973616C6C6F7765642062792064656661756C742E0A20202F2F205765207374696C6C206E65656420746F206B6E6F772074';
wwv_flow_api.g_varchar2_table(64) := '68656D20736F20746861742077652063616E20646F206E616D6573706163650A20202F2F20636865636B732070726F7065726C7920696E2063617365206F6E652077616E747320746F20616464207468656D20746F0A20202F2F20616C6C6F772D6C6973';
wwv_flow_api.g_varchar2_table(65) := '742E0A202076617220737667446973616C6C6F776564203D20667265657A65285B27616E696D617465272C2027636F6C6F722D70726F66696C65272C2027637572736F72272C202764697363617264272C2027666564726F70736861646F77272C202766';
wwv_flow_api.g_varchar2_table(66) := '65696D616765272C2027666F6E742D66616365272C2027666F6E742D666163652D666F726D6174272C2027666F6E742D666163652D6E616D65272C2027666F6E742D666163652D737263272C2027666F6E742D666163652D757269272C2027666F726569';
wwv_flow_api.g_varchar2_table(67) := '676E6F626A656374272C20276861746368272C2027686174636870617468272C20276D657368272C20276D6573686772616469656E74272C20276D6573687061746368272C20276D657368726F77272C20276D697373696E672D676C797068272C202773';
wwv_flow_api.g_varchar2_table(68) := '6372697074272C2027736574272C2027736F6C6964636F6C6F72272C2027756E6B6E6F776E272C2027757365275D293B0A0A2020766172206D6174684D6C203D20667265657A65285B276D617468272C20276D656E636C6F7365272C20276D6572726F72';
wwv_flow_api.g_varchar2_table(69) := '272C20276D66656E636564272C20276D66726163272C20276D676C797068272C20276D69272C20276D6C6162656C65647472272C20276D6D756C746973637269707473272C20276D6E272C20276D6F272C20276D6F766572272C20276D70616464656427';
wwv_flow_api.g_varchar2_table(70) := '2C20276D7068616E746F6D272C20276D726F6F74272C20276D726F77272C20276D73272C20276D7370616365272C20276D73717274272C20276D7374796C65272C20276D737562272C20276D737570272C20276D737562737570272C20276D7461626C65';
wwv_flow_api.g_varchar2_table(71) := '272C20276D7464272C20276D74657874272C20276D7472272C20276D756E646572272C20276D756E6465726F766572275D293B0A0A20202F2F2053696D696C61726C7920746F205356472C2077652077616E7420746F206B6E6F7720616C6C204D617468';
wwv_flow_api.g_varchar2_table(72) := '4D4C20656C656D656E74732C0A20202F2F206576656E2074686F7365207468617420776520646973616C6C6F772062792064656661756C742E0A2020766172206D6174684D6C446973616C6C6F776564203D20667265657A65285B276D616374696F6E27';
wwv_flow_api.g_varchar2_table(73) := '2C20276D616C69676E67726F7570272C20276D616C69676E6D61726B272C20276D6C6F6E67646976272C20276D7363617272696573272C20276D736361727279272C20276D7367726F7570272C20276D737461636B272C20276D736C696E65272C20276D';
wwv_flow_api.g_varchar2_table(74) := '73726F77272C202773656D616E74696373272C2027616E6E6F746174696F6E272C2027616E6E6F746174696F6E2D786D6C272C20276D70726573637269707473272C20276E6F6E65275D293B0A0A20207661722074657874203D20667265657A65285B27';
wwv_flow_api.g_varchar2_table(75) := '2374657874275D293B0A0A20207661722068746D6C2431203D20667265657A65285B27616363657074272C2027616374696F6E272C2027616C69676E272C2027616C74272C20276175746F6361706974616C697A65272C20276175746F636F6D706C6574';
wwv_flow_api.g_varchar2_table(76) := '65272C20276175746F70696374757265696E70696374757265272C20276175746F706C6179272C20276261636B67726F756E64272C20276267636F6C6F72272C2027626F72646572272C202763617074757265272C202763656C6C70616464696E67272C';
wwv_flow_api.g_varchar2_table(77) := '202763656C6C73706163696E67272C2027636865636B6564272C202763697465272C2027636C617373272C2027636C656172272C2027636F6C6F72272C2027636F6C73272C2027636F6C7370616E272C2027636F6E74726F6C73272C2027636F6E74726F';
wwv_flow_api.g_varchar2_table(78) := '6C736C697374272C2027636F6F726473272C202763726F73736F726967696E272C20276461746574696D65272C20276465636F64696E67272C202764656661756C74272C2027646972272C202764697361626C6564272C202764697361626C6570696374';
wwv_flow_api.g_varchar2_table(79) := '757265696E70696374757265272C202764697361626C6572656D6F7465706C61796261636B272C2027646F776E6C6F6164272C2027647261676761626C65272C2027656E6374797065272C2027656E7465726B657968696E74272C202766616365272C20';
wwv_flow_api.g_varchar2_table(80) := '27666F72272C202768656164657273272C2027686569676874272C202768696464656E272C202768696768272C202768726566272C2027687265666C616E67272C20276964272C2027696E7075746D6F6465272C2027696E74656772697479272C202769';
wwv_flow_api.g_varchar2_table(81) := '736D6170272C20276B696E64272C20276C6162656C272C20276C616E67272C20276C697374272C20276C6F6164696E67272C20276C6F6F70272C20276C6F77272C20276D6178272C20276D61786C656E677468272C20276D65646961272C20276D657468';
wwv_flow_api.g_varchar2_table(82) := '6F64272C20276D696E272C20276D696E6C656E677468272C20276D756C7469706C65272C20276D75746564272C20276E616D65272C20276E6F7368616465272C20276E6F76616C6964617465272C20276E6F77726170272C20276F70656E272C20276F70';
wwv_flow_api.g_varchar2_table(83) := '74696D756D272C20277061747465726E272C2027706C616365686F6C646572272C2027706C617973696E6C696E65272C2027706F73746572272C20277072656C6F6164272C202770756264617465272C2027726164696F67726F7570272C202772656164';
wwv_flow_api.g_varchar2_table(84) := '6F6E6C79272C202772656C272C20277265717569726564272C2027726576272C20277265766572736564272C2027726F6C65272C2027726F7773272C2027726F777370616E272C20277370656C6C636865636B272C202773636F7065272C202773656C65';
wwv_flow_api.g_varchar2_table(85) := '63746564272C20277368617065272C202773697A65272C202773697A6573272C20277370616E272C20277372636C616E67272C20277374617274272C2027737263272C2027737263736574272C202773746570272C20277374796C65272C202773756D6D';
wwv_flow_api.g_varchar2_table(86) := '617279272C2027746162696E646578272C20277469746C65272C20277472616E736C617465272C202774797065272C20277573656D6170272C202776616C69676E272C202776616C7565272C20277769647468272C2027786D6C6E73275D293B0A0A2020';
wwv_flow_api.g_varchar2_table(87) := '766172207376672431203D20667265657A65285B27616363656E742D686569676874272C2027616363756D756C617465272C20276164646974697665272C2027616C69676E6D656E742D626173656C696E65272C2027617363656E74272C202761747472';
wwv_flow_api.g_varchar2_table(88) := '69627574656E616D65272C202761747472696275746574797065272C2027617A696D757468272C2027626173656672657175656E6379272C2027626173656C696E652D7368696674272C2027626567696E272C202762696173272C20276279272C202763';
wwv_flow_api.g_varchar2_table(89) := '6C617373272C2027636C6970272C2027636C697070617468756E697473272C2027636C69702D70617468272C2027636C69702D72756C65272C2027636F6C6F72272C2027636F6C6F722D696E746572706F6C6174696F6E272C2027636F6C6F722D696E74';
wwv_flow_api.g_varchar2_table(90) := '6572706F6C6174696F6E2D66696C74657273272C2027636F6C6F722D70726F66696C65272C2027636F6C6F722D72656E646572696E67272C20276378272C20276379272C202764272C20276478272C20276479272C202764696666757365636F6E737461';
wwv_flow_api.g_varchar2_table(91) := '6E74272C2027646972656374696F6E272C2027646973706C6179272C202764697669736F72272C2027647572272C2027656467656D6F6465272C2027656C65766174696F6E272C2027656E64272C202766696C6C272C202766696C6C2D6F706163697479';
wwv_flow_api.g_varchar2_table(92) := '272C202766696C6C2D72756C65272C202766696C746572272C202766696C746572756E697473272C2027666C6F6F642D636F6C6F72272C2027666C6F6F642D6F706163697479272C2027666F6E742D66616D696C79272C2027666F6E742D73697A65272C';
wwv_flow_api.g_varchar2_table(93) := '2027666F6E742D73697A652D61646A757374272C2027666F6E742D73747265746368272C2027666F6E742D7374796C65272C2027666F6E742D76617269616E74272C2027666F6E742D776569676874272C20276678272C20276679272C20276731272C20';
wwv_flow_api.g_varchar2_table(94) := '276732272C2027676C7970682D6E616D65272C2027676C797068726566272C20276772616469656E74756E697473272C20276772616469656E747472616E73666F726D272C2027686569676874272C202768726566272C20276964272C2027696D616765';
wwv_flow_api.g_varchar2_table(95) := '2D72656E646572696E67272C2027696E272C2027696E32272C20276B272C20276B31272C20276B32272C20276B33272C20276B34272C20276B65726E696E67272C20276B6579706F696E7473272C20276B657973706C696E6573272C20276B657974696D';
wwv_flow_api.g_varchar2_table(96) := '6573272C20276C616E67272C20276C656E67746861646A757374272C20276C65747465722D73706163696E67272C20276B65726E656C6D6174726978272C20276B65726E656C756E69746C656E677468272C20276C69676874696E672D636F6C6F72272C';
wwv_flow_api.g_varchar2_table(97) := '20276C6F63616C272C20276D61726B65722D656E64272C20276D61726B65722D6D6964272C20276D61726B65722D7374617274272C20276D61726B6572686569676874272C20276D61726B6572756E697473272C20276D61726B65727769647468272C20';
wwv_flow_api.g_varchar2_table(98) := '276D61736B636F6E74656E74756E697473272C20276D61736B756E697473272C20276D6178272C20276D61736B272C20276D65646961272C20276D6574686F64272C20276D6F6465272C20276D696E272C20276E616D65272C20276E756D6F6374617665';
wwv_flow_api.g_varchar2_table(99) := '73272C20276F6666736574272C20276F70657261746F72272C20276F706163697479272C20276F72646572272C20276F7269656E74272C20276F7269656E746174696F6E272C20276F726967696E272C20276F766572666C6F77272C20277061696E742D';
wwv_flow_api.g_varchar2_table(100) := '6F72646572272C202770617468272C2027706174686C656E677468272C20277061747465726E636F6E74656E74756E697473272C20277061747465726E7472616E73666F726D272C20277061747465726E756E697473272C2027706F696E7473272C2027';
wwv_flow_api.g_varchar2_table(101) := '7072657365727665616C706861272C20277072657365727665617370656374726174696F272C20277072696D6974697665756E697473272C202772272C20277278272C20277279272C2027726164697573272C202772656678272C202772656679272C20';
wwv_flow_api.g_varchar2_table(102) := '27726570656174636F756E74272C2027726570656174647572272C202772657374617274272C2027726573756C74272C2027726F74617465272C20277363616C65272C202773656564272C202773686170652D72656E646572696E67272C202773706563';
wwv_flow_api.g_varchar2_table(103) := '756C6172636F6E7374616E74272C202773706563756C61726578706F6E656E74272C20277370726561646D6574686F64272C202773746172746F6666736574272C2027737464646576696174696F6E272C202773746974636874696C6573272C20277374';
wwv_flow_api.g_varchar2_table(104) := '6F702D636F6C6F72272C202773746F702D6F706163697479272C20277374726F6B652D646173686172726179272C20277374726F6B652D646173686F6666736574272C20277374726F6B652D6C696E65636170272C20277374726F6B652D6C696E656A6F';
wwv_flow_api.g_varchar2_table(105) := '696E272C20277374726F6B652D6D697465726C696D6974272C20277374726F6B652D6F706163697479272C20277374726F6B65272C20277374726F6B652D7769647468272C20277374796C65272C2027737572666163657363616C65272C202773797374';
wwv_flow_api.g_varchar2_table(106) := '656D6C616E6775616765272C2027746162696E646578272C202774617267657478272C202774617267657479272C20277472616E73666F726D272C2027746578742D616E63686F72272C2027746578742D6465636F726174696F6E272C2027746578742D';
wwv_flow_api.g_varchar2_table(107) := '72656E646572696E67272C2027746578746C656E677468272C202774797065272C20277531272C20277532272C2027756E69636F6465272C202776616C756573272C202776696577626F78272C20277669736962696C697479272C202776657273696F6E';
wwv_flow_api.g_varchar2_table(108) := '272C2027766572742D6164762D79272C2027766572742D6F726967696E2D78272C2027766572742D6F726967696E2D79272C20277769647468272C2027776F72642D73706163696E67272C202777726170272C202777726974696E672D6D6F6465272C20';
wwv_flow_api.g_varchar2_table(109) := '27786368616E6E656C73656C6563746F72272C2027796368616E6E656C73656C6563746F72272C202778272C20277831272C20277832272C2027786D6C6E73272C202779272C20277931272C20277932272C20277A272C20277A6F6F6D616E6470616E27';
wwv_flow_api.g_varchar2_table(110) := '5D293B0A0A2020766172206D6174684D6C2431203D20667265657A65285B27616363656E74272C2027616363656E74756E646572272C2027616C69676E272C2027626576656C6C6564272C2027636C6F7365272C2027636F6C756D6E73616C69676E272C';
wwv_flow_api.g_varchar2_table(111) := '2027636F6C756D6E6C696E6573272C2027636F6C756D6E7370616E272C202764656E6F6D616C69676E272C20276465707468272C2027646972272C2027646973706C6179272C2027646973706C61797374796C65272C2027656E636F64696E67272C2027';
wwv_flow_api.g_varchar2_table(112) := '66656E6365272C20276672616D65272C2027686569676874272C202768726566272C20276964272C20276C617267656F70272C20276C656E677468272C20276C696E65746869636B6E657373272C20276C7370616365272C20276C71756F7465272C2027';
wwv_flow_api.g_varchar2_table(113) := '6D6174686261636B67726F756E64272C20276D617468636F6C6F72272C20276D61746873697A65272C20276D61746876617269616E74272C20276D617873697A65272C20276D696E73697A65272C20276D6F7661626C656C696D697473272C20276E6F74';
wwv_flow_api.g_varchar2_table(114) := '6174696F6E272C20276E756D616C69676E272C20276F70656E272C2027726F77616C69676E272C2027726F776C696E6573272C2027726F7773706163696E67272C2027726F777370616E272C2027727370616365272C20277271756F7465272C20277363';
wwv_flow_api.g_varchar2_table(115) := '726970746C6576656C272C20277363726970746D696E73697A65272C202773637269707473697A656D756C7469706C696572272C202773656C656374696F6E272C2027736570617261746F72272C2027736570617261746F7273272C2027737472657463';
wwv_flow_api.g_varchar2_table(116) := '6879272C20277375627363726970747368696674272C20277375707363726970747368696674272C202773796D6D6574726963272C2027766F6666736574272C20277769647468272C2027786D6C6E73275D293B0A0A202076617220786D6C203D206672';
wwv_flow_api.g_varchar2_table(117) := '65657A65285B27786C696E6B3A68726566272C2027786D6C3A6964272C2027786C696E6B3A7469746C65272C2027786D6C3A7370616365272C2027786D6C6E733A786C696E6B275D293B0A0A20202F2F2065736C696E742D64697361626C652D6E657874';
wwv_flow_api.g_varchar2_table(118) := '2D6C696E6520756E69636F726E2F6265747465722D72656765780A2020766172204D555354414348455F45585052203D207365616C282F5C7B5C7B5B5C735C535D2A7C5B5C735C535D2A5C7D5C7D2F676D293B202F2F20537065636966792074656D706C';
wwv_flow_api.g_varchar2_table(119) := '61746520646574656374696F6E20726567657820666F7220534146455F464F525F54454D504C41544553206D6F64650A2020766172204552425F45585052203D207365616C282F3C255B5C735C535D2A7C5B5C735C535D2A253E2F676D293B0A20207661';
wwv_flow_api.g_varchar2_table(120) := '7220444154415F41545452203D207365616C282F5E646174612D5B5C2D5C772E5C75303042372D5C75464646465D2F293B202F2F2065736C696E742D64697361626C652D6C696E65206E6F2D7573656C6573732D6573636170650A202076617220415249';
wwv_flow_api.g_varchar2_table(121) := '415F41545452203D207365616C282F5E617269612D5B5C2D5C775D2B242F293B202F2F2065736C696E742D64697361626C652D6C696E65206E6F2D7573656C6573732D6573636170650A20207661722049535F414C4C4F5745445F555249203D20736561';
wwv_flow_api.g_varchar2_table(122) := '6C282F5E283F3A283F3A283F3A667C6874297470733F7C6D61696C746F7C74656C7C63616C6C746F7C6369647C786D7070293A7C5B5E612D7A5D7C5B612D7A2B2E5C2D5D2B283F3A5B5E612D7A2B2E5C2D3A5D7C2429292F69202F2F2065736C696E742D';
wwv_flow_api.g_varchar2_table(123) := '64697361626C652D6C696E65206E6F2D7573656C6573732D6573636170650A2020293B0A20207661722049535F5343524950545F4F525F44415441203D207365616C282F5E283F3A5C772B7363726970747C64617461293A2F69293B0A20207661722041';
wwv_flow_api.g_varchar2_table(124) := '5454525F57484954455350414345203D207365616C282F5B5C75303030302D5C75303032305C75303041305C75313638305C75313830455C75323030302D5C75323032395C75323035465C75333030305D2F67202F2F2065736C696E742D64697361626C';
wwv_flow_api.g_varchar2_table(125) := '652D6C696E65206E6F2D636F6E74726F6C2D72656765780A2020293B0A0A2020766172205F747970656F66203D20747970656F662053796D626F6C203D3D3D202266756E6374696F6E2220262620747970656F662053796D626F6C2E6974657261746F72';
wwv_flow_api.g_varchar2_table(126) := '203D3D3D202273796D626F6C22203F2066756E6374696F6E20286F626A29207B2072657475726E20747970656F66206F626A3B207D203A2066756E6374696F6E20286F626A29207B2072657475726E206F626A20262620747970656F662053796D626F6C';
wwv_flow_api.g_varchar2_table(127) := '203D3D3D202266756E6374696F6E22202626206F626A2E636F6E7374727563746F72203D3D3D2053796D626F6C202626206F626A20213D3D2053796D626F6C2E70726F746F74797065203F202273796D626F6C22203A20747970656F66206F626A3B207D';
wwv_flow_api.g_varchar2_table(128) := '3B0A0A202066756E6374696F6E205F746F436F6E73756D61626C65417272617924312861727229207B206966202841727261792E69734172726179286172722929207B20666F7220287661722069203D20302C2061727232203D20417272617928617272';
wwv_flow_api.g_varchar2_table(129) := '2E6C656E677468293B2069203C206172722E6C656E6774683B20692B2B29207B20617272325B695D203D206172725B695D3B207D2072657475726E20617272323B207D20656C7365207B2072657475726E2041727261792E66726F6D28617272293B207D';
wwv_flow_api.g_varchar2_table(130) := '207D0A0A202076617220676574476C6F62616C203D2066756E6374696F6E20676574476C6F62616C2829207B0A2020202072657475726E20747970656F662077696E646F77203D3D3D2027756E646566696E656427203F206E756C6C203A2077696E646F';
wwv_flow_api.g_varchar2_table(131) := '773B0A20207D3B0A0A20202F2A2A0A2020202A20437265617465732061206E6F2D6F7020706F6C69637920666F7220696E7465726E616C20757365206F6E6C792E0A2020202A20446F6E2774206578706F727420746869732066756E6374696F6E206F75';
wwv_flow_api.g_varchar2_table(132) := '74736964652074686973206D6F64756C65210A2020202A2040706172616D207B3F5472757374656454797065506F6C696379466163746F72797D207472757374656454797065732054686520706F6C69637920666163746F72792E0A2020202A20407061';
wwv_flow_api.g_varchar2_table(133) := '72616D207B446F63756D656E747D20646F63756D656E742054686520646F63756D656E74206F626A6563742028746F2064657465726D696E6520706F6C696379206E616D6520737566666978290A2020202A204072657475726E207B3F54727573746564';
wwv_flow_api.g_varchar2_table(134) := '54797065506F6C6963797D2054686520706F6C696379206372656174656420286F72206E756C6C2C20696620547275737465642054797065730A2020202A20617265206E6F7420737570706F72746564292E0A2020202A2F0A2020766172205F63726561';
wwv_flow_api.g_varchar2_table(135) := '7465547275737465645479706573506F6C696379203D2066756E6374696F6E205F637265617465547275737465645479706573506F6C696379287472757374656454797065732C20646F63756D656E7429207B0A202020206966202828747970656F6620';
wwv_flow_api.g_varchar2_table(136) := '747275737465645479706573203D3D3D2027756E646566696E656427203F2027756E646566696E656427203A205F747970656F6628747275737465645479706573292920213D3D20276F626A65637427207C7C20747970656F6620747275737465645479';
wwv_flow_api.g_varchar2_table(137) := '7065732E637265617465506F6C69637920213D3D202766756E6374696F6E2729207B0A20202020202072657475726E206E756C6C3B0A202020207D0A0A202020202F2F20416C6C6F77207468652063616C6C65727320746F20636F6E74726F6C20746865';
wwv_flow_api.g_varchar2_table(138) := '20756E6971756520706F6C696379206E616D650A202020202F2F20627920616464696E67206120646174612D74742D706F6C6963792D73756666697820746F207468652073637269707420656C656D656E7420776974682074686520444F4D5075726966';
wwv_flow_api.g_varchar2_table(139) := '792E0A202020202F2F20506F6C696379206372656174696F6E2077697468206475706C6963617465206E616D6573207468726F777320696E20547275737465642054797065732E0A2020202076617220737566666978203D206E756C6C3B0A2020202076';
wwv_flow_api.g_varchar2_table(140) := '617220415454525F4E414D45203D2027646174612D74742D706F6C6963792D737566666978273B0A2020202069662028646F63756D656E742E63757272656E7453637269707420262620646F63756D656E742E63757272656E745363726970742E686173';
wwv_flow_api.g_varchar2_table(141) := '41747472696275746528415454525F4E414D452929207B0A202020202020737566666978203D20646F63756D656E742E63757272656E745363726970742E67657441747472696275746528415454525F4E414D45293B0A202020207D0A0A202020207661';
wwv_flow_api.g_varchar2_table(142) := '7220706F6C6963794E616D65203D2027646F6D70757269667927202B2028737566666978203F20272327202B20737566666978203A202727293B0A0A20202020747279207B0A20202020202072657475726E207472757374656454797065732E63726561';
wwv_flow_api.g_varchar2_table(143) := '7465506F6C69637928706F6C6963794E616D652C207B0A202020202020202063726561746548544D4C3A2066756E6374696F6E2063726561746548544D4C2868746D6C24243129207B0A2020202020202020202072657475726E2068746D6C2424313B0A';
wwv_flow_api.g_varchar2_table(144) := '20202020202020207D0A2020202020207D293B0A202020207D20636174636820285F29207B0A2020202020202F2F20506F6C696379206372656174696F6E206661696C656420286D6F7374206C696B656C7920616E6F7468657220444F4D507572696679';
wwv_flow_api.g_varchar2_table(145) := '20736372697074206861730A2020202020202F2F20616C72656164792072756E292E20536B6970206372656174696E672074686520706F6C6963792C20617320746869732077696C6C206F6E6C79206361757365206572726F72730A2020202020202F2F';
wwv_flow_api.g_varchar2_table(146) := '2069662054542061726520656E666F726365642E0A202020202020636F6E736F6C652E7761726E282754727573746564547970657320706F6C6963792027202B20706F6C6963794E616D65202B202720636F756C64206E6F742062652063726561746564';
wwv_flow_api.g_varchar2_table(147) := '2E27293B0A20202020202072657475726E206E756C6C3B0A202020207D0A20207D3B0A0A202066756E6374696F6E20637265617465444F4D5075726966792829207B0A202020207661722077696E646F77203D20617267756D656E74732E6C656E677468';

wwv_flow_api.g_varchar2_table(148) := '203E203020262620617267756D656E74735B305D20213D3D20756E646566696E6564203F20617267756D656E74735B305D203A20676574476C6F62616C28293B0A0A2020202076617220444F4D507572696679203D2066756E6374696F6E20444F4D5075';
wwv_flow_api.g_varchar2_table(149) := '7269667928726F6F7429207B0A20202020202072657475726E20637265617465444F4D50757269667928726F6F74293B0A202020207D3B0A0A202020202F2A2A0A20202020202A2056657273696F6E206C6162656C2C206578706F73656420666F722065';
wwv_flow_api.g_varchar2_table(150) := '617369657220636865636B730A20202020202A20696620444F4D50757269667920697320757020746F2064617465206F72206E6F740A20202020202A2F0A20202020444F4D5075726966792E76657273696F6E203D2027322E322E36273B0A0A20202020';
wwv_flow_api.g_varchar2_table(151) := '2F2A2A0A20202020202A204172726179206F6620656C656D656E7473207468617420444F4D5075726966792072656D6F76656420647572696E672073616E69746174696F6E2E0A20202020202A20456D707479206966206E6F7468696E67207761732072';
wwv_flow_api.g_varchar2_table(152) := '656D6F7665642E0A20202020202A2F0A20202020444F4D5075726966792E72656D6F766564203D205B5D3B0A0A20202020696620282177696E646F77207C7C202177696E646F772E646F63756D656E74207C7C2077696E646F772E646F63756D656E742E';
wwv_flow_api.g_varchar2_table(153) := '6E6F64655479706520213D3D203929207B0A2020202020202F2F204E6F742072756E6E696E6720696E20612062726F777365722C2070726F76696465206120666163746F72792066756E6374696F6E0A2020202020202F2F20736F207468617420796F75';
wwv_flow_api.g_varchar2_table(154) := '2063616E207061737320796F7572206F776E2057696E646F770A202020202020444F4D5075726966792E6973537570706F72746564203D2066616C73653B0A0A20202020202072657475726E20444F4D5075726966793B0A202020207D0A0A2020202076';
wwv_flow_api.g_varchar2_table(155) := '6172206F726967696E616C446F63756D656E74203D2077696E646F772E646F63756D656E743B0A0A2020202076617220646F63756D656E74203D2077696E646F772E646F63756D656E743B0A2020202076617220446F63756D656E74467261676D656E74';
wwv_flow_api.g_varchar2_table(156) := '203D2077696E646F772E446F63756D656E74467261676D656E742C0A202020202020202048544D4C54656D706C617465456C656D656E74203D2077696E646F772E48544D4C54656D706C617465456C656D656E742C0A20202020202020204E6F6465203D';
wwv_flow_api.g_varchar2_table(157) := '2077696E646F772E4E6F64652C0A2020202020202020456C656D656E74203D2077696E646F772E456C656D656E742C0A20202020202020204E6F646546696C746572203D2077696E646F772E4E6F646546696C7465722C0A20202020202020205F77696E';
wwv_flow_api.g_varchar2_table(158) := '646F77244E616D65644E6F64654D6170203D2077696E646F772E4E616D65644E6F64654D61702C0A20202020202020204E616D65644E6F64654D6170203D205F77696E646F77244E616D65644E6F64654D6170203D3D3D20756E646566696E6564203F20';
wwv_flow_api.g_varchar2_table(159) := '77696E646F772E4E616D65644E6F64654D6170207C7C2077696E646F772E4D6F7A4E616D6564417474724D6170203A205F77696E646F77244E616D65644E6F64654D61702C0A202020202020202054657874203D2077696E646F772E546578742C0A2020';
wwv_flow_api.g_varchar2_table(160) := '202020202020436F6D6D656E74203D2077696E646F772E436F6D6D656E742C0A2020202020202020444F4D506172736572203D2077696E646F772E444F4D5061727365722C0A2020202020202020747275737465645479706573203D2077696E646F772E';
wwv_flow_api.g_varchar2_table(161) := '7472757374656454797065733B0A0A0A2020202076617220456C656D656E7450726F746F74797065203D20456C656D656E742E70726F746F747970653B0A0A2020202076617220636C6F6E654E6F6465203D206C6F6F6B757047657474657228456C656D';
wwv_flow_api.g_varchar2_table(162) := '656E7450726F746F747970652C2027636C6F6E654E6F646527293B0A20202020766172206765744E6578745369626C696E67203D206C6F6F6B757047657474657228456C656D656E7450726F746F747970652C20276E6578745369626C696E6727293B0A';
wwv_flow_api.g_varchar2_table(163) := '20202020766172206765744368696C644E6F646573203D206C6F6F6B757047657474657228456C656D656E7450726F746F747970652C20276368696C644E6F64657327293B0A2020202076617220676574506172656E744E6F6465203D206C6F6F6B7570';
wwv_flow_api.g_varchar2_table(164) := '47657474657228456C656D656E7450726F746F747970652C2027706172656E744E6F646527293B0A0A202020202F2F20417320706572206973737565202334372C20746865207765622D636F6D706F6E656E747320726567697374727920697320696E68';
wwv_flow_api.g_varchar2_table(165) := '65726974656420627920610A202020202F2F206E657720646F63756D656E742063726561746564207669612063726561746548544D4C446F63756D656E742E204173207065722074686520737065630A202020202F2F2028687474703A2F2F7733632E67';
wwv_flow_api.g_varchar2_table(166) := '69746875622E696F2F776562636F6D706F6E656E74732F737065632F637573746F6D2F236372656174696E672D616E642D70617373696E672D72656769737472696573290A202020202F2F2061206E657720656D70747920726567697374727920697320';
wwv_flow_api.g_varchar2_table(167) := '75736564207768656E206372656174696E6720612074656D706C61746520636F6E74656E7473206F776E65720A202020202F2F20646F63756D656E742C20736F207765207573652074686174206173206F757220706172656E7420646F63756D656E7420';
wwv_flow_api.g_varchar2_table(168) := '746F20656E73757265206E6F7468696E670A202020202F2F20697320696E686572697465642E0A2020202069662028747970656F662048544D4C54656D706C617465456C656D656E74203D3D3D202766756E6374696F6E2729207B0A2020202020207661';
wwv_flow_api.g_varchar2_table(169) := '722074656D706C617465203D20646F63756D656E742E637265617465456C656D656E74282774656D706C61746527293B0A2020202020206966202874656D706C6174652E636F6E74656E742026262074656D706C6174652E636F6E74656E742E6F776E65';
wwv_flow_api.g_varchar2_table(170) := '72446F63756D656E7429207B0A2020202020202020646F63756D656E74203D2074656D706C6174652E636F6E74656E742E6F776E6572446F63756D656E743B0A2020202020207D0A202020207D0A0A202020207661722074727573746564547970657350';
wwv_flow_api.g_varchar2_table(171) := '6F6C696379203D205F637265617465547275737465645479706573506F6C696379287472757374656454797065732C206F726967696E616C446F63756D656E74293B0A2020202076617220656D70747948544D4C203D2074727573746564547970657350';
wwv_flow_api.g_varchar2_table(172) := '6F6C6963792026262052455455524E5F545255535445445F54595045203F20747275737465645479706573506F6C6963792E63726561746548544D4C28272729203A2027273B0A0A20202020766172205F646F63756D656E74203D20646F63756D656E74';
wwv_flow_api.g_varchar2_table(173) := '2C0A2020202020202020696D706C656D656E746174696F6E203D205F646F63756D656E742E696D706C656D656E746174696F6E2C0A20202020202020206372656174654E6F64654974657261746F72203D205F646F63756D656E742E6372656174654E6F';
wwv_flow_api.g_varchar2_table(174) := '64654974657261746F722C0A2020202020202020676574456C656D656E747342795461674E616D65203D205F646F63756D656E742E676574456C656D656E747342795461674E616D652C0A2020202020202020637265617465446F63756D656E74467261';
wwv_flow_api.g_varchar2_table(175) := '676D656E74203D205F646F63756D656E742E637265617465446F63756D656E74467261676D656E743B0A2020202076617220696D706F72744E6F6465203D206F726967696E616C446F63756D656E742E696D706F72744E6F64653B0A0A0A202020207661';
wwv_flow_api.g_varchar2_table(176) := '7220646F63756D656E744D6F6465203D207B7D3B0A20202020747279207B0A202020202020646F63756D656E744D6F6465203D20636C6F6E6528646F63756D656E74292E646F63756D656E744D6F6465203F20646F63756D656E742E646F63756D656E74';
wwv_flow_api.g_varchar2_table(177) := '4D6F6465203A207B7D3B0A202020207D20636174636820285F29207B7D0A0A2020202076617220686F6F6B73203D207B7D3B0A0A202020202F2A2A0A20202020202A204578706F7365207768657468657220746869732062726F7773657220737570706F';
wwv_flow_api.g_varchar2_table(178) := '7274732072756E6E696E67207468652066756C6C20444F4D5075726966792E0A20202020202A2F0A20202020444F4D5075726966792E6973537570706F72746564203D20696D706C656D656E746174696F6E20262620747970656F6620696D706C656D65';
wwv_flow_api.g_varchar2_table(179) := '6E746174696F6E2E63726561746548544D4C446F63756D656E7420213D3D2027756E646566696E65642720262620646F63756D656E744D6F646520213D3D20393B0A0A20202020766172204D555354414348455F45585052242431203D204D5553544143';
wwv_flow_api.g_varchar2_table(180) := '48455F455850522C0A20202020202020204552425F45585052242431203D204552425F455850522C0A2020202020202020444154415F41545452242431203D20444154415F415454522C0A2020202020202020415249415F41545452242431203D204152';
wwv_flow_api.g_varchar2_table(181) := '49415F415454522C0A202020202020202049535F5343524950545F4F525F44415441242431203D2049535F5343524950545F4F525F444154412C0A2020202020202020415454525F57484954455350414345242431203D20415454525F57484954455350';
wwv_flow_api.g_varchar2_table(182) := '4143453B0A202020207661722049535F414C4C4F5745445F555249242431203D2049535F414C4C4F5745445F5552493B0A0A202020202F2A2A0A20202020202A20576520636F6E73696465722074686520656C656D656E747320616E6420617474726962';
wwv_flow_api.g_varchar2_table(183) := '757465732062656C6F7720746F20626520736166652E20496465616C6C790A20202020202A20646F6E27742061646420616E79206E6577206F6E657320627574206665656C206672656520746F2072656D6F766520756E77616E746564206F6E65732E0A';
wwv_flow_api.g_varchar2_table(184) := '20202020202A2F0A0A202020202F2A20616C6C6F77656420656C656D656E74206E616D6573202A2F0A0A2020202076617220414C4C4F5745445F54414753203D206E756C6C3B0A202020207661722044454641554C545F414C4C4F5745445F5441475320';
wwv_flow_api.g_varchar2_table(185) := '3D20616464546F536574287B7D2C205B5D2E636F6E636174285F746F436F6E73756D61626C65417272617924312868746D6C292C205F746F436F6E73756D61626C654172726179243128737667292C205F746F436F6E73756D61626C6541727261792431';
wwv_flow_api.g_varchar2_table(186) := '2873766746696C74657273292C205F746F436F6E73756D61626C6541727261792431286D6174684D6C292C205F746F436F6E73756D61626C654172726179243128746578742929293B0A0A202020202F2A20416C6C6F7765642061747472696275746520';
wwv_flow_api.g_varchar2_table(187) := '6E616D6573202A2F0A2020202076617220414C4C4F5745445F41545452203D206E756C6C3B0A202020207661722044454641554C545F414C4C4F5745445F41545452203D20616464546F536574287B7D2C205B5D2E636F6E636174285F746F436F6E7375';
wwv_flow_api.g_varchar2_table(188) := '6D61626C65417272617924312868746D6C2431292C205F746F436F6E73756D61626C6541727261792431287376672431292C205F746F436F6E73756D61626C6541727261792431286D6174684D6C2431292C205F746F436F6E73756D61626C6541727261';
wwv_flow_api.g_varchar2_table(189) := '79243128786D6C2929293B0A0A202020202F2A204578706C696369746C7920666F7262696464656E207461677320286F766572726964657320414C4C4F5745445F544147532F4144445F5441475329202A2F0A2020202076617220464F524249445F5441';
wwv_flow_api.g_varchar2_table(190) := '4753203D206E756C6C3B0A0A202020202F2A204578706C696369746C7920666F7262696464656E206174747269627574657320286F766572726964657320414C4C4F5745445F415454522F4144445F4154545229202A2F0A2020202076617220464F5242';
wwv_flow_api.g_varchar2_table(191) := '49445F41545452203D206E756C6C3B0A0A202020202F2A204465636964652069662041524941206174747269627574657320617265206F6B6179202A2F0A2020202076617220414C4C4F575F415249415F41545452203D20747275653B0A0A202020202F';
wwv_flow_api.g_varchar2_table(192) := '2A2044656369646520696620637573746F6D2064617461206174747269627574657320617265206F6B6179202A2F0A2020202076617220414C4C4F575F444154415F41545452203D20747275653B0A0A202020202F2A2044656369646520696620756E6B';
wwv_flow_api.g_varchar2_table(193) := '6E6F776E2070726F746F636F6C7320617265206F6B6179202A2F0A2020202076617220414C4C4F575F554E4B4E4F574E5F50524F544F434F4C53203D2066616C73653B0A0A202020202F2A204F75747075742073686F756C64206265207361666520666F';
wwv_flow_api.g_varchar2_table(194) := '7220636F6D6D6F6E2074656D706C61746520656E67696E65732E0A20202020202A2054686973206D65616E732C20444F4D5075726966792072656D6F766573206461746120617474726962757465732C206D757374616368657320616E64204552420A20';
wwv_flow_api.g_varchar2_table(195) := '202020202A2F0A2020202076617220534146455F464F525F54454D504C41544553203D2066616C73653B0A0A202020202F2A2044656369646520696620646F63756D656E742077697468203C68746D6C3E2E2E2E2073686F756C64206265207265747572';
wwv_flow_api.g_varchar2_table(196) := '6E6564202A2F0A202020207661722057484F4C455F444F43554D454E54203D2066616C73653B0A0A202020202F2A20547261636B207768657468657220636F6E66696720697320616C726561647920736574206F6E207468697320696E7374616E636520';
wwv_flow_api.g_varchar2_table(197) := '6F6620444F4D5075726966792E202A2F0A20202020766172205345545F434F4E464947203D2066616C73653B0A0A202020202F2A2044656369646520696620616C6C20656C656D656E74732028652E672E207374796C652C2073637269707429206D7573';
wwv_flow_api.g_varchar2_table(198) := '74206265206368696C6472656E206F660A20202020202A20646F63756D656E742E626F64792E2042792064656661756C742C2062726F7773657273206D69676874206D6F7665207468656D20746F20646F63756D656E742E68656164202A2F0A20202020';
wwv_flow_api.g_varchar2_table(199) := '76617220464F5243455F424F4459203D2066616C73653B0A0A202020202F2A20446563696465206966206120444F4D206048544D4C426F6479456C656D656E74602073686F756C642062652072657475726E65642C20696E7374656164206F6620612068';
wwv_flow_api.g_varchar2_table(200) := '746D6C0A20202020202A20737472696E6720286F722061205472757374656448544D4C206F626A65637420696620547275737465642054797065732061726520737570706F72746564292E0A20202020202A204966206057484F4C455F444F43554D454E';
wwv_flow_api.g_varchar2_table(201) := '546020697320656E61626C65642061206048544D4C48746D6C456C656D656E74602077696C6C2062652072657475726E656420696E73746561640A20202020202A2F0A202020207661722052455455524E5F444F4D203D2066616C73653B0A0A20202020';
wwv_flow_api.g_varchar2_table(202) := '2F2A20446563696465206966206120444F4D2060446F63756D656E74467261676D656E74602073686F756C642062652072657475726E65642C20696E7374656164206F6620612068746D6C0A20202020202A20737472696E672020286F72206120547275';
wwv_flow_api.g_varchar2_table(203) := '7374656448544D4C206F626A65637420696620547275737465642054797065732061726520737570706F7274656429202A2F0A202020207661722052455455524E5F444F4D5F465241474D454E54203D2066616C73653B0A0A202020202F2A2049662060';
wwv_flow_api.g_varchar2_table(204) := '52455455524E5F444F4D60206F72206052455455524E5F444F4D5F465241474D454E546020697320656E61626C65642C20646563696465206966207468652072657475726E656420444F4D0A20202020202A20604E6F64656020697320696D706F727465';
wwv_flow_api.g_varchar2_table(205) := '6420696E746F207468652063757272656E742060446F63756D656E74602E204966207468697320666C6167206973206E6F7420656E61626C6564207468650A20202020202A20604E6F6465602077696C6C2062656C6F6E672028697473206F776E657244';
wwv_flow_api.g_varchar2_table(206) := '6F63756D656E742920746F2061206672657368206048544D4C446F63756D656E74602C20637265617465642062790A20202020202A20444F4D5075726966792E0A20202020202A0A20202020202A20546869732064656661756C747320746F2060747275';
wwv_flow_api.g_varchar2_table(207) := '6560207374617274696E6720444F4D50757269667920322E322E302E204E6F746520746861742073657474696E6720697420746F206066616C7365600A20202020202A206D69676874206361757365205853532066726F6D2061747461636B7320686964';
wwv_flow_api.g_varchar2_table(208) := '64656E20696E20636C6F73656420736861646F77726F6F747320696E2063617365207468652062726F777365720A20202020202A20737570706F727473204465636C6172617469766520536861646F773A20444F4D2068747470733A2F2F7765622E6465';
wwv_flow_api.g_varchar2_table(209) := '762F6465636C617261746976652D736861646F772D646F6D2F0A20202020202A2F0A202020207661722052455455524E5F444F4D5F494D504F5254203D20747275653B0A0A202020202F2A2054727920746F2072657475726E2061205472757374656420';
wwv_flow_api.g_varchar2_table(210) := '54797065206F626A65637420696E7374656164206F66206120737472696E672C2072657475726E206120737472696E6720696E0A20202020202A2063617365205472757374656420547970657320617265206E6F7420737570706F7274656420202A2F0A';
wwv_flow_api.g_varchar2_table(211) := '202020207661722052455455524E5F545255535445445F54595045203D2066616C73653B0A0A202020202F2A204F75747075742073686F756C6420626520667265652066726F6D20444F4D20636C6F62626572696E672061747461636B733F202A2F0A20';
wwv_flow_api.g_varchar2_table(212) := '2020207661722053414E4954495A455F444F4D203D20747275653B0A0A202020202F2A204B65657020656C656D656E7420636F6E74656E74207768656E2072656D6F76696E6720656C656D656E743F202A2F0A20202020766172204B4545505F434F4E54';
wwv_flow_api.g_varchar2_table(213) := '454E54203D20747275653B0A0A202020202F2A204966206120604E6F6465602069732070617373656420746F2073616E6974697A6528292C207468656E20706572666F726D732073616E6974697A6174696F6E20696E2D706C61636520696E7374656164';
wwv_flow_api.g_varchar2_table(214) := '0A20202020202A206F6620696D706F7274696E6720697420696E746F2061206E657720446F63756D656E7420616E642072657475726E696E6720612073616E6974697A656420636F7079202A2F0A2020202076617220494E5F504C414345203D2066616C';
wwv_flow_api.g_varchar2_table(215) := '73653B0A0A202020202F2A20416C6C6F77207573616765206F662070726F66696C6573206C696B652068746D6C2C2073766720616E64206D6174684D6C202A2F0A20202020766172205553455F50524F46494C4553203D207B7D3B0A0A202020202F2A20';
wwv_flow_api.g_varchar2_table(216) := '5461677320746F2069676E6F726520636F6E74656E74206F66207768656E204B4545505F434F4E54454E542069732074727565202A2F0A2020202076617220464F524249445F434F4E54454E5453203D20616464546F536574287B7D2C205B27616E6E6F';
wwv_flow_api.g_varchar2_table(217) := '746174696F6E2D786D6C272C2027617564696F272C2027636F6C67726F7570272C202764657363272C2027666F726569676E6F626A656374272C202768656164272C2027696672616D65272C20276D617468272C20276D69272C20276D6E272C20276D6F';
wwv_flow_api.g_varchar2_table(218) := '272C20276D73272C20276D74657874272C20276E6F656D626564272C20276E6F6672616D6573272C20276E6F736372697074272C2027706C61696E74657874272C2027736372697074272C20277374796C65272C2027737667272C202774656D706C6174';
wwv_flow_api.g_varchar2_table(219) := '65272C20277468656164272C20277469746C65272C2027766964656F272C2027786D70275D293B0A0A202020202F2A2054616773207468617420617265207361666520666F7220646174613A2055524973202A2F0A2020202076617220444154415F5552';
wwv_flow_api.g_varchar2_table(220) := '495F54414753203D206E756C6C3B0A202020207661722044454641554C545F444154415F5552495F54414753203D20616464546F536574287B7D2C205B27617564696F272C2027766964656F272C2027696D67272C2027736F75726365272C2027696D61';
wwv_flow_api.g_varchar2_table(221) := '6765272C2027747261636B275D293B0A0A202020202F2A2041747472696275746573207361666520666F722076616C756573206C696B6520226A6176617363726970743A22202A2F0A20202020766172205552495F534146455F41545452494255544553';
wwv_flow_api.g_varchar2_table(222) := '203D206E756C6C3B0A202020207661722044454641554C545F5552495F534146455F41545452494255544553203D20616464546F536574287B7D2C205B27616C74272C2027636C617373272C2027666F72272C20276964272C20276C6162656C272C2027';
wwv_flow_api.g_varchar2_table(223) := '6E616D65272C20277061747465726E272C2027706C616365686F6C646572272C202773756D6D617279272C20277469746C65272C202776616C7565272C20277374796C65272C2027786D6C6E73275D293B0A0A202020202F2A204B656570206120726566';
wwv_flow_api.g_varchar2_table(224) := '6572656E636520746F20636F6E66696720746F207061737320746F20686F6F6B73202A2F0A2020202076617220434F4E464947203D206E756C6C3B0A0A202020202F2A20496465616C6C792C20646F206E6F7420746F75636820616E797468696E672062';
wwv_flow_api.g_varchar2_table(225) := '656C6F772074686973206C696E65202A2F0A202020202F2A205F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F5F202A2F0A0A2020202076617220666F726D456C656D656E74203D20646F';
wwv_flow_api.g_varchar2_table(226) := '63756D656E742E637265617465456C656D656E742827666F726D27293B0A0A202020202F2A2A0A20202020202A205F7061727365436F6E6669670A20202020202A0A20202020202A2040706172616D20207B4F626A6563747D20636667206F7074696F6E';
wwv_flow_api.g_varchar2_table(227) := '616C20636F6E666967206C69746572616C0A20202020202A2F0A202020202F2F2065736C696E742D64697361626C652D6E6578742D6C696E6520636F6D706C65786974790A20202020766172205F7061727365436F6E666967203D2066756E6374696F6E';
wwv_flow_api.g_varchar2_table(228) := '205F7061727365436F6E6669672863666729207B0A20202020202069662028434F4E46494720262620434F4E464947203D3D3D2063666729207B0A202020202020202072657475726E3B0A2020202020207D0A0A2020202020202F2A20536869656C6420';
wwv_flow_api.g_varchar2_table(229) := '636F6E66696775726174696F6E206F626A6563742066726F6D2074616D706572696E67202A2F0A2020202020206966202821636667207C7C2028747970656F6620636667203D3D3D2027756E646566696E656427203F2027756E646566696E656427203A';
wwv_flow_api.g_varchar2_table(230) := '205F747970656F6628636667292920213D3D20276F626A6563742729207B0A2020202020202020636667203D207B7D3B0A2020202020207D0A0A2020202020202F2A20536869656C6420636F6E66696775726174696F6E206F626A6563742066726F6D20';
wwv_flow_api.g_varchar2_table(231) := '70726F746F7479706520706F6C6C7574696F6E202A2F0A202020202020636667203D20636C6F6E6528636667293B0A0A2020202020202F2A2053657420636F6E66696775726174696F6E20706172616D6574657273202A2F0A202020202020414C4C4F57';
wwv_flow_api.g_varchar2_table(232) := '45445F54414753203D2027414C4C4F5745445F544147532720696E20636667203F20616464546F536574287B7D2C206366672E414C4C4F5745445F5441475329203A2044454641554C545F414C4C4F5745445F544147533B0A202020202020414C4C4F57';
wwv_flow_api.g_varchar2_table(233) := '45445F41545452203D2027414C4C4F5745445F415454522720696E20636667203F20616464546F536574287B7D2C206366672E414C4C4F5745445F4154545229203A2044454641554C545F414C4C4F5745445F415454523B0A2020202020205552495F53';
wwv_flow_api.g_varchar2_table(234) := '4146455F41545452494255544553203D20274144445F5552495F534146455F415454522720696E20636667203F20616464546F53657428636C6F6E652844454641554C545F5552495F534146455F41545452494255544553292C206366672E4144445F55';
wwv_flow_api.g_varchar2_table(235) := '52495F534146455F4154545229203A2044454641554C545F5552495F534146455F415454524942555445533B0A202020202020444154415F5552495F54414753203D20274144445F444154415F5552495F544147532720696E20636667203F2061646454';
wwv_flow_api.g_varchar2_table(236) := '6F53657428636C6F6E652844454641554C545F444154415F5552495F54414753292C206366672E4144445F444154415F5552495F5441475329203A2044454641554C545F444154415F5552495F544147533B0A202020202020464F524249445F54414753';
wwv_flow_api.g_varchar2_table(237) := '203D2027464F524249445F544147532720696E20636667203F20616464546F536574287B7D2C206366672E464F524249445F5441475329203A207B7D3B0A202020202020464F524249445F41545452203D2027464F524249445F415454522720696E2063';
wwv_flow_api.g_varchar2_table(238) := '6667203F20616464546F536574287B7D2C206366672E464F524249445F4154545229203A207B7D3B0A2020202020205553455F50524F46494C4553203D20275553455F50524F46494C45532720696E20636667203F206366672E5553455F50524F46494C';
wwv_flow_api.g_varchar2_table(239) := '4553203A2066616C73653B0A202020202020414C4C4F575F415249415F41545452203D206366672E414C4C4F575F415249415F4154545220213D3D2066616C73653B202F2F2044656661756C7420747275650A202020202020414C4C4F575F444154415F';
wwv_flow_api.g_varchar2_table(240) := '41545452203D206366672E414C4C4F575F444154415F4154545220213D3D2066616C73653B202F2F2044656661756C7420747275650A202020202020414C4C4F575F554E4B4E4F574E5F50524F544F434F4C53203D206366672E414C4C4F575F554E4B4E';
wwv_flow_api.g_varchar2_table(241) := '4F574E5F50524F544F434F4C53207C7C2066616C73653B202F2F2044656661756C742066616C73650A202020202020534146455F464F525F54454D504C41544553203D206366672E534146455F464F525F54454D504C41544553207C7C2066616C73653B';
wwv_flow_api.g_varchar2_table(242) := '202F2F2044656661756C742066616C73650A20202020202057484F4C455F444F43554D454E54203D206366672E57484F4C455F444F43554D454E54207C7C2066616C73653B202F2F2044656661756C742066616C73650A20202020202052455455524E5F';
wwv_flow_api.g_varchar2_table(243) := '444F4D203D206366672E52455455524E5F444F4D207C7C2066616C73653B202F2F2044656661756C742066616C73650A20202020202052455455524E5F444F4D5F465241474D454E54203D206366672E52455455524E5F444F4D5F465241474D454E5420';
wwv_flow_api.g_varchar2_table(244) := '7C7C2066616C73653B202F2F2044656661756C742066616C73650A20202020202052455455524E5F444F4D5F494D504F5254203D206366672E52455455524E5F444F4D5F494D504F525420213D3D2066616C73653B202F2F2044656661756C7420747275';
wwv_flow_api.g_varchar2_table(245) := '650A20202020202052455455524E5F545255535445445F54595045203D206366672E52455455524E5F545255535445445F54595045207C7C2066616C73653B202F2F2044656661756C742066616C73650A202020202020464F5243455F424F4459203D20';
wwv_flow_api.g_varchar2_table(246) := '6366672E464F5243455F424F4459207C7C2066616C73653B202F2F2044656661756C742066616C73650A20202020202053414E4954495A455F444F4D203D206366672E53414E4954495A455F444F4D20213D3D2066616C73653B202F2F2044656661756C';
wwv_flow_api.g_varchar2_table(247) := '7420747275650A2020202020204B4545505F434F4E54454E54203D206366672E4B4545505F434F4E54454E5420213D3D2066616C73653B202F2F2044656661756C7420747275650A202020202020494E5F504C414345203D206366672E494E5F504C4143';
wwv_flow_api.g_varchar2_table(248) := '45207C7C2066616C73653B202F2F2044656661756C742066616C73650A20202020202049535F414C4C4F5745445F555249242431203D206366672E414C4C4F5745445F5552495F524547455850207C7C2049535F414C4C4F5745445F5552492424313B0A';
wwv_flow_api.g_varchar2_table(249) := '20202020202069662028534146455F464F525F54454D504C4154455329207B0A2020202020202020414C4C4F575F444154415F41545452203D2066616C73653B0A2020202020207D0A0A2020202020206966202852455455524E5F444F4D5F465241474D';
wwv_flow_api.g_varchar2_table(250) := '454E5429207B0A202020202020202052455455524E5F444F4D203D20747275653B0A2020202020207D0A0A2020202020202F2A2050617273652070726F66696C6520696E666F202A2F0A202020202020696620285553455F50524F46494C455329207B0A';
wwv_flow_api.g_varchar2_table(251) := '2020202020202020414C4C4F5745445F54414753203D20616464546F536574287B7D2C205B5D2E636F6E636174285F746F436F6E73756D61626C654172726179243128746578742929293B0A2020202020202020414C4C4F5745445F41545452203D205B';
wwv_flow_api.g_varchar2_table(252) := '5D3B0A2020202020202020696620285553455F50524F46494C45532E68746D6C203D3D3D207472756529207B0A20202020202020202020616464546F53657428414C4C4F5745445F544147532C2068746D6C293B0A20202020202020202020616464546F';
wwv_flow_api.g_varchar2_table(253) := '53657428414C4C4F5745445F415454522C2068746D6C2431293B0A20202020202020207D0A0A2020202020202020696620285553455F50524F46494C45532E737667203D3D3D207472756529207B0A20202020202020202020616464546F53657428414C';
wwv_flow_api.g_varchar2_table(254) := '4C4F5745445F544147532C20737667293B0A20202020202020202020616464546F53657428414C4C4F5745445F415454522C207376672431293B0A20202020202020202020616464546F53657428414C4C4F5745445F415454522C20786D6C293B0A2020';
wwv_flow_api.g_varchar2_table(255) := '2020202020207D0A0A2020202020202020696620285553455F50524F46494C45532E73766746696C74657273203D3D3D207472756529207B0A20202020202020202020616464546F53657428414C4C4F5745445F544147532C2073766746696C74657273';
wwv_flow_api.g_varchar2_table(256) := '293B0A20202020202020202020616464546F53657428414C4C4F5745445F415454522C207376672431293B0A20202020202020202020616464546F53657428414C4C4F5745445F415454522C20786D6C293B0A20202020202020207D0A0A202020202020';
wwv_flow_api.g_varchar2_table(257) := '2020696620285553455F50524F46494C45532E6D6174684D6C203D3D3D207472756529207B0A20202020202020202020616464546F53657428414C4C4F5745445F544147532C206D6174684D6C293B0A20202020202020202020616464546F5365742841';
wwv_flow_api.g_varchar2_table(258) := '4C4C4F5745445F415454522C206D6174684D6C2431293B0A20202020202020202020616464546F53657428414C4C4F5745445F415454522C20786D6C293B0A20202020202020207D0A2020202020207D0A0A2020202020202F2A204D6572676520636F6E';
wwv_flow_api.g_varchar2_table(259) := '66696775726174696F6E20706172616D6574657273202A2F0A202020202020696620286366672E4144445F5441475329207B0A202020202020202069662028414C4C4F5745445F54414753203D3D3D2044454641554C545F414C4C4F5745445F54414753';
wwv_flow_api.g_varchar2_table(260) := '29207B0A20202020202020202020414C4C4F5745445F54414753203D20636C6F6E6528414C4C4F5745445F54414753293B0A20202020202020207D0A0A2020202020202020616464546F53657428414C4C4F5745445F544147532C206366672E4144445F';
wwv_flow_api.g_varchar2_table(261) := '54414753293B0A2020202020207D0A0A202020202020696620286366672E4144445F4154545229207B0A202020202020202069662028414C4C4F5745445F41545452203D3D3D2044454641554C545F414C4C4F5745445F4154545229207B0A2020202020';
wwv_flow_api.g_varchar2_table(262) := '2020202020414C4C4F5745445F41545452203D20636C6F6E6528414C4C4F5745445F41545452293B0A20202020202020207D0A0A2020202020202020616464546F53657428414C4C4F5745445F415454522C206366672E4144445F41545452293B0A2020';
wwv_flow_api.g_varchar2_table(263) := '202020207D0A0A202020202020696620286366672E4144445F5552495F534146455F4154545229207B0A2020202020202020616464546F536574285552495F534146455F415454524942555445532C206366672E4144445F5552495F534146455F415454';
wwv_flow_api.g_varchar2_table(264) := '52293B0A2020202020207D0A0A2020202020202F2A2041646420237465787420696E2063617365204B4545505F434F4E54454E542069732073657420746F2074727565202A2F0A202020202020696620284B4545505F434F4E54454E5429207B0A202020';
wwv_flow_api.g_varchar2_table(265) := '2020202020414C4C4F5745445F544147535B272374657874275D203D20747275653B0A2020202020207D0A0A2020202020202F2A204164642068746D6C2C206865616420616E6420626F647920746F20414C4C4F5745445F5441475320696E2063617365';
wwv_flow_api.g_varchar2_table(266) := '2057484F4C455F444F43554D454E542069732074727565202A2F0A2020202020206966202857484F4C455F444F43554D454E5429207B0A2020202020202020616464546F53657428414C4C4F5745445F544147532C205B2768746D6C272C202768656164';
wwv_flow_api.g_varchar2_table(267) := '272C2027626F6479275D293B0A2020202020207D0A0A2020202020202F2A204164642074626F647920746F20414C4C4F5745445F5441475320696E2063617365207461626C657320617265207065726D69747465642C2073656520233238362C20233336';
wwv_flow_api.g_varchar2_table(268) := '35202A2F0A20202020202069662028414C4C4F5745445F544147532E7461626C6529207B0A2020202020202020616464546F53657428414C4C4F5745445F544147532C205B2774626F6479275D293B0A202020202020202064656C65746520464F524249';
wwv_flow_api.g_varchar2_table(269) := '445F544147532E74626F64793B0A2020202020207D0A0A2020202020202F2F2050726576656E742066757274686572206D616E6970756C6174696F6E206F6620636F6E66696775726174696F6E2E0A2020202020202F2F204E6F7420617661696C61626C';
wwv_flow_api.g_varchar2_table(270) := '6520696E204945382C2053616661726920352C206574632E0A20202020202069662028667265657A6529207B0A2020202020202020667265657A6528636667293B0A2020202020207D0A0A202020202020434F4E464947203D206366673B0A202020207D';
wwv_flow_api.g_varchar2_table(271) := '3B0A0A20202020766172204D4154484D4C5F544558545F494E544547524154494F4E5F504F494E5453203D20616464546F536574287B7D2C205B276D69272C20276D6F272C20276D6E272C20276D73272C20276D74657874275D293B0A0A202020207661';

wwv_flow_api.g_varchar2_table(272) := '722048544D4C5F494E544547524154494F4E5F504F494E5453203D20616464546F536574287B7D2C205B27666F726569676E6F626A656374272C202764657363272C20277469746C65272C2027616E6E6F746174696F6E2D786D6C275D293B0A0A202020';
wwv_flow_api.g_varchar2_table(273) := '202F2A204B65657020747261636B206F6620616C6C20706F737369626C652053564720616E64204D6174684D4C20746167730A20202020202A20736F20746861742077652063616E20706572666F726D20746865206E616D65737061636520636865636B';
wwv_flow_api.g_varchar2_table(274) := '730A20202020202A20636F72726563746C792E202A2F0A2020202076617220414C4C5F5356475F54414753203D20616464546F536574287B7D2C20737667293B0A20202020616464546F53657428414C4C5F5356475F544147532C2073766746696C7465';
wwv_flow_api.g_varchar2_table(275) := '7273293B0A20202020616464546F53657428414C4C5F5356475F544147532C20737667446973616C6C6F776564293B0A0A2020202076617220414C4C5F4D4154484D4C5F54414753203D20616464546F536574287B7D2C206D6174684D6C293B0A202020';
wwv_flow_api.g_varchar2_table(276) := '20616464546F53657428414C4C5F4D4154484D4C5F544147532C206D6174684D6C446973616C6C6F776564293B0A0A20202020766172204D4154484D4C5F4E414D455350414345203D2027687474703A2F2F7777772E77332E6F72672F313939382F4D61';
wwv_flow_api.g_varchar2_table(277) := '74682F4D6174684D4C273B0A20202020766172205356475F4E414D455350414345203D2027687474703A2F2F7777772E77332E6F72672F323030302F737667273B0A202020207661722048544D4C5F4E414D455350414345203D2027687474703A2F2F77';
wwv_flow_api.g_varchar2_table(278) := '77772E77332E6F72672F313939392F7868746D6C273B0A0A202020202F2A2A0A20202020202A0A20202020202A0A20202020202A2040706172616D20207B456C656D656E747D20656C656D656E74206120444F4D20656C656D656E742077686F7365206E';
wwv_flow_api.g_varchar2_table(279) := '616D657370616365206973206265696E6720636865636B65640A20202020202A204072657475726E73207B626F6F6C65616E7D2052657475726E2066616C73652069662074686520656C656D656E742068617320610A20202020202A20206E616D657370';
wwv_flow_api.g_varchar2_table(280) := '6163652074686174206120737065632D636F6D706C69616E742070617273657220776F756C64206E657665720A20202020202A202072657475726E2E2052657475726E2074727565206F74686572776973652E0A20202020202A2F0A2020202076617220';
wwv_flow_api.g_varchar2_table(281) := '5F636865636B56616C69644E616D657370616365203D2066756E6374696F6E205F636865636B56616C69644E616D65737061636528656C656D656E7429207B0A20202020202076617220706172656E74203D20676574506172656E744E6F646528656C65';
wwv_flow_api.g_varchar2_table(282) := '6D656E74293B0A0A2020202020202F2F20496E204A53444F4D2C20696620776527726520696E7369646520736861646F7720444F4D2C207468656E20706172656E744E6F64650A2020202020202F2F2063616E206265206E756C6C2E205765206A757374';
wwv_flow_api.g_varchar2_table(283) := '2073696D756C61746520706172656E7420696E207468697320636173652E0A2020202020206966202821706172656E74207C7C2021706172656E742E7461674E616D6529207B0A2020202020202020706172656E74203D207B0A20202020202020202020';
wwv_flow_api.g_varchar2_table(284) := '6E616D6573706163655552493A2048544D4C5F4E414D4553504143452C0A202020202020202020207461674E616D653A202774656D706C617465270A20202020202020207D3B0A2020202020207D0A0A202020202020766172207461674E616D65203D20';
wwv_flow_api.g_varchar2_table(285) := '737472696E67546F4C6F7765724361736528656C656D656E742E7461674E616D65293B0A20202020202076617220706172656E745461674E616D65203D20737472696E67546F4C6F7765724361736528706172656E742E7461674E616D65293B0A0A2020';
wwv_flow_api.g_varchar2_table(286) := '2020202069662028656C656D656E742E6E616D657370616365555249203D3D3D205356475F4E414D45535041434529207B0A20202020202020202F2F20546865206F6E6C792077617920746F207377697463682066726F6D2048544D4C206E616D657370';
wwv_flow_api.g_varchar2_table(287) := '61636520746F205356470A20202020202020202F2F20697320766961203C7376673E2E2049662069742068617070656E732076696120616E79206F74686572207461672C207468656E0A20202020202020202F2F2069742073686F756C64206265206B69';
wwv_flow_api.g_varchar2_table(288) := '6C6C65642E0A202020202020202069662028706172656E742E6E616D657370616365555249203D3D3D2048544D4C5F4E414D45535041434529207B0A2020202020202020202072657475726E207461674E616D65203D3D3D2027737667273B0A20202020';
wwv_flow_api.g_varchar2_table(289) := '202020207D0A0A20202020202020202F2F20546865206F6E6C792077617920746F207377697463682066726F6D204D6174684D4C20746F20535647206973207669610A20202020202020202F2F2073766720696620706172656E74206973206569746865';
wwv_flow_api.g_varchar2_table(290) := '72203C616E6E6F746174696F6E2D786D6C3E206F72204D6174684D4C0A20202020202020202F2F207465787420696E746567726174696F6E20706F696E74732E0A202020202020202069662028706172656E742E6E616D657370616365555249203D3D3D';
wwv_flow_api.g_varchar2_table(291) := '204D4154484D4C5F4E414D45535041434529207B0A2020202020202020202072657475726E207461674E616D65203D3D3D2027737667272026262028706172656E745461674E616D65203D3D3D2027616E6E6F746174696F6E2D786D6C27207C7C204D41';
wwv_flow_api.g_varchar2_table(292) := '54484D4C5F544558545F494E544547524154494F4E5F504F494E54535B706172656E745461674E616D655D293B0A20202020202020207D0A0A20202020202020202F2F205765206F6E6C7920616C6C6F7720656C656D656E747320746861742061726520';
wwv_flow_api.g_varchar2_table(293) := '646566696E656420696E205356470A20202020202020202F2F20737065632E20416C6C206F74686572732061726520646973616C6C6F77656420696E20535647206E616D6573706163652E0A202020202020202072657475726E20426F6F6C65616E2841';
wwv_flow_api.g_varchar2_table(294) := '4C4C5F5356475F544147535B7461674E616D655D293B0A2020202020207D0A0A20202020202069662028656C656D656E742E6E616D657370616365555249203D3D3D204D4154484D4C5F4E414D45535041434529207B0A20202020202020202F2F205468';
wwv_flow_api.g_varchar2_table(295) := '65206F6E6C792077617920746F207377697463682066726F6D2048544D4C206E616D65737061636520746F204D6174684D4C0A20202020202020202F2F20697320766961203C6D6174683E2E2049662069742068617070656E732076696120616E79206F';
wwv_flow_api.g_varchar2_table(296) := '74686572207461672C207468656E0A20202020202020202F2F2069742073686F756C64206265206B696C6C65642E0A202020202020202069662028706172656E742E6E616D657370616365555249203D3D3D2048544D4C5F4E414D45535041434529207B';
wwv_flow_api.g_varchar2_table(297) := '0A2020202020202020202072657475726E207461674E616D65203D3D3D20276D617468273B0A20202020202020207D0A0A20202020202020202F2F20546865206F6E6C792077617920746F207377697463682066726F6D2053564720746F204D6174684D';
wwv_flow_api.g_varchar2_table(298) := '4C206973207669610A20202020202020202F2F203C6D6174683E20616E642048544D4C20696E746567726174696F6E20706F696E74730A202020202020202069662028706172656E742E6E616D657370616365555249203D3D3D205356475F4E414D4553';
wwv_flow_api.g_varchar2_table(299) := '5041434529207B0A2020202020202020202072657475726E207461674E616D65203D3D3D20276D617468272026262048544D4C5F494E544547524154494F4E5F504F494E54535B706172656E745461674E616D655D3B0A20202020202020207D0A0A2020';
wwv_flow_api.g_varchar2_table(300) := '2020202020202F2F205765206F6E6C7920616C6C6F7720656C656D656E747320746861742061726520646566696E656420696E204D6174684D4C0A20202020202020202F2F20737065632E20416C6C206F74686572732061726520646973616C6C6F7765';
wwv_flow_api.g_varchar2_table(301) := '6420696E204D6174684D4C206E616D6573706163652E0A202020202020202072657475726E20426F6F6C65616E28414C4C5F4D4154484D4C5F544147535B7461674E616D655D293B0A2020202020207D0A0A20202020202069662028656C656D656E742E';
wwv_flow_api.g_varchar2_table(302) := '6E616D657370616365555249203D3D3D2048544D4C5F4E414D45535041434529207B0A20202020202020202F2F20546865206F6E6C792077617920746F207377697463682066726F6D2053564720746F2048544D4C206973207669610A20202020202020';
wwv_flow_api.g_varchar2_table(303) := '202F2F2048544D4C20696E746567726174696F6E20706F696E74732C20616E642066726F6D204D6174684D4C20746F2048544D4C0A20202020202020202F2F20697320766961204D6174684D4C207465787420696E746567726174696F6E20706F696E74';
wwv_flow_api.g_varchar2_table(304) := '730A202020202020202069662028706172656E742E6E616D657370616365555249203D3D3D205356475F4E414D455350414345202626202148544D4C5F494E544547524154494F4E5F504F494E54535B706172656E745461674E616D655D29207B0A2020';
wwv_flow_api.g_varchar2_table(305) := '202020202020202072657475726E2066616C73653B0A20202020202020207D0A0A202020202020202069662028706172656E742E6E616D657370616365555249203D3D3D204D4154484D4C5F4E414D45535041434520262620214D4154484D4C5F544558';
wwv_flow_api.g_varchar2_table(306) := '545F494E544547524154494F4E5F504F494E54535B706172656E745461674E616D655D29207B0A2020202020202020202072657475726E2066616C73653B0A20202020202020207D0A0A20202020202020202F2F204365727461696E20656C656D656E74';
wwv_flow_api.g_varchar2_table(307) := '732061726520616C6C6F77656420696E20626F74682053564720616E642048544D4C0A20202020202020202F2F206E616D6573706163652E205765206E65656420746F2073706563696679207468656D206578706C696369746C790A2020202020202020';
wwv_flow_api.g_varchar2_table(308) := '2F2F20736F2074686174207468657920646F6E277420676574206572726F6E6F75736C792064656C657465642066726F6D0A20202020202020202F2F2048544D4C206E616D6573706163652E0A202020202020202076617220636F6D6D6F6E537667416E';
wwv_flow_api.g_varchar2_table(309) := '6448544D4C456C656D656E7473203D20616464546F536574287B7D2C205B277469746C65272C20277374796C65272C2027666F6E74272C202761272C2027736372697074275D293B0A0A20202020202020202F2F20576520646973616C6C6F7720746167';
wwv_flow_api.g_varchar2_table(310) := '7320746861742061726520737065636966696320666F72204D6174684D4C0A20202020202020202F2F206F722053564720616E642073686F756C64206E657665722061707065617220696E2048544D4C206E616D6573706163650A202020202020202072';
wwv_flow_api.g_varchar2_table(311) := '657475726E2021414C4C5F4D4154484D4C5F544147535B7461674E616D655D2026262028636F6D6D6F6E537667416E6448544D4C456C656D656E74735B7461674E616D655D207C7C2021414C4C5F5356475F544147535B7461674E616D655D293B0A2020';
wwv_flow_api.g_varchar2_table(312) := '202020207D0A0A2020202020202F2F2054686520636F64652073686F756C64206E65766572207265616368207468697320706C616365202874686973206D65616E730A2020202020202F2F20746861742074686520656C656D656E7420736F6D65686F77';
wwv_flow_api.g_varchar2_table(313) := '20676F74206E616D6573706163652074686174206973206E6F740A2020202020202F2F2048544D4C2C20535647206F72204D6174684D4C292E2052657475726E2066616C7365206A75737420696E20636173652E0A20202020202072657475726E206661';
wwv_flow_api.g_varchar2_table(314) := '6C73653B0A202020207D3B0A0A202020202F2A2A0A20202020202A205F666F72636552656D6F76650A20202020202A0A20202020202A2040706172616D20207B4E6F64657D206E6F6465206120444F4D206E6F64650A20202020202A2F0A202020207661';
wwv_flow_api.g_varchar2_table(315) := '72205F666F72636552656D6F7665203D2066756E6374696F6E205F666F72636552656D6F7665286E6F646529207B0A20202020202061727261795075736828444F4D5075726966792E72656D6F7665642C207B20656C656D656E743A206E6F6465207D29';
wwv_flow_api.g_varchar2_table(316) := '3B0A202020202020747279207B0A20202020202020206E6F64652E706172656E744E6F64652E72656D6F76654368696C64286E6F6465293B0A2020202020207D20636174636820285F29207B0A2020202020202020747279207B0A202020202020202020';
wwv_flow_api.g_varchar2_table(317) := '206E6F64652E6F7574657248544D4C203D20656D70747948544D4C3B0A20202020202020207D20636174636820285F29207B0A202020202020202020206E6F64652E72656D6F766528293B0A20202020202020207D0A2020202020207D0A202020207D3B';
wwv_flow_api.g_varchar2_table(318) := '0A0A202020202F2A2A0A20202020202A205F72656D6F76654174747269627574650A20202020202A0A20202020202A2040706172616D20207B537472696E677D206E616D6520616E20417474726962757465206E616D650A20202020202A204070617261';
wwv_flow_api.g_varchar2_table(319) := '6D20207B4E6F64657D206E6F6465206120444F4D206E6F64650A20202020202A2F0A20202020766172205F72656D6F7665417474726962757465203D2066756E6374696F6E205F72656D6F7665417474726962757465286E616D652C206E6F646529207B';
wwv_flow_api.g_varchar2_table(320) := '0A202020202020747279207B0A202020202020202061727261795075736828444F4D5075726966792E72656D6F7665642C207B0A202020202020202020206174747269627574653A206E6F64652E6765744174747269627574654E6F6465286E616D6529';
wwv_flow_api.g_varchar2_table(321) := '2C0A2020202020202020202066726F6D3A206E6F64650A20202020202020207D293B0A2020202020207D20636174636820285F29207B0A202020202020202061727261795075736828444F4D5075726966792E72656D6F7665642C207B0A202020202020';
wwv_flow_api.g_varchar2_table(322) := '202020206174747269627574653A206E756C6C2C0A2020202020202020202066726F6D3A206E6F64650A20202020202020207D293B0A2020202020207D0A0A2020202020206E6F64652E72656D6F7665417474726962757465286E616D65293B0A202020';
wwv_flow_api.g_varchar2_table(323) := '207D3B0A0A202020202F2A2A0A20202020202A205F696E6974446F63756D656E740A20202020202A0A20202020202A2040706172616D20207B537472696E677D206469727479206120737472696E67206F66206469727479206D61726B75700A20202020';
wwv_flow_api.g_varchar2_table(324) := '202A204072657475726E207B446F63756D656E747D206120444F4D2C2066696C6C6564207769746820746865206469727479206D61726B75700A20202020202A2F0A20202020766172205F696E6974446F63756D656E74203D2066756E6374696F6E205F';
wwv_flow_api.g_varchar2_table(325) := '696E6974446F63756D656E7428646972747929207B0A2020202020202F2A2043726561746520612048544D4C20646F63756D656E74202A2F0A20202020202076617220646F63203D20766F696420303B0A202020202020766172206C656164696E675768';
wwv_flow_api.g_varchar2_table(326) := '6974657370616365203D20766F696420303B0A0A20202020202069662028464F5243455F424F445929207B0A20202020202020206469727479203D20273C72656D6F76653E3C2F72656D6F76653E27202B2064697274793B0A2020202020207D20656C73';
wwv_flow_api.g_varchar2_table(327) := '65207B0A20202020202020202F2A20496620464F5243455F424F44592069736E277420757365642C206C656164696E672077686974657370616365206E6565647320746F20626520707265736572766564206D616E75616C6C79202A2F0A202020202020';
wwv_flow_api.g_varchar2_table(328) := '2020766172206D617463686573203D20737472696E674D617463682864697274792C202F5E5B5C725C6E5C74205D2B2F293B0A20202020202020206C656164696E6757686974657370616365203D206D617463686573202626206D6174636865735B305D';
wwv_flow_api.g_varchar2_table(329) := '3B0A2020202020207D0A0A2020202020207661722064697274795061796C6F6164203D20747275737465645479706573506F6C696379203F20747275737465645479706573506F6C6963792E63726561746548544D4C28646972747929203A2064697274';
wwv_flow_api.g_varchar2_table(330) := '793B0A2020202020202F2A205573652074686520444F4D506172736572204150492062792064656661756C742C2066616C6C6261636B206C61746572206966206E65656473206265202A2F0A202020202020747279207B0A2020202020202020646F6320';
wwv_flow_api.g_varchar2_table(331) := '3D206E657720444F4D50617273657228292E706172736546726F6D537472696E672864697274795061796C6F61642C2027746578742F68746D6C27293B0A2020202020207D20636174636820285F29207B7D0A0A2020202020202F2A2055736520637265';
wwv_flow_api.g_varchar2_table(332) := '61746548544D4C446F63756D656E7420696E206361736520444F4D506172736572206973206E6F7420617661696C61626C65202A2F0A2020202020206966202821646F63207C7C2021646F632E646F63756D656E74456C656D656E7429207B0A20202020';
wwv_flow_api.g_varchar2_table(333) := '20202020646F63203D20696D706C656D656E746174696F6E2E63726561746548544D4C446F63756D656E74282727293B0A2020202020202020766172205F646F63203D20646F632C0A202020202020202020202020626F6479203D205F646F632E626F64';
wwv_flow_api.g_varchar2_table(334) := '793B0A0A2020202020202020626F64792E706172656E744E6F64652E72656D6F76654368696C6428626F64792E706172656E744E6F64652E6669727374456C656D656E744368696C64293B0A2020202020202020626F64792E6F7574657248544D4C203D';
wwv_flow_api.g_varchar2_table(335) := '2064697274795061796C6F61643B0A2020202020207D0A0A202020202020696620286469727479202626206C656164696E675768697465737061636529207B0A2020202020202020646F632E626F64792E696E736572744265666F726528646F63756D65';
wwv_flow_api.g_varchar2_table(336) := '6E742E637265617465546578744E6F6465286C656164696E6757686974657370616365292C20646F632E626F64792E6368696C644E6F6465735B305D207C7C206E756C6C293B0A2020202020207D0A0A2020202020202F2A20576F726B206F6E2077686F';
wwv_flow_api.g_varchar2_table(337) := '6C6520646F63756D656E74206F72206A7573742069747320626F6479202A2F0A20202020202072657475726E20676574456C656D656E747342795461674E616D652E63616C6C28646F632C2057484F4C455F444F43554D454E54203F202768746D6C2720';
wwv_flow_api.g_varchar2_table(338) := '3A2027626F647927295B305D3B0A202020207D3B0A0A202020202F2A2A0A20202020202A205F6372656174654974657261746F720A20202020202A0A20202020202A2040706172616D20207B446F63756D656E747D20726F6F7420646F63756D656E742F';
wwv_flow_api.g_varchar2_table(339) := '667261676D656E7420746F20637265617465206974657261746F7220666F720A20202020202A204072657475726E207B4974657261746F727D206974657261746F7220696E7374616E63650A20202020202A2F0A20202020766172205F63726561746549';
wwv_flow_api.g_varchar2_table(340) := '74657261746F72203D2066756E6374696F6E205F6372656174654974657261746F7228726F6F7429207B0A20202020202072657475726E206372656174654E6F64654974657261746F722E63616C6C28726F6F742E6F776E6572446F63756D656E74207C';
wwv_flow_api.g_varchar2_table(341) := '7C20726F6F742C20726F6F742C204E6F646546696C7465722E53484F575F454C454D454E54207C204E6F646546696C7465722E53484F575F434F4D4D454E54207C204E6F646546696C7465722E53484F575F544558542C2066756E6374696F6E20282920';
wwv_flow_api.g_varchar2_table(342) := '7B0A202020202020202072657475726E204E6F646546696C7465722E46494C5445525F4143434550543B0A2020202020207D2C2066616C7365293B0A202020207D3B0A0A202020202F2A2A0A20202020202A205F6973436C6F6262657265640A20202020';
wwv_flow_api.g_varchar2_table(343) := '202A0A20202020202A2040706172616D20207B4E6F64657D20656C6D20656C656D656E7420746F20636865636B20666F7220636C6F62626572696E672061747461636B730A20202020202A204072657475726E207B426F6F6C65616E7D20747275652069';
wwv_flow_api.g_varchar2_table(344) := '6620636C6F6262657265642C2066616C736520696620736166650A20202020202A2F0A20202020766172205F6973436C6F626265726564203D2066756E6374696F6E205F6973436C6F62626572656428656C6D29207B0A20202020202069662028656C6D';
wwv_flow_api.g_varchar2_table(345) := '20696E7374616E63656F662054657874207C7C20656C6D20696E7374616E63656F6620436F6D6D656E7429207B0A202020202020202072657475726E2066616C73653B0A2020202020207D0A0A20202020202069662028747970656F6620656C6D2E6E6F';
wwv_flow_api.g_varchar2_table(346) := '64654E616D6520213D3D2027737472696E6727207C7C20747970656F6620656C6D2E74657874436F6E74656E7420213D3D2027737472696E6727207C7C20747970656F6620656C6D2E72656D6F76654368696C6420213D3D202766756E6374696F6E2720';
wwv_flow_api.g_varchar2_table(347) := '7C7C202128656C6D2E6174747269627574657320696E7374616E63656F66204E616D65644E6F64654D617029207C7C20747970656F6620656C6D2E72656D6F766541747472696275746520213D3D202766756E6374696F6E27207C7C20747970656F6620';
wwv_flow_api.g_varchar2_table(348) := '656C6D2E73657441747472696275746520213D3D202766756E6374696F6E27207C7C20747970656F6620656C6D2E6E616D65737061636555524920213D3D2027737472696E6727207C7C20747970656F6620656C6D2E696E736572744265666F72652021';
wwv_flow_api.g_varchar2_table(349) := '3D3D202766756E6374696F6E2729207B0A202020202020202072657475726E20747275653B0A2020202020207D0A0A20202020202072657475726E2066616C73653B0A202020207D3B0A0A202020202F2A2A0A20202020202A205F69734E6F64650A2020';
wwv_flow_api.g_varchar2_table(350) := '2020202A0A20202020202A2040706172616D20207B4E6F64657D206F626A206F626A65637420746F20636865636B20776865746865722069742773206120444F4D206E6F64650A20202020202A204072657475726E207B426F6F6C65616E7D2074727565';
wwv_flow_api.g_varchar2_table(351) := '206973206F626A656374206973206120444F4D206E6F64650A20202020202A2F0A20202020766172205F69734E6F6465203D2066756E6374696F6E205F69734E6F6465286F626A65637429207B0A20202020202072657475726E2028747970656F66204E';
wwv_flow_api.g_varchar2_table(352) := '6F6465203D3D3D2027756E646566696E656427203F2027756E646566696E656427203A205F747970656F66284E6F64652929203D3D3D20276F626A65637427203F206F626A65637420696E7374616E63656F66204E6F6465203A206F626A656374202626';
wwv_flow_api.g_varchar2_table(353) := '2028747970656F66206F626A656374203D3D3D2027756E646566696E656427203F2027756E646566696E656427203A205F747970656F66286F626A6563742929203D3D3D20276F626A6563742720262620747970656F66206F626A6563742E6E6F646554';
wwv_flow_api.g_varchar2_table(354) := '797065203D3D3D20276E756D6265722720262620747970656F66206F626A6563742E6E6F64654E616D65203D3D3D2027737472696E67273B0A202020207D3B0A0A202020202F2A2A0A20202020202A205F65786563757465486F6F6B0A20202020202A20';
wwv_flow_api.g_varchar2_table(355) := '45786563757465207573657220636F6E666967757261626C6520686F6F6B730A20202020202A0A20202020202A2040706172616D20207B537472696E677D20656E747279506F696E7420204E616D65206F662074686520686F6F6B277320656E74727920';
wwv_flow_api.g_varchar2_table(356) := '706F696E740A20202020202A2040706172616D20207B4E6F64657D2063757272656E744E6F6465206E6F646520746F20776F726B206F6E20776974682074686520686F6F6B0A20202020202A2040706172616D20207B4F626A6563747D20646174612061';
wwv_flow_api.g_varchar2_table(357) := '64646974696F6E616C20686F6F6B20706172616D65746572730A20202020202A2F0A20202020766172205F65786563757465486F6F6B203D2066756E6374696F6E205F65786563757465486F6F6B28656E747279506F696E742C2063757272656E744E6F';
wwv_flow_api.g_varchar2_table(358) := '64652C206461746129207B0A2020202020206966202821686F6F6B735B656E747279506F696E745D29207B0A202020202020202072657475726E3B0A2020202020207D0A0A2020202020206172726179466F724561636828686F6F6B735B656E74727950';
wwv_flow_api.g_varchar2_table(359) := '6F696E745D2C2066756E6374696F6E2028686F6F6B29207B0A2020202020202020686F6F6B2E63616C6C28444F4D5075726966792C2063757272656E744E6F64652C20646174612C20434F4E464947293B0A2020202020207D293B0A202020207D3B0A0A';
wwv_flow_api.g_varchar2_table(360) := '202020202F2A2A0A20202020202A205F73616E6974697A65456C656D656E74730A20202020202A0A20202020202A204070726F74656374206E6F64654E616D650A20202020202A204070726F746563742074657874436F6E74656E740A20202020202A20';
wwv_flow_api.g_varchar2_table(361) := '4070726F746563742072656D6F76654368696C640A20202020202A0A20202020202A2040706172616D2020207B4E6F64657D2063757272656E744E6F646520746F20636865636B20666F72207065726D697373696F6E20746F2065786973740A20202020';
wwv_flow_api.g_varchar2_table(362) := '202A204072657475726E20207B426F6F6C65616E7D2074727565206966206E6F646520776173206B696C6C65642C2066616C7365206966206C65667420616C6976650A20202020202A2F0A20202020766172205F73616E6974697A65456C656D656E7473';
wwv_flow_api.g_varchar2_table(363) := '203D2066756E6374696F6E205F73616E6974697A65456C656D656E74732863757272656E744E6F646529207B0A20202020202076617220636F6E74656E74203D20766F696420303B0A0A2020202020202F2A2045786563757465206120686F6F6B206966';
wwv_flow_api.g_varchar2_table(364) := '2070726573656E74202A2F0A2020202020205F65786563757465486F6F6B28276265666F726553616E6974697A65456C656D656E7473272C2063757272656E744E6F64652C206E756C6C293B0A0A2020202020202F2A20436865636B20696620656C656D';
wwv_flow_api.g_varchar2_table(365) := '656E7420697320636C6F626265726564206F722063616E20636C6F62626572202A2F0A202020202020696620285F6973436C6F6262657265642863757272656E744E6F64652929207B0A20202020202020205F666F72636552656D6F7665286375727265';
wwv_flow_api.g_varchar2_table(366) := '6E744E6F6465293B0A202020202020202072657475726E20747275653B0A2020202020207D0A0A2020202020202F2A20436865636B206966207461676E616D6520636F6E7461696E7320556E69636F6465202A2F0A20202020202069662028737472696E';
wwv_flow_api.g_varchar2_table(367) := '674D617463682863757272656E744E6F64652E6E6F64654E616D652C202F5B5C75303038302D5C75464646465D2F2929207B0A20202020202020205F666F72636552656D6F76652863757272656E744E6F6465293B0A202020202020202072657475726E';
wwv_flow_api.g_varchar2_table(368) := '20747275653B0A2020202020207D0A0A2020202020202F2A204E6F77206C6574277320636865636B2074686520656C656D656E742773207479706520616E64206E616D65202A2F0A202020202020766172207461674E616D65203D20737472696E67546F';
wwv_flow_api.g_varchar2_table(369) := '4C6F776572436173652863757272656E744E6F64652E6E6F64654E616D65293B0A0A2020202020202F2A2045786563757465206120686F6F6B2069662070726573656E74202A2F0A2020202020205F65786563757465486F6F6B282775706F6E53616E69';
wwv_flow_api.g_varchar2_table(370) := '74697A65456C656D656E74272C2063757272656E744E6F64652C207B0A20202020202020207461674E616D653A207461674E616D652C0A2020202020202020616C6C6F776564546167733A20414C4C4F5745445F544147530A2020202020207D293B0A0A';
wwv_flow_api.g_varchar2_table(371) := '2020202020202F2A20446574656374206D58535320617474656D7074732061627573696E67206E616D65737061636520636F6E667573696F6E202A2F0A20202020202069662028215F69734E6F64652863757272656E744E6F64652E6669727374456C65';
wwv_flow_api.g_varchar2_table(372) := '6D656E744368696C64292026262028215F69734E6F64652863757272656E744E6F64652E636F6E74656E7429207C7C20215F69734E6F64652863757272656E744E6F64652E636F6E74656E742E6669727374456C656D656E744368696C64292920262620';
wwv_flow_api.g_varchar2_table(373) := '72656745787054657374282F3C5B2F5C775D2F672C2063757272656E744E6F64652E696E6E657248544D4C292026262072656745787054657374282F3C5B2F5C775D2F672C2063757272656E744E6F64652E74657874436F6E74656E742929207B0A2020';
wwv_flow_api.g_varchar2_table(374) := '2020202020205F666F72636552656D6F76652863757272656E744E6F6465293B0A202020202020202072657475726E20747275653B0A2020202020207D0A0A2020202020202F2A2052656D6F766520656C656D656E7420696620616E797468696E672066';
wwv_flow_api.g_varchar2_table(375) := '6F7262696473206974732070726573656E6365202A2F0A2020202020206966202821414C4C4F5745445F544147535B7461674E616D655D207C7C20464F524249445F544147535B7461674E616D655D29207B0A20202020202020202F2A204B6565702063';
wwv_flow_api.g_varchar2_table(376) := '6F6E74656E742065786365707420666F72206261642D6C697374656420656C656D656E7473202A2F0A2020202020202020696620284B4545505F434F4E54454E542026262021464F524249445F434F4E54454E54535B7461674E616D655D29207B0A2020';
wwv_flow_api.g_varchar2_table(377) := '202020202020202076617220706172656E744E6F6465203D20676574506172656E744E6F64652863757272656E744E6F6465293B0A20202020202020202020766172206368696C644E6F646573203D206765744368696C644E6F6465732863757272656E';
wwv_flow_api.g_varchar2_table(378) := '744E6F6465293B0A20202020202020202020766172206368696C64436F756E74203D206368696C644E6F6465732E6C656E6774683B0A20202020202020202020666F7220287661722069203D206368696C64436F756E74202D20313B2069203E3D20303B';
wwv_flow_api.g_varchar2_table(379) := '202D2D6929207B0A202020202020202020202020706172656E744E6F64652E696E736572744265666F726528636C6F6E654E6F6465286368696C644E6F6465735B695D2C2074727565292C206765744E6578745369626C696E672863757272656E744E6F';
wwv_flow_api.g_varchar2_table(380) := '646529293B0A202020202020202020207D0A20202020202020207D0A0A20202020202020205F666F72636552656D6F76652863757272656E744E6F6465293B0A202020202020202072657475726E20747275653B0A2020202020207D0A0A202020202020';
wwv_flow_api.g_varchar2_table(381) := '2F2A20436865636B207768657468657220656C656D656E742068617320612076616C6964206E616D657370616365202A2F0A2020202020206966202863757272656E744E6F646520696E7374616E63656F6620456C656D656E7420262620215F63686563';
wwv_flow_api.g_varchar2_table(382) := '6B56616C69644E616D6573706163652863757272656E744E6F64652929207B0A20202020202020205F666F72636552656D6F76652863757272656E744E6F6465293B0A202020202020202072657475726E20747275653B0A2020202020207D0A0A202020';
wwv_flow_api.g_varchar2_table(383) := '20202069662028287461674E616D65203D3D3D20276E6F73637269707427207C7C207461674E616D65203D3D3D20276E6F656D62656427292026262072656745787054657374282F3C5C2F6E6F287363726970747C656D626564292F692C206375727265';
wwv_flow_api.g_varchar2_table(384) := '6E744E6F64652E696E6E657248544D4C2929207B0A20202020202020205F666F72636552656D6F76652863757272656E744E6F6465293B0A202020202020202072657475726E20747275653B0A2020202020207D0A0A2020202020202F2A2053616E6974';
wwv_flow_api.g_varchar2_table(385) := '697A6520656C656D656E7420636F6E74656E7420746F2062652074656D706C6174652D73616665202A2F0A20202020202069662028534146455F464F525F54454D504C415445532026262063757272656E744E6F64652E6E6F646554797065203D3D3D20';
wwv_flow_api.g_varchar2_table(386) := '3329207B0A20202020202020202F2A204765742074686520656C656D656E742773207465787420636F6E74656E74202A2F0A2020202020202020636F6E74656E74203D2063757272656E744E6F64652E74657874436F6E74656E743B0A20202020202020';
wwv_flow_api.g_varchar2_table(387) := '20636F6E74656E74203D20737472696E675265706C61636528636F6E74656E742C204D555354414348455F455850522424312C20272027293B0A2020202020202020636F6E74656E74203D20737472696E675265706C61636528636F6E74656E742C2045';
wwv_flow_api.g_varchar2_table(388) := '52425F455850522424312C20272027293B0A20202020202020206966202863757272656E744E6F64652E74657874436F6E74656E7420213D3D20636F6E74656E7429207B0A2020202020202020202061727261795075736828444F4D5075726966792E72';
wwv_flow_api.g_varchar2_table(389) := '656D6F7665642C207B20656C656D656E743A2063757272656E744E6F64652E636C6F6E654E6F64652829207D293B0A2020202020202020202063757272656E744E6F64652E74657874436F6E74656E74203D20636F6E74656E743B0A2020202020202020';
wwv_flow_api.g_varchar2_table(390) := '7D0A2020202020207D0A0A2020202020202F2A2045786563757465206120686F6F6B2069662070726573656E74202A2F0A2020202020205F65786563757465486F6F6B2827616674657253616E6974697A65456C656D656E7473272C2063757272656E74';
wwv_flow_api.g_varchar2_table(391) := '4E6F64652C206E756C6C293B0A0A20202020202072657475726E2066616C73653B0A202020207D3B0A0A202020202F2A2A0A20202020202A205F697356616C69644174747269627574650A20202020202A0A20202020202A2040706172616D20207B7374';
wwv_flow_api.g_varchar2_table(392) := '72696E677D206C63546167204C6F7765726361736520746167206E616D65206F6620636F6E7461696E696E6720656C656D656E742E0A20202020202A2040706172616D20207B737472696E677D206C634E616D65204C6F77657263617365206174747269';
wwv_flow_api.g_varchar2_table(393) := '62757465206E616D652E0A20202020202A2040706172616D20207B737472696E677D2076616C7565204174747269627574652076616C75652E0A20202020202A204072657475726E207B426F6F6C65616E7D2052657475726E7320747275652069662060';
wwv_flow_api.g_varchar2_table(394) := '76616C7565602069732076616C69642C206F74686572776973652066616C73652E0A20202020202A2F0A202020202F2F2065736C696E742D64697361626C652D6E6578742D6C696E6520636F6D706C65786974790A20202020766172205F697356616C69';
wwv_flow_api.g_varchar2_table(395) := '64417474726962757465203D2066756E6374696F6E205F697356616C6964417474726962757465286C635461672C206C634E616D652C2076616C756529207B0A2020202020202F2A204D616B652073757265206174747269627574652063616E6E6F7420';

wwv_flow_api.g_varchar2_table(396) := '636C6F62626572202A2F0A2020202020206966202853414E4954495A455F444F4D20262620286C634E616D65203D3D3D2027696427207C7C206C634E616D65203D3D3D20276E616D652729202626202876616C756520696E20646F63756D656E74207C7C';
wwv_flow_api.g_varchar2_table(397) := '2076616C756520696E20666F726D456C656D656E742929207B0A202020202020202072657475726E2066616C73653B0A2020202020207D0A0A2020202020202F2A20416C6C6F772076616C696420646174612D2A20617474726962757465733A20417420';
wwv_flow_api.g_varchar2_table(398) := '6C65617374206F6E652063686172616374657220616674657220222D220A202020202020202020202868747470733A2F2F68746D6C2E737065632E7768617477672E6F72672F6D756C7469706167652F646F6D2E68746D6C23656D62656464696E672D63';
wwv_flow_api.g_varchar2_table(399) := '7573746F6D2D6E6F6E2D76697369626C652D646174612D776974682D7468652D646174612D2A2D61747472696275746573290A20202020202020202020584D4C2D636F6D70617469626C65202868747470733A2F2F68746D6C2E737065632E7768617477';
wwv_flow_api.g_varchar2_table(400) := '672E6F72672F6D756C7469706167652F696E6672617374727563747572652E68746D6C23786D6C2D636F6D70617469626C6520616E6420687474703A2F2F7777772E77332E6F72672F54522F786D6C2F23643065383034290A2020202020202020202057';
wwv_flow_api.g_varchar2_table(401) := '6520646F6E2774206E65656420746F20636865636B207468652076616C75653B206974277320616C776179732055524920736166652E202A2F0A20202020202069662028414C4C4F575F444154415F415454522026262072656745787054657374284441';
wwv_flow_api.g_varchar2_table(402) := '54415F415454522424312C206C634E616D652929203B20656C73652069662028414C4C4F575F415249415F41545452202626207265674578705465737428415249415F415454522424312C206C634E616D652929203B20656C7365206966202821414C4C';
wwv_flow_api.g_varchar2_table(403) := '4F5745445F415454525B6C634E616D655D207C7C20464F524249445F415454525B6C634E616D655D29207B0A202020202020202072657475726E2066616C73653B0A0A20202020202020202F2A20436865636B2076616C756520697320736166652E2046';
wwv_flow_api.g_varchar2_table(404) := '697273742C206973206174747220696E6572743F20496620736F2C2069732073616665202A2F0A2020202020207D20656C736520696620285552495F534146455F415454524942555445535B6C634E616D655D29203B20656C7365206966202872656745';
wwv_flow_api.g_varchar2_table(405) := '7870546573742849535F414C4C4F5745445F5552492424312C20737472696E675265706C6163652876616C75652C20415454525F574849544553504143452424312C202727292929203B20656C73652069662028286C634E616D65203D3D3D2027737263';
wwv_flow_api.g_varchar2_table(406) := '27207C7C206C634E616D65203D3D3D2027786C696E6B3A6872656627207C7C206C634E616D65203D3D3D2027687265662729202626206C6354616720213D3D20277363726970742720262620737472696E67496E6465784F662876616C75652C20276461';
wwv_flow_api.g_varchar2_table(407) := '74613A2729203D3D3D203020262620444154415F5552495F544147535B6C635461675D29203B20656C73652069662028414C4C4F575F554E4B4E4F574E5F50524F544F434F4C532026262021726567457870546573742849535F5343524950545F4F525F';
wwv_flow_api.g_varchar2_table(408) := '444154412424312C20737472696E675265706C6163652876616C75652C20415454525F574849544553504143452424312C202727292929203B20656C736520696620282176616C756529203B20656C7365207B0A202020202020202072657475726E2066';
wwv_flow_api.g_varchar2_table(409) := '616C73653B0A2020202020207D0A0A20202020202072657475726E20747275653B0A202020207D3B0A0A202020202F2A2A0A20202020202A205F73616E6974697A65417474726962757465730A20202020202A0A20202020202A204070726F7465637420';
wwv_flow_api.g_varchar2_table(410) := '617474726962757465730A20202020202A204070726F74656374206E6F64654E616D650A20202020202A204070726F746563742072656D6F76654174747269627574650A20202020202A204070726F74656374207365744174747269627574650A202020';
wwv_flow_api.g_varchar2_table(411) := '20202A0A20202020202A2040706172616D20207B4E6F64657D2063757272656E744E6F646520746F2073616E6974697A650A20202020202A2F0A20202020766172205F73616E6974697A6541747472696275746573203D2066756E6374696F6E205F7361';
wwv_flow_api.g_varchar2_table(412) := '6E6974697A65417474726962757465732863757272656E744E6F646529207B0A2020202020207661722061747472203D20766F696420303B0A2020202020207661722076616C7565203D20766F696420303B0A202020202020766172206C634E616D6520';
wwv_flow_api.g_varchar2_table(413) := '3D20766F696420303B0A202020202020766172206C203D20766F696420303B0A2020202020202F2A2045786563757465206120686F6F6B2069662070726573656E74202A2F0A2020202020205F65786563757465486F6F6B28276265666F726553616E69';
wwv_flow_api.g_varchar2_table(414) := '74697A6541747472696275746573272C2063757272656E744E6F64652C206E756C6C293B0A0A2020202020207661722061747472696275746573203D2063757272656E744E6F64652E617474726962757465733B0A0A2020202020202F2A20436865636B';
wwv_flow_api.g_varchar2_table(415) := '206966207765206861766520617474726962757465733B206966206E6F74207765206D69676874206861766520612074657874206E6F6465202A2F0A0A20202020202069662028216174747269627574657329207B0A202020202020202072657475726E';
wwv_flow_api.g_varchar2_table(416) := '3B0A2020202020207D0A0A20202020202076617220686F6F6B4576656E74203D207B0A2020202020202020617474724E616D653A2027272C0A20202020202020206174747256616C75653A2027272C0A20202020202020206B656570417474723A207472';
wwv_flow_api.g_varchar2_table(417) := '75652C0A2020202020202020616C6C6F776564417474726962757465733A20414C4C4F5745445F415454520A2020202020207D3B0A2020202020206C203D20617474726962757465732E6C656E6774683B0A0A2020202020202F2A20476F206261636B77';
wwv_flow_api.g_varchar2_table(418) := '61726473206F76657220616C6C20617474726962757465733B20736166656C792072656D6F766520626164206F6E6573202A2F0A2020202020207768696C6520286C2D2D29207B0A202020202020202061747472203D20617474726962757465735B6C5D';
wwv_flow_api.g_varchar2_table(419) := '3B0A2020202020202020766172205F61747472203D20617474722C0A2020202020202020202020206E616D65203D205F617474722E6E616D652C0A2020202020202020202020206E616D657370616365555249203D205F617474722E6E616D6573706163';
wwv_flow_api.g_varchar2_table(420) := '655552493B0A0A202020202020202076616C7565203D20737472696E675472696D28617474722E76616C7565293B0A20202020202020206C634E616D65203D20737472696E67546F4C6F77657243617365286E616D65293B0A0A20202020202020202F2A';
wwv_flow_api.g_varchar2_table(421) := '2045786563757465206120686F6F6B2069662070726573656E74202A2F0A2020202020202020686F6F6B4576656E742E617474724E616D65203D206C634E616D653B0A2020202020202020686F6F6B4576656E742E6174747256616C7565203D2076616C';
wwv_flow_api.g_varchar2_table(422) := '75653B0A2020202020202020686F6F6B4576656E742E6B65657041747472203D20747275653B0A2020202020202020686F6F6B4576656E742E666F7263654B65657041747472203D20756E646566696E65643B202F2F20416C6C6F777320646576656C6F';
wwv_flow_api.g_varchar2_table(423) := '7065727320746F20736565207468697320697320612070726F706572747920746865792063616E207365740A20202020202020205F65786563757465486F6F6B282775706F6E53616E6974697A65417474726962757465272C2063757272656E744E6F64';
wwv_flow_api.g_varchar2_table(424) := '652C20686F6F6B4576656E74293B0A202020202020202076616C7565203D20686F6F6B4576656E742E6174747256616C75653B0A20202020202020202F2A204469642074686520686F6F6B7320617070726F7665206F6620746865206174747269627574';
wwv_flow_api.g_varchar2_table(425) := '653F202A2F0A202020202020202069662028686F6F6B4576656E742E666F7263654B6565704174747229207B0A20202020202020202020636F6E74696E75653B0A20202020202020207D0A0A20202020202020202F2A2052656D6F766520617474726962';
wwv_flow_api.g_varchar2_table(426) := '757465202A2F0A20202020202020205F72656D6F7665417474726962757465286E616D652C2063757272656E744E6F6465293B0A0A20202020202020202F2A204469642074686520686F6F6B7320617070726F7665206F66207468652061747472696275';
wwv_flow_api.g_varchar2_table(427) := '74653F202A2F0A20202020202020206966202821686F6F6B4576656E742E6B6565704174747229207B0A20202020202020202020636F6E74696E75653B0A20202020202020207D0A0A20202020202020202F2A20576F726B2061726F756E642061207365';
wwv_flow_api.g_varchar2_table(428) := '63757269747920697373756520696E206A517565727920332E30202A2F0A20202020202020206966202872656745787054657374282F5C2F3E2F692C2076616C75652929207B0A202020202020202020205F72656D6F7665417474726962757465286E61';
wwv_flow_api.g_varchar2_table(429) := '6D652C2063757272656E744E6F6465293B0A20202020202020202020636F6E74696E75653B0A20202020202020207D0A0A20202020202020202F2A2053616E6974697A652061747472696275746520636F6E74656E7420746F2062652074656D706C6174';
wwv_flow_api.g_varchar2_table(430) := '652D73616665202A2F0A202020202020202069662028534146455F464F525F54454D504C4154455329207B0A2020202020202020202076616C7565203D20737472696E675265706C6163652876616C75652C204D555354414348455F455850522424312C';
wwv_flow_api.g_varchar2_table(431) := '20272027293B0A2020202020202020202076616C7565203D20737472696E675265706C6163652876616C75652C204552425F455850522424312C20272027293B0A20202020202020207D0A0A20202020202020202F2A204973206076616C756560207661';
wwv_flow_api.g_varchar2_table(432) := '6C696420666F722074686973206174747269627574653F202A2F0A2020202020202020766172206C63546167203D2063757272656E744E6F64652E6E6F64654E616D652E746F4C6F7765724361736528293B0A202020202020202069662028215F697356';
wwv_flow_api.g_varchar2_table(433) := '616C6964417474726962757465286C635461672C206C634E616D652C2076616C75652929207B0A20202020202020202020636F6E74696E75653B0A20202020202020207D0A0A20202020202020202F2A2048616E646C6520696E76616C69642064617461';
wwv_flow_api.g_varchar2_table(434) := '2D2A2061747472696275746520736574206279207472792D6361746368696E67206974202A2F0A2020202020202020747279207B0A20202020202020202020696620286E616D65737061636555524929207B0A2020202020202020202020206375727265';
wwv_flow_api.g_varchar2_table(435) := '6E744E6F64652E7365744174747269627574654E53286E616D6573706163655552492C206E616D652C2076616C7565293B0A202020202020202020207D20656C7365207B0A2020202020202020202020202F2A2046616C6C6261636B20746F2073657441';
wwv_flow_api.g_varchar2_table(436) := '7474726962757465282920666F722062726F777365722D756E7265636F676E697A6564206E616D6573706163657320652E672E2022782D736368656D61222E202A2F0A20202020202020202020202063757272656E744E6F64652E736574417474726962';
wwv_flow_api.g_varchar2_table(437) := '757465286E616D652C2076616C7565293B0A202020202020202020207D0A0A202020202020202020206172726179506F7028444F4D5075726966792E72656D6F766564293B0A20202020202020207D20636174636820285F29207B7D0A2020202020207D';
wwv_flow_api.g_varchar2_table(438) := '0A0A2020202020202F2A2045786563757465206120686F6F6B2069662070726573656E74202A2F0A2020202020205F65786563757465486F6F6B2827616674657253616E6974697A6541747472696275746573272C2063757272656E744E6F64652C206E';
wwv_flow_api.g_varchar2_table(439) := '756C6C293B0A202020207D3B0A0A202020202F2A2A0A20202020202A205F73616E6974697A65536861646F77444F4D0A20202020202A0A20202020202A2040706172616D20207B446F63756D656E74467261676D656E747D20667261676D656E7420746F';
wwv_flow_api.g_varchar2_table(440) := '2069746572617465206F766572207265637572736976656C790A20202020202A2F0A20202020766172205F73616E6974697A65536861646F77444F4D203D2066756E6374696F6E205F73616E6974697A65536861646F77444F4D28667261676D656E7429';
wwv_flow_api.g_varchar2_table(441) := '207B0A20202020202076617220736861646F774E6F6465203D20766F696420303B0A20202020202076617220736861646F774974657261746F72203D205F6372656174654974657261746F7228667261676D656E74293B0A0A2020202020202F2A204578';
wwv_flow_api.g_varchar2_table(442) := '6563757465206120686F6F6B2069662070726573656E74202A2F0A2020202020205F65786563757465486F6F6B28276265666F726553616E6974697A65536861646F77444F4D272C20667261676D656E742C206E756C6C293B0A0A202020202020776869';
wwv_flow_api.g_varchar2_table(443) := '6C652028736861646F774E6F6465203D20736861646F774974657261746F722E6E6578744E6F6465282929207B0A20202020202020202F2A2045786563757465206120686F6F6B2069662070726573656E74202A2F0A20202020202020205F6578656375';
wwv_flow_api.g_varchar2_table(444) := '7465486F6F6B282775706F6E53616E6974697A65536861646F774E6F6465272C20736861646F774E6F64652C206E756C6C293B0A0A20202020202020202F2A2053616E6974697A65207461677320616E6420656C656D656E7473202A2F0A202020202020';
wwv_flow_api.g_varchar2_table(445) := '2020696620285F73616E6974697A65456C656D656E747328736861646F774E6F64652929207B0A20202020202020202020636F6E74696E75653B0A20202020202020207D0A0A20202020202020202F2A204465657020736861646F7720444F4D20646574';
wwv_flow_api.g_varchar2_table(446) := '6563746564202A2F0A202020202020202069662028736861646F774E6F64652E636F6E74656E7420696E7374616E63656F6620446F63756D656E74467261676D656E7429207B0A202020202020202020205F73616E6974697A65536861646F77444F4D28';
wwv_flow_api.g_varchar2_table(447) := '736861646F774E6F64652E636F6E74656E74293B0A20202020202020207D0A0A20202020202020202F2A20436865636B20617474726962757465732C2073616E6974697A65206966206E6563657373617279202A2F0A20202020202020205F73616E6974';
wwv_flow_api.g_varchar2_table(448) := '697A654174747269627574657328736861646F774E6F6465293B0A2020202020207D0A0A2020202020202F2A2045786563757465206120686F6F6B2069662070726573656E74202A2F0A2020202020205F65786563757465486F6F6B2827616674657253';
wwv_flow_api.g_varchar2_table(449) := '616E6974697A65536861646F77444F4D272C20667261676D656E742C206E756C6C293B0A202020207D3B0A0A202020202F2A2A0A20202020202A2053616E6974697A650A20202020202A205075626C6963206D6574686F642070726F766964696E672063';
wwv_flow_api.g_varchar2_table(450) := '6F72652073616E69746174696F6E2066756E6374696F6E616C6974790A20202020202A0A20202020202A2040706172616D207B537472696E677C4E6F64657D20646972747920737472696E67206F7220444F4D206E6F64650A20202020202A2040706172';
wwv_flow_api.g_varchar2_table(451) := '616D207B4F626A6563747D20636F6E66696775726174696F6E206F626A6563740A20202020202A2F0A202020202F2F2065736C696E742D64697361626C652D6E6578742D6C696E6520636F6D706C65786974790A20202020444F4D5075726966792E7361';
wwv_flow_api.g_varchar2_table(452) := '6E6974697A65203D2066756E6374696F6E202864697274792C2063666729207B0A20202020202076617220626F6479203D20766F696420303B0A20202020202076617220696D706F727465644E6F6465203D20766F696420303B0A202020202020766172';
wwv_flow_api.g_varchar2_table(453) := '2063757272656E744E6F6465203D20766F696420303B0A202020202020766172206F6C644E6F6465203D20766F696420303B0A2020202020207661722072657475726E4E6F6465203D20766F696420303B0A2020202020202F2A204D616B652073757265';
wwv_flow_api.g_varchar2_table(454) := '2077652068617665206120737472696E6720746F2073616E6974697A652E0A2020202020202020444F204E4F542072657475726E206561726C792C20617320746869732077696C6C2072657475726E207468652077726F6E6720747970652069660A2020';
wwv_flow_api.g_varchar2_table(455) := '20202020202074686520757365722068617320726571756573746564206120444F4D206F626A65637420726174686572207468616E206120737472696E67202A2F0A2020202020206966202821646972747929207B0A2020202020202020646972747920';
wwv_flow_api.g_varchar2_table(456) := '3D20273C212D2D3E273B0A2020202020207D0A0A2020202020202F2A20537472696E676966792C20696E206361736520646972747920697320616E206F626A656374202A2F0A20202020202069662028747970656F6620646972747920213D3D20277374';
wwv_flow_api.g_varchar2_table(457) := '72696E672720262620215F69734E6F64652864697274792929207B0A20202020202020202F2F2065736C696E742D64697361626C652D6E6578742D6C696E65206E6F2D6E6567617465642D636F6E646974696F6E0A202020202020202069662028747970';
wwv_flow_api.g_varchar2_table(458) := '656F662064697274792E746F537472696E6720213D3D202766756E6374696F6E2729207B0A202020202020202020207468726F7720747970654572726F724372656174652827746F537472696E67206973206E6F7420612066756E6374696F6E27293B0A';
wwv_flow_api.g_varchar2_table(459) := '20202020202020207D20656C7365207B0A202020202020202020206469727479203D2064697274792E746F537472696E6728293B0A2020202020202020202069662028747970656F6620646972747920213D3D2027737472696E672729207B0A20202020';
wwv_flow_api.g_varchar2_table(460) := '20202020202020207468726F7720747970654572726F7243726561746528276469727479206973206E6F74206120737472696E672C2061626F7274696E6727293B0A202020202020202020207D0A20202020202020207D0A2020202020207D0A0A202020';
wwv_flow_api.g_varchar2_table(461) := '2020202F2A20436865636B2077652063616E2072756E2E204F74686572776973652066616C6C206261636B206F722069676E6F7265202A2F0A2020202020206966202821444F4D5075726966792E6973537570706F7274656429207B0A20202020202020';
wwv_flow_api.g_varchar2_table(462) := '20696620285F747970656F662877696E646F772E746F53746174696348544D4C29203D3D3D20276F626A65637427207C7C20747970656F662077696E646F772E746F53746174696348544D4C203D3D3D202766756E6374696F6E2729207B0A2020202020';
wwv_flow_api.g_varchar2_table(463) := '202020202069662028747970656F66206469727479203D3D3D2027737472696E672729207B0A20202020202020202020202072657475726E2077696E646F772E746F53746174696348544D4C286469727479293B0A202020202020202020207D0A0A2020';
wwv_flow_api.g_varchar2_table(464) := '2020202020202020696620285F69734E6F64652864697274792929207B0A20202020202020202020202072657475726E2077696E646F772E746F53746174696348544D4C2864697274792E6F7574657248544D4C293B0A202020202020202020207D0A20';
wwv_flow_api.g_varchar2_table(465) := '202020202020207D0A0A202020202020202072657475726E2064697274793B0A2020202020207D0A0A2020202020202F2A2041737369676E20636F6E6669672076617273202A2F0A20202020202069662028215345545F434F4E46494729207B0A202020';
wwv_flow_api.g_varchar2_table(466) := '20202020205F7061727365436F6E66696728636667293B0A2020202020207D0A0A2020202020202F2A20436C65616E2075702072656D6F76656420656C656D656E7473202A2F0A202020202020444F4D5075726966792E72656D6F766564203D205B5D3B';
wwv_flow_api.g_varchar2_table(467) := '0A0A2020202020202F2A20436865636B20696620646972747920697320636F72726563746C7920747970656420666F7220494E5F504C414345202A2F0A20202020202069662028747970656F66206469727479203D3D3D2027737472696E672729207B0A';
wwv_flow_api.g_varchar2_table(468) := '2020202020202020494E5F504C414345203D2066616C73653B0A2020202020207D0A0A20202020202069662028494E5F504C41434529203B20656C73652069662028646972747920696E7374616E63656F66204E6F646529207B0A20202020202020202F';
wwv_flow_api.g_varchar2_table(469) := '2A204966206469727479206973206120444F4D20656C656D656E742C20617070656E6420746F20616E20656D70747920646F63756D656E7420746F2061766F69640A2020202020202020202020656C656D656E7473206265696E67207374726970706564';
wwv_flow_api.g_varchar2_table(470) := '2062792074686520706172736572202A2F0A2020202020202020626F6479203D205F696E6974446F63756D656E7428273C212D2D2D2D3E27293B0A2020202020202020696D706F727465644E6F6465203D20626F64792E6F776E6572446F63756D656E74';
wwv_flow_api.g_varchar2_table(471) := '2E696D706F72744E6F64652864697274792C2074727565293B0A202020202020202069662028696D706F727465644E6F64652E6E6F646554797065203D3D3D203120262620696D706F727465644E6F64652E6E6F64654E616D65203D3D3D2027424F4459';
wwv_flow_api.g_varchar2_table(472) := '2729207B0A202020202020202020202F2A204E6F646520697320616C7265616479206120626F64792C20757365206173206973202A2F0A20202020202020202020626F6479203D20696D706F727465644E6F64653B0A20202020202020207D20656C7365';
wwv_flow_api.g_varchar2_table(473) := '2069662028696D706F727465644E6F64652E6E6F64654E616D65203D3D3D202748544D4C2729207B0A20202020202020202020626F6479203D20696D706F727465644E6F64653B0A20202020202020207D20656C7365207B0A202020202020202020202F';
wwv_flow_api.g_varchar2_table(474) := '2F2065736C696E742D64697361626C652D6E6578742D6C696E6520756E69636F726E2F7072656665722D6E6F64652D617070656E640A20202020202020202020626F64792E617070656E644368696C6428696D706F727465644E6F6465293B0A20202020';
wwv_flow_api.g_varchar2_table(475) := '202020207D0A2020202020207D20656C7365207B0A20202020202020202F2A2045786974206469726563746C792069662077652068617665206E6F7468696E6720746F20646F202A2F0A2020202020202020696620282152455455524E5F444F4D202626';
wwv_flow_api.g_varchar2_table(476) := '2021534146455F464F525F54454D504C41544553202626202157484F4C455F444F43554D454E542026260A20202020202020202F2F2065736C696E742D64697361626C652D6E6578742D6C696E6520756E69636F726E2F7072656665722D696E636C7564';
wwv_flow_api.g_varchar2_table(477) := '65730A202020202020202064697274792E696E6465784F6628273C2729203D3D3D202D3129207B0A2020202020202020202072657475726E20747275737465645479706573506F6C6963792026262052455455524E5F545255535445445F54595045203F';
wwv_flow_api.g_varchar2_table(478) := '20747275737465645479706573506F6C6963792E63726561746548544D4C28646972747929203A2064697274793B0A20202020202020207D0A0A20202020202020202F2A20496E697469616C697A652074686520646F63756D656E7420746F20776F726B';
wwv_flow_api.g_varchar2_table(479) := '206F6E202A2F0A2020202020202020626F6479203D205F696E6974446F63756D656E74286469727479293B0A0A20202020202020202F2A20436865636B2077652068617665206120444F4D206E6F64652066726F6D207468652064617461202A2F0A2020';
wwv_flow_api.g_varchar2_table(480) := '2020202020206966202821626F647929207B0A2020202020202020202072657475726E2052455455524E5F444F4D203F206E756C6C203A20656D70747948544D4C3B0A20202020202020207D0A2020202020207D0A0A2020202020202F2A2052656D6F76';
wwv_flow_api.g_varchar2_table(481) := '6520666972737420656C656D656E74206E6F646520286F7572732920696620464F5243455F424F445920697320736574202A2F0A20202020202069662028626F647920262620464F5243455F424F445929207B0A20202020202020205F666F7263655265';
wwv_flow_api.g_varchar2_table(482) := '6D6F766528626F64792E66697273744368696C64293B0A2020202020207D0A0A2020202020202F2A20476574206E6F6465206974657261746F72202A2F0A202020202020766172206E6F64654974657261746F72203D205F637265617465497465726174';
wwv_flow_api.g_varchar2_table(483) := '6F7228494E5F504C414345203F206469727479203A20626F6479293B0A0A2020202020202F2A204E6F7720737461727420697465726174696E67206F76657220746865206372656174656420646F63756D656E74202A2F0A2020202020207768696C6520';
wwv_flow_api.g_varchar2_table(484) := '2863757272656E744E6F6465203D206E6F64654974657261746F722E6E6578744E6F6465282929207B0A20202020202020202F2A20466978204945277320737472616E6765206265686176696F722077697468206D616E6970756C617465642074657874';
wwv_flow_api.g_varchar2_table(485) := '4E6F64657320233839202A2F0A20202020202020206966202863757272656E744E6F64652E6E6F646554797065203D3D3D20332026262063757272656E744E6F6465203D3D3D206F6C644E6F646529207B0A20202020202020202020636F6E74696E7565';
wwv_flow_api.g_varchar2_table(486) := '3B0A20202020202020207D0A0A20202020202020202F2A2053616E6974697A65207461677320616E6420656C656D656E7473202A2F0A2020202020202020696620285F73616E6974697A65456C656D656E74732863757272656E744E6F64652929207B0A';
wwv_flow_api.g_varchar2_table(487) := '20202020202020202020636F6E74696E75653B0A20202020202020207D0A0A20202020202020202F2A20536861646F7720444F4D2064657465637465642C2073616E6974697A65206974202A2F0A20202020202020206966202863757272656E744E6F64';
wwv_flow_api.g_varchar2_table(488) := '652E636F6E74656E7420696E7374616E63656F6620446F63756D656E74467261676D656E7429207B0A202020202020202020205F73616E6974697A65536861646F77444F4D2863757272656E744E6F64652E636F6E74656E74293B0A2020202020202020';
wwv_flow_api.g_varchar2_table(489) := '7D0A0A20202020202020202F2A20436865636B20617474726962757465732C2073616E6974697A65206966206E6563657373617279202A2F0A20202020202020205F73616E6974697A65417474726962757465732863757272656E744E6F6465293B0A0A';
wwv_flow_api.g_varchar2_table(490) := '20202020202020206F6C644E6F6465203D2063757272656E744E6F64653B0A2020202020207D0A0A2020202020206F6C644E6F6465203D206E756C6C3B0A0A2020202020202F2A2049662077652073616E6974697A6564206064697274796020696E2D70';
wwv_flow_api.g_varchar2_table(491) := '6C6163652C2072657475726E2069742E202A2F0A20202020202069662028494E5F504C41434529207B0A202020202020202072657475726E2064697274793B0A2020202020207D0A0A2020202020202F2A2052657475726E2073616E6974697A65642073';
wwv_flow_api.g_varchar2_table(492) := '7472696E67206F7220444F4D202A2F0A2020202020206966202852455455524E5F444F4D29207B0A20202020202020206966202852455455524E5F444F4D5F465241474D454E5429207B0A2020202020202020202072657475726E4E6F6465203D206372';
wwv_flow_api.g_varchar2_table(493) := '65617465446F63756D656E74467261676D656E742E63616C6C28626F64792E6F776E6572446F63756D656E74293B0A0A202020202020202020207768696C652028626F64792E66697273744368696C6429207B0A2020202020202020202020202F2F2065';
wwv_flow_api.g_varchar2_table(494) := '736C696E742D64697361626C652D6E6578742D6C696E6520756E69636F726E2F7072656665722D6E6F64652D617070656E640A20202020202020202020202072657475726E4E6F64652E617070656E644368696C6428626F64792E66697273744368696C';
wwv_flow_api.g_varchar2_table(495) := '64293B0A202020202020202020207D0A20202020202020207D20656C7365207B0A2020202020202020202072657475726E4E6F6465203D20626F64793B0A20202020202020207D0A0A20202020202020206966202852455455524E5F444F4D5F494D504F';
wwv_flow_api.g_varchar2_table(496) := '525429207B0A202020202020202020202F2A0A20202020202020202020202041646F70744E6F64652829206973206E6F742075736564206265636175736520696E7465726E616C207374617465206973206E6F742072657365740A202020202020202020';
wwv_flow_api.g_varchar2_table(497) := '20202028652E672E207468652070617374206E616D6573206D6170206F6620612048544D4C466F726D456C656D656E74292C207468697320697320736166650A202020202020202020202020696E207468656F72792062757420776520776F756C642072';
wwv_flow_api.g_varchar2_table(498) := '6174686572206E6F74207269736B20616E6F746865722061747461636B20766563746F722E0A202020202020202020202020546865207374617465207468617420697320636C6F6E656420627920696D706F72744E6F64652829206973206578706C6963';
wwv_flow_api.g_varchar2_table(499) := '69746C7920646566696E65640A2020202020202020202020206279207468652073706563732E0A202020202020202020202A2F0A2020202020202020202072657475726E4E6F6465203D20696D706F72744E6F64652E63616C6C286F726967696E616C44';
wwv_flow_api.g_varchar2_table(500) := '6F63756D656E742C2072657475726E4E6F64652C2074727565293B0A20202020202020207D0A0A202020202020202072657475726E2072657475726E4E6F64653B0A2020202020207D0A0A2020202020207661722073657269616C697A656448544D4C20';
wwv_flow_api.g_varchar2_table(501) := '3D2057484F4C455F444F43554D454E54203F20626F64792E6F7574657248544D4C203A20626F64792E696E6E657248544D4C3B0A0A2020202020202F2A2053616E6974697A652066696E616C20737472696E672074656D706C6174652D73616665202A2F';
wwv_flow_api.g_varchar2_table(502) := '0A20202020202069662028534146455F464F525F54454D504C4154455329207B0A202020202020202073657269616C697A656448544D4C203D20737472696E675265706C6163652873657269616C697A656448544D4C2C204D555354414348455F455850';
wwv_flow_api.g_varchar2_table(503) := '522424312C20272027293B0A202020202020202073657269616C697A656448544D4C203D20737472696E675265706C6163652873657269616C697A656448544D4C2C204552425F455850522424312C20272027293B0A2020202020207D0A0A2020202020';
wwv_flow_api.g_varchar2_table(504) := '2072657475726E20747275737465645479706573506F6C6963792026262052455455524E5F545255535445445F54595045203F20747275737465645479706573506F6C6963792E63726561746548544D4C2873657269616C697A656448544D4C29203A20';
wwv_flow_api.g_varchar2_table(505) := '73657269616C697A656448544D4C3B0A202020207D3B0A0A202020202F2A2A0A20202020202A205075626C6963206D6574686F6420746F207365742074686520636F6E66696775726174696F6E206F6E63650A20202020202A20736574436F6E6669670A';
wwv_flow_api.g_varchar2_table(506) := '20202020202A0A20202020202A2040706172616D207B4F626A6563747D2063666720636F6E66696775726174696F6E206F626A6563740A20202020202A2F0A20202020444F4D5075726966792E736574436F6E666967203D2066756E6374696F6E202863';
wwv_flow_api.g_varchar2_table(507) := '666729207B0A2020202020205F7061727365436F6E66696728636667293B0A2020202020205345545F434F4E464947203D20747275653B0A202020207D3B0A0A202020202F2A2A0A20202020202A205075626C6963206D6574686F6420746F2072656D6F';
wwv_flow_api.g_varchar2_table(508) := '76652074686520636F6E66696775726174696F6E0A20202020202A20636C656172436F6E6669670A20202020202A0A20202020202A2F0A20202020444F4D5075726966792E636C656172436F6E666967203D2066756E6374696F6E202829207B0A202020';
wwv_flow_api.g_varchar2_table(509) := '202020434F4E464947203D206E756C6C3B0A2020202020205345545F434F4E464947203D2066616C73653B0A202020207D3B0A0A202020202F2A2A0A20202020202A205075626C6963206D6574686F6420746F20636865636B20696620616E2061747472';
wwv_flow_api.g_varchar2_table(510) := '69627574652076616C75652069732076616C69642E0A20202020202A2055736573206C6173742073657420636F6E6669672C20696620616E792E204F74686572776973652C207573657320636F6E6669672064656661756C74732E0A20202020202A2069';
wwv_flow_api.g_varchar2_table(511) := '7356616C69644174747269627574650A20202020202A0A20202020202A2040706172616D20207B737472696E677D2074616720546167206E616D65206F6620636F6E7461696E696E6720656C656D656E742E0A20202020202A2040706172616D20207B73';
wwv_flow_api.g_varchar2_table(512) := '7472696E677D206174747220417474726962757465206E616D652E0A20202020202A2040706172616D20207B737472696E677D2076616C7565204174747269627574652076616C75652E0A20202020202A204072657475726E207B426F6F6C65616E7D20';
wwv_flow_api.g_varchar2_table(513) := '52657475726E732074727565206966206076616C7565602069732076616C69642E204F74686572776973652C2072657475726E732066616C73652E0A20202020202A2F0A20202020444F4D5075726966792E697356616C6964417474726962757465203D';
wwv_flow_api.g_varchar2_table(514) := '2066756E6374696F6E20287461672C20617474722C2076616C756529207B0A2020202020202F2A20496E697469616C697A652073686172656420636F6E6669672076617273206966206E65636573736172792E202A2F0A2020202020206966202821434F';
wwv_flow_api.g_varchar2_table(515) := '4E46494729207B0A20202020202020205F7061727365436F6E666967287B7D293B0A2020202020207D0A0A202020202020766172206C63546167203D20737472696E67546F4C6F7765724361736528746167293B0A202020202020766172206C634E616D';
wwv_flow_api.g_varchar2_table(516) := '65203D20737472696E67546F4C6F776572436173652861747472293B0A20202020202072657475726E205F697356616C6964417474726962757465286C635461672C206C634E616D652C2076616C7565293B0A202020207D3B0A0A202020202F2A2A0A20';
wwv_flow_api.g_varchar2_table(517) := '202020202A20416464486F6F6B0A20202020202A205075626C6963206D6574686F6420746F2061646420444F4D50757269667920686F6F6B730A20202020202A0A20202020202A2040706172616D207B537472696E677D20656E747279506F696E742065';
wwv_flow_api.g_varchar2_table(518) := '6E74727920706F696E7420666F722074686520686F6F6B20746F206164640A20202020202A2040706172616D207B46756E6374696F6E7D20686F6F6B46756E6374696F6E2066756E6374696F6E20746F20657865637574650A20202020202A2F0A202020';
wwv_flow_api.g_varchar2_table(519) := '20444F4D5075726966792E616464486F6F6B203D2066756E6374696F6E2028656E747279506F696E742C20686F6F6B46756E6374696F6E29207B0A20202020202069662028747970656F6620686F6F6B46756E6374696F6E20213D3D202766756E637469';

wwv_flow_api.g_varchar2_table(520) := '6F6E2729207B0A202020202020202072657475726E3B0A2020202020207D0A0A202020202020686F6F6B735B656E747279506F696E745D203D20686F6F6B735B656E747279506F696E745D207C7C205B5D3B0A2020202020206172726179507573682868';
wwv_flow_api.g_varchar2_table(521) := '6F6F6B735B656E747279506F696E745D2C20686F6F6B46756E6374696F6E293B0A202020207D3B0A0A202020202F2A2A0A20202020202A2052656D6F7665486F6F6B0A20202020202A205075626C6963206D6574686F6420746F2072656D6F7665206120';
wwv_flow_api.g_varchar2_table(522) := '444F4D50757269667920686F6F6B206174206120676976656E20656E747279506F696E740A20202020202A2028706F70732069742066726F6D2074686520737461636B206F6620686F6F6B73206966206D6F7265206172652070726573656E74290A2020';
wwv_flow_api.g_varchar2_table(523) := '2020202A0A20202020202A2040706172616D207B537472696E677D20656E747279506F696E7420656E74727920706F696E7420666F722074686520686F6F6B20746F2072656D6F76650A20202020202A2F0A20202020444F4D5075726966792E72656D6F';
wwv_flow_api.g_varchar2_table(524) := '7665486F6F6B203D2066756E6374696F6E2028656E747279506F696E7429207B0A20202020202069662028686F6F6B735B656E747279506F696E745D29207B0A20202020202020206172726179506F7028686F6F6B735B656E747279506F696E745D293B';
wwv_flow_api.g_varchar2_table(525) := '0A2020202020207D0A202020207D3B0A0A202020202F2A2A0A20202020202A2052656D6F7665486F6F6B730A20202020202A205075626C6963206D6574686F6420746F2072656D6F766520616C6C20444F4D50757269667920686F6F6B73206174206120';
wwv_flow_api.g_varchar2_table(526) := '676976656E20656E747279506F696E740A20202020202A0A20202020202A2040706172616D20207B537472696E677D20656E747279506F696E7420656E74727920706F696E7420666F722074686520686F6F6B7320746F2072656D6F76650A2020202020';
wwv_flow_api.g_varchar2_table(527) := '2A2F0A20202020444F4D5075726966792E72656D6F7665486F6F6B73203D2066756E6374696F6E2028656E747279506F696E7429207B0A20202020202069662028686F6F6B735B656E747279506F696E745D29207B0A2020202020202020686F6F6B735B';
wwv_flow_api.g_varchar2_table(528) := '656E747279506F696E745D203D205B5D3B0A2020202020207D0A202020207D3B0A0A202020202F2A2A0A20202020202A2052656D6F7665416C6C486F6F6B730A20202020202A205075626C6963206D6574686F6420746F2072656D6F766520616C6C2044';
wwv_flow_api.g_varchar2_table(529) := '4F4D50757269667920686F6F6B730A20202020202A0A20202020202A2F0A20202020444F4D5075726966792E72656D6F7665416C6C486F6F6B73203D2066756E6374696F6E202829207B0A202020202020686F6F6B73203D207B7D3B0A202020207D3B0A';
wwv_flow_api.g_varchar2_table(530) := '0A2020202072657475726E20444F4D5075726966793B0A20207D0A0A202076617220707572696679203D20637265617465444F4D50757269667928293B0A0A202072657475726E207075726966793B0A0A7D29293B0A2F2F2320736F757263654D617070';
wwv_flow_api.g_varchar2_table(531) := '696E6755524C3D7075726966792E6A732E6D61700A';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(106690234523525314)
,p_plugin_id=>wwv_flow_api.id(14934236679644451)
,p_file_name=>'js/dompurify/2.2.6/purify.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
commit;
end;
/
set verify on feedback on define on
prompt  ...done


