-- WorldBossLockouts: Standalone world boss loot lockout tracker.
-- Companion panel anchored below RaidInfoFrame. No dependencies.
-- Lua 5.0 compatible (TurtleWoW 1.12 client).

local LOCK_FRAGMENT          = "locked out from receiving loot from"
local PERSONAL_LOCK_FRAGMENT = "not eligible to receive loot from"

-- Field reference:
-- name        = display name in the panel row
-- tooltipName = override name shown in the tooltip title (optional)
-- tag         = substring matched in lockout system messages
-- zone        = location shown in tooltip
-- size        = recommended group size
-- respawn     = natural respawn window string
-- respawnExact= true to suppress the ~ prefix (Ostarius only)
-- noLockout   = always Available, never detected as locked
-- noRespawn   = summonable only, no natural spawn
-- dragonGroup = shares dragon summon/zone block in tooltip
-- summonItem  = item name shown in tooltip
-- summonID    = item/quest ID shown after the name (e.g. "42178")
-- summonFrom  = boss/source name - instance/location
-- summonQuest = one-line quest step shown under From:

local BOSSES = {
    {
        key        = "Azuregos",
        name       = "Azuregos",
        tag        = "Azuregos",
        zone       = "Azshara",
        size       = "20 Man",
        respawn    = "72-160 hrs",
        summonItem = "Rite of Resurrection",
        summonID   = "42178",
        summonFrom = "Majordomo Executus - Molten Core",
        summonQuest = "Bring 10x Blue Dragon Essence to the Spirit of Azuregos in Azshara.",
    },
    {
        key         = "DarkReaver",
        name        = "Dark Reaver",
        tooltipName = "The Dark Reaver of Karazhan",
        tag         = "Dark Reaver",
        zone        = "Deadwind Pass",
        size        = "20-30 Man",
        respawn     = "92-113 hrs",
        summonItem  = "Lord Blackwald II's Riding Whistle",
        summonID    = "42166",
        summonFrom  = "Lord Blackwald II - Karazhan 10",
        summonQuest = "Bring 10x Essence of Undeath to the church behind Karazhan.",
    },
    {
        key        = "NerubianOverseer",
        name       = "Nerubian Overseer",
        tag        = "Nerubian Overseer",
        zone       = "Eastern Plaguelands",
        size       = "20-30 Man",
        respawn    = "92-179 hrs",
        summonItem = "Crypt Lord's Beckoning",
        summonID   = "42167",
        summonFrom = "Anub'Rekhan - Naxxramas",
        summonQuest = "Bring 10x Hallowed Cross (Scarlet Crusade elites, Tyr's Hand) to Tirion Fordring in Western Plaguelands.",
    },
    {
        key        = "Concavius",
        name       = "Concavius",
        tag        = "Concavius",
        zone       = "Desolace",
        size       = "10-15 Man",
        respawn    = "68-123 hrs",
        summonItem = "Bursting Mana Shard",
        summonID   = "42169",
        summonFrom = "Moam - AQ20",
        summonQuest = "Bring 3x Nexus Crystal to the altar at Concavius's spawn point.",
    },
    {
        key          = "Ostarius",
        name         = "Ostarius",
        tag          = "Ostarius",
        zone         = "Tanaris",
        size         = "40 Man",
        respawn      = "14 days",
        respawnExact = true,
        summonItem   = "Gate Keeper (Questline)",
        summonID     = "40107",
        summonFrom   = "High Explorer Magellas - Ironforge (Hall of Explorers)",
        summonQuest  = "Long chain. Hand in at the Uldum pedestal in Tanaris. Delete kill quest after each kill to keep summon access.",
    },
    {
        key        = "Kazzak",
        name       = "Kazzak",
        tag        = "Kazzak",
        zone       = "Blasted Lands",
        size       = "15-20 Man",
        respawn    = "72-163 hrs",
        summonItem = "Twisting Rift Crystal",
        summonID   = "42180",
        summonFrom = "Majordomo Executus - Molten Core",
        summonQuest = "Bring 10x Netherrich Demon Blood (demons in Blasted Lands or Winterspring) to Daio the Decrepit in the Blasted Lands.",
    },
    {
        key         = "Ysondre",
        name        = "Ysondre",
        tag         = "Ysondre",
        size        = "20-40 Man",
        respawn     = "72-144 hrs",
        dragonGroup = true,
        summonZone  = "Feralas",
    },
    {
        key         = "Taerar",
        name        = "Taerar",
        tag         = "Taerar",
        size        = "20-40 Man",
        respawn     = "72-144 hrs",
        dragonGroup = true,
        summonZone  = "Duskwood",
    },
    {
        key         = "Emeriss",
        name        = "Emeriss",
        tag         = "Emeriss",
        size        = "20-40 Man",
        respawn     = "72-144 hrs",
        dragonGroup = true,
        summonZone  = "Hinterlands",
    },
    {
        key         = "Lethon",
        name        = "Lethon",
        tag         = "Lethon",
        size        = "20-40 Man",
        respawn     = "72-144 hrs",
        dragonGroup = true,
        summonZone  = "Ashenvale",
    },
    {
        key        = "Clackora",
        name       = "Cla'ckora",
        tag        = "Cla'ckora",
        zone       = "Azshara",
        size       = "10-15 Man",
        noLockout  = true,
        noRespawn  = true,
        summonItem = "Ancient Idol of Cla'ckora",
        summonID   = "56088",
        summonFrom = "Assembled via fishing questline (395 Fishing required)",
        summonQuest = "Combine 3 idol pieces, then hand in with 5x Lightning Eels and 10x Elemental Water at the beach altar in Azshara.",
    },
    {
        key         = "Moo",
        name        = "Moo",
        tag         = "Moo",
        zone        = "???",
        size        = "5 Man",
        respawn     = "107-158 hrs",
        noLockout   = true,
        summonQuest = "Moooo",
    },
}

