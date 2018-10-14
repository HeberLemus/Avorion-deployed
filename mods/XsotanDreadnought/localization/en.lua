return {
	--[[
	To add another language create the file xx.lua (replace xx by your country code).
	Be sure encoding is UTF-8 (I'm not sure if BOM is supported, I always use UTF-8 without BOM).
	Copy all contents of this file into the new one and modify it like this:
	
	["Never change this"] = "change this to implement your own language",
	]]
	
	["Your sensors picked up very curious subspace signals at \\s(%i:%i)."] = "Your sensors picked up very curious subspace signals at \\s(%i:%i).",
	["Your sensors picked up subspace signals at %i:%i."] = "Your sensors picked up subspace signals at %i:%i.",
	["Curious subspace signals"] = "Curious subspace signals",
	["You received curious subaspace signals by an unknown source. Their position is %i:%i."] = "You received curious subaspace signals by an unknown source. Their position is %i:%i.",
	["The Dreadnought charges up his weapons and shields"] = "The Dreadnought charges up his weapons and shields",
	["The Dreadnought finished charging and is vulnerable again"] = "The Dreadnought finished charging and is vulnerable again",
}