# Teleporters improved
A minimalist teleporter mode that is more user friendly. 

This is a mix of the different teleporters implementation that were 
existing until now but didn't cover my needs:
* https://github.com/Bad-Command/teleporter/wiki/Teleporter-Mod
* https://github.com/Zeg9/minetest-teleporters
* teleport_tube from https://github.com/VanessaE/pipeworks.git

# Additional changes by minertestdude
- made compatible with MCL2, keeping compatibility to Minetest Game
- balanced the resource cost against rail cost, Mese Crystal -> Mese Block
- created new texture from scratch and replaced it
- added "pos" checks to prevent run-time errors
- added teleport sound
- restructured mod folder, since its not a modpack

# Crafting
A teleporter pad is build using a mese block and three glass blocks

```txt
G G G
X X X
X M X

G = Glass
X = Nothing
M = Mese Block
```

# Configuring
When placed, a teleporter pad is unlinked and has a default name built 
from its locationl. Right click on a pad and you can configure the 
teleportation:

* **Teleporter name**: A user friendly name describing the teleporter
* **Destination**: A drop down list with the available destination

When destroying a teleporter, teleporters linked to the destroyed one 
become unlinked.

When a teleporter spawns a player, it cools down for a while and is not
able to teleport a player a during this time. This to avoid the player
being teleported again when he appears on a teleporter

# TODO
This is just a proof of concept, a lot of work has to be done to 
make this mode more complete:
* Add permissions to configure a teleporter not owned by a player
* Add permissions to remove a teleporter not owned by a player
* Add one way teleporters:
  * Teleport only, not visible in the destination list, no need to give
    a name
  * Spawn only, cannot teleport to anywhere, just need to give a 
    destination name
* Add locked teleporters that are only visible in the destination list 
  for the owner
* Code optimisation

# Contributors
- minertestdude (minerdudetest on minetest forums), some improvements to work by r4nd0m6uy
- r4nd0m6uy, "minimalist teleporter" project, based upon:
- Bad-Command, "teleporter mod" code
- VanessaE, "teleport_tube" code
- Ẑeg9, "minetest-teleporters" code

