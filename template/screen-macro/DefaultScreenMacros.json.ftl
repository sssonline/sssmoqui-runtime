<#-- Copyright 2014-2017 Spokane Software Systems, Inc. All Rights Reserved. -->

<#macro jsonValue textValue>
    <#-- sssonline: ?json_string escapes backslash before quote (and control characters); the old replace chain escaped
         the quote first and then doubled its backslash, so any value with a " in it (block S. Neumann "a") broke the
         XLSX and JSON exports of its page -->
    <#t><#if textValue??><#if fieldPrinted!false>,</#if><#assign fieldPrinted = true><#assign cellsEmitted = (cellsEmitted!0) + 1>"${textValue?json_string}"</#if>
</#macro>

<#-- ================ Export objects ================
     sssonline: the XLSX (/poi) and JSON exports wrap this output in [ ] and parse it with JsonSlurperClassic, which
     accepts a trailing comma, so every object ends with "},". Each grid (form-list) is one object, {"title":...,
     "columns":...,"colTypes":...,"data":...}, and one sheet. A box opens {"title":"<box title>", and closes it; a second
     grid in the same box closes the first object and opens another with the same title (makeWorkbook numbers repeated
     sheet names); a grid outside any box gets its own object titled with its screen's name. A box with no grid comes
     out as {"title":"...",}, which the exports skip.
     A section, section-iterate, section-include or subscreen renders in its own FreeMarker environment
     (ScreenWidgetRenderFtl) straight to the screen writer, so nothing here may capture output into a variable (that
     was the AP Open Invoices 500 on Saticoy, 11/11) and the box state lives in the context stack's shared map, which
     every one of those environments sees. It is keyed to this render (sri) so a stale state from an earlier render in
     the same execution context (a scheduled send) is never read. -->
<#function jsonExportState>
    <#local shared = ec.getContext().getSharedMap()>
    <#local renderId = sri.hashCode()?c>
    <#if (shared.get("_jsonExportRender")!"") != renderId>
        <#local ignored = shared.put("_jsonExportRender", renderId)!>
        <#local ignored = shared.put("_jsonBoxDepth", 0)!>
        <#local ignored = shared.put("_jsonBoxTitle", "")!>
        <#local ignored = shared.put("_jsonBoxGrids", 0)!>
    </#if>
    <#return shared>
</#function>

<#macro @element><#-- do nothing for unknown elements --></#macro>
<#macro screen><#recurse></#macro>
<#macro widgets>
    <#if !singleFormTitle?has_content><#assign singleFormTitle = ""></#if>
    <#recurse>
</#macro>
<#macro "fail-widgets"><#recurse></#macro>

<#-- ================ Subscreens ================ -->
<#macro "subscreens-menu"></#macro>
<#macro "subscreens-active">${sri.renderSubscreen()}</#macro>
<#macro "subscreens-panel">${sri.renderSubscreen()}</#macro>

<#-- ================ Section ================ -->
<#macro section>${sri.renderSection(.node["@name"])}</#macro>
<#macro "section-iterate">${sri.renderSection(.node["@name"])}</#macro>
<#-- sssonline (Simple Report #1301/#1340): a section-include renders its section, as in the csv macros; without this the
     XLSX (/poi) and JSON exports of a screen that shows its grid through a section-include (System > Custom Reports) are empty -->
<#macro "section-include">${sri.renderSectionInclude(.node)}</#macro>

<#-- ================ Containers ================ -->
<#macro container><#recurse></#macro>
<#macro "container-box">
    <#assign boxHeader = .node["box-header"][0]!>
    <#assign boxTitle = ec.getResource().expand(boxHeader["@title"]!"", "")>
    <#if !singleFormTitle?has_content || singleFormTitle == boxTitle>
        <#-- written straight to the output, never captured (see Export objects above). A box inside a box closes the
             outer box's object, and reopens it after, so its grids are never inside another object -->
        <#local state = jsonExportState()>
        <#local outerDepth = state.get("_jsonBoxDepth")!0>
        <#local outerTitle = state.get("_jsonBoxTitle")!"">
        <#t><#if (outerDepth > 0)>},</#if>{"title":"${boxTitle?json_string}",
        <#local ignored = state.put("_jsonBoxDepth", outerDepth + 1)!>
        <#local ignored = state.put("_jsonBoxTitle", boxTitle)!>
        <#local ignored = state.put("_jsonBoxGrids", 0)!>
        <#t><#if .node["box-body"]?has_content><#recurse .node["box-body"][0]></#if>
        <#t><#if .node["box-body-nopad"]?has_content><#recurse .node["box-body-nopad"][0]></#if>
        <#t>},<#if (outerDepth > 0)>{"title":"${outerTitle?json_string}",</#if>
        <#local ignored = state.put("_jsonBoxDepth", outerDepth)!>
        <#local ignored = state.put("_jsonBoxTitle", outerTitle)!>
        <#local ignored = state.put("_jsonBoxGrids", 0)!>
    </#if>
</#macro>
<#macro "container-panel">
    <#t><#if .node["panel-header"]?has_content><#recurse .node["panel-header"][0]></#if>
    <#t><#if .node["panel-left"]?has_content><#recurse .node["panel-left"][0]></#if>
    <#t><#recurse .node["panel-center"][0]>
    <#t><#if .node["panel-right"]?has_content><#recurse .node["panel-right"][0]></#if>
    <#t><#if .node["panel-footer"]?has_content><#recurse .node["panel-footer"][0]></#if>
</#macro>
<#-- sssonline: a dialog is a popup, not part of the page, so it exports nothing; a grid in a per-row dialog (charge
     history on Grower Charges) made one sheet per row, and a dialog grid next to the box's own grid broke the export -->
