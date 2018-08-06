---------------------------------------------------------------------
-- Player Buff/Debuff Display
---------------------------------------------------------------------

local _, ns = ...
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)

ns.addon = CreateFrame("frame", nil, UIParent)

local FONT = LSM:Fetch(LSM.MediaType.FONT, "Roboto Bold Condensed")

-- These are Kellen's preferences. Eventually these may be
-- configurable, but they are fixed for now. And you cannot
-- just change the values, since they are tied to a
-- secure button template.
local BUFF_SIZE = 32
local DEBUFF_SIZE = 60

local buff_blacklist   = {}
local debuff_blacklist = {}

local defaults = {
  buffs = {
    spacing   = 1,
    rowlength = 15,
    hgrowth   = "Left",
    vgrowth   = "Downwards",
  },
  debuffs = {
    spacing   = 2,
    rowlength = 8,
    hgrowth   = "Left",
    vgrowth   = "Downwards",
  }
}


-- Create frames to store the player auras
local Buffs = CreateFrame("frame", "klnBuffs", UIParent, "SecureAuraHeaderTemplate")
Buffs:SetPoint('TOPRIGHT', UIParent, "TOPRIGHT", -300, -38)

local Debuffs = CreateFrame("frame", "klnDebuffs", UIParent, "SecureAuraHeaderTemplate")
Debuffs:SetPoint('TOPRIGHT', UIParent, "TOPRIGHT", -300, -165)


-- 
-- Sets the size of a header's child frames.
-- 
local function setChildrenSize(header, size)
  local c = { header:GetChildren() }
  for i = 1, #c do
    local child = c[i]
    child:SetSize(size,size)
  end
end


-- 
-- Size the aura frames and (re)define their behavior.
-- 
function ns.addon:UpdatePlayerAuraFrame()
  if (InCombatLockdown()) then return end

  -- TODO: Hook a configuration system in here
  local cfg = defaults

  -- Update buffs
  local buff_rows   = math.ceil(20 / cfg.buffs.rowlength)
  local buff_width  = (BUFF_SIZE + cfg.buffs.spacing + 2) * cfg.buffs.rowlength
  local buff_height = (BUFF_SIZE + cfg.buffs.spacing + 2) * buff_rows
  Buffs:SetSize(buff_width, buff_height)
  Buffs:SetAttribute("template", ("klnBuffsTemplate%d"):format(BUFF_SIZE))
  Buffs:SetAttribute("style-width", BUFF_SIZE)
  Buffs:SetAttribute("style-height", BUFF_SIZE)
  Buffs:SetAttribute('wrapAfter', cfg.buffs.rowlength)
  Buffs:SetAttribute("minWidth", (BUFF_SIZE + cfg.buffs.spacing + 2) * cfg.buffs.rowlength)
  Buffs:SetAttribute("minHeight", (BUFF_SIZE + cfg.buffs.spacing + 2) * buff_rows)
  Buffs:SetAttribute('weaponTemplate', ("klnBuffsTemplate%d"):format(BUFF_SIZE))
  if cfg.buffs.hgrowth == "Left" then
    Buffs:SetAttribute('xOffset', - (BUFF_SIZE + cfg.buffs.spacing + 2))
    Buffs:SetAttribute('sortDirection', "-")
    Buffs:SetAttribute('point', "TOPRIGHT")
  else
    Buffs:SetAttribute('xOffset', (BUFF_SIZE + cfg.buffs.spacing + 2))
    Buffs:SetAttribute('sortDirection', "+")
    Buffs:SetAttribute('point', "TOPLEFT")
  end
  if cfg.buffs.vgrowth == "Upwards" then
    Buffs:SetAttribute('wrapYOffset', (BUFF_SIZE + cfg.buffs.spacing + 16))
    if (cfg.buffs.hgrowth == "Left") then
      Buffs:SetAttribute('point', "BOTTOMRIGHT")
    else
      Buffs:SetAttribute('point', "BOTTOMLEFT")
    end
  else
    Buffs:SetAttribute('wrapYOffset', - (BUFF_SIZE + cfg.buffs.spacing + 16))
  end
  setChildrenSize(Buffs, BUFF_SIZE)

  local debuff_rows   = math.ceil(10/cfg.debuffs.rowlength)
  local debuff_width  = (DEBUFF_SIZE + cfg.debuffs.spacing + 2) * cfg.debuffs.rowlength
  local debuff_height = (DEBUFF_SIZE + cfg.debuffs.spacing + 2) * debuff_rows
  Debuffs:SetSize(debuff_width, debuff_height)
  Debuffs:SetAttribute("template", ("klnDebuffsTemplate%d"):format(DEBUFF_SIZE))
  Debuffs:SetAttribute("style-width", DEBUFF_SIZE)
  Debuffs:SetAttribute("style-height", DEBUFF_SIZE)
  Debuffs:SetAttribute('wrapAfter', cfg.debuffs.rowlength)
  Debuffs:SetAttribute("minWidth", (DEBUFF_SIZE + cfg.debuffs.spacing + 2) * cfg.debuffs.rowlength)
  Debuffs:SetAttribute("minHeight", (DEBUFF_SIZE + cfg.debuffs.spacing + 2) * debuff_rows)
  if (cfg.debuffs.hgrowth == "Left") then
    Debuffs:SetAttribute('xOffset', - (DEBUFF_SIZE + cfg.debuffs.spacing + 2))
    Debuffs:SetAttribute('sortDirection', "-")
    Debuffs:SetAttribute('point', "TOPRIGHT")
  else
    Debuffs:SetAttribute('xOffset', (DEBUFF_SIZE + cfg.debuffs.spacing + 2))
    Debuffs:SetAttribute('sortDirection', "+")
    Debuffs:SetAttribute('point', "TOPLEFT")
  end
  if (cfg.debuffs.vgrowth == "Upwards") then
    Debuffs:SetAttribute('wrapYOffset', (DEBUFF_SIZE + cfg.debuffs.spacing + 16))
    if (cfg.debuffs.hgrowth == "Left") then
      Debuffs:SetAttribute('point', "BOTTOMRIGHT")
    else
      Debuffs:SetAttribute('point', "BOTTOMLEFT")
    end
  else
    Debuffs:SetAttribute('wrapYOffset', - (DEBUFF_SIZE + cfg.debuffs.spacing + 16))
  end
  setChildrenSize(Debuffs,DEBUFF_SIZE)
  Debuffs:EnableMouse(0)
  Debuffs:SetAttribute('enableMouse', 0)
