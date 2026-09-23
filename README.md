# SimpleCVarLoader

## About

A World of Warcraft addon that stores CVar values in named profiles and reapplies the active one
at every login. Profiles can also carry Lua snippets ("tweaks") for settings no CVar exposes.

No configuration window, no dependencies: one slash command does everything.

## Features

* Named profiles, each with its own CVars and tweaks
* The active profile is reapplied on `PLAYER_LOGIN`
* CVars are validated before being stored: a typo is rejected, not saved
* `cvar list` shows each value against its game default, colour-coded when it differs
* Tweaks run under `pcall`: a broken snippet reports its error without aborting the profile

## Commands

`/scvl` is short for `/simplecvarloader`. Either one with no arguments prints this list.

| Command | Description |
| --- | --- |
| `/scvl profile list` | List every profile, marking the active one |
| `/scvl profile new <name>` | Create an empty profile |
| `/scvl profile set <name>` | Apply a profile and make it the active one |
| `/scvl profile delete <name>` | Delete a profile |
| `/scvl cvar list` | List the CVars of the active profile with their defaults |
| `/scvl cvar set <name> <value>` | Apply a CVar and store it in the active profile |
| `/scvl cvar delete <name>` | Remove a CVar override from the active profile |
| `/scvl tweak list` | List the tweaks of the active profile |
| `/scvl tweak set <name> <code>` | Run a Lua snippet and store it in the active profile |
| `/scvl tweak delete <name>` | Remove a tweak from the active profile |

`cvar` and `tweak` act on the active profile; select one with `/scvl profile set` first.

## Example

Two profiles: one for the open world, one for raid nights. Both declare the same settings with
different values, which is what makes switching reversible.

A `default` profile, with immersion left on:

```
/scvl profile new default
/scvl profile set default
/scvl cvar set nameplateShowAll 0
/scvl cvar set nameplateShowFriendlyPlayers 1
/scvl cvar set nameplateShowOffscreen 0
/scvl cvar set showTargetOfTarget 0
/scvl cvar set chatBubbles 1
/scvl cvar set Sound_EnableAmbience 1
/scvl cvar set Sound_EnableMusic 1
/scvl cvar set Sound_EnableErrorSpeech 1
/scvl cvar set Sound_NumChannels 64
/scvl tweak set UIErrorsFrame UIErrorsFrame:Show()
```

A `raid` profile, trading atmosphere for readability:

```
/scvl profile new raid
/scvl profile set raid
/scvl cvar set nameplateShowAll 1
/scvl cvar set nameplateShowFriendlyPlayers 0
/scvl cvar set nameplateShowOffscreen 1
/scvl cvar set showTargetOfTarget 1
/scvl cvar set chatBubbles 0
/scvl cvar set Sound_EnableAmbience 0
/scvl cvar set Sound_EnableMusic 0
/scvl cvar set Sound_EnableErrorSpeech 0
/scvl cvar set Sound_NumChannels 128
/scvl tweak set UIErrorsFrame UIErrorsFrame:Hide()
```

Switching is one command; the last profile applied comes back at the next login:

```
/scvl profile set raid
/scvl profile set default
```

No CVar hides the red error text, which is what tweaks are for. But a tweak is only Lua that runs
on apply — nothing undoes it. Hiding `UIErrorsFrame` in `raid` is reversible only because `default`
shows it again.

## Installation

Extract the archive into `World of Warcraft/_retail_/Interface/AddOns/SimpleCVarLoader`:

```
World of Warcraft/_retail_/Interface/AddOns/
└── SimpleCVarLoader/
    ├── LICENSE
    ├── README.md
    ├── SimpleCVarLoader.lua
    └── SimpleCVarLoader.toc
```

## Resources

* [IntelliJ-IDEA-Lua-IDE-WoW-API](https://github.com/Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API)
* [wow-ui-source](https://github.com/Gethe/wow-ui-source)

## License

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
