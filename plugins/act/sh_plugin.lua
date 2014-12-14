--[[
	NutScript is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	NutScript is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

PLUGIN.name = "Acts"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds acts that can be performed."
PLUGIN.acts = PLUGIN.acts or {}

nut.util.include("sh_setup.lua")

for k, v in pairs(PLUGIN.acts) do
	local data = {}
		local multiple = false

		for k2, v2 in pairs(v) do
			if (type(v2.sequence) == "table" and #v2.sequence > 1) then
				multiple = true

				break
			end
		end

		if (multiple) then
			data.syntax = "[number type]"
		end

		data.onRun = function(client, arguments)
			if (client.nutSeqUntimed) then
				client:setNetVar("actAng")
				client:leaveSequence()
				client.nutSeqUntimed = nil

				return
			end

			if ((client.nutNextAct or 0) < CurTime()) then
				local class = nut.anim.getModelClass(client:GetModel())
				local info = v[class]

				if (info) then
					if (info.onCheck) then
						local result = info.onCheck(client)

						if (result) then
							return result
						end
					end

					local sequence

					if (type(info.sequence) == "table") then
						local index = math.Clamp(math.floor(tonumber(arguments[1]) or 1), 1, #info.sequence)

						sequence = info.sequence[index]
					else
						sequence = info.sequence
					end

					local duration = client:forceSequence(sequence, nil, info.untimed and 0 or nil)

					client.nutSeqUntimed = info.untimed
					client.nutNextAct = CurTime() + (info.untimed and 4 or duration) + 1
					client:setNetVar("actAng", client:GetAngles())
				else
					return "@modelNoSeq"
				end
			end
		end
	nut.command.add("act"..k, data)
end

function PLUGIN:UpdateAnimation(client, moveData)
	local angles = client:getNetVar("actAng")

	if (angles) then
		client:SetRenderAngles(angles)
	end
end

function PLUGIN:ShouldDrawLocalPlayer(client)
	if (client:getNetVar("actAng")) then
		return true
	end
end

local GROUND_PADDING = Vector(0, 0, 8)
local PLAYER_OFFSET = Vector(0, 0, 72)

function PLUGIN:CalcView(client, origin, angles, fov)
	if (client:getNetVar("actAng")) then
		local view = {}
			local data = {}
				data.start = client:GetPos() + PLAYER_OFFSET
				data.endpos = data.start - client:EyeAngles():Forward()*72
			view.origin = util.TraceLine(data).HitPos + GROUND_PADDING
			view.angles = client:EyeAngles()
		return view
	end
end

function PLUGIN:PlayerBindPress(client, bind, pressed)
	if (client:getNetVar("actAng")) then
		bind = bind:lower()

		if (bind:find("+jump") and pressed) then
			nut.command.send("actsit")

			return true
		end
	end
end