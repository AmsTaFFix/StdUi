local MAJOR, MINOR = 'StdUi', 5;
--- @class StdUi
local StdUi = LibStub:NewLibrary(MAJOR, MINOR);

if not StdUi then
	return
end

local TableInsert = tinsert;

StdUi.moduleVersions = {};
if not StdUiInstances then
	StdUiInstances = {StdUi};
else
	TableInsert(StdUiInstances, StdUi);
end

function StdUi:NewInstance()
	local instance = CopyTable(self);
	instance:ResetConfig();
	TableInsert(StdUiInstances, instance);
	return instance;
end

function StdUi:RegisterModule(module, version)
	self.moduleVersions[module] = version;
end

function StdUi:UpgradeNeeded(module, version)
	if not self.moduleVersions[module] then
		return true;
	end

	return self.moduleVersions[module] < version;
end

function StdUi:RegisterWidget(name, func)
	if not self[name] then
		self[name] = func;
		return true;
	end

	return false;
end

---Inject `StdUiWidgetMixin` into any `StdUi.Frame` object. This method mutate the object itself.
---@param frame StdUi.Frame
function StdUi:InitWidget(frame)
	frame.isWidget = true;

	function frame:GetChildrenWidgets()
		local children = {frame:GetChildren()};
		---@cast children StdUi.Frame[]
		local result = {};
		for i = 1, #children do
			local child = children[i];
			if child.isWidget then
				TableInsert(result, child);
			end
		end

		return result;
	end
end

---@param obj Frame
---@param width number?
---@param height number?
function StdUi:SetObjSize(obj, width, height)
	if width then
		obj:SetWidth(width);
	end

	if height then
		obj:SetHeight(height);
	end
end

function StdUi:SetTextColor(fontString, colorType)
	colorType = colorType or 'normal';
	if fontString.SetTextColor then
		local c = self.config.font.color[colorType];
		fontString:SetTextColor(c.r, c.g, c.b, c.a);
	end
end

StdUi.SetHighlightBorder = function(self)
	if self.target then
		self = self.target;
	end

	if self.isDisabled then
		return
	end

	local hc = StdUi.config.highlight.color;
	if not self.origBackdropBorderColor then
		self.origBackdropBorderColor = {self:GetBackdropBorderColor()};
	end
	self:SetBackdropBorderColor(hc.r, hc.g, hc.b, 1);
end

StdUi.ResetHighlightBorder = function(self)
	if self.target then
		self = self.target;
	end

	if self.isDisabled then
		return
	end

	local hc = self.origBackdropBorderColor;
	if hc then
		self:SetBackdropBorderColor(unpack(hc));
	end
end

function StdUi:HookHoverBorder(object)
	if not object.SetBackdrop then
		Mixin(object, BackdropTemplateMixin)
	end
	object:HookScript('OnEnter', self.SetHighlightBorder);
	object:HookScript('OnLeave', self.ResetHighlightBorder);
end

function StdUi:ApplyBackdrop(frame, type, border, insets)
	local config = frame.config or self.config;
	local backdrop = {
		bgFile   = config.backdrop.texture,
		edgeFile = config.backdrop.texture,
		edgeSize = 2,
	};
	if insets then
		backdrop.insets = insets;
	end
	if not frame.SetBackdrop then
		Mixin(frame, BackdropTemplateMixin)
	end
	frame:SetBackdrop(backdrop);

	type = type or 'button';
	border = border or 'border';

	if config.backdrop[type] then
		frame:SetBackdropColor(
			config.backdrop[type].r,
			config.backdrop[type].g,
			config.backdrop[type].b,
			config.backdrop[type].a
		);
	end

	if config.backdrop[border] then
		frame:SetBackdropBorderColor(
			config.backdrop[border].r,
			config.backdrop[border].g,
			config.backdrop[border].b,
			config.backdrop[border].a
		);
	end
end

function StdUi:ClearBackdrop(frame)
	if not frame.SetBackdrop then
		Mixin(frame, BackdropTemplateMixin)
	end
	frame:SetBackdrop(nil);
end

