-- WorldBossLockouts: Standalone world boss loot lockout tracker.
-- Companion panel anchored below RaidInfoFrame. No dependencies.
-- Lua 5.0 compatible (TurtleWoW 1.12 client).

local LOCK_FRAGMENT = "locked out from receiving loot from"

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
local DRAGON_RESPAWN      = "Timer starts only after all four dragons are dead."

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
    if not string.find( msg, LOCK_FRAGMENT ) then return end
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

    -- Natural respawn
    GameTooltip:AddLine( " " )
    if b.noRespawn then
        GameTooltip:AddLine( "Natural spawn: Summonable only.", 0.6, 0.6, 0.6 )
    elseif b.dragonGroup then
        GameTooltip:AddLine( "Natural respawn: ~" .. b.respawn .. " (" .. DRAGON_RESPAWN .. ")", 0.6, 0.6, 0.6 )
    elseif b.respawnExact then
        GameTooltip:AddLine( "Natural respawn: " .. b.respawn, 0.6, 0.6, 0.6 )
    else
        GameTooltip:AddLine( "Natural respawn: ~" .. b.respawn, 0.6, 0.6, 0.6 )
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
        -- Ostarius: questline, no numeric item ID
        GameTooltip:AddLine( "Summoning: " .. b.summonItem, 0.9, 0.8, 0.4 )
        if b.summonFrom then
            GameTooltip:AddLine( "From: " .. b.summonFrom, 0.75, 0.75, 0.75 )
        end
        if b.summonQuest then
            GameTooltip:AddLine( "Quest: " .. b.summonQuest, 0.65, 0.65, 0.65 )
        end
    elseif b.summonQuest then
        -- Moo: no item, just access note
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
