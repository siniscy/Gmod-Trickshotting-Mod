ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Planted Claymore"
ENT.Author = "KatBug"
ENT.Information = ""
ENT.Spawnable = false
ENT.AdminSpawnable = false 

function ENT:SetupDataTables()
	self:DTVar("Bool", 0, "Armed")
	self:DTVar("Bool", 1, "Activated")
	self.dt.Activated = false
	self.dt.Armed = false
	
	self:SetNetworkedBool( "Det", false )
	

end