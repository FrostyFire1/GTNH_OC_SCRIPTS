# Collection of scripts of random usefulness.  
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
If you are too lazy to place the required foundation blocks by yourself you can make an OC robot do it for you!  
Simply:
1. create an OC Robot (MUST have a keyboard, a screen, a wireless network card (T2 recommended), an inventory upgrade and an inventory controller upgrade).
2. Run `wget https://raw.githubusercontent.com/FrostyFire1/GTNH_OC_SCRIPTS/main/BreederTron3000/robotSetup.lua && robotSetup`
3. Place the robot so it faces the foundation spot for your apiary/alveary
4. Run the command `robot`
Remember to put a charger next to your robot!