end


local function UpdateTime(self, elapsed)
  if self.expiration then
    self.expiration = math.max(self.expiration - elapsed, 0)
    local seconds = self.expiration

    if self.expiration <= 0 then
      self.duration:SetText('')
    else
      local secs  = tonumber(math.floor(seconds))
      local mins  = tonumber(math.floor(seconds/60));
      local hours = tonumber(kln.round(mins/60,1));

      if (hours and hours > 1) then
        self.duration:SetText(hours.."h")
      elseif (mins and mins > 0) then
        self.duration:SetText(mins.."m")
      else      
        self.duration:SetText(secs.."s")
      end    
    end
  end
end


local function UpdateAura(self, index, filter)
  local unit = self:GetParent():GetAttribute('unit')
  local filter = self:GetParent():GetAttribute('filter')
  local name, texture, count, debuffType, duration, expiration,
    caster, isStealable, nameplateShowSelf, spellID, canApply,
    isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod,
    effect1, effect2, effect3 = UnitAura(unit, index, filter)
  if name then
    if filter == 'HARMFUL' and debuff_blacklist[name] then
      self:SetSize(0,0);
    end

    if filter == 'HELPFUL' and buff_blacklist[name] then
      self:SetSize(0,0);
    end

    self.texture:SetTexture(texture)

    if not count then
      count = 0
    end
    self.count:SetText(count > 1 and count or '')

    self.expiration = expiration - GetTime()
  end
end


local function OnAttributeChanged(self, attribute, value)
  if attribute == 'index' then
    UpdateAura(self, value)
  end
end


local function InitiateAura(self, name, button)
  if not string.match(name, '^child') then return end
  local filter = button:GetParent():GetAttribute("filter")
  
  button.filter = filter
  button:SetScript('OnUpdate', UpdateTime)
  button:SetScript('OnAttributeChanged', OnAttributeChanged)
  
  klnCore.frames.setBackdrop(button)
  
  if filter == "HARMFUL" then
    button.border:SetVertexColor(.7,0,0,1)
  end
  
  if not button.texture then
    button.texture = button:CreateTexture(nil, 'BORDER')
    button.texture:SetAllPoints()
    button.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end

  if not button.count then
    button.count = button:CreateFontString()
    button.count:SetPoint('BOTTOMRIGHT', -2, 2)
    button.count:SetFont(FONT, 14, "OUTLINE")
    button.count:SetJustifyH("LEFT")
  end

  if not button.duration then
    button.duration = button:CreateFontString()
    button.duration:SetPoint('TOP', button, "BOTTOM", 0, -4)
    button.duration:SetFont(FONT, 14, "OUTLINE")
    button.duration:SetJustifyH("CENTER")
  end
  
  UpdateAura(button, button:GetID(), filter)
end


-- Set secure header attributes
local function setHeaderAttributes(header, template, isBuff)
  local s = function(...) header:SetAttribute(...) end
  header.filter = isBuff and "HELPFUL" or "HARMFUL"
  
  if isBuff then
    header:SetAttribute('includeWeapons', 1)
    header:SetAttribute('weaponTemplate', "klnBuffsTemplate")
  end
  
  s('unit', 'player')
  s("filter", header.filter)
  s("separateOwn", 0)
  s('sortMethod', 'TIME')
  header:HookScript("OnAttributeChanged", InitiateAura)

  header:Show()
end


-- Make the spice flow!
ns.addon:RegisterEvent("PLAYER_REGEN_ENABLED")
ns.addon:RegisterEvent("ADDON_LOADED")
ns.addon:SetScript("OnEvent",function(self,event,name)
  if event == "ADDON_LOADED" then
    if name ~= 'klnBuffs' then return end
    self:UnregisterEvent(event)

    setHeaderAttributes(Buffs,"klnBuffsTemplate",true)
    setHeaderAttributes(Debuffs,"klnDebuffsTemplate",false)
    
    BuffFrame:UnregisterEvent("UNIT_AURA")

    ns.addon:UpdatePlayerAuraFrame()

    local toggle = function(f) f.Show = f.Hide; f:Hide() end
    toggle(BuffFrame)
    toggle(TemporaryEnchantFrame)
    
    -- Show who casts each buff
    hooksecurefunc(GameTooltip, "SetUnitAura", function(self, unit, index, filter)
      local caster = select(7, UnitAura(unit, index, filter))
      local name = caster and UnitName(caster)
      if name then
        self:AddDoubleLine("Cast by:", name, nil, nil, nil, 1, 1, 1)
        self:Show()
      end
    end)
    
    -- Clean up
    setHeaderAttributes = nil
    collectgarbage("collect")
  else
    ns.addon:UpdatePlayerAuraFrame()
  end
end)