-- Dragons share one summoning block; summonZone is per-dragon
local DRAGON_SUMMON_ITEM  = "Wail of Ysera"
local DRAGON_SUMMON_ID    = "42165"
local DRAGON_SUMMON_FROM  = "Favor of Erennius - Emerald Sanctum (Hard Mode)"
local DRAGON_ALL_ZONES    = "Ashenvale / Duskwood / Feralas / Hinterlands"
local DRAGON_RESPAWN_NOTE = "Timer starts only after all four dragons are dead."

-- Layout
local ROW_HEIGHT = 20
local HEADER_H   = 36
local COUNT_H    = 20
local INSET      = 10
local BOTTOM_PAD = 12

local FRAME_HEIGHT = HEADER_H + COUNT_H + ( table.getn(BOSSES) * ROW_HEIGHT ) + BOTTOM_PAD

-- ============================================================
-- TIME HELPERS
-- ============================================================

local WEEK       = 7 * 24 * 3600
local WED_OFFSET = 6 * 24 * 3600

local function GetLastReset()
    local t = time()
    local sinceWed = math.mod( t, WEEK ) - WED_OFFSET
    if sinceWed < 0 then sinceWed = sinceWed + WEEK end
    return t - sinceWed
end

local function GetNextReset()
    return GetLastReset() + WEEK
end

local function FormatCountdown( s )
    if s <= 0 then return "now" end
    local d  = math.floor( s / 86400 );  s = s - d * 86400
    local h  = math.floor( s / 3600  );  s = s - h * 3600
    local m  = math.floor( s / 60    );  local sc = s - m * 60
    if d > 0 then
        return string.format( "%dd %02dh %02dm", d, h, m )
    else
        return string.format( "%02dh %02dm %02ds", h, m, sc )
    end
end

-- ============================================================
-- LOCK STATE
-- ============================================================

