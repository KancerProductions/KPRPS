-- NPCWorldRefs.lua (011): wider search so they leave the pad
return {
  SipBlockTag = "SipBlock",
  SipRoots = { "Map", "Grounds", "SGZone1", "SGZone2", "SGZone3" }, -- auto-scan here
  DepositTargets = { "Prism", "Bank", "Collector", "Shop" },
  EnergyPerSip = 4,
  SipsPerStop = {3,6},
  DepositThreshold = 28,
  SipDrain = {brightness = 0.5, transparency = 0.1, duration = 0.25},
}
