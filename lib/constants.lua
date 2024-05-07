local constants = {}
constants.preferedInputPath = "/home/lib/preferedInputs.txt"
constants.dbRows = {
--{"glass",0}, Not every glass recipe accepts substitues.
{"circuit",1},
}
constants.glass = {
{"Reinforced Glass","Titanium Reinforced Borosilicate Glass Block"},
{"Thorium Yttrium Glass Block","Tungstensteel Reinforced Borosilicate Glass Block"},
}
--OFFSET DEPRECATED
constants.glassOffset = 3
constants.circuit = {
{"Any LV Circuit","Electronic Circuit","Integrated Logic Circuit","Basic Magneto Resonatic Circuit","Microprocessor"},
{"Any MV Circuit","Good Electronic Circuit","Good Integrated Circuit","Good Magneto Resonatic Circuit","Integrated Processor"},
{"Any HV Circuit","Advanced Circuit","Processor Assembly","Advanced Magneto Resonatic Circuit","Nanoprocessor"},
{"Any EV Circuit","Workstation","Quantumprocessor","Data Magneto Resonatic Circuit","Nanoprocessor Assembly"},
{"Any IV Circuit","Mainframe","Quantumprocessor Assembly","Elite Magneto Resonatic Circuit","Elite Nanocomputer","Crystalprocessor"},
{"Any LuV Circuit","Nanoprocessor Mainframe","Master Quantumcomputer","Wetwareprocessor","Master Magneto Resonatic Circuit", "Crystalprocessor Assembly"},
{"Any ZPM Circuit","Quantumprocessor Mainframe","Wetwareprocessor Assembly","Bioprocessor","Ultimate Magneto Resonatic Circuit","Ultimate Crystalcomputer",},
{"Any UV Circuit", "Wetware Supercomputer","Biowareprocessor Assembly","Optical Processor","Superconductor Magneto Resonatic Circuit", "Crystalprocessor Mainframe"},
{"Any UHV Circuit","Wetware Mainframe","Bioware Supercomputer","Optical Assembly","Exotic Processor","Infinite Magneto Resonatic Circuit"},
{"Any UEV Circuit","Bio Mainframe","Optical Computer","Exotic Assembly","Cosmic Processor","Bio Magneto Resonatic Circuit"},
{"Any UIV Circuit","Optical Mainframe","Exotic Computer","Cosmic Assembly","Temporally Transcendent Processor"},
{"Any UXV Circuit","Cosmic Mainframe","Temporally Transcendent Computer"}
}
--OFFSET DEPRECATED
constants.circuitOffset = 3
return constants