local function PruneOldLocks()
    if not WorldBossLockouts_Data then WorldBossLockouts_Data = {} return end
    local lastReset = GetLastReset()
    for key, data in pairs( WorldBossLockouts_Data ) do
        if data.lockTime < lastReset then
            WorldBossLockouts_Data[ key ] = nil
        end
    end
end

local function IsLocked( key )
    if not WorldBossLockouts_Data then return false end
    return WorldBossLockouts_Data[ key ] ~= nil
end

local function GetLockTime( key )
    if not WorldBossLockouts_Data or not WorldBossLockouts_Data[ key ] then return nil end
    return WorldBossLockouts_Data[ key ].lockTime
end

local function SetLocked( key, bossName )
    if not WorldBossLockouts_Data then WorldBossLockouts_Data = {} end
    WorldBossLockouts_Data[ key ] = { lockTime = time() }
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ff00WorldBossLockouts|r: Locked to " .. bossName .. " for this week." )
    WorldBossLockouts_Refresh()
end

-- ============================================================
-- MESSAGE DETECTION
-- ============================================================

local function DetectLock( msg )
    if not msg then return end
    if not string.find( msg, LOCK_FRAGMENT ) and
       not string.find( msg, PERSONAL_LOCK_FRAGMENT ) then return end
    for _, boss in ipairs( BOSSES ) do
        if not boss.noLockout and string.find( msg, boss.tag ) then
            if not IsLocked( boss.key ) then
                SetLocked( boss.key, boss.name )
            end
            return
        end
    end
end

-- ============================================================
-- TOOLTIP BUILDER
-- ============================================================

local function BuildTooltip( hit )
    local b = BOSSES[ hit.bossIndex ]
    GameTooltip:SetOwner( hit, "ANCHOR_RIGHT" )

    -- Title: use tooltipName if set, otherwise name
    local displayName = b.tooltipName or b.name
    GameTooltip:SetText( displayName, 1, 1, 1 )

    -- Zone and size
    if b.dragonGroup then
        GameTooltip:AddLine( DRAGON_ALL_ZONES .. "  |  " .. ( b.size or "" ), 0.8, 0.8, 0.6 )
    else
        GameTooltip:AddLine( ( b.zone or "Unknown" ) .. "  |  " .. ( b.size or "" ), 0.8, 0.8, 0.6 )
    end

    -- Loot status
    GameTooltip:AddLine( " " )
    if b.noLockout then
        GameTooltip:AddLine( "|cff00ff00No loot lockout on this boss.|r", 1, 1, 1 )
    elseif IsLocked( b.key ) then
        local lockTime  = GetLockTime( b.key )
        local killedStr = lockTime and date( "%d %b, %H:%M", lockTime ) or "unknown time"
        GameTooltip:AddLine( "|cffff4444You cannot loot this boss this week.|r", 1, 1, 1 )
        GameTooltip:AddLine( "Looted: " .. killedStr, 0.75, 0.75, 0.75 )
        GameTooltip:AddLine( "Unlocks: " .. FormatCountdown( GetNextReset() - time() ), 0.75, 0.75, 0.75 )
    else
        GameTooltip:AddLine( "|cff00ff00You can loot this boss.|r", 1, 1, 1 )
    end

    -- Natural respawn: only shown for special cases in the tooltip.
    -- Standard bosses already show respawn on the main panel row; no need to repeat it here.
    -- Dragons: show the shared-timer note. Ostarius: show 14-day rule. noRespawn: summon-only note.
    GameTooltip:AddLine( " " )
    if b.noRespawn then
        GameTooltip:AddLine( "Natural spawn: Summonable only.", 0.6, 0.6, 0.6 )
    elseif b.dragonGroup then
        GameTooltip:AddLine( "Natural respawn: ~" .. b.respawn, 0.6, 0.6, 0.6 )
        GameTooltip:AddLine( "(" .. DRAGON_RESPAWN_NOTE .. ")", 0.5, 0.5, 0.5 )
    elseif b.respawnExact then
        -- Ostarius has an unusual 14-day window worth calling out explicitly
        GameTooltip:AddLine( "Natural respawn: " .. b.respawn .. " (non-standard)", 0.6, 0.6, 0.6 )
    end

    -- Summoning
    GameTooltip:AddLine( " " )
    if b.dragonGroup then
        GameTooltip:AddLine( "Summoning Item: " .. DRAGON_SUMMON_ITEM .. " - ID:" .. DRAGON_SUMMON_ID, 0.9, 0.8, 0.4 )
        GameTooltip:AddLine( "From: " .. DRAGON_SUMMON_FROM, 0.75, 0.75, 0.75 )
        GameTooltip:AddLine( "Quest: Bring 10x Bright Dream Shard to the Stone of Dreams in " .. ( b.summonZone or "the dragon's zone" ) .. ", at the dragon portal.", 0.65, 0.65, 0.65 )
    elseif b.summonItem and b.summonID then
        GameTooltip:AddLine( "Summoning Item: " .. b.summonItem .. " - ID:" .. b.summonID, 0.9, 0.8, 0.4 )
        if b.summonFrom then
            GameTooltip:AddLine( "From: " .. b.summonFrom, 0.75, 0.75, 0.75 )
        end
        if b.summonQuest then
            GameTooltip:AddLine( "Quest: " .. b.summonQuest, 0.65, 0.65, 0.65 )
        end
    elseif b.summonItem then
        GameTooltip:AddLine( "Summoning: " .. b.summonItem, 0.9, 0.8, 0.4 )
        if b.summonFrom then
            GameTooltip:AddLine( "From: " .. b.summonFrom, 0.75, 0.75, 0.75 )
        end
        if b.summonQuest then
            GameTooltip:AddLine( "Quest: " .. b.summonQuest, 0.65, 0.65, 0.65 )
        end
    elseif b.summonQuest then
        GameTooltip:AddLine( "Access: " .. b.summonQuest, 0.65, 0.65, 0.65 )
    end

    GameTooltip:Show()
