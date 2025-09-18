-- NPCOutfits.lua (011): random outfits via Shirt/Pants instances (more reliable than HumanoidDescription in Studio).
return {
  shirts = { 144076760, 382538386, 4763070282, 8268889365, 6404280288, 6865440806 },
  pants  = { 376530407, 5687813103, 4763071468, 8268890117, 6404280994, 6865441339 },
  walkSpeedRange = {14,18},
  jumpPowerRange = {40,50},
  palettes = {
    Color3.fromRGB(255,224,189), Color3.fromRGB(241,194,125), Color3.fromRGB(224,172,105),
    Color3.fromRGB(198,134,66),  Color3.fromRGB(141,85,36),
  },
  maxNPCs = 6,
}
