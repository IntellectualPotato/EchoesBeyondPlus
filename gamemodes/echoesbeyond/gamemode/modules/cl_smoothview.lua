
-- Smoothens the player's view
CreateClientConVar("echoes_smoothview", "1")

local curView

hook.Add("CalcView", "smoothview_CalcView", function(client, origin, angles, fov, zNear, zFar)
	local smoothView = EchoesSettings["echoes_smoothview"]
	if (not smoothView) then return end

	curView = curView and LerpAngle(math.Clamp(FrameTime() * 10, 0, 1), curView, angles) or angles

	return {angles = curView}
end)
