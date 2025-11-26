local meta = FindMetaTable("Player")
local pocket = {}
local frame
local reload

local inventoryConfig = DUBZ_INVENTORY and DUBZ_INVENTORY.Config or {}
local colors = {
    background = inventoryConfig.ColorBackground or Color(10, 10, 10, 230),
    header      = inventoryConfig.ColorAccent or Color(25, 178, 208),
    panel       = inventoryConfig.ColorPanel or Color(24, 28, 38),
    text        = inventoryConfig.ColorText or Color(230, 234, 242),
    muted       = Color(180, 190, 205)
}

surface.CreateFont("DubzPocket_Title", {
    font = "Roboto",
    size = 26,
    weight = 800,
})

surface.CreateFont("DubzPocket_Text", {
    font = "Roboto",
    size = 20,
    weight = 600,
})

surface.CreateFont("DubzPocket_Small", {
    font = "Roboto",
    size = 16,
    weight = 500,
})

--[[---------------------------------------------------------------------------
Stubs
---------------------------------------------------------------------------]]
DarkRP.stub{
    name = "openPocketMenu",
    description = "Open the DarkRP pocket menu.",
    realm = "Client",
    parameters = {
    },
    returns = {
    },
    metatable = DarkRP
}

--[[---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------]]
function meta:getPocketItems()
    if self ~= LocalPlayer() then return nil end

    return pocket
end

local function buildCloseButton(parent)
    local btn = vgui.Create("DButton", parent)
    btn:SetSize(36, 36)
    btn:SetText("✕")
    btn:SetFont("DubzPocket_Text")
    btn:SetTextColor(colors.text)

    btn.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 160))
    end

    btn.DoClick = function()
        parent:Close()
    end

    return btn
end

local function buildEmptyState(container)
    local msg = vgui.Create("DLabel", container)
    msg:Dock(TOP)
    msg:SetTall(120)
    msg:DockMargin(0, 40, 0, 0)
    msg:SetTextColor(colors.muted)
    msg:SetFont("DubzPocket_Text")
    msg:SetContentAlignment(5)
    msg:SetText("Your pocket is empty.")
    return msg
end

local function buildPocketItem(list, index, data)
    local itemPanel = list:Add("DPanel")
    itemPanel:Dock(TOP)
    itemPanel:DockMargin(0, 0, 0, 8)
    itemPanel:SetTall(72)

    itemPanel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, colors.panel)
    end

    local icon = vgui.Create("SpawnIcon", itemPanel)
    icon:SetSize(64, 64)
    icon:SetModel(data.model)
    icon:SetTooltip(false)
    icon:Dock(LEFT)
    icon:DockMargin(4, 4, 8, 4)

    local label = vgui.Create("DLabel", itemPanel)
    label:Dock(TOP)
    label:DockMargin(0, 8, 8, 0)
    label:SetTall(22)
    label:SetFont("DubzPocket_Text")
    label:SetTextColor(colors.text)
    label:SetText(string.upper(data.class or ""))

    local hint = vgui.Create("DLabel", itemPanel)
    hint:Dock(TOP)
    hint:DockMargin(0, 0, 8, 0)
    hint:SetTall(18)
    hint:SetFont("DubzPocket_Small")
    hint:SetTextColor(colors.muted)
    hint:SetText("Take this item out of your pocket")

    local btn = vgui.Create("DButton", itemPanel)
    btn:Dock(BOTTOM)
    btn:DockMargin(0, 6, 8, 8)
    btn:SetTall(26)
    btn:SetText("Take Out")
    btn:SetFont("DubzPocket_Small")
    btn:SetTextColor(colors.text)

    btn.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, colors.header)
    end

    btn.DoClick = function()
        net.Start("DarkRP_spawnPocket")
            net.WriteFloat(index)
        net.SendToServer()
        pocket[index] = nil
        reload()
    end

    return itemPanel
end

function DarkRP.openPocketMenu()
    if IsValid(frame) and frame:IsVisible() then return end
    local wep = LocalPlayer():GetActiveWeapon()
    if not IsValid(wep) or (wep:GetClass() ~= "pocket" and wep:GetClass() ~= "dubz_pocket") then return end

    if not pocket then
        pocket = {}
        return
    end

    frame = vgui.Create("DFrame")
    frame:SetSize(460, 520)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("")
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, colors.background)
        draw.RoundedBox(8, 0, 0, w, 52, colors.header)
        draw.SimpleText("POCKET INVENTORY", "DubzPocket_Title", 16, 12, colors.text)
    end

    local closeBtn = buildCloseButton(frame)
    closeBtn:SetPos(frame:GetWide() - 44, 8)

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(12, 60, 12, 12)

    local sbar = scroll:GetVBar()
    function sbar:Paint(w, h) end
    function sbar.btnUp:Paint(w, h) end
    function sbar.btnDown:Paint(w, h) end
    function sbar.btnGrip:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, colors.header)
    end

    frame.List = vgui.Create("DIconLayout", scroll)
    frame.List:Dock(TOP)
    frame.List:SetSpaceY(4)
    frame.List:SetSpaceX(0)

    reload()
end
net.Receive("DarkRP_PocketMenu", DarkRP.openPocketMenu)

--[[---------------------------------------------------------------------------
UI
---------------------------------------------------------------------------]]
function reload()
    if not IsValid(frame) or not frame:IsVisible() then return end
    frame.List:Clear()

    local itemCount = table.Count(pocket or {})
    if itemCount == 0 then
        buildEmptyState(frame.List)
        return
    end

    for index, data in pairs(pocket) do
        buildPocketItem(frame.List, index, data)
    end
end

local function retrievePocket()
    pocket = net.ReadTable()
    reload()
end
net.Receive("DarkRP_Pocket", retrievePocket)
