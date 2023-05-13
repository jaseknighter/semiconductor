# semiconductor

norns ensemble script

this script was written to support the creation of irl norns ensembles, providing players a way of "conducting" a performance in a non-hierarchical manner.

using this mod, players register their norns with an arbitrarily selected "host" which then broadcasts each registration with all the other devices.

the registered norns can then see what scripts the other norns have currently loaded and select a script to conduct.

once a script has been selected, its parameters appear in the mod menu and can be controlled just as if the script was running on the norns locally.

## instructions

### get started

* assemble your ensemble and connect each norns to the network (wifi or physical)
* turn on the `semiconductor` mod each of the norns and restart
* chose one norns to be the *host* and note the host's ip address 
* in `PARAMETERS>EDIT` menu of the *host* norns, set the `host enabled` parameter to `true` (note, only one norns in the ensemble should have this setting set to `true`) 
* enter the `semiconductor` mod menu
* enter the `REGISTER >` menu, select `register` and provide a name for your norns and then the ip address of the host (note: see *shortcuts* below)
* enter the `PLAYERS >` menu and select a script to conduct 

### leave the ensemble
* enter the `semiconductor` mod menu
* enter the `REGISTER >` menu and select `unregister`

### change the script
if you want to change the script you are controlling, enter the `PLAYERS >` menu and select a new script

## misc notes
### controlling complex scripts 
some scripts (e.g. cheat codes and flora) have custom state handling features that will not be accessible from the `semiconductor` mod or, if accessible, may result in errors. *proceed with caution.*

### running a new script after registering
after registering your norns with the `semiconductor` mod, if you change the script you are running locally, all the other registered norns will be notified of the change and any norns that had your script selected will have to select a new script in the `PLAYERS >` menu.

### shortcuts to speed up registration
* for each norns in the ensemble, in the file */lib/globals.lua*, set the parameter `norns_name` to a unique name.
* for each norns in the ensemble, in the file */lib/globals.lua* set the parameter `host_ip` to the name of the one norns that will act as the host for the ensemble.

## using this mod with a single norns
this mod will work with just a single norns which is nice for developing the code for this mod but not much else 

## todo
* fix bugs
* create parameters and mapping controls to update remote script params via midi
* enable control of multiple scripts' params at the same time
* built a macro interface to update multiple params at the same time