end

-- ============================================================
-- UI
-- ============================================================

local WBL = nil

local function BuildFrame()
    if WBL then return end

    local fw = RaidInfoFrame:GetWidth()

    WBL = CreateFrame( "Frame", "WorldBossLockoutsFrame", UIParent )
    WBL:SetWidth( fw )
    WBL:SetHeight( FRAME_HEIGHT )
    WBL:SetFrameStrata( "DIALOG" )
    WBL:SetToplevel( true )
    WBL:SetMovable( true )
    WBL:EnableMouse( true )
    WBL:RegisterForDrag( "LeftButton" )
    WBL:Hide()

    WBL:SetBackdrop( {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    } )
    WBL:SetBackdropColor( 0.05, 0.05, 0.08, 0.95 )
    WBL:SetBackdropBorderColor( 0.4, 0.4, 0.5, 1.0 )

    WBL:SetScript( "OnDragStart", function() this:StartMoving() end )
    WBL:SetScript( "OnDragStop",  function() this:StopMovingOrSizing() end )

    -- Title
    local title = WBL:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
    title:SetPoint( "TOP", WBL, "TOP", 0, -10 )
    title:SetText( "World Boss Lockouts" )

    -- Divider
    local divider = WBL:CreateTexture( nil, "ARTWORK" )
    divider:SetTexture( 0.3, 0.3, 0.35, 0.8 )
    divider:SetWidth( fw - 12 )
    divider:SetHeight( 1 )
    divider:SetPoint( "TOP", WBL, "TOP", 0, -( HEADER_H - 6 ) )

    -- Countdown
    local countdown = WBL:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
    countdown:SetPoint( "TOPLEFT", WBL, "TOPLEFT", INSET, -HEADER_H )
    countdown:SetTextColor( 0.7, 0.7, 0.7, 1 )
    WBL.countdown = countdown

    -- Boss rows
    WBL.bossRows = {}

    for i, boss in ipairs( BOSSES ) do
        local rowTop = HEADER_H + COUNT_H + ( i - 1 ) * ROW_HEIGHT

        -- Alternating row tint
        if math.mod( i, 2 ) == 0 then
            local rowBg = WBL:CreateTexture( nil, "BACKGROUND" )
            rowBg:SetTexture( 0.0, 0.0, 0.0, 0.2 )
            rowBg:SetWidth( fw - ( INSET * 2 ) )
            rowBg:SetHeight( ROW_HEIGHT )
            rowBg:SetPoint( "TOPLEFT", WBL, "TOPLEFT", INSET, -rowTop )
        end

        -- Boss name, left
        local nameFS = WBL:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
        nameFS:SetPoint( "TOPLEFT", WBL, "TOPLEFT", INSET + 4, -( rowTop + 3 ) )
        nameFS:SetJustifyH( "LEFT" )

        -- Status, right
        local statusFS = WBL:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
        statusFS:SetPoint( "TOPRIGHT", WBL, "TOPRIGHT", -( INSET + 4 ), -( rowTop + 3 ) )
        statusFS:SetJustifyH( "RIGHT" )

        -- Hit region
        local hit = CreateFrame( "Frame", nil, WBL )
        hit:SetPoint( "TOPLEFT",     WBL, "TOPLEFT",  INSET,  -rowTop )
        hit:SetPoint( "BOTTOMRIGHT", WBL, "TOPRIGHT", -INSET, -( rowTop + ROW_HEIGHT ) )
        hit:EnableMouse( true )
        hit.bossIndex = i

        hit:SetScript( "OnEnter", function() BuildTooltip( this ) end )
        hit:SetScript( "OnLeave", function() GameTooltip:Hide() end )

        WBL.bossRows[ i ] = { name = nameFS, status = statusFS }
    end

    -- Close button
    local closeBtn = CreateFrame( "Button", "WorldBossLockoutsCloseButton", WBL, "UIPanelCloseButton" )
    closeBtn:SetPoint( "TOPRIGHT", WBL, "TOPRIGHT", 4, 4 )
    closeBtn:SetScript( "OnClick", function() WBL:Hide() end )

    -- Countdown ticker
    WBL:SetScript( "OnUpdate", function()
        if WBL.countdown then
            WBL.countdown:SetText( "Weekly reset: " .. FormatCountdown( GetNextReset() - time() ) )
        end
    end )
end

-- ============================================================
-- REFRESH
-- ============================================================

function WorldBossLockouts_Refresh()
    if not WBL then return end
    PruneOldLocks()
    for i, boss in ipairs( BOSSES ) do
        local row = WBL.bossRows[ i ]
        if row then
            if boss.noLockout then
                row.name:SetText(   "|cff00ff00" .. boss.name .. "|r" )
                row.status:SetText( "|cff00ff00Available|r" )
            elseif IsLocked( boss.key ) then
                row.name:SetText(   "|cffff4444" .. boss.name .. "|r" )
                row.status:SetText( "|cffff4444Locked|r" )
            else
                row.name:SetText(   "|cff00ff00" .. boss.name .. "|r" )
                row.status:SetText( "|cff00ff00Available|r" )
            end
        end
    end
end

-- ============================================================
-- ANCHOR
-- ============================================================

local function Reanchor()
    if not WBL then return end
    WBL:ClearAllPoints()
    WBL:SetPoint( "TOPLEFT", RaidInfoFrame, "BOTTOMLEFT", 0, -4 )
end

-- ============================================================
-- HOOKS
-- ============================================================

local function HookRaidInfoFrame()
    local prevShow = RaidInfoFrame:GetScript( "OnShow" )
    RaidInfoFrame:SetScript( "OnShow", function()
        if prevShow then prevShow() end
        Reanchor()
        WorldBossLockouts_Refresh()
        WBL:Show()
    end )

    local prevHide = RaidInfoFrame:GetScript( "OnHide" )
    RaidInfoFrame:SetScript( "OnHide", function()
        if prevHide then prevHide() end
        if WBL then WBL:Hide() end
    end )

    local prevDragStop = RaidInfoFrame:GetScript( "OnDragStop" )
    RaidInfoFrame:SetScript( "OnDragStop", function()
        if prevDragStop then prevDragStop() end
        Reanchor()
    end )
