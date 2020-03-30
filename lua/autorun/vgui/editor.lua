-- Editor test panel

PANEL = {}

--[[
modes:
insert
normal
visual
]]

function PANEL:Init()
	self:SetCursor("beam")
	self.focused = false 
	self.shift = false
	self.line = 1
	self.char = 0 
	self.lines = {}
	self.linespace = 5
	self.marginspace = 3
	self.bg = Color(0,0,0)
	self.fg = Color(255,255,255)
	self.key_states = {}
	self.key_times = {}
	self.key_repeats = {}
	self.repeat_delay = 0.1
	self.mode = "normal"
end

-- Paint the panel 
function PANEL:Paint(w,h)
	surface.SetDrawColor(self.bg)
	surface.SetTextColor(self.fg)
	surface.SetFont("DebugFixed") -- Temp for now

	-- Loop through all the lines and render
	local x,y = self:GetPos()
	local fontw, fonth = surface.GetTextSize("|") -- Use tallest char
	local ypos = 0
	
	-- Draw the bg rect
	surface.DrawRect(x,y,w,h)

	-- Draw lines
	fonth = fonth + self.linespace 
	for k,v in pairs(self.lines) do
		surface.SetTextPos(x + self.marginspace, y + ypos * fonth)
		surface.SetTextColor(self.fg.r, self.fg.g, self.fg.b, 255)
		surface.DrawText(v)
		ypos = ypos + 1
	end
	-- Draw the cursor
	surface.SetDrawColor(100,100,100,100)
	surface.DrawRect(((self.char+1) * fontw + (x)) - (fontw/2), (self.line-1) * fonth + (y), fontw, fonth)
	
	-- Draw the status bar at the bottom
	if self.mode == "normal" then 
		surface.SetDrawColor(50,50,50,255)
	elseif self.mode == "visual" then
		surface.SetDrawColor(255, 100, 0, 255)
	elseif self.mode == "insert" then
		surface.SetDrawColor(0,50,255,255)
	end 
	surface.DrawRect(x, h-fonth, w, fonth)
	surface.SetTextColor(255,255,255,255)
	surface.SetTextPos(x + self.marginspace, h-fonth + fonth / 4)
	surface.DrawText("---"..string.upper(self.mode).."---")
	return true
end 

-- Check for focus, if we dont have it, explode 
function PANEL:OnFocusChanged(gained)
	self.focused = gained 
end 

local key_table_normal = {
	[KEY_0] = "0",
	[KEY_1] = "1",
	[KEY_2] = "2",
	[KEY_3] = "3",
	[KEY_4] = "4",
	[KEY_5] = "5",
	[KEY_6] = "6",
	[KEY_7] = "7",
	[KEY_8] = "8",
	[KEY_9] = "9",
	[KEY_COMMA] = ",",
	[KEY_EQUAL] = "=",
	[KEY_LBRACKET] = "[",
	[KEY_RBRACKET] = "]",
	[KEY_PERIOD] = ".",
	[KEY_SLASH] = "/",
	[KEY_BACKSLASH] = "\\",
	[KEY_APOSTROPHE] = "'",
	[KEY_BACKQUOTE] = "`",
	[KEY_SPACE] = " ",
	[KEY_TAB] = "\t",
	[KEY_MINUS] = "-",
	[KEY_EQUAL] = "=",
}

local key_table_upper = {
	[KEY_0] = ")",
	[KEY_1] = "!",
	[KEY_2] = "@",
	[KEY_3] = "#",
	[KEY_4] = "$",
	[KEY_5] = "%",
	[KEY_6] = "^",
	[KEY_7] = "&",
	[KEY_8] = "*",
	[KEY_9] = "(",
	[KEY_COMMA] = "<",
	[KEY_EQUAL] = "+",
	[KEY_LBRACKET] = "{",
	[KEY_RBRACKET] = "}",
	[KEY_PERIOD] = ">",
	[KEY_SLASH] = "?",
	[KEY_BACKSLASH] = "|",
	[KEY_APOSTROPHE] = "\"",
	[KEY_BACKQUOTE] = "~",
	[KEY_SPACE] = " ",
	[KEY_TAB] = "\t",
	[KEY_MINUS] = "_",
	[KEY_EQUAL] = "+",
}