<#macro "container-dialog"></#macro>

<#-- ==================== Includes ==================== -->
<#macro "include-screen">${sri.renderIncludeScreen(.node["@location"], .node["@share-scope"]!)}</#macro>

<#-- ============== Tree ============== -->
<#-- TABLED, not to be part of 1.0:
<#macro tree>
</#macro>
<#macro "tree-node">
</#macro>
<#macro "tree-sub-node">
</#macro>
-->

<#-- ============== Render Mode Elements ============== -->
<#macro "render-mode">
<#t><#if .node["text"]?has_content>
    <#list .node["text"] as textNode><#if !textNode["@type"]?has_content || textNode["@type"] == "any"><#local textToUse = textNode/></#if></#list>
    <#list .node["text"] as textNode><#if textNode["@type"]?has_content && textNode["@type"]?split(",")?seq_contains(sri.getRenderMode())><#local textToUse = textNode></#if></#list>
    <#t><#if textToUse??>
        <#t><#if textToUse["@location"]?has_content>
            <#-- NOTE: this still won't encode templates that are rendered to the writer -->
            <#t><#if .node["@encode"]! == "true">${sri.renderText(textToUse["@location"], textToUse["@template"]!)?html}<#else>${sri.renderText(textToUse["@location"], textToUse["@template"]!)}</#if>
        </#if>
        <#assign inlineTemplateSource = textToUse?string/>
        <#t><#if inlineTemplateSource?has_content>
            <#t><#if !textToUse["@template"]?has_content || textToUse["@template"] == "true">
                <#assign inlineTemplate = [inlineTemplateSource, sri.getActiveScreenDef().location + ".render_mode.text"]?interpret>
                <#t><@inlineTemplate/>
            <#else>
                <#t>${inlineTemplateSource}
            </#if><#t>
        </#if>
    </#if>
</#if>
</#macro>

<#macro text><#-- do nothing, is used only through "render-mode" --></#macro>

<#-- ================== Standalone Fields ==================== -->
<#macro link><#if .node?parent?node_name?ends_with("-field") && (.node["@link-type"]! == "anchor" || .node["@link-type"]! == "hidden-form-link")>
    <#assign linkNode = .node>
    <#if linkNode["@condition"]?has_content><#assign conditionResult = ec.getResource().condition(linkNode["@condition"], "")><#else><#assign conditionResult = true></#if>
    <#if conditionResult>
        <#if linkNode["@entity-name"]?has_content>
            <#assign linkText = ""><#assign linkText = sri.getFieldEntityValue(linkNode)>
        <#else>
            <#assign textMap = "">
            <#if linkNode["@text-map"]?has_content><#assign textMap = ec.getResource().expression(linkNode["@text-map"], "")!></#if>
            <#if textMap?has_content><#assign linkText = ec.getResource().expand(linkNode["@text"], "", textMap)>
                <#else><#assign linkText = ec.getResource().expand(linkNode["@text"]!"", "")></#if>
        </#if>
        <#if linkText == "null"><#assign linkText = ""></#if>
        <#t><@jsonValue linkText/>
    </#if>
</#if></#macro>

<#macro image><#-- do nothing for image, most likely part of screen and is funny in csv file: <@jsonValue .node["@alt"]!"image"/> --></#macro>
<#macro label><#-- do nothing for label, most likely part of screen and is funny in csv file: <#assign labelValue = ec.resource.expand(.node["@text"], "")><@jsonValue labelValue/> --></#macro>
<#macro parameter><#-- do nothing, used directly in other elements --></#macro>


<#-- ====================================================== -->
<#-- ======================= Form ========================= -->

<#-- NOTE: form-single in a csv file is a bit funny, ignoring in case there is a form-single and form-list
on the same screen to increase reusability of those screens -->
<#macro "form-single"></#macro>

<#macro "form-list">
    <#-- one object per grid (see Export objects above): inside a box, the first grid uses the object the box opened and
         each later one starts its own; outside any box the grid opens and closes its own object, titled with the
         screen's name, and "This Form Only" (singleFormTitle) keeps it only when that is the name asked for -->
    <#local state = jsonExportState()>
    <#local inBox = ((state.get("_jsonBoxDepth")!0) > 0)>
    <#if inBox>
        <#local boxGrids = state.get("_jsonBoxGrids")!0>
        <#if (boxGrids > 0)><#t>},{"title":"${(state.get("_jsonBoxTitle")!"")?json_string}",</#if>
        <#local ignored = state.put("_jsonBoxGrids", boxGrids + 1)!>
    <#else>
        <#local gridTitle = ec.getResource().expand(sri.getActiveScreenDef().getDefaultMenuName()!"", "")>
        <#if singleFormTitle?has_content && singleFormTitle != gridTitle><#return></#if>
        <#t>{"title":"${gridTitle?json_string}",
    </#if>
    <#-- Use the formNode assembled based on other settings instead of the straight one from the file: -->
    <#assign formInstance = sri.getFormInstance(.node["@name"])>
    <#assign formListInfo = formInstance.makeFormListRenderInfo()>
    <#assign formNode = formListInfo.getFormNode()>
    <#assign formListColumnList = formListInfo.getAllColInfo()>
    <#assign listObject = formListInfo.getListObject(false)!>
    <#assign listName = formNode["@list"]>
    <#assign fieldPrinted = false>
    <@compress single_line=true>
    <#t>"columns": [
    <#t><#list formListColumnList as columnFieldList>
        <#t><#list columnFieldList as fieldNode>
            <#t><@formListHeaderField fieldNode/>
        <#t></#list>
    <#t></#list>]
    </@compress>
    <#-- per-column type hints for the XLSX exporter (card #943): "text" columns are identifiers
         and must never be coerced to numbers no matter what their values look like; "auto" keeps
         the exporter's value sniffing. Emitted in the same iteration as "columns" so the two
         arrays are positionally aligned by construction. -->
    <#assign fieldPrinted = false>
    <@compress single_line=true>
    <#t>,"colTypes": [
    <#t><#list formListColumnList as columnFieldList>
        <#t><#list columnFieldList as fieldNode>
            <#t><#if formListColEmits(fieldNode)><@jsonValue formListColType(fieldNode)/></#if>
        <#t></#list>
    <#t></#list>]
    </@compress>
    <#assign fieldPrinted = false>
    <#if formListColumnList?size &gt; 0 && listObject?size &gt; 0><#t>,</#if>
    <#if listObject?size &gt; 0><#t>"data":[</#if>
    <@compress>
    <#list listObject as listEntry>
        <#-- NOTE: the form-list.@list-entry attribute is handled in the ScreenForm class through this call: -->
        ${sri.startFormListRow(formListInfo, listEntry, listEntry_index, listEntry_has_next)}<#t>
        <#lt><#if listEntry_index &gt; 0>,</#if>
        <@compress single_line=true>
        <#t><#assign fieldPrinted = false>[<#list formListColumnList as columnFieldList>
            <#t><#list columnFieldList as fieldNode>
                <#t><@formListSubField fieldNode/>
            <#t></#list>
        <#t></#list>]
        </@compress>
        ${sri.endFormListRow()}<#t>
    </#list>
    <#if listObject?size &gt; 0><#t>]</#if>
    </@compress>
    ${sri.safeCloseList(listObject)}<#t><#-- if listObject is an EntityListIterator, close it -->
    <#if !inBox><#t>},</#if>
</#macro>
<#-- does this column ever emit a data cell? Mirrors formListWidget's skip rules exactly, so
     headers, colTypes, and data cells stay positionally aligned by construction: hidden fields
     and submit-only control columns (Find/Edit buttons) drop out of ALL THREE instead of leaving
     a header with no cells under it (the old header/data mismatch). -->
<#function formListColEmits fieldNode>
    <#if fieldNode["@hide"]! == "true"><#return false></#if>
    <#if fieldNode["conditional-field"]?has_content><#return true></#if>
    <#if fieldNode["default-field"]?has_content>
        <#local dNode = fieldNode["default-field"][0]>
        <#if dNode["ignored"]?has_content || dNode["hidden"]?has_content || dNode["submit"]?has_content><#return false></#if>
        <#return true>
    </#if>
    <#-- header-field only (e.g. a find button column): never a data cell -->
    <#return false>
