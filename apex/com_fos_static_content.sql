

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
--     PLUGIN: 168413046168897010
--     PLUGIN: 13235263798301758
--     PLUGIN: 37441962356114799
--     PLUGIN: 1846579882179407086
--     PLUGIN: 8354320589762683
--     PLUGIN: 50031193176975232
--     PLUGIN: 34175298479606152
--     PLUGIN: 35822631205839510
--     PLUGIN: 2674568769566617
--     PLUGIN: 14934236679644451
--     PLUGIN: 2600618193722136
--     PLUGIN: 2657630155025963
--     PLUGIN: 284978227819945411
--     PLUGIN: 56714461465893111
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
'                                  when ''TEXT_ESCAPE_JS''      then replace(cSC.shortcut,'''''''',''\'''''')',
'                                  when ''MESSAGE''             then apex_lang.message(cSC.shortcut)',
'                                  when ''MESSAGE_ESCAPE_JS''   then replace(apex_lang.message(cSC.shortcut),'''''''',''\'''''')',
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
'    l_raw_content          p_region.attribute_01%type := p_region.attribute_01;',
'    l_escape_item_values   boolean                    := p_region.attribute_06 = ''Y'';',
'    l_local_refresh        boolean                    := p_region.attribute_07 = ''Y'';',
'    l_expand_shortcuts     boolean                    := instr(p_region.attribute_15, ''expand-shortcuts'') > 0;',
'    l_exec_plsql           boolean                    := instr(p_region.attribute_15, ''execute-plsql-before-refresh'') > 0;',
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
'',
'begin',
'    -- standard debugging intro, but only if necessary',
'    if apex_application.g_debug',
'    then',
'        apex_plugin_util.debug_region',
'          ( p_plugin => p_plugin',
'          , p_region => p_region',
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
'            sys.htp.p( case when l_escape_content then apex_escape.html(l_raw_content) else l_raw_content end );',
'        else',
'            -- output the static region content and make sure all substitution variables are replaced',
'            sys.htp.p( apex_plugin_util.replace_substitutions',
'                         ( p_value  => l_raw_content',
'                         , p_escape => l_escape_item_values',
'                         )',
'                      );',
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
'    l_raw_content          p_region.attribute_01%type := p_region.attribute_01;',
'    l_escape_item_values   boolean                    := p_region.attribute_06 = ''Y'';',
'    l_expand_shortcuts     boolean                    := instr(p_region.attribute_15, ''expand-shortcuts'') > 0;',
'    l_exec_plsql           boolean                    := instr(p_region.attribute_15, ''execute-plsql-before-refresh'') > 0;',
'    l_exec_plsql_code      p_region.attribute_01%type := p_region.attribute_09;',
'    l_skip_substitutions   boolean                    := instr(p_region.attribute_15, ''skip-substitutions'') > 0;',
'    l_items_to_return      p_region.attribute_13%type := p_region.attribute_13;',
'    l_escape_content       boolean                    := p_region.attribute_14 = ''Y'';',
'    l_item_names           apex_t_varchar2;',
'    ',
'    -- resulting content',
'    l_content              clob                       := '''';',
'',
'    l_return               apex_plugin.t_region_ajax_result;',
'begin',
'    -- standard debugging intro, but only if necessary',
'    if apex_application.g_debug',
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
'                 case when l_escape_content then apex_escape.html(l_raw_content) else l_raw_content end',
'             else',
'                 apex_plugin_util.replace_substitutions',
'                   ( p_value  => l_raw_content',
'                   , p_escape => l_escape_item_values',
'                   )',
'         end',
'    ;',
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
,p_standard_attributes=>'INIT_JAVASCRIPT_CODE'
,p_substitute_attributes=>false
,p_subscribe_plugin_settings=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>The <strong>FOS - Static Region</strong> plug-in has been created to honour the "everything refreshable" principle. The plug-in allows you to refresh the static content client-side or server-side. It also supports shortcuts, Lazy Loading, Lazy Ref'
||'reshing, and showing a loading spinner and mask.',
'</p>',
'<p>',
'    Why would I want to refresh static content when it is static content after all? ...the reason is in the situations when you have used substitutions in your content. ',
'</p>'))
,p_version_identifier=>'20.1.1'
,p_about_url=>'https://fos.world'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// Settings for the FOS browser extension',
'@fos-auto-return-to-page',
'@fos-auto-open-files:js/script.js'))
,p_files_version=>148
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
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A20676C6F62616C7320617065782C24202A2F0A0A76617220464F53203D2077696E646F772E464F53207C7C207B7D3B0A464F532E726567696F6E203D20464F532E726567696F6E207C7C207B7D3B0A0A2F2A2A0A202A20496E697469616C697A6174';
wwv_flow_api.g_varchar2_table(2) := '696F6E2066756E6374696F6E20666F72207468652064796E616D696320636F6E74656E7420726567696F6E2E0A202A20546869732066756E6374696F6E206D7573742062652072756E20666F722074686520726567696F6E20746F207375627363726962';
wwv_flow_api.g_varchar2_table(3) := '6520746F207468652072656672657368206576656E740A202A204578706563747320617320706172616D6574657220616E206F626A65637420776974682074686520666F6C6C6F77696E6720617474726962757465733A0A202A0A202A2040706172616D';
wwv_flow_api.g_varchar2_table(4) := '207B6F626A6563747D20206461436F6E746578742020202020202020202020202020202020202020202054686520636F6E74657874204F626A65637420706173736564206279204150455820746F2064796E616D696320616374696F6E730A202A204070';
wwv_flow_api.g_varchar2_table(5) := '6172616D207B6F626A6563747D2020636F6E66696720202020202020202020202020202020202020202020202020436F6E66696775726174696F6E206F626A65637420686F6C64696E6720616C6C20617474726962757465730A202A2040706172616D20';
wwv_flow_api.g_varchar2_table(6) := '7B737472696E677D2020636F6E6669672E726567696F6E496420202020202020202020202020202020546865206D61696E20726567696F6E2049442E2054686520726567696F6E206F6E207768696368202272656672657368222063616E206265207472';
wwv_flow_api.g_varchar2_table(7) := '696767657265640A202A2040706172616D207B737472696E677D2020636F6E6669672E726567696F6E5772617070657249642020202020202020204944206F66207772617070657220656C656D656E742E2054686520636F6E74656E7473206F66207468';
wwv_flow_api.g_varchar2_table(8) := '697320656C656D656E742077696C6C206265207265706C61636564207769746820746865206E657720636F6E74656E740A202A2040706172616D207B737472696E677D20205B636F6E6669672E6974656D73546F5375626D69745D202020202020202020';
wwv_flow_api.g_varchar2_table(9) := '436F6D6D612D7365706172617465642070616765206974656D206E616D657320696E206A51756572792073656C6563746F7220666F726D61740A202A2040706172616D207B626F6F6C65616E7D205B636F6E6669672E73757070726573734368616E6765';
wwv_flow_api.g_varchar2_table(10) := '4576656E745D2020204966207468657265206172652070616765206974656D7320746F2062652072657475726E65642C20746869732064656369646573207768657468657220746F20747269676765722061206368616E6765206576656E74206F72206E';
wwv_flow_api.g_varchar2_table(11) := '6F740A202A2040706172616D207B626F6F6C65616E7D205B636F6E6669672E73686F775370696E6E65725D202020202020202020202053686F77732061207370696E6E6572206F72206E6F740A202A2040706172616D207B626F6F6C65616E7D205B636F';
wwv_flow_api.g_varchar2_table(12) := '6E6669672E73686F775370696E6E65724F7665726C61795D20202020446570656E6473206F6E2073686F775370696E6E65722E20416464732061207472616E736C7563656E74206F7665726C617920626568696E6420746865207370696E6E65720A202A';
wwv_flow_api.g_varchar2_table(13) := '2040706172616D207B737472696E677D20205B636F6E6669672E7370696E6E6572506F736974696F6E5D20202020202020446570656E6473206F6E2073686F775370696E6E65722E2041206A51756572792073656C6563746F7220756E746F2077686963';
wwv_flow_api.g_varchar2_table(14) := '6820746865207370696E6E65722077696C6C2062652073686F776E0A202A2040706172616D207B737472696E677D2020636F6E6669672E726177436F6E74656E7420202020202020202020202020205468652072617720636F6E74656E7420737472696E';
wwv_flow_api.g_varchar2_table(15) := '670A202A2040706172616D207B626F6F6C65616E7D20636F6E6669672E6573636170652020202020202020202020202020202020205768657468657220746F20657363617065207468652076616C756573206F66207265666572656E636564206974656D';
wwv_flow_api.g_varchar2_table(16) := '730A202A2040706172616D207B626F6F6C65616E7D20636F6E6669672E6C6F63616C52656672657368202020202020202020202020466574636820746865206E657720636F6E74656E742066726F6D207468652044422C206F72207265706C6163652073';
wwv_flow_api.g_varchar2_table(17) := '7562737469747574696F6E73206C6F63616C6C793F0A202A2F0A464F532E726567696F6E2E737461746963436F6E74656E74203D2066756E6374696F6E20286461436F6E746578742C20636F6E6669672C20696E6974466E29207B0A2020202076617220';
wwv_flow_api.g_varchar2_table(18) := '636F6E74657874203D206461436F6E74657874207C7C20746869732C0A2020202020202020656C243B0A0A2020202076617220706C7567696E4E616D65203D2027464F53202D2053746174696320436F6E74656E74273B0A20202020617065782E646562';
wwv_flow_api.g_varchar2_table(19) := '75672E696E666F28706C7567696E4E616D652C20636F6E6669672C20696E6974466E293B0A0A202020202F2F20416C6C6F772074686520646576656C6F70657220746F20706572666F726D20616E79206C617374202863656E7472616C697A6564292063';
wwv_flow_api.g_varchar2_table(20) := '68616E676573207573696E67204A61766173637269707420496E697469616C697A6174696F6E20436F64652073657474696E670A2020202069662028696E6974466E20696E7374616E63656F662046756E6374696F6E29207B0A2020202020202020696E';
wwv_flow_api.g_varchar2_table(21) := '6974466E2E63616C6C28636F6E746578742C20636F6E666967293B0A202020207D0A0A20202020656C24203D20636F6E6669672E656C24203D202428272327202B20636F6E6669672E726567696F6E4964293B0A0A202020202F2F20696D706C656D656E';
wwv_flow_api.g_varchar2_table(22) := '74696E672074686520617065782E726567696F6E20696E7465726661636520696E206F7264657220746F20726573706F6E6420746F2072656672657368206576656E74730A20202020617065782E726567696F6E2E63726561746528636F6E6669672E72';
wwv_flow_api.g_varchar2_table(23) := '6567696F6E49642C207B0A2020202020202020747970653A2027666F732D726567696F6E2D7374617469632D636F6E74656E74272C0A2020202020202020726566726573683A2066756E6374696F6E202829207B0A202020202020202020202020696620';
wwv_flow_api.g_varchar2_table(24) := '28636F6E6669672E697356697369626C65207C7C2021636F6E6669672E6C617A795265667265736829207B0A20202020202020202020202020202020464F532E726567696F6E2E737461746963436F6E74656E742E726566726573682E63616C6C28636F';
wwv_flow_api.g_varchar2_table(25) := '6E746578742C20636F6E666967293B0A2020202020202020202020207D20656C7365207B0A20202020202020202020202020202020636F6E6669672E6E6565647352656672657368203D20747275653B0A2020202020202020202020207D0A2020202020';
wwv_flow_api.g_varchar2_table(26) := '2020207D2C0A20202020202020206F7074696F6E3A2066756E6374696F6E20286E616D652C2076616C756529207B0A2020202020202020202020207661722077686974654C6973744F7074696F6E73203D205B2773686F775370696E6E6572275D3B0A20';
wwv_flow_api.g_varchar2_table(27) := '202020202020202020202076617220617267436F756E74203D20617267756D656E74732E6C656E6774683B0A20202020202020202020202069662028617267436F756E74203D3D3D203129207B0A2020202020202020202020202020202072657475726E';
wwv_flow_api.g_varchar2_table(28) := '20636F6E6669675B6E616D655D3B0A2020202020202020202020207D20656C73652069662028617267436F756E74203E203129207B0A20202020202020202020202020202020696620286E616D652026262076616C75652026262077686974654C697374';
wwv_flow_api.g_varchar2_table(29) := '4F7074696F6E732E696E636C75646573286E616D652929207B0A2020202020202020202020202020202020202020636F6E6669675B6E616D655D203D2076616C75653B0A202020202020202020202020202020207D20656C736520696620286E616D6520';
wwv_flow_api.g_varchar2_table(30) := '2626202177686974654C6973744F7074696F6E732E696E636C75646573286E616D652929207B0A2020202020202020202020202020202020202020617065782E64656275672E7761726E2827796F752061726520747279696E6720746F2073657420616E';
wwv_flow_api.g_varchar2_table(31) := '206F7074696F6E2074686174206973206E6F7420616C6C6F7765643A2027202B206E616D65293B0A202020202020202020202020202020207D0A2020202020202020202020207D0A20202020202020207D0A202020207D293B0A0A202020202F2F206966';
wwv_flow_api.g_varchar2_table(32) := '2077652072656672657368206C6F63616C6C79207468656E207765206E65656420746F2073756273746974757465207468656D206F6E20706167652072656E6465720A2020202069662028636F6E6669672E6C6F63616C5265667265736829207B0A2020';
wwv_flow_api.g_varchar2_table(33) := '202020202020617065782E726567696F6E28636F6E6669672E726567696F6E4964292E7265667265736828293B0A202020207D0A202020202F2F20636865636B206966207765206E65656420746F206C617A79206C6F61642074686520726567696F6E0A';
wwv_flow_api.g_varchar2_table(34) := '20202020656C73652069662028636F6E6669672E6C617A794C6F616429207B0A2020202020202020617065782E7769646765742E7574696C2E6F6E5669736962696C6974794368616E676528656C245B305D2C2066756E6374696F6E2028697356697369';
wwv_flow_api.g_varchar2_table(35) := '626C6529207B0A202020202020202020202020636F6E6669672E697356697369626C65203D20697356697369626C653B0A20202020202020202020202069662028697356697369626C65202626202821636F6E6669672E6C6F61646564207C7C20636F6E';
wwv_flow_api.g_varchar2_table(36) := '6669672E6E65656473526566726573682929207B0A20202020202020202020202020202020617065782E726567696F6E28636F6E6669672E726567696F6E4964292E7265667265736828293B0A20202020202020202020202020202020636F6E6669672E';
wwv_flow_api.g_varchar2_table(37) := '6C6F61646564203D20747275653B0A20202020202020202020202020202020636F6E6669672E6E6565647352656672657368203D2066616C73653B0A2020202020202020202020207D0A20202020202020207D293B0A2020202020202020617065782E6A';
wwv_flow_api.g_varchar2_table(38) := '51756572792877696E646F77292E6F6E2827617065787265616479656E64272C2066756E6374696F6E202829207B0A2020202020202020202020202F2F2077652061646420617661726961626C65207265666572656E636520746F2061766F6964206C6F';
wwv_flow_api.g_varchar2_table(39) := '7373206F662073636F70650A20202020202020202020202076617220656C203D20656C245B305D3B0A2020202020202020202020202F2F207765206861766520746F20616464206120736C696768742064656C617920746F206D616B6520737572652061';
wwv_flow_api.g_varchar2_table(40) := '7065782077696467657473206861766520696E697469616C697A65642073696E6365202873757270726973696E676C79292022617065787265616479656E6422206973206E6F7420656E6F7567680A20202020202020202020202073657454696D656F75';
wwv_flow_api.g_varchar2_table(41) := '742866756E6374696F6E202829207B0A20202020202020202020202020202020617065782E7769646765742E7574696C2E7669736962696C6974794368616E676528656C2C2074727565293B0A2020202020202020202020207D2C20636F6E6669672E76';
wwv_flow_api.g_varchar2_table(42) := '69736962696C697479436865636B44656C6179207C7C2031303030293B0A20202020202020207D293B0A202020207D0A7D3B0A0A464F532E726567696F6E2E737461746963436F6E74656E742E72656672657368203D2066756E6374696F6E2028636F6E';
wwv_flow_api.g_varchar2_table(43) := '66696729207B0A2020202076617220656C656D24203D202428272327202B20636F6E6669672E726567696F6E577261707065724964293B0A2020202076617220726177436F6E74656E74203D20636F6E6669672E726177436F6E74656E743B0A20202020';
wwv_flow_api.g_varchar2_table(44) := '76617220657363617065203D20636F6E6669672E6573636170653B0A20202020766172206C6F6164696E67496E64696361746F72466E3B0A0A202020202F2F636F6E66696775726573207468652073686F77696E6720616E6420686964696E67206F6620';
wwv_flow_api.g_varchar2_table(45) := '6120706F737369626C65207370696E6E65720A2020202069662028636F6E6669672E73686F775370696E6E657229207B0A20202020202020206C6F6164696E67496E64696361746F72466E203D202866756E6374696F6E2028706F736974696F6E2C2073';
wwv_flow_api.g_varchar2_table(46) := '686F774F7665726C617929207B0A2020202020202020202020207661722066697865644F6E426F6479203D20706F736974696F6E203D3D2027626F6479273B0A20202020202020202020202072657475726E2066756E6374696F6E2028704C6F6164696E';
wwv_flow_api.g_varchar2_table(47) := '67496E64696361746F7229207B0A20202020202020202020202020202020766172206F7665726C6179243B0A20202020202020202020202020202020766172207370696E6E657224203D20617065782E7574696C2E73686F775370696E6E657228706F73';
wwv_flow_api.g_varchar2_table(48) := '6974696F6E2C207B2066697865643A2066697865644F6E426F6479207D293B0A202020202020202020202020202020206966202873686F774F7665726C617929207B0A20202020202020202020202020202020202020206F7665726C617924203D202428';
wwv_flow_api.g_varchar2_table(49) := '273C64697620636C6173733D22666F732D726567696F6E2D6F7665726C617927202B202866697865644F6E426F6479203F20272D666978656427203A20272729202B2027223E3C2F6469763E27292E70726570656E64546F28706F736974696F6E293B0A';
wwv_flow_api.g_varchar2_table(50) := '202020202020202020202020202020207D0A2020202020202020202020202020202066756E6374696F6E2072656D6F76655370696E6E65722829207B0A2020202020202020202020202020202020202020696620286F7665726C61792429207B0A202020';
wwv_flow_api.g_varchar2_table(51) := '2020202020202020202020202020202020202020206F7665726C6179242E72656D6F766528293B0A20202020202020202020202020202020202020207D0A20202020202020202020202020202020202020207370696E6E6572242E72656D6F766528293B';
wwv_flow_api.g_varchar2_table(52) := '0A202020202020202020202020202020207D0A202020202020202020202020202020202F2F746869732066756E6374696F6E206D7573742072657475726E20612066756E6374696F6E2077686963682068616E646C6573207468652072656D6F76696E67';
wwv_flow_api.g_varchar2_table(53) := '206F6620746865207370696E6E65720A2020202020202020202020202020202072657475726E2072656D6F76655370696E6E65723B0A2020202020202020202020207D3B0A20202020202020207D2928636F6E6669672E7370696E6E6572506F73697469';
wwv_flow_api.g_varchar2_table(54) := '6F6E2C20636F6E6669672E73686F775370696E6E65724F7665726C6179293B0A202020207D0A202020202F2F2074726967676572206F7572206265666F72652072656672657368206576656E742873290A20202020766172206576656E7443616E63656C';
wwv_flow_api.g_varchar2_table(55) := '6C6564203D20617065782E6576656E742E747269676765722827617065786265666F726572656672657368272C20272327202B20636F6E6669672E726567696F6E49642C20636F6E666967293B0A20202020696620286576656E7443616E63656C6C6564';
wwv_flow_api.g_varchar2_table(56) := '29207B0A2020202020202020617065782E64656275672E7761726E2827746865207265667265736820616374696F6E20686173206265656E2063616E63656C6C6564206279207468652022617065786265666F72657265667265736822206576656E7421';
wwv_flow_api.g_varchar2_table(57) := '27293B0A202020202020202072657475726E2066616C73653B0A202020207D0A202020202F2F2077652063616E20656974686572207265706C6163652074686520737562737469747574696F6E20737472696E6773206C6F63616C6C792028627574206F';
wwv_flow_api.g_varchar2_table(58) := '6E6C792077697468206974656D73206F6E20746869732070616765206F722074686520676C6F62616C2070616765290A202020202F2F206F7220666574636820746865207570646174656420636F6E74656E742066726F6D207468652064617461626173';
wwv_flow_api.g_varchar2_table(59) := '650A2020202069662028636F6E6669672E6C6F63616C5265667265736829207B0A2020202020202020656C656D242E68746D6C28617065782E7574696C2E6170706C7954656D706C61746528726177436F6E74656E742C207B0A20202020202020202020';
wwv_flow_api.g_varchar2_table(60) := '202064656661756C7445736361706546696C7465723A20657363617065203F202748544D4C27203A2027524157270A20202020202020207D29293B0A20202020202020202F2F2074726967676572206F7572206166746572207265667265736820657665';
wwv_flow_api.g_varchar2_table(61) := '6E742873290A2020202020202020617065782E6576656E742E74726967676572282761706578616674657272656672657368272C20272327202B20636F6E6669672E726567696F6E49642C20636F6E666967293B0A202020207D20656C7365207B0A2020';
wwv_flow_api.g_varchar2_table(62) := '202020202020617065782E7365727665722E706C7567696E28636F6E6669672E616A61784964656E7469666965722C207B0A202020202020202020202020706167654974656D733A20636F6E6669672E6974656D73546F5375626D69740A202020202020';
wwv_flow_api.g_varchar2_table(63) := '20207D2C207B0A2020202020202020202020202F2F6E656564656420746F2074726967676572206265666F726520616E642061667465722072656672657368206576656E7473206F6E2074686520726567696F6E0A202020202020202020202020726566';
wwv_flow_api.g_varchar2_table(64) := '726573684F626A6563743A20272327202B20636F6E6669672E726567696F6E49642C0A2020202020202020202020202F2F746869732066756E6374696F6E206973207265706F6E7369626C6520666F722073686F77696E672061207370696E6E65720A20';
wwv_flow_api.g_varchar2_table(65) := '20202020202020202020206C6F6164696E67496E64696361746F723A206C6F6164696E67496E64696361746F72466E2C0A202020202020202020202020737563636573733A2066756E6374696F6E20286461746129207B0A202020202020202020202020';
wwv_flow_api.g_varchar2_table(66) := '202020202F2F73657474696E672070616765206974656D2076616C7565730A2020202020202020202020202020202069662028646174612E6974656D7329207B0A2020202020202020202020202020202020202020666F7220287661722069203D20303B';
wwv_flow_api.g_varchar2_table(67) := '2069203C20646174612E6974656D732E6C656E6774683B20692B2B29207B0A202020202020202020202020202020202020202020202020617065782E6974656D28646174612E6974656D735B695D2E6964292E73657456616C756528646174612E697465';
wwv_flow_api.g_varchar2_table(68) := '6D735B695D2E76616C75652C206E756C6C2C20636F6E6669672E73757070726573734368616E67654576656E74293B0A20202020202020202020202020202020202020207D0A202020202020202020202020202020207D0A202020202020202020202020';
wwv_flow_api.g_varchar2_table(69) := '202020202F2F7265706C6163696E6720746865206F6C6420636F6E74656E74207769746820746865206E65770A202020202020202020202020202020202428272327202B20636F6E6669672E726567696F6E577261707065724964292E68746D6C286461';
wwv_flow_api.g_varchar2_table(70) := '74612E636F6E74656E74293B0A202020202020202020202020202020202F2F2074726967676572206F75722061667465722072656672657368206576656E742873290A20202020202020202020202020202020617065782E6576656E742E747269676765';
wwv_flow_api.g_varchar2_table(71) := '72282761706578616674657272656672657368272C20272327202B20636F6E6669672E726567696F6E49642C20636F6E666967293B0A2020202020202020202020207D2C0A2020202020202020202020202F2F6F6D697474696E6720616E206572726F72';
wwv_flow_api.g_varchar2_table(72) := '2068616E646C6572206C65747320617065782E73657276657220757365207468652064656661756C74206F6E650A20202020202020202020202064617461547970653A20276A736F6E270A20202020202020207D293B0A202020207D0A7D3B';
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
wwv_flow_api.g_varchar2_table(4) := '6E73222C22617267436F756E74222C22617267756D656E7473222C226C656E677468222C22696E636C75646573222C227761726E222C226C6F63616C52656672657368222C226C617A794C6F6164222C22776964676574222C227574696C222C226F6E56';
wwv_flow_api.g_varchar2_table(5) := '69736962696C6974794368616E6765222C226C6F61646564222C226A5175657279222C226F6E222C22656C222C2273657454696D656F7574222C227669736962696C6974794368616E6765222C227669736962696C697479436865636B44656C6179222C';
wwv_flow_api.g_varchar2_table(6) := '226C6F6164696E67496E64696361746F72466E222C22706F736974696F6E222C2273686F774F7665726C6179222C2266697865644F6E426F6479222C22656C656D24222C22726567696F6E577261707065724964222C22726177436F6E74656E74222C22';
wwv_flow_api.g_varchar2_table(7) := '657363617065222C2273686F775370696E6E6572222C227370696E6E6572506F736974696F6E222C2273686F775370696E6E65724F7665726C6179222C22704C6F6164696E67496E64696361746F72222C226F7665726C617924222C227370696E6E6572';
wwv_flow_api.g_varchar2_table(8) := '24222C226669786564222C2270726570656E64546F222C2272656D6F7665222C226576656E74222C2274726967676572222C2268746D6C222C226170706C7954656D706C617465222C2264656661756C7445736361706546696C746572222C2273657276';
wwv_flow_api.g_varchar2_table(9) := '6572222C22706C7567696E222C22616A61784964656E746966696572222C22706167654974656D73222C226974656D73546F5375626D6974222C22726566726573684F626A656374222C226C6F6164696E67496E64696361746F72222C22737563636573';
wwv_flow_api.g_varchar2_table(10) := '73222C2264617461222C226974656D73222C2269222C226974656D222C226964222C2273657456616C7565222C2273757070726573734368616E67654576656E74222C22636F6E74656E74222C226461746154797065225D2C226D617070696E6773223A';
wwv_flow_api.g_varchar2_table(11) := '22414145412C49414149412C4941414D432C4F41414F442C4B41414F2C4741437842412C49414149452C4F414153462C49414149452C514141552C47416F423342462C49414149452C4F41414F432C63414167422C53414155432C45414157432C454141';
wwv_flow_api.g_varchar2_table(12) := '51432C47414370442C49414349432C45414441432C454141554A2C474141614B2C4B41493342432C4B41414B432C4D41414D432C4B41444D2C7542414357502C45414151432C4741476843412C6141416B424F2C5541436C42502C4541414F512C4B4141';
wwv_flow_api.g_varchar2_table(13) := '4B4E2C45414153482C4741477A42452C4541414D462C4541414F452C4941414D512C454141452C4941414D562C4541414F572C5541476C434E2C4B41414B522C4F41414F652C4F41414F5A2C4541414F572C534141552C4341436843452C4B41414D2C34';
wwv_flow_api.g_varchar2_table(14) := '4241434E432C514141532C57414344642C4541414F652C59414163662C4541414F67422C594143354272422C49414149452C4F41414F432C6341416367422C514141514C2C4B41414B4E2C45414153482C4741452F43412C4541414F69422C634141652C';
wwv_flow_api.g_varchar2_table(15) := '4741473942432C4F4141512C53414155432C4541414D432C47414370422C49414149432C4541416D422C434141432C6541437042432C45414157432C55414155432C4F41437A422C47414169422C49414162462C454143412C4F41414F74422C4541414F';
wwv_flow_api.g_varchar2_table(16) := '6D422C47414350472C454141572C49414364482C47414151432C47414153432C4541416942492C534141534E2C47414333436E422C4541414F6D422C47414151432C45414352442C49414153452C4541416942492C534141534E2C4941433143642C4B41';
wwv_flow_api.g_varchar2_table(17) := '414B432C4D41414D6F422C4B41414B2C774441413044502C4F414F74466E422C4541414F32422C6141435074422C4B41414B522C4F41414F472C4541414F572C55414155472C5541477842642C4541414F34422C5741435A76422C4B41414B77422C4F41';
wwv_flow_api.g_varchar2_table(18) := '414F432C4B41414B432C6D4241416D4237422C454141492C494141492C53414155612C4741436C44662C4541414F652C55414159412C47414366412C47414165662C4541414F67432C5341415568432C4541414F69422C65414376435A2C4B41414B522C';
wwv_flow_api.g_varchar2_table(19) := '4F41414F472C4541414F572C55414155472C5541433742642C4541414F67432C514141532C454143684268432C4541414F69422C634141652C4D414739425A2C4B41414B34422C4F41414F72432C5141415173432C474141472C6742414167422C574145';
wwv_flow_api.g_varchar2_table(20) := '6E432C49414149432C4541414B6A432C454141492C474145626B432C594141572C574143502F422C4B41414B77422C4F41414F432C4B41414B4F2C694241416942462C474141492C4B414376436E432C4541414F73432C7342414177422C55414B394333';
wwv_flow_api.g_varchar2_table(21) := '432C49414149452C4F41414F432C6341416367422C514141552C53414155642C4741437A432C4941474975432C4541496743432C45414155432C4541436C43432C45415252432C454141516A432C454141452C4941414D562C4541414F34432C69424143';
wwv_flow_api.g_varchar2_table(22) := '7642432C4541416137432C4541414F36432C5741437042432C4541415339432C4541414F38432C4F41304270422C474174424939432C4541414F2B432C6341437942502C45416942374278432C4541414F67442C6742416A426743502C45416942667A43';
wwv_flow_api.g_varchar2_table(23) := '2C4541414F69442C6D424168423142502C45414130422C5141415A462C4541447442442C454145572C53414155572C474143622C49414149432C45414341432C454141572F432C4B41414B79422C4B41414B69422C59414159502C454141552C43414145';
wwv_flow_api.g_varchar2_table(24) := '612C4D41414F582C49415778442C4F415649442C49414341552C454141577A432C454141452C6B4341416F4367432C454141632C534141572C4941414D2C59414159592C55414155642C49414531472C57414351572C47414341412C45414153492C5341';
wwv_flow_api.g_varchar2_table(25) := '4562482C45414153472C5941514A6C442C4B41414B6D442C4D41414D432C514141512C6F42414171422C4941414D7A442C4541414F572C53414155582C47414768462C4F4144414B2C4B41414B432C4D41414D6F422C4B41414B2C34454143542C454149';
wwv_flow_api.g_varchar2_table(26) := '5031422C4541414F32422C6341435067422C4541414D652C4B41414B72442C4B41414B79422C4B41414B36422C63414163642C454141592C4341433343652C6F4241417142642C454141532C4F4141532C53414733437A432C4B41414B6D442C4D41414D';
wwv_flow_api.g_varchar2_table(27) := '432C514141512C6D4241416F422C4941414D7A442C4541414F572C53414155582C49414539444B2C4B41414B77442C4F41414F432C4F41414F39442C4541414F2B442C65414167422C4341437443432C5541415768452C4541414F69452C6541436E422C';
wwv_flow_api.g_varchar2_table(28) := '43414543432C634141652C4941414D6C452C4541414F572C534145354277442C694241416B4235422C4541436C4236422C514141532C53414155432C474145662C47414149412C4541414B432C4D41434C2C4941414B2C49414149432C454141492C4541';
wwv_flow_api.g_varchar2_table(29) := '4147412C45414149462C4541414B432C4D41414D39432C4F4141512B432C4941436E436C452C4B41414B6D452C4B41414B482C4541414B432C4D41414D432C47414147452C49414149432C534141534C2C4541414B432C4D41414D432C474141476E442C';
wwv_flow_api.g_varchar2_table(30) := '4D41414F2C4B41414D70422C4541414F32452C714241492F456A452C454141452C4941414D562C4541414F34432C694241416942632C4B41414B572C4541414B4F2C534145314376452C4B41414B6D442C4D41414D432C514141512C6D4241416F422C49';
wwv_flow_api.g_varchar2_table(31) := '41414D7A442C4541414F572C53414155582C4941476C4536452C53414155222C2266696C65223A227363726970742E6A73227D';
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
wwv_flow_api.g_varchar2_table(1) := '76617220464F533D77696E646F772E464F537C7C7B7D3B464F532E726567696F6E3D464F532E726567696F6E7C7C7B7D2C464F532E726567696F6E2E737461746963436F6E74656E743D66756E6374696F6E28652C6E2C69297B76617220722C743D657C';
wwv_flow_api.g_varchar2_table(2) := '7C746869733B617065782E64656275672E696E666F2822464F53202D2053746174696320436F6E74656E74222C6E2C69292C6920696E7374616E63656F662046756E6374696F6E2626692E63616C6C28742C6E292C723D6E2E656C243D24282223222B6E';
wwv_flow_api.g_varchar2_table(3) := '2E726567696F6E4964292C617065782E726567696F6E2E637265617465286E2E726567696F6E49642C7B747970653A22666F732D726567696F6E2D7374617469632D636F6E74656E74222C726566726573683A66756E6374696F6E28297B6E2E69735669';
wwv_flow_api.g_varchar2_table(4) := '7369626C657C7C216E2E6C617A79526566726573683F464F532E726567696F6E2E737461746963436F6E74656E742E726566726573682E63616C6C28742C6E293A6E2E6E65656473526566726573683D21307D2C6F7074696F6E3A66756E6374696F6E28';
wwv_flow_api.g_varchar2_table(5) := '652C69297B76617220723D5B2273686F775370696E6E6572225D2C743D617267756D656E74732E6C656E6774683B696628313D3D3D742972657475726E206E5B655D3B743E31262628652626692626722E696E636C756465732865293F6E5B655D3D693A';
wwv_flow_api.g_varchar2_table(6) := '65262621722E696E636C756465732865292626617065782E64656275672E7761726E2822796F752061726520747279696E6720746F2073657420616E206F7074696F6E2074686174206973206E6F7420616C6C6F7765643A20222B6529297D7D292C6E2E';
wwv_flow_api.g_varchar2_table(7) := '6C6F63616C526566726573683F617065782E726567696F6E286E2E726567696F6E4964292E7265667265736828293A6E2E6C617A794C6F6164262628617065782E7769646765742E7574696C2E6F6E5669736962696C6974794368616E676528725B305D';
wwv_flow_api.g_varchar2_table(8) := '2C2866756E6374696F6E2865297B6E2E697356697369626C653D652C21657C7C6E2E6C6F616465642626216E2E6E65656473526566726573687C7C28617065782E726567696F6E286E2E726567696F6E4964292E7265667265736828292C6E2E6C6F6164';
wwv_flow_api.g_varchar2_table(9) := '65643D21302C6E2E6E65656473526566726573683D2131297D29292C617065782E6A51756572792877696E646F77292E6F6E2822617065787265616479656E64222C2866756E6374696F6E28297B76617220653D725B305D3B73657454696D656F757428';
wwv_flow_api.g_varchar2_table(10) := '2866756E6374696F6E28297B617065782E7769646765742E7574696C2E7669736962696C6974794368616E676528652C2130297D292C6E2E7669736962696C697479436865636B44656C61797C7C316533297D2929297D2C464F532E726567696F6E2E73';

wwv_flow_api.g_varchar2_table(11) := '7461746963436F6E74656E742E726566726573683D66756E6374696F6E2865297B766172206E2C692C722C742C613D24282223222B652E726567696F6E577261707065724964292C6F3D652E726177436F6E74656E742C733D652E6573636170653B6966';
wwv_flow_api.g_varchar2_table(12) := '28652E73686F775370696E6E6572262628693D652E7370696E6E6572506F736974696F6E2C723D652E73686F775370696E6E65724F7665726C61792C743D22626F6479223D3D692C6E3D66756E6374696F6E2865297B766172206E2C613D617065782E75';
wwv_flow_api.g_varchar2_table(13) := '74696C2E73686F775370696E6E657228692C7B66697865643A747D293B72657475726E20722626286E3D2428273C64697620636C6173733D22666F732D726567696F6E2D6F7665726C6179272B28743F222D6669786564223A2222292B27223E3C2F6469';
wwv_flow_api.g_varchar2_table(14) := '763E27292E70726570656E64546F286929292C66756E6374696F6E28297B6E26266E2E72656D6F766528292C612E72656D6F766528297D7D292C617065782E6576656E742E747269676765722822617065786265666F726572656672657368222C222322';
wwv_flow_api.g_varchar2_table(15) := '2B652E726567696F6E49642C65292972657475726E20617065782E64656275672E7761726E2827746865207265667265736820616374696F6E20686173206265656E2063616E63656C6C6564206279207468652022617065786265666F72657265667265';
wwv_flow_api.g_varchar2_table(16) := '736822206576656E742127292C21313B652E6C6F63616C526566726573683F28612E68746D6C28617065782E7574696C2E6170706C7954656D706C617465286F2C7B64656661756C7445736361706546696C7465723A733F2248544D4C223A2252415722';
wwv_flow_api.g_varchar2_table(17) := '7D29292C617065782E6576656E742E74726967676572282261706578616674657272656672657368222C2223222B652E726567696F6E49642C6529293A617065782E7365727665722E706C7567696E28652E616A61784964656E7469666965722C7B7061';
wwv_flow_api.g_varchar2_table(18) := '67654974656D733A652E6974656D73546F5375626D69747D2C7B726566726573684F626A6563743A2223222B652E726567696F6E49642C6C6F6164696E67496E64696361746F723A6E2C737563636573733A66756E6374696F6E286E297B6966286E2E69';
wwv_flow_api.g_varchar2_table(19) := '74656D7329666F722876617220693D303B693C6E2E6974656D732E6C656E6774683B692B2B29617065782E6974656D286E2E6974656D735B695D2E6964292E73657456616C7565286E2E6974656D735B695D2E76616C75652C6E756C6C2C652E73757070';
wwv_flow_api.g_varchar2_table(20) := '726573734368616E67654576656E74293B24282223222B652E726567696F6E577261707065724964292E68746D6C286E2E636F6E74656E74292C617065782E6576656E742E74726967676572282261706578616674657272656672657368222C2223222B';
wwv_flow_api.g_varchar2_table(21) := '652E726567696F6E49642C65297D2C64617461547970653A226A736F6E227D297D3B0A2F2F2320736F757263654D617070696E6755524C3D7363726970742E6A732E6D6170';
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
prompt --application/end_environment
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
commit;
end;
/
set verify on feedback on define on
prompt  ...done




