
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Citizen Terminal"
ENT.Category = "ix: HL2RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PhysgunDisable = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Broken")
end

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_combine/breenconsole.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetBroken(false)
		self:SetHealth(50)

		local physics = self:GetPhysicsObject()
		physics:EnableMotion(false)
		physics:Sleep()

		self.nextUse = 0
	end

	function ENT:Use(ply)
		if not ( ply:GetEyeTrace().Entity == self ) then
			return
		end

		if ( self.nextUse > CurTime() ) then
			return
		end

		self.nextUse = CurTime() + 1

		if ( Schema:IsCombine(ply) ) then
			self:EmitSound("buttons/combine_button_locked.wav")

			return
		end

		Schema:OpenUI(ply, "ixCitizenTerminal")
	end

	function ENT:OnRemove()
		if not ( ix.shuttingDown ) then
			Schema:SaveData()
		end
	end

	function ENT:OnTakeDamage(dmgInfo)
		if ( self:GetBroken() ) then
			return
		end

		self:SetHealth(self:Health() - dmgInfo:GetDamage())

		if ( self:Health() <= 0 ) then
			self:SetBroken(true)
			self:EmitSound("ambient/energy/spark"..math.random(1, 6)..".wav")
		end
	end
else
	function ENT:Draw()
		self:DrawModel()
    end

	local UI = {}

	local gradient = Material("vgui/gradient-l")

	function UI:Init()
		if ( IsValid(ix.gui.citizenTerminal) ) then
			ix.gui.citizenTerminal:Remove()
			ix.gui.citizenTerminal = nil
		end

		ix.gui.citizenTerminal = self

		self:SetPos(0, scrH * 0.25)
		self:SetSize(scrW * 0.50, scrH * 0.50)

		self:MakePopup()

		self:MoveTo(scrW / 2 - scrW * 0.25, scrH / 2 - scrH * 0.25, 0.2, 0, 0.2)

        local progressBar = self:Add("DProgress")
        progressBar:Dock(FILL)
        progressBar:SetFraction(0)
        progressBar:DockMargin(0, ScreenScale(20), 0, ScreenScale(125))
        progressBar.Think = function(this)
            this:SetFraction(this:GetFraction() + FrameTime() * 550)

            if ( this:GetFraction() >= 1000 ) then
                for k, v in pairs(self:GetChildren()) do
                    v:Remove()
                end

                self:Populate()
            end
        end
        progressBar.Paint = function(this, w, h)
            surface.SetDrawColor(Color(0, 255, 0))
            surface.DrawRect(0, 0, this:GetFraction(), 1)

            surface.SetDrawColor(Color(0, 255, 0, 30))
            surface.SetMaterial(gradient)
            surface.DrawTexturedRect(0, 2, this:GetFraction() * 1.4, h - 1)
        end

        local label = self:Add("DLabel")
        label:Dock(TOP)
        label:SetText("Citizen Terminal")
        label:SetFont("ixMenuButtonFont")
        label:SetContentAlignment(5)
        label:SizeToContents()

        label = self:Add("DLabel")
        label:Dock(TOP)
        label:SetText("Loading...")
        label:SetFont("ixMenuButtonFont")
        label:SetTextColor(color_white)
        label:SetContentAlignment(5)
        label:SizeToContents()
	end

    function UI:Populate()
        self.close = self:Add("ixMenuButton")
        self.close:Dock(BOTTOM)
        self.close:SetText("<:: Exit ::>")
        self.close:SetFont("ixMenuButtonFont")
        self.close:SetContentAlignment(5)
        self.close:SizeToContents()
        self.close.DoClick = function()
            self:Remove()
        end
        self.close.paintW = 0
        self.close.Paint = function(this, w, h)
            if ( this:IsHovered() ) then
                this.paintW = Lerp(FrameTime() * 10, this.paintW, w)
            else
                this.paintW = Lerp(FrameTime() * 10, this.paintW, 0)
            end

            surface.SetDrawColor(Color(255, 0, 0))
            surface.DrawRect(0, 0, this.paintW, 2)

            surface.SetDrawColor(Color(255, 0, 0, 30))
            surface.SetMaterial(gradient)
            surface.DrawTexturedRect(0, 0, this.paintW, h)
        end

        local label = self:Add("DLabel")
        label:Dock(TOP)
        label:SetText("<:: Civillian DataBase: " .. localPlayer:SteamID64() .. " ::>")
        label:SetFont("ixSubTitleFont")
        label:SetContentAlignment(5)
        label:DockMargin(0, 0, 0, ScreenScale(10))
        label:SizeToContents()

        label = self:Add("DLabel")
        label:Dock(TOP)
        label:SetText("Name: " .. localPlayer:Name())
        label:SetFont("ixMediumFont")
        label:SetContentAlignment(4)
        label:SizeToContents()

        label = self:Add("DLabel")
        label:Dock(TOP)
        label:SetText("Loyalty Points: " .. localPlayer:GetCharacter():GetLoyaltyPoints())
        label:SetFont("ixMediumFont")
        label:SetContentAlignment(4)
        label:SizeToContents()

    end

	function UI:Paint(w, h)
        surface.SetDrawColor(Color(0, 0, 0, 255))
        surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(Color(0, 100, 0, 50))
		surface.SetMaterial(gradient)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	vgui.Register("ixCitizenTerminal", UI, "Panel")

	if ( IsValid(ix.gui.citizenTerminal) ) then
		ix.gui.citizenTerminal:Remove()
		ix.gui.citizenTerminal = nil

		ix.gui.citizenTerminal = vgui.Create("ixCitizenTerminal")
	end
end