</#function>
<#macro formListHeaderField fieldNode>
    <#if !formListColEmits(fieldNode)><#return></#if>
    <#if fieldNode["header-field"]?has_content>
        <#assign fieldSubNode = fieldNode["header-field"][0]>
    <#elseif fieldNode["default-field"]?has_content>
        <#assign fieldSubNode = fieldNode["default-field"][0]>
    <#else>
        <#-- this only makes sense for fields with a single conditional -->
        <#assign fieldSubNode = fieldNode["conditional-field"][0]>
    </#if>
    <#t><@fieldTitle fieldSubNode/>
</#macro>
<#-- Export type hint for one form-list column (card #943): "text" = identifier, never coerce;
     "auto" = let the exporter's value sniffing decide (today's behavior). Conservative on
     purpose: only returns "text" on signals that mark a column as identifier-shaped. -->
<#function formListColType fieldNode>
    <#-- the app's explicit numeric-column conventions win: right-aligned/totaled columns are
         genuinely numeric even when a widget below would read as text -->
    <#if (fieldNode["@align"]! == "right") || fieldNode["@show-total"]?has_content><#return "auto"></#if>
    <#if fieldNode["default-field"]?has_content>
        <#local dNode = fieldNode["default-field"][0]>
    <#elseif fieldNode["conditional-field"]?has_content>
        <#local dNode = fieldNode["conditional-field"][0]>
    <#else>
        <#return "auto">
    </#if>
    <#-- links and entity descriptions are identifiers/names even when all digits (pseudoId) -->
    <#if dNode["link"]?has_content || dNode["display-entity"]?has_content><#return "text"></#if>
    <#-- a display with numeric formatting is a number column; leave it to the sniffing -->
    <#if dNode["display"]?has_content>
        <#local dispNode = dNode["display"][0]>
        <#if dispNode["@currency-unit-field"]?has_content || dispNode["@format"]?has_content><#return "auto"></#if>
    </#if>
    <#-- entity field type where the form declares one: id and text types export as text -->
    <#local vType = (formInstance.getFieldValidateNode(dNode)["@type"])!"">
    <#if vType == "id" || vType == "id-long" || vType?starts_with("text-")><#return "text"></#if>
    <#return "auto">
</#function>
<#macro formListSubField fieldNode>
    <#-- skip the same columns the header skips, emit exactly ONE cell for everything else: a
         null value or non-rendering widget used to emit nothing, shifting every later cell in
         the row one column left under the wrong header (null-shift fix) -->
    <#if !formListColEmits(fieldNode)><#return></#if>
    <#local cellsBefore = cellsEmitted!0>
    <#list fieldNode["conditional-field"] as fieldSubNode>
        <#if ec.resource.condition(fieldSubNode["@condition"], "")>
            <#t><@formListWidget fieldSubNode/>
            <#if (cellsEmitted!0) == cellsBefore><#t><@jsonValue ""/></#if>
            <#return>
        </#if>
    </#list>
    <#if fieldNode["default-field"]?has_content>
        <#t><@formListWidget fieldNode["default-field"][0]/>
    </#if>
    <#if (cellsEmitted!0) == cellsBefore><#t><@jsonValue ""/></#if>
</#macro>
<#macro formListWidget fieldSubNode>
    <#if fieldSubNode["ignored"]?has_content || fieldSubNode["hidden"]?has_content || fieldSubNode["submit"]?has_content><#return/></#if>
    <#if fieldSubNode?parent["@hide"]! == "true"><#return></#if>
    <#t><#recurse fieldSubNode>
</#macro>
<#macro "row-actions"><#-- do nothing, these are run by the SRI --></#macro>

<#macro fieldTitle fieldSubNode><#t>
    <#t><#if (fieldSubNode?node_name == 'header-field')>
        <#local fieldNode = fieldSubNode?parent>
        <#local headerFieldNode = fieldNode["header-field"][0]!>
        <#local defaultFieldNode = fieldNode["default-field"][0]!>
        <#t><#if headerFieldNode["@title"]?has_content><#local fieldSubNode = headerFieldNode><#elseif defaultFieldNode["@title"]?has_content><#local fieldSubNode = defaultFieldNode></#if>
    </#if>
    <#t><#assign titleValue><#if fieldSubNode["@title"]?has_content>${ec.getResource().expand(fieldSubNode["@title"], "")}<#else><#list fieldSubNode?parent["@name"]?split("(?=[A-Z])", "r") as nameWord>${nameWord?cap_first?replace("Id", "ID")}<#if nameWord_has_next> </#if></#list></#if></#assign><@jsonValue ec.getL10n().localize(titleValue)/>