function StdUi:ApplyDisabledBackdrop(frame, enabled)
	if frame.target then
		frame = frame.target;
	end

	if enabled then
		self:ApplyBackdrop(frame, 'button', 'border');
		self:SetTextColor(frame, 'normal');
		if frame.label then
			self:SetTextColor(frame.label, 'normal');
		end

		if frame.text then
			self:SetTextColor(frame.text, 'normal');
		end
		frame.isDisabled = false;
	else
		self:ApplyBackdrop(frame, 'buttonDisabled', 'borderDisabled');
		self:SetTextColor(frame, 'disabled');
		if frame.label then
			self:SetTextColor(frame.label, 'disabled');
		end

		if frame.text then
			self:SetTextColor(frame.text, 'disabled');
		end
		frame.isDisabled = true;
	end
end

function StdUi:HookDisabledBackdrop(frame)
	local this = self;
	hooksecurefunc(frame, 'Disable', function(self)
		this:ApplyDisabledBackdrop(self, false);
	end);

	hooksecurefunc(frame, 'Enable', function(self)
		this:ApplyDisabledBackdrop(self, true);
	end);
end

function StdUi:StripTextures(frame)
	for i = 1, frame:GetNumRegions() do
		local region = select(i, frame:GetRegions());

		if region and region:GetObjectType() == 'Texture' then
			region:SetTexture(nil);
		end
	end
end

function StdUi:MakeDraggable(frame, handle)
	frame:SetMovable(true);
	frame:EnableMouse(true);
	frame:RegisterForDrag('LeftButton');
	frame:SetScript('OnDragStart', frame.StartMoving);
	frame:SetScript('OnDragStop', frame.StopMovingOrSizing);

	if handle then
		handle:EnableMouse(true);
		handle:SetMovable(true);
		handle:RegisterForDrag('LeftButton');

		handle:SetScript('OnDragStart', function(self)
			frame.StartMoving(frame);
		end);

		handle:SetScript('OnDragStop', function(self)
			frame.StopMovingOrSizing(frame);
		end);
	end
end

-- Make a frame resizable
function StdUi:MakeResizable(frame, direction)
	-- Possible resize directions and handle rotation values
	local anchorDirections = {
		["TOP"] = 0,
		["TOPRIGHT"] = 1.5708,
		["RIGHT"] = 0,
		["BOTTOMRIGHT"] = 0,
		["BOTTOM"] = 0,
		["BOTTOMLEFT"] = -1.5708,
		["LEFT"] = 0,
		["TOPLEFT"] = 3.1416,
	}

	direction = string.upper(direction);

	-- Return if invalid direction
	if not anchorDirections[direction] then return false end

	frame:SetResizable(true);

	-- Create the resize anchor
	local anchor = CreateFrame("Button", nil, frame);
	anchor:SetPoint(direction, frame, direction);

	-- Attach side anchor to adjacent sides of frame
	if direction == "TOP" or direction == "BOTTOM" then
		anchor:SetHeight(self.config.resizeHandle.height);
		anchor:SetPoint("LEFT", frame, "LEFT", self.config.resizeHandle.width, 0);
		anchor:SetPoint("RIGHT", frame, "RIGHT", self.config.resizeHandle.width*-1, 0);
	elseif direction == "LEFT" or direction == "RIGHT" then
		anchor:SetWidth(self.config.resizeHandle.width);
		anchor:SetPoint("TOP", frame, "TOP", 0, self.config.resizeHandle.height*-1);
		anchor:SetPoint("BOTTOM", frame, "BOTTOM", 0, self.config.resizeHandle.height);
	else
		-- Set the corner anchor textures
		anchor:SetNormalTexture(self.config.resizeHandle.texture.normal);
		anchor:SetHighlightTexture(self.config.resizeHandle.texture.highlight);
		anchor:SetPushedTexture(self.config.resizeHandle.texture.pushed);

		-- Set size and rotate corner anchor
		anchor:SetSize(self.config.resizeHandle.width, self.config.resizeHandle.height);
		anchor:GetNormalTexture():SetRotation(anchorDirections[direction]);
		anchor:GetHighlightTexture():SetRotation(anchorDirections[direction]);
		anchor:GetPushedTexture():SetRotation(anchorDirections[direction]);
	end

	-- Resize anchor click handlers
	anchor:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:StartSizing(direction);
			frame:SetUserPlaced(true);
		end
	end)
	anchor:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			frame:StopMovingOrSizing();
		end
	end)
end

