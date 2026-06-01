# EchoesBeyondPlus
A modification/fork of the echoes beyond garry's mod gamemode, just random changes that i put
Includes:
* Skin system that gives a few maps and the first echo on the map a unique skin
* Funky "draft" system to make up to 3 echoes queued to be created when cooldown expires
* "Pin" echo system to pin echoes you want to remember, ~~along with a translate feature~~ Translation is now also a part of base mod!
* A couple extra settings
* Map list filters (installed, uninstalled, echoed on/not echoed)
* Map list shows your personal echoes next to the global echoes count
* Community menu, Listing a wall of people who have contributed to the community
* More verbose info in the tab menu - Some now included in the base mod!
* "Scary" mode for fun (makes map dark, new 'music'), Requires [Gmod Light / Environment Editor](https://steamcommunity.com/sharedfiles/filedetails/?id=2779451924)
* ~~Echoes follow the cameras height to help with vents being annoying~~ Now included in base mod!
* Couple extra QOL things

i am unsure if i will add too much here, but its here!
I do not have access to the serverside/backend of EchoesBeyond, This version does not ping the servers any more than the normal mod, for this reason i cannot add things such as timestamps to the echoes

alt + e while reading an echo to open the pin/translate options, you have to hold alt and tap e, releasing alt does the selected option

# WARNING
~~recommended to make a backup of your readechoes.txt in your garrysmod/data/echoesbeyond folder, as this version will convert it to a new format that does not work and breaks the original mod.~~

edit: The mod now saves/converts to a separate readechoes_plus.txt, that doesn't interfere with the original, do note reading echoes with this fork doesn't add to the original mod's readechoes!

# How to install
Firstly, disable the original addon in-game, as this is a fork, it uses much of the same code

In steam, right click garry's mod and press "Properties", navigate to "Installed files" from the sidebar, and press "Browse"
Navigate to the addon's folder (GarrysMod\garrysmod\addons)

Unzip the code downloaded from here into the addons folder, Or git clone into the addons folder, the folder should directly lead to the asset folders and not another sub-folder (gamemodes/lua/materials/etc)
Restart/Launch GMod

You should now have an Echoes beyond plus selectable in the gamemodes!
If it still shows as normal echoes: Beyond, you may not have disabled the original addon or restarted

To update, simply repeat the steps above, replacing the files, Or git pull from inside the EB+ folder to update