</#macro>

<#macro "field"><#-- shouldn't be called directly, but just in case --><#recurse/></#macro>
<#macro "conditional-field"><#-- shouldn't be called directly, but just in case --><#recurse/></#macro>
<#macro "default-field"><#-- shouldn't be called directly, but just in case --><#recurse/></#macro>

<#-- ================== Form Field Widgets ==================== -->

<#macro "check">
    <#assign options = sri.getFieldOptions(.node)>
    <#assign currentValue = sri.getFieldValueString(.node)>
    <#if !currentValue?has_content><#assign currentValue = ec.getResource().expandNoL10n(.node["@no-current-selected-key"]!, "")/></#if>
    <#t><@jsonValue (options.get(currentValue))!(currentValue)/>
</#macro>

<#macro "date-find"></#macro>
<#macro "date-time">
    <#assign fieldValue = sri.getFieldValue(.node?parent?parent, .node["@default-value"]!"")!>
    <#if .node["@format"]?has_content><#assign fieldValue = ec.l10n.format(fieldValue, .node["@format"])></#if>
    <#if .node["@type"]! == "time"><#assign size=9/><#assign maxlength=12/><#elseif .node["@type"]! == "date"><#assign size=10/><#assign maxlength=10/><#else><#assign size=23/><#assign maxlength=23/></#if>
    <#t><@jsonValue fieldValue/>
</#macro>

<#macro "display">
    <#assign fieldValue = ""/>
    <#assign dispFieldNode = .node?parent?parent>
    <#if .node["@text"]?has_content>
        <#assign textMap = "">
        <#if .node["@text-map"]?has_content><#assign textMap = ec.getResource().expression(.node["@text-map"], "")!></#if>
        <#if textMap?has_content>
            <#assign fieldValue = ec.getResource().expand(.node["@text"], "", textMap)>
        <#else>
            <#assign fieldValue = ec.getResource().expand(.node["@text"], "")>
        </#if>
        <#if .node["@currency-unit-field"]?has_content>
            <#assign fieldValue = ec.getL10n().formatCurrency(fieldValue, ec.getResource().expression(.node["@currency-unit-field"], ""))>
        </#if>
    <#elseif .node["@currency-unit-field"]?has_content>
        <#assign fieldValue = ec.getL10n().formatCurrency(sri.getFieldValue(dispFieldNode, ""), ec.getResource().expression(.node["@currency-unit-field"], ""))>
    <#else>
        <#assign fieldValue = sri.getFieldValueString(.node)>
    </#if>
    <#t><@jsonValue fieldValue/>
</#macro>
<#macro "display-entity">
    <#assign fieldValue = ""/><#assign fieldValue = sri.getFieldEntityValue(.node)/>
    <#t><@jsonValue fieldValue/>
</#macro>

<#macro "drop-down">
    <#assign options = sri.getFieldOptions(.node)>
    <#assign currentValue = sri.getFieldValueString(.node)/>
    <#if !currentValue?has_content><#assign currentValue = .node["@no-current-selected-key"]!""/></#if>
    <#t><@jsonValue (options.get(currentValue))!(currentValue)/>
</#macro>

<#macro "file"></#macro>
<#macro "hidden"></#macro>
<#macro "ignored"><#-- shouldn't ever be called as it is checked in the form-* macros --></#macro>
<#macro "password"></#macro>

<#macro "radio">
    <#assign options = {"":""}/><#assign options = sri.getFieldOptions(.node)>
    <#assign currentValue = sri.getFieldValueString(.node)/>
    <#if !currentValue?has_content><#assign currentValue = .node["@no-current-selected-key"]!""/></#if>
    <#t><@jsonValue (options.get(currentValue))!(currentValue)/>
</#macro>

<#macro "range-find"></#macro>
<#macro "reset"></#macro>

<#macro "submit">
    <#assign fieldValue><@fieldTitle .node?parent/></#assign>
    <#t><@jsonValue fieldValue/>
</#macro>

<#macro "text-area">
    <#assign fieldValue = sri.getFieldValueString(.node)>
    <#t><@jsonValue fieldValue/>
</#macro>

<#macro "text-line">
    <#assign fieldValue = sri.getFieldValueString(.node)>
    <#t><@jsonValue fieldValue/>
</#macro>

<#macro "text-find">
    <#assign fieldValue = sri.getFieldValueString(.node)>
    <#t><@jsonValue fieldValue/>
</#macro>
