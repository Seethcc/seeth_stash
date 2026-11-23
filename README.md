# seeth_stash

Standalone FiveM resource for turf-owned prop stashes using `ox_target` and `ox_inventory`.

## Flow

1. Player targets an allowed prop with third eye.
2. Player selects **Rig a secret stash**.
3. Server confirms the player has an OP Crime organisation and owns the turf at the prop coords.
4. Player performs a mechanic/welding animation for 10 seconds.
5. The prop becomes a 4-slot ox_inventory stash owned by that player.
6. Each player can only own one secret stash.
7. The owner can destroy their empty stash with a crowbar in hand, then place a new stash elsewhere.

## Install

1. Copy `seeth_stash` into your server resources folder.
2. Add this after `ox_lib`, `ox_inventory`, `ox_target`, `oxmysql`, and your OP Crime resource:

```cfg
ensure jonni_stash
```

3. Edit `config.lua` if your OP Crime resource uses a different folder name:

```lua
Config.OPCrimeResources = {
    'op-crime',
    'op_crime',
    'opcrime'
}
```

No QBCore data is used. Organisation and turf permissions come from OP Crime exports only.

This resource uses these OP Crime client exports:

```lua
exports[resource]:isInTurfZone()
exports[resource]:getPlayerOrganisation()
```

And these OP Crime server exports:

```lua
exports[resource]:getPlayerTurfZone(source)
exports[resource]:isPlayerTurfOwner(...)
```

The server checks that the player is currently inside a turf zone and then confirms that player owns that turf before allowing the stash.

Stash creation requires OP Crime ownership confirmation. The current turf from `isInTurfZone()` must match the player's owned turf from `getPlayerTurfZone()`, or `isPlayerTurfOwner(...)` must return true.

```lua
Config.AllowClientTurfOrganisationFallback = false
```

Anyone can search/open discovered stashes.

## Notes

- Stashes persist in the `seeth_stashes` SQL table.
- Stashes are opened server-side and registered with `owner`, so other players cannot open the stash by spoofing target data.
- The database has a unique key on `owner`, enforcing one stash per player.
- Add or remove targetable props in `Config.AllowedProps`.
- Change the build emote with `Config.BuildEmote`. By default it runs `/e mechanic` from rpemotes.
- Potted plant props use `Config.PlantEmote`, which defaults to `/e garden`, when creating or destroying a stash.
- Potted plant stashes require `Config.PlantRequiredItem`, which defaults to `shovel`, for both creating and destroying.
- Destroying a stash requires holding `Config.DestroyWeapon`, which defaults to `weapon_crowbar`, and the stash must be empty.
- Jobs in `Config.PoliceJobs`, default `police`, can destroy stashes without a crowbar.
- Set `Config.Debug = true` to print turf-check results in the server console while testing.
