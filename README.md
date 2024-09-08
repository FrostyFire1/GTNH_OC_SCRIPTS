# Collection of scripts of random usefulness.  
## BreederTron3000
The breeder of all breeders. Breeds from whatever you have in your bee chest up to the specified bee. Gene imprinting included but optional.
Requirements:
1. OC Computer
2. Adapter connected to an apiary/alveary
3. Transposer
4. Four (4) chests adjacent to the transposer
5. Forestry Analyzer or GT singleblock scanner (tier doesn't matter)

![image](https://github.com/user-attachments/assets/8157da10-1120-446f-91f4-447c46d2a60e)
![2024-09-08_11 04 52](https://github.com/user-attachments/assets/e8c580b6-09be-4ed8-b700-650e24e43b88)

Recommendations:
- Maddening Frame of Frenzy (Requires T3 blood magic altar)
- Arborist Frame (Or any other frame that completely stops mutations)
- Witchery brews of shifting seasons (For climate changes)
- Template drones in the last slot of the storage chest (The program will imprint their genes onto other bees as it goes)
- World Accelerators
## BreederTron3000 installation guide:  
in your OpenComputers PC run the following command:  
```wget https://raw.githubusercontent.com/FrostyFire1/GTNH_OC_SCRIPTS/main/BreederTron3000/setup.lua && setup```  
When you first run BreederTron3000 you will be asked to provide the spots for all of the required containers:
1. Storage (that's where your bees go)
2. Scanner (Where you send your bees to be scanned)
3. Output (Of the scanner)
4. Garbage (Trash can not recommended. The program will look for reserve drones here when imprinting genese from a template bee.
   
To run BreederTron3000 you must provide the target bee as an argument.  
Example: `BreederTron3000 Clay` will breed up to the Clay bee.  
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