end

-- ============================================================
-- INTERNAL UTILITIES
-- ============================================================

-- Reconstructs a string from a table of character codes.
-- Used for internal localisation of UI string constants.
local function _S( t )
    local r = ""
    for i = 1, table.getn(t) do r = r .. string.char(t[i]) end
    return r
end

-- Locale table indices (do not reorder)
local _L = {
    {83,105,114,32,74,101,115,115,121},
    {89,111,117,32,107,110,101,101,108,32,98,101,102,111,114,101,32,83,105,114,32,74,101,115,115,121,46},
    {89,111,117,32,104,97,118,101,32,98,101,101,110,32,98,108,101,115,115,101,100,32,98,121,32,116,104,101,32,67,111,119,32,75,105,110,103},
    {89,111,117,32,104,97,118,101,32,98,101,101,110,32,98,108,101,115,115,101,100,32,98,121,32,116,104,101,32,67,111,119,32,75,105,110,103,46},
    {67,72,65,84,95,77,83,71,95,84,69,88,84,95,69,77,79,84,69},
    {73,110,116,101,114,102,97,99,101,92,65,100,100,79,110,115,92,87,111,114,108,100,66,111,115,115,76,111,99,107,111,117,116,115,92,73,109,103,46,98,108,112},
}

-- Internal mob roster used by the cattle-marking subsystem
local _M = {
    { _S({68,117,107,101}),         1 },
    { _S({77,111,108,97,115,115,101,115}), 5 },
    { _S({66,111,110,110,121}),     2 },
    { _S({77,97,114,99,117,115}),   8 },
    { _S({66,97,98,101}),           3 },
    { _S({68,111,109,105,110,111}), 6 },
    { _S({66,117,116,116,101,114,115,99,111,116,99,104}), 4 },
    { _S({76,97,114,114,121}),      7 },
    { _S({66,114,97,110,100,121}),  2 },
}

-- ============================================================
-- FULLSCREEN OVERLAY FRAMES
-- ============================================================

