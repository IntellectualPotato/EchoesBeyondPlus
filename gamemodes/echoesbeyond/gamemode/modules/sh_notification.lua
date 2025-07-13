function EchoNotify(client, text) end

if (SERVER) then
	util.AddNetworkString("echoNotify")

	function EchoNotify(client, text)
		net.Start("echoNotify")
			net.WriteString(text)
		net.Send(client)
	end
else
	local activeNotifications = {}
	local soundDebounce = false

	local NOTIF_HEIGHT = 50
	local NOTIF_SPACING = 5
	local NOTIF_Y_START = 25
	local NOTIF_LIFETIME = 7
	local NOTIF_ANIM_SPEED = 0.3
	local MAX_NOTIFICATIONS = 5

	local function UpdateNotificationPositions()
		local targetY = NOTIF_Y_START

		for i, panel in ipairs(activeNotifications) do
			if IsValid(panel) then
				panel:MoveTo(panel:GetX(), targetY, NOTIF_ANIM_SPEED, 0, -1)
				targetY = targetY + NOTIF_HEIGHT + NOTIF_SPACING
			end
		end
	end


	local PANEL = {}

	function PANEL:Init()
		self:SetSize(ScrW() * 0.5, NOTIF_HEIGHT)
		self:CenterHorizontal()
		self:SetY(-self:GetTall())
		self:SetAlpha(0)
	end

	function PANEL:Setup(text)
		self:AlphaTo(255, NOTIF_ANIM_SPEED)

		local label = vgui.Create("DLabel", self)
		label:SetFont("HudDefault")
		label:SetText(text)
		label:SetColor(color_white)
		label:SizeToContents()
		label:Center()
	end

	function PANEL:RemoveSelf()
		table.RemoveByValue(activeNotifications, self)
		UpdateNotificationPositions()
		self:MoveTo(self:GetX(), -self:GetTall(), NOTIF_ANIM_SPEED, 0, -1)
		self:AlphaTo(0, NOTIF_ANIM_SPEED, 0, function()
			self:Remove()
		end)
	end

	local notifMaterial = Material("echoesbeyond/notification.png")

	function PANEL:Paint(width, height)
		surface.SetDrawColor(25, 25, 25, self:GetAlpha())
		surface.SetMaterial(notifMaterial)
		surface.DrawTexturedRect(0, 0, width, height)
	end

	vgui.Register("echoNotification", PANEL, "DPanel")

	function EchoNotify(text)
		if #activeNotifications >= MAX_NOTIFICATIONS then
			local oldestPanel = activeNotifications[1]
			if IsValid(oldestPanel) then
				oldestPanel:RemoveSelf()
			else
				table.remove(activeNotifications, 1)
			end
		end

		local notifPanel = vgui.Create("echoNotification")
		notifPanel:Setup(text)

		table.insert(activeNotifications, notifPanel)
		UpdateNotificationPositions()

		if not soundDebounce then
			soundDebounce = true
			EchoSound("notification")
			timer.Simple(0, function()
				soundDebounce = false
			end)
		end

		timer.Simple(NOTIF_LIFETIME, function()
			if IsValid(notifPanel) then
				notifPanel:RemoveSelf()
			end
		end)
	end

	net.Receive("echoNotify", function()
		EchoNotify(net.ReadString())
	end)
end