function PANEL:OnKeyCodePressed(code)
	-- Check for the escape key 
	if code == KEY_ESCAPE then
		self.mode = "normal"
		return false
	end 
	
	if self.mode == "insert" then 
		
		-- Put this into a key_states table and log the time in which it was pressed
		self.key_states[code] = true
		self.key_times[code] = CurTime()

		-- Handle capslock logic
		if self.caps == true and code == KEY_CAPSLOCK then
			self.caps = false
		elseif code == KEY_CAPSLOCK then 
			self.caps = true
		end 

		--
		-- Handle various shortcuts
		--
		
		-- Shortcut for saving 
		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_S) then
			self:OnSaveShortcut()
			return false
		end 

		-- Check if shift keys are down 
		if (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)) then
			if not self.caps then 
				self.shift = true  
			end 
		elseif self.caps then
			self.shift = true 
		end 

		if self.lines[self.line] == nil then self.lines[self.line] = "" end 

		-- Handle uppercase strings
		if (self.shift) and code >= KEY_A and code <= KEY_Z then
			self.lines[self.line] = self.lines[self.line] .. string.upper(language.GetPhrase(input.GetKeyName(code)))
			self.char = self.char + 1
			return true 
		end 

		-- Lowercase ASCII/numbers 
		if (code <= KEY_Z and code >= KEY_0) then
			self.lines[self.line] = self.lines[self.line] .. (language.GetPhrase(input.GetKeyName(code)))
			self.char = self.char + 1
			return true 
		end 

		-- Simple enter key
		if code == KEY_ENTER then
			-- We still need to append a newline char 
			local _p1 = string.sub(self.lines[self.line], 1, self.char)
			local _p2 = string.sub(self.lines[self.line], self.char+1, #self.lines[self.line])
			self.lines[self.line] = _p1
			self.lines[self.line+1] = _p2 
			self.char = 0 
			self.line = self.line + 1
			return true 
		end 

		-- Backspace handling
		if code == KEY_BACKSPACE and self.char >= 0 then
			-- If we're at the end of a line already let's reset the char index
			if self.char == 0 then
				if self.line == 1 then
					return true
				end 
				self.line = self.line - 1
				local linelen = #self.lines[self.line] 
				if linelen == 0 then
					self.char = 1
				else 
					self.char = linelen
				end
			end 
			local _line = string.ToTable(self.lines[self.line])
			table.remove(_line,self.char)
			self.lines[self.line] = table.concat(_line,"")
			self.char = self.char - 1
			return true
		end

		-- Handling of the arrow keys
		if code == KEY_LEFT and self.char > 0 then
			self.char = self.char - 1
			return true 
		end

		if code == KEY_RIGHT and self.char < #self.lines[self.line] then
			self.char = self.char + 1
			return true 
		end 

		if code == KEY_UP and self.line > 1 then
			self.line = self.line - 1
			if self.char > #self.lines[self.line] then
				self.char = #self.lines[self.line]
			end 
			return true
		end

		if code == KEY_DOWN then
			if self.lines[self.line + 1] == nil then return true end 
			self.line = self.line + 1
			if self.char > #self.lines[self.line] then
				self.char = #self.lines[self.line]
			end 
			return true 
		end 

		if (code >= KEY_0 and code <= KEY_Z) or (code >= KEY_LBRACKET and code < KEY_ENTER) or
			code == KEY_TAB or code == KEY_SPACE then 
			-- Handle other keys
			if not self.shift then
				local _p1 = string.sub(self.lines[self.line], 1, self.char)
				local _p2 = string.sub(self.lines[self.line], self.char+1, #self.lines[self.line])
				self.lines[self.line] = _p1 .. key_table_normal[code] .. _p2
			else
				local _p1 = string.sub(self.lines[self.line], 1, self.char)
				local _p2 = string.sub(self.lines[self.line], self.char+1, #self.lines[self.line])
				self.lines[self.line] = _p1 .. key_table_upper[code] .. _p2 
			end 
			self.char = self.char + 1
		end
		return false
	elseif self.mode == "visual" then
		
	else
		-- Normal mode shortcuts ---
		if code == KEY_I and self.mode == "normal" then
			self.mode = "insert"
		elseif code == KEY_ESC then
			self.mode = "normal"
		elseif code == KEY_V and self.mode == "normal" then
			self.mode = "visual"
		end 
		return false
	end 
end

function PANEL:OnKeyCodeReleased(code)
	-- Set the key states within the table
	self.key_states[code] = false
	self.key_times[code] = 0

	if code == KEY_LSHIFT or code == KEY_RSHIFT then
		self.shift = false
	end 
end 

-- We're only using Think to handle repeat keys
function PANEL:Think()
	local dt = FrameTime() -- delta time
	
	for k,v in pairs(self.key_states) do
		if not v then
			self.key_repeats[k] = false
			self.key_times[k] = 0
		end 
		-- If the change in time between key press > repeat time, resend the key events
		if self.key_repeats[k] then
			if (CurTime() - self.key_times[k]) > 0.03 and self.key_times[k] != 0 then
				self:OnKeyCodePressed(k)
			end 
		elseif self.key_repeats[k] == false and (CurTime() - self.key_times[k]) > 0.5 and self.key_times[k] != 0 then
			self:OnKeyCodePressed(k)
			self.key_repeats[k] = true
		end

	end 
end 

function PANEL:PerformLayout()
	derma.SkinHook("Layout","RichText", self)
end 

function PANEL:OnSaveShortcut()
	-- Stub
end 

-- Saves the internal buffer to the specified file
function PANEL:SaveBuffer(file,path)
	local _file = file.Open(file,"w",path)
	if _file == nil then return false end
	for k,v in self.lines do
		if v == nil then break end
		_file:Write(v..'\n')
	end
	_file:Flush()
	_file:Close()
	return true
end 

-- Loads a file into the editor
function PANEL:LoadFile(file,path)
	local _file = file.Open(file,"r",path)
	if _file == nil then return false end
	self.line = 1
	self.lines = {}
	while not _file:EndOfFile() do 
		self.lines[self.line] = _file:ReadLine()
		self.line = self.line + 1
	end 
	_file:Close()
	return true 
end 

derma.DefineControl("DCodeEditor", "Code editor widget", PANEL, "RichText")

concommand.Add("test_open_editor", function(ply, cmd, args, argstr)
	print("Opening test editor...")
	
	-- Create the panel 
	local panel = vgui.Create("DFrame")
	panel:SetPos(0 + (ScrW() - ScrW() / 1.1)/2, 0 + (ScrH() - ScrH() / 1.1)/2)
	panel:SetSize(ScrW() / 1.1, ScrH() / 1.1)
	panel:SetTitle("Editor Test")
	panel:SetDraggable(true)
	panel:MakePopup()

	local textedit = vgui.Create("DCodeEditor", panel)
	textedit:Dock(FILL)
	textedit:SetVerticalScrollbarEnabled(true)

	textedit:AppendText("Test")
	textedit:SetKeyboardInputEnabled(true)
	textedit:SetCursor("beam")
	textedit:SetCaretPos(1)
	textedit:GotoTextStart()

	function textedit:PerformLayout()
		textedit:SetFontInternal("Trebuchet18")
		textedit:SetBGColor(Color(100,100,100))
	end 
	textedit:RequestFocus()
end) 