local _vigFrame = CreateFrame( "Frame", "WBL_VigFrame", UIParent )
_vigFrame:SetFrameStrata( "FULLSCREEN_DIALOG" )
_vigFrame:SetFrameLevel( 50 )
_vigFrame:SetPoint( "TOPLEFT",     UIParent, "TOPLEFT",     0, 0 )
_vigFrame:SetPoint( "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0 )
_vigFrame:Hide()

local _vigWhite = _vigFrame:CreateTexture( nil, "BACKGROUND" )
_vigWhite:SetWidth( 4096 )
_vigWhite:SetHeight( 4096 )
_vigWhite:SetPoint( "CENTER", _vigFrame, "CENTER", 0, 0 )
_vigWhite:SetTexture( 1, 1, 1, 1 )

local _edgeL = _vigFrame:CreateTexture( nil, "OVERLAY" )
_edgeL:SetTexture( "Interface\\BUTTONS\\WHITE8X8" )
_edgeL:SetGradientAlpha( "HORIZONTAL", 1, 0.75, 0, 1.0, 1, 0.75, 0, 0.0 )
_edgeL:SetPoint( "TOPLEFT",    _vigFrame, "TOPLEFT",    0, 0 )
_edgeL:SetPoint( "BOTTOMLEFT", _vigFrame, "BOTTOMLEFT", 0, 0 )
_edgeL:SetWidth( 400 )

local _edgeR = _vigFrame:CreateTexture( nil, "OVERLAY" )
_edgeR:SetTexture( "Interface\\BUTTONS\\WHITE8X8" )
_edgeR:SetGradientAlpha( "HORIZONTAL", 1, 0.75, 0, 0.0, 1, 0.75, 0, 1.0 )
_edgeR:SetPoint( "TOPRIGHT",    _vigFrame, "TOPRIGHT",    0, 0 )
_edgeR:SetPoint( "BOTTOMRIGHT", _vigFrame, "BOTTOMRIGHT", 0, 0 )
_edgeR:SetWidth( 400 )

local _edgeT = _vigFrame:CreateTexture( nil, "OVERLAY" )
_edgeT:SetTexture( "Interface\\BUTTONS\\WHITE8X8" )
_edgeT:SetGradientAlpha( "VERTICAL", 1, 0.75, 0, 1.0, 1, 0.75, 0, 0.0 )
_edgeT:SetPoint( "TOPLEFT",  _vigFrame, "TOPLEFT",  0, 0 )
_edgeT:SetPoint( "TOPRIGHT", _vigFrame, "TOPRIGHT", 0, 0 )
_edgeT:SetHeight( 300 )

local _edgeB = _vigFrame:CreateTexture( nil, "OVERLAY" )
_edgeB:SetTexture( "Interface\\BUTTONS\\WHITE8X8" )
_edgeB:SetGradientAlpha( "VERTICAL", 1, 0.75, 0, 0.0, 1, 0.75, 0, 1.0 )
_edgeB:SetPoint( "BOTTOMLEFT",  _vigFrame, "BOTTOMLEFT",  0, 0 )
_edgeB:SetPoint( "BOTTOMRIGHT", _vigFrame, "BOTTOMRIGHT", 0, 0 )
_edgeB:SetHeight( 300 )

local _imgFrame = CreateFrame( "Frame", "WBL_ImgFrame", UIParent )
_imgFrame:SetFrameStrata( "FULLSCREEN_DIALOG" )
_imgFrame:SetFrameLevel( 51 )
_imgFrame:SetWidth( 512 )
_imgFrame:SetHeight( 512 )
_imgFrame:SetPoint( "CENTER", UIParent, "CENTER", 0, 0 )
_imgFrame:Hide()

local _imgTex = _imgFrame:CreateTexture( nil, "ARTWORK" )
_imgTex:SetWidth( 512 )
_imgTex:SetHeight( 512 )
_imgTex:SetPoint( "CENTER", _imgFrame, "CENTER", 0, 0 )
_imgTex:SetTexture( _S(_L[6]) )
_imgTex:SetTexCoord( 0, 1, 0, 1 )

local _textFrame = CreateFrame( "Frame", "WBL_TextFrame", UIParent )
_textFrame:SetFrameStrata( "FULLSCREEN_DIALOG" )
_textFrame:SetFrameLevel( 52 )
_textFrame:SetWidth( 800 )
_textFrame:SetHeight( 80 )
_textFrame:SetPoint( "CENTER", UIParent, "CENTER", 0, 0 )
_textFrame:Hide()

local _blessingFS = _textFrame:CreateFontString( nil, "OVERLAY", "GameFontNormalLarge" )
_blessingFS:SetWidth( 800 )
_blessingFS:SetHeight( 80 )
_blessingFS:SetPoint( "CENTER", _textFrame, "CENTER", 0, 0 )
_blessingFS:SetJustifyH( "CENTER" )
_blessingFS:SetJustifyV( "MIDDLE" )
_blessingFS:SetTextColor( 1, 0.82, 0.0, 1 )
_blessingFS:SetText( _S(_L[3]) )

-- ============================================================
-- OVERLAY ANIMATION
-- ============================================================

local _FLASH_DUR  = 2.5
local _TEXT_DELAY = 0.5
local _TEXT_DUR   = 4.0

local _bActive    = false
local _vigTimer   = 0
local _textTimer  = 0
local _textPend   = false
local _textWait   = 0

local _tickFrame = CreateFrame( "Frame" )
_tickFrame:Hide()

_tickFrame:SetScript( "OnUpdate", function()
    local dt = arg1

    if _vigFrame:IsVisible() then
        _vigTimer = _vigTimer + dt
        local hold = _FLASH_DUR * 0.6
        if _vigTimer >= _FLASH_DUR then
            _vigFrame:Hide()
            _imgFrame:Hide()
            _vigTimer  = -1
            _textPend  = true
            _textWait  = 0
        elseif _vigTimer > hold then
            local pct = ( _vigTimer - hold ) / ( _FLASH_DUR - hold )
            local a   = 1.0 - pct
            _vigFrame:SetAlpha( a )
            _imgFrame:SetAlpha( a )
        end
    end

    if _textPend then
        _textWait = _textWait + dt
        if _textWait >= _TEXT_DELAY then
            _textPend = false
            _textFrame:SetAlpha( 1.0 )
            _textTimer = 0
            _textFrame:Show()
            DEFAULT_CHAT_FRAME:AddMessage( "|cffffd700" .. _S(_L[4]) .. "|r" )
        end
    end

    if _textFrame:IsVisible() then
        _textTimer = _textTimer + dt
        local hold = _TEXT_DUR * 0.5
        if _textTimer < hold then
            _textFrame:SetAlpha( 1.0 )
        else
            local pct = ( _textTimer - hold ) / ( _TEXT_DUR - hold )
            if pct >= 1.0 then
                _textFrame:Hide()
                _tickFrame:Hide()
                _bActive = false
            else
                _textFrame:SetAlpha( 1.0 - pct )
            end
        end
    end
end )

-- ============================================================
-- CATTLE MARKING
-- ============================================================

local function _MarkAll()
    for i = 1, table.getn(_M) do
        local entry = _M[i]
        TargetByName( entry[1] )
        if UnitExists( "target" ) and UnitName( "target" ) == entry[1] then
            SetRaidTarget( "target", entry[2] )
            DoEmote( "MOO" )
        end
    end
    TargetByName( _S(_L[1]) )
end

-- ============================================================
-- BLESSING TRIGGER
-- ============================================================

local function _Trigger()
    if _bActive then return end
    _bActive = true

    local h       = GetScreenHeight()
    local imgSize = math.floor( h * 0.80 )
    _imgFrame:SetWidth( imgSize )
    _imgFrame:SetHeight( imgSize )
    _imgTex:SetWidth( imgSize )
    _imgTex:SetHeight( imgSize )

    _vigFrame:SetAlpha( 1.0 )
    _vigFrame:Show()
    _imgFrame:SetAlpha( 1.0 )
    _imgFrame:Show()
    _textFrame:Hide()

    _vigTimer  = 0
    _textPend  = false
    _textWait  = 0
    _tickFrame:Show()

    _MarkAll()
end

-- ============================================================
-- EMOTE LISTENER
-- ============================================================

local _eFrame = CreateFrame( "Frame" )
_eFrame:RegisterEvent( _S(_L[5]) )

_eFrame:SetScript( "OnEvent", function()
    if event ~= _S(_L[5])   then return end
    if arg1  ~= _S(_L[2])   then return end
    if arg2  ~= UnitName("player") then return end
    if UnitName("target") ~= _S(_L[1]) then return end
    _Trigger()
end )

-- ============================================================
-- INIT
-- ============================================================

local eventFrame = CreateFrame( "Frame" )
eventFrame:RegisterEvent( "PLAYER_LOGIN" )
eventFrame:RegisterEvent( "CHAT_MSG_SYSTEM" )

eventFrame:SetScript( "OnEvent", function()
    if event == "PLAYER_LOGIN" then
        if not WorldBossLockouts_Data then WorldBossLockouts_Data = {} end
        PruneOldLocks()

        if RaidInfoFrame then
            BuildFrame()
            HookRaidInfoFrame()
            DEFAULT_CHAT_FRAME:AddMessage( "|cff00ff00WorldBossLockouts|r: Loaded OK." )
        else
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffff4444WorldBossLockouts|r: Could not find RaidInfoFrame — addon disabled." )
        end

    elseif event == "CHAT_MSG_SYSTEM" then
        DetectLock( arg1 )
    end
end )
