# semiconductor

a norns ensemble script

![](sc.png)

semconductor is a norns mod that was written to encourage physically gathered together norns ensembles, providing players a way of "conducting" a performance in a non-hierarchical manner.

it occurred to me that a whole lot of music performance involves control. also, and conversely, there has been a lot of music concerned more with giving up control to a machine with the development of generative music and instruments inspired by chaos (blippoo box and wing pinger, for example). this script is meant to promote a somewhat different approach, where a performance is built around performers in immediate physical proximity to one another giving up control to each other as a performative strategy.

## requirements

* norns 

## install

`https://github.com/jaseknighter/semiconductor`

## how does it work?
using this mod, players gather together and connect their norns to the same network. then, they register their norns with an arbitrarily selected "host" which then broadcasts each registration with all the other devices.

once registered, each norns can then see what scripts the other norns have currently loaded. each norns can then select parameters from one or more registered script to (semi)conduct.

the remote parameters that appear in this mod may be controlled (more or less) just as if the script was running on the norns locally.

the mod also includes macro param features so multiple params on multiple norns can be mapped and controlled from a single macro param. 

## instructions

### get started

* assemble your ensemble and connect each norns to the network (wifi or physical)
* turn on the `semiconductor` mod on each of the norns and restart
* load the norns script you want to perform (e.g. awake, etc.)
* chose one norns in the ensemble to be the *host* and note the host's ip address 
  * with the one norns selected to be the *host*, set the `host enabled` parameter to `true`
  * IMPORTANT: only one norns in the ensemble should have the `host enabled` parameter set to `true`
* enter the `semiconductor` mod menu
* enter the `REGISTER >` menu, select `register` and provide a name for your norns and then the ip address of the host (note: see *shortcuts* below)
* enter the `PLAYERS >` menu to see the other norns scripts and control their paparameters

### leave the ensemble
* enter the `semiconductor` mod menu
* enter the `REGISTER >` menu and select `unregister`

### group sync
there are three params that you can sync across all registered norns from the `group sync >` sub-menu found in `PARAMETERS>EDIT`:

* `output levels`: change all the norns output levels 
* `tempos`: change all the norns tempos
* `clocks reset`: reset all the norns clocks to sync them with one another 

### macros
macros allow you to change multiple paramaters at once, either within a single script or across multiple scripts.

* from the SEMICONDUCTOR mod, enter the `PMAP` menu, select a registered norns, and set one or more of the listed params to one of the macro controls 
* repeat the step above for a different registered norns to set params for multiple norns simultaneously
* the macro controls are found in the main script parameters menu (PARAMETERS>EDIT) at the bottom of the list of params in the `macro controls` sub menu
* since these macro controls are params, they can be midi mapped (e.g. to a 16n controller)

#### xy controller
* map two or more params to a couple of macros (see *macros* above)
* select `xy` from the mod's `MACROS` menu and a dot will appear that can be moved with E2 and E3. as the dot moves, two of the macro controls will be updated.
* you can change which macro controls are updated with the `xy controller` from the PARAMETERS>EDIT menu by updating the `macro x` and `macro y` parameters to map to one of the 10 `macro controls`
* by default, macro controls 1 and 2 are mapped to x and y, respectively

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

