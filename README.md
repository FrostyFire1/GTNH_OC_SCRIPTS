# Collection of scripts of random usefulness.  
## BreederTron3000
The breeder of all breeders. Breeds from whatever you have in your bee chest up to the specified bee. Gene imprinting included but optional.
Requirements:
1. OC Computer
2. Adapter connected to an apiary/alveary
3. Transposer
4. Four (4) chests and an apiary/alveary adjacent to the transposer  
 ### WARNING: Alveary adapter cannot be on the edge of the alveary. If the program doesn't detect it: break and replace the alveary
5. Forestry Analyzer or GT singleblock scanner (tier doesn't matter)
6. Drones and princesses. Queens won't be recognized by the program. Any unscanned bees will automatically be scanned when the program starts.
   Any bees that have both a drone and a princess will automatically be populated up to a minimum of 16 drones if they're not already.
   If a species is required for the breeding chain but you don't have drones of that species the program will not detect the bee.
### Note: You can have literally any princess in your storage chest. The program will convert it to the required species if necessary.
   
   
![image](https://github.com/user-attachments/assets/8157da10-1120-446f-91f4-447c46d2a60e)
![2024-09-08_11 04 52](https://github.com/user-attachments/assets/e8c580b6-09be-4ed8-b700-650e24e43b88)

Recommendations:
- Maddening Frame of Frenzy (For mutations; Requires T3 blood magic altar; If you dont't want to make those you can use a mutation alveary instead (not compatible with world accelerators))
- Arborist Frame (Or any other frame that completely stops mutations)
- Witchery brews of shifting seasons (For climate changes)
- Genetics acclimatizer (so you don't have to change the biome every cycle on some bees)  
- Template drones in the last slot of the storage chest (The program will imprint their genes onto other bees as it goes)
- World Accelerators (drastically speeds up the bee cycles)
## BreederTron3000 installation guide:  
in your OpenComputers PC run the following command:  
```wget https://raw.githubusercontent.com/FrostyFire1/GTNH_OC_SCRIPTS/main/BreederTron3000/setup.lua && setup```  
When you first run BreederTron3000 you will be asked to provide the spots for all of the required containers:
1. Storage (that's where your bees go)
2. Scanner (Where you send your bees to be scanned)
3. Output (Of the scanner)
4. Garbage (Trash can not recommended. The program will look for reserve drones here when imprinting genes from a template bee or breeding new species.)  
   
To run BreederTron3000 you must provide the mode and the target bee (if running breed mode) as an argument. Please note that the bee name is case sensitive. The general command is as follows:  
`BreederTron3000 programMode targetBee [OptionalArguments] [Flags]`  
**Available modes: `breed`, `imprint` and `convert`**   
Breed mode breeds bees up to the given bee. Example:  
`BreederTron3000 breed Clay` will breed up to the Clay bee.  
If the bee name has spaces in it type the whole name without spaces. Example:  
`BreederTron3000 breed Infinitycatalyst`  
**Bees that have a different internal name (you need to use the internal name for the program to work):**  
- Wither -> Sparkeling
- Ender Shard -> Endshard
- Thaumic Shard -> Thaumiumshard

Breed mode supports the `--noFinalImprint` flag. If used the target bee won't have its genes replaced with the template genes (in case you want a gene this bee provides). To run breedertron with this flag simply add it at the end of the command.  
Imprint mode simply imprints template genes onto every bee in the storage chest unless you provide the TargetBee argument, in which case it will only imprint that specific bee. To run the program in imprint mode run:  
`BreederTron3000 imprint`  
Convert mode converts the first princess it finds in the storage chest to the target species. Optionally supports convertCount as an argument to specify how many princesses to make. To run:  
`BreederTron3000 convert beeName [convertCount]`  
Convert mode supports the `--swarm` flag. If used the conversion will be performed on every princess in your storage chest.
## BreederTron3000 Robot Mode
THIS MODE REQUIRES A WIRELESS NETWORK CARD (T2) IN THE OC COMPUTER  
If you are too lazy to place the required foundation blocks by yourself you can make an OC robot do it for you! 
Simply:
1. In an OC computer install openos on the hard disk and run  
   `wget https://raw.githubusercontent.com/FrostyFire1/GTNH_OC_SCRIPTS/main/BreederTron3000/robotSetup.lua && robotSetup`
3. create an OC Robot (MUST have a keyboard, a screen, a wireless network card (T2 recommended), the hard disk from step 1, an inventory upgrade and an inventory controller upgrade). 
4. Place the robot so it faces the foundation spot for your apiary/alveary
5. Give it all of the required foundation blocks and a tool to break already placed ones (pickaxe recommended)
6. Run the command `robot`
Remember to put a charger next to your robot!
