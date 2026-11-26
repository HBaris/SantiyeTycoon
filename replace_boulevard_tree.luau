local RS = game:GetService("ReplicatedStorage")
local trees = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Trees")
if not trees then return "No Trees folder" end

local garden = trees:FindFirstChild("GardenTree")
if not garden then return "No GardenTree found" end

local oldBoulevard = trees:FindFirstChild("BoulevardTree")
if oldBoulevard then
    oldBoulevard:Destroy()
end

-- Create a pristine BoulevardTree model containing a clean planter and the Oak Tree mesh
local newBoulevard = Instance.new("Model")
newBoulevard.Name = "BoulevardTree"

-- Clone the garden oak tree inside
local treeMesh = garden:Clone()
treeMesh.Name = "TreeMesh"
treeMesh.Parent = newBoulevard

newBoulevard.Parent = trees
return "BoulevardTree replaced successfully with clean LowPoly Tree!"
