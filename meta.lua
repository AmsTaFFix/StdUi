---@meta _

---@class StdUiWidgetMixin
---@field isWidget boolean
---@field GetChildrenWidgets fun(self):StdUi.Frame[]

---@class StdUi.EasyLayoutMixin
---@field stdUi StdUi
---@field layout StdUi.LayoutConfigOptions
---@field rows EasyLayoutRow[]
---@field AddRow fun(self, config: StdUiLayoutRowConfig?):EasyLayoutRow

---@alias StdUiLayoutWidgetType 
---|"checkbox"
---|"editBox"
---|"multiLineBox"
---|"dropdown"
---|"autocomplete"
---|"slider"
---|"sliderWithBox"
---|"color"
---|"button"
---|"header"
---|"label"
---|"texture"
---|"panel"
---|"scroll"
---|"fauxScroll"
---|"tab"
---|"custom"

---@class StdUiLayoutRowConfig
---@field children StdUiLayoutConfig?
local StdUiLayoutRowConfig = {
    ---Widget column width
    ---@type number
    column = 0,
    ---Widgets are sorted in rows using this property
    ---@type number
    order = 0,
    ---Widget type
    ---@type StdUiLayoutWidgetType
    type = "custom",
    ---By default, if you append database to LayoutInfo, it will set widget value depending on key of widget, use this 
    ---property to override this behavior, supports nested variables like 'some.db.value'
    ---@type string? 
    key = nil,
    ---Function to execute at the beginning of initialization
    ---@type fun(widget:any)?
    init = nil,
    ---If you want to have label above widget, use this
    ---@type string?
    label = nil,
    ---Set initial value to widget
    ---@type any
    initialValue = nil,
    ---Function that will be executed when value of widget changes
    ---@type fun(...)?
    onChange = nil,
    ---function that will be executed when value of widget changes this will unbind widget from database
    ---@type fun(...)?
    onValueChanged = nil,
    ---For container widgets, pass yet another layoutConfig
    ---@type StdUiLayoutConfig?
    children = nil,
    ---If set to true, widget will take WHOLE parent space. Use this only for a single widget
    ---@type boolean?
    fullSize = nil,
    ---If set to true, widget will take remaining vertical space
    ---@type boolean?
    fullHeight = nil,
}

---@class StdUiLayoutConfig
---@field layoutConfig StdUi.LayoutConfigOptions? 
---@field rows {[string]:StdUiLayoutRowConfig}[]
local StdUiLayoutConfig = {
    ---@type StdUi.LayoutConfigOptions?
    layoutConfig  = {},
    ---@type {[string]:StdUiLayoutRowConfig}[]
    rows = {},
    ---@type table?
    database = {},
}
