# semiconductor

norns ensemble script

## background
this script was written to support the creation of physically gathered together norns ensembles, providing players a way of "conducting" a performance in a non-hierarchical manner.

it occurred to me that a whole lot of music performance involves control. also, and conversely, there has been a lot of music concerned more with giving up control to a machine with the development of generative music and instruments inspired by chaos (blippoo box and wing pinger, for example). this script is meant to promote a somewhat different approach, where a performance is built around performers in immediate physical proximity to one another giving up control to each other as a performative strategy.

## how does it work?
using this mod, players gather together and connect their norns to the same network.
then, they register their norns with an arbitrarily selected "host" which then broadcasts each registration with all the other devices.

once registered, each norns can then see what scripts the other norns have currently loaded. each norns can then select parameters from one or more registered script to (semi)conduct.

the remote parameters that appear in this mod may be controlled (more or less) just as if the script was running on the norns locally.

the mod also includes macro param features so multiple params on multiple norns can be mapped and controlled from a single macro param set by the mod. 

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

### using the macro controls
* enter the `PMAP` menu, select a registered script, and set one or more of the listed params to one of the macro controls.
* by default, there are 10 macro controls that params can be mapped to. the variable `max_pmaps` defined in the */lib/globals.lua* file can be updated to generate more or less macro controls

#### changing the macro controls directly
* the macro controls are found in the main script parameters menu (PARAMETERS>EDIT) at the bottom of the list of params (i.e. following whatever params the main script loads by default into the PARAMETERS>EDIT menu)
* since these macro controls are params, they can be midi mapped (e.g. to a 16n controller)

#### xy controller: changing the macro controls directly from the mod
* enter mod's `MACROS` menu, select `xy` and a dot will appear that can be moved with E2 and E3. as the dot moves, two of the macro controls will be updated.
* which macro controls are updated with the `xy controller` can be changed in the PARAMETERS>EDIT menu by updating the `macro x` and `macro y` parameters to map to one of the 10 10 `macro controls`

## misc notes
### controlling complex scripts 
some scripts (e.g. cheat codes and flora) have custom state handling features that will not be accessible from the `semiconductor` mod or, if accessible, may result in errors. *proceed with caution.*

### running a new script after registering
after registering your norns with the `semiconductor` mod, if you change the script you are running locally, all the other registered norns will be notified of the change and any norns that had your script selected will have to select a new script in the `PLAYERS >` menu.

### shortcuts to speed up registration
* for each norns in the ensemble, in the file */lib/globals.lua*, set the parameter `norns_name` to a unique name.
* for each norns in the ensemble, in the file */lib/globals.lua* set the parameter `host_ip` to the name of the one norns that will act as the host for the ensemble.

## using this mod with a single norns
this mod will work with just a single norns (e.g. to take advantage of the macro controls)

## todo
* fix bugs
* add more control interfaces (e.g. a lorenz param controller)

