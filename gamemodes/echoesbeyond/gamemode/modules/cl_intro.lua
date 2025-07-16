
-- Small intro sequence
local vignette = Material("echoesbeyond/vignette.png", "smooth")
local echoMat = Material("echoesbeyond/echo_simple.png", "smooth")

hook.Add("InitPostEntity", "intro_InitPostEntity", function()
	if (file.Exists("echoesbeyond/readechoes_plus.txt", "DATA")) then return end

	local intro = vgui.Create("DPanel")
	intro:SetSize(ScrW(), ScrH())
	intro:MakePopup()
	intro:Center()
	intro:SetCursor("blank")
	intro.Paint = function(self, width, height)
		surface.SetDrawColor(25, 25, 25)
		surface.DrawRect(0, 0, width, height)

		surface.SetDrawColor(color_black)
		surface.SetMaterial(vignette)
		surface.DrawTexturedRect(0, 0, width, height)

		local breatheLayer = math.sin(CurTime() * 1.5)

		surface.SetDrawColor(255, 255, 255, 5)
		surface.SetMaterial(echoMat)
		surface.DrawTexturedRectRotated(width / 2, height / 2 + 5 * breatheLayer, height / 1.5, height / 1.5, 0)
	end

	timer.Simple(3, function()
		local text = vgui.Create("DLabel", intro)
		text:SetFont("DermaLarge")
		text:SetText("This game is connected to the internet. All echoes are shared across all players.")
		text:SizeToContents()
		text:Center()
		text:SetAlpha(0)
		text:AlphaTo(255, 0.5)

		EchoSound("whoosh", nil, 0.75)

		timer.Simple(5, function()
			text:AlphaTo(0, 0.5, 0, function()
				text:Remove()
			end)

			timer.Simple(2, function()
				text = vgui.Create("DLabel", intro)
				text:SetFont("DermaLarge")
				text:SetText("Please be respectful and considerate of others when echoing.")
				text:SizeToContents()
				text:Center()
				text:SetAlpha(0)
				text:AlphaTo(255, 0.5)

				EchoSound("whoosh", nil, 0.75)

				timer.Simple(5, function()
					text:AlphaTo(0, 0.5, 0, function()
						text:Remove()
					end)

					timer.Simple(2, function()
						text = vgui.Create("DLabel", intro)
						text:SetFont("DermaLarge")
						text:SetText("Press TAB for options, and R to echo.")
						text:SizeToContents()
						text:Center()
						text:SetAlpha(0)
						text:AlphaTo(255, 0.5)

						EchoSound("whoosh", nil, 0.75)

						timer.Simple(5, function()
							text:AlphaTo(0, 0.5, 0, function()
								text:Remove()
							end)

							timer.Simple(1, function()
								intro:SetKeyboardInputEnabled(false)
								intro:SetMouseInputEnabled(false)

								intro:AlphaTo(0, 5, 0, function()
									intro:Remove()
								end)
							end)
						end)
					end)
				end)
			end)
		end)
	end)
end)
