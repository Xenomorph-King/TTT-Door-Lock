local DoorConfig = {}

DoorConfig["ShowMessage"] = false // Whether to print a message to the players chatbox when locking/unlocking doors
DoorConfig["LockSound"] = "doors/door_latch1.wav" // Lock sound
DoorConfig["UnlockSound"] = "doors/door_latch3.wav" // Unlock sound
DoorConfig["BreakDoors"] = true // Can we break doors?
DoorConfig["DoorHealth"] = 300 // How much health do doors have?
DoorConfig["BreakSounds"] = {"physics/wood/wood_plank_break1.wav", "physics/wood/wood_plank_break2.wav", "physics/wood/wood_plank_break3.wav", "physics/wood/wood_plank_break4.wav"}


// DONT TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOURE DOING

if CLIENT then
	hook.Add("HUDPaint", "DoorLockSystem", function ()
		local ply = LocalPlayer()
		local ent = ply:GetEyeTrace().Entity
		if not ent or not ent:IsValid() then return end
		if not ply:Alive() or ply:IsSpec() then return end
		if not (ply:IsTraitor() or ply:IsDetective()) then return end
		if ent:GetClass() != "prop_door_rotating" then return end
		if ent:GetPos():Distance(ply:GetPos()) > 100 then return end
		if ent:GetNWBool("broken",false) then return end
		local txt = "Hold R to Lock"
		if ent:GetNWBool("locked",false) then
			txt = "Hold R to Unlock"
		end
		surface.SetFont("TargetID")
		local w,h = surface.GetTextSize(txt)
		surface.SetTextPos(ScrW()/2-w/2,ScrH()/2-h/2+50)
		surface.SetTextColor(Color(255,0,0))
		surface.DrawText(txt)
	end)
else
	function DoorLockSystem()
		for k,ply in pairs(player.GetAll()) do
			if ply:Alive() and ply:KeyDown(IN_RELOAD) then
				if ply:IsTraitor() or ply:IsDetective() then					
					local trace = ply:GetEyeTrace();
					//print(CurTime()-ply.lastLocked )
					if ply.lastLocked and CurTime()-ply.lastLocked < 1 then continue end
					ply.lastLocked = CurTime()
					if(trace.Entity:IsValid() and trace.Entity:GetClass() == "prop_door_rotating" and !trace.Entity:GetNWBool("broken",false) and trace.Entity:GetPos():Distance(ply:GetPos()) < 100 ) then
						if trace.Entity:GetSaveTable( ).m_bLocked then
							trace.Entity:Fire( "unlock", "", 0 );
							trace.Entity:EmitSound(DoorConfig["UnlockSound"])
							if DoorConfig["ShowMessage"] then
								ply:SendLua([[chat.AddText(Color(150,200,100), "[MSG] ", color_white, "Unlocked!")]])
							end
						else
							trace.Entity:Fire( "lock", "", 0 );
							trace.Entity:EmitSound(DoorConfig["LockSound"]);
							if DoorConfig["ShowMessage"] then							
								ply:SendLua([[chat.AddText(Color(150,200,100), "[MSG] ", color_white, "Locked!")]])
							end
						end
					end
				end
			end
		end
		for k,ent in pairs(ents.FindByClass("prop_door_rotating")) do
			if ent:GetSaveTable().m_bLocked then
				ent:SetNWBool("locked",true)
			else
				ent:SetNWBool("locked",false)
			end
			if !ent.Healthed then
				ent.Healthed = true
				ent:SetHealth(DoorConfig["DoorHealth"])
			end
		end
	end
	hook.Add("Think", "DoorLockSystem", DoorLockSystem)

	hook.Add("EntityTakeDamage","DoorLockSystem", function(ent,dmginfo)
		if ent:GetClass() == "prop_door_rotating" and ent:GetSaveTable( ).m_bLocked and DoorConfig["BreakDoors"] then
			ent:SetHealth(ent:Health()-dmginfo:GetDamage())
			if ent:Health() <= 0 and !ent:GetNWBool("broken",false) then
				ent:Fire( "unlock", "", 0 );
				ent:Fire( "Open", "", 0)
				ent:EmitSound(DoorConfig["UnlockSound"])
				ent:SetNWBool("broken",true)
				ent:EmitSound(DoorConfig["BreakSounds"][#DoorConfig["BreakSounds"]])
			end
			return true
		end
	end)
end