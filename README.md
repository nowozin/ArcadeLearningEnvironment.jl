
# ArcadeLearningEnvironment.jl

This package is a [Julia](http://julialang.org/) wrapper for the
[ArcadeLearningEnvironment](http://www.arcadelearningenvironment.org/) (ALE).

ALE is a modified emulator for the Atari 2600 that can emulate around 50 games
with additional access to game state information and in-game rewards.
This is useful for learning and benchmarking artificial intelligence agents
playing computer games.

If you use this package for research publications, please cite the following
paper to acknowledge the work that went into ALE.

```
@ARTICLE{bellemare13arcade,
	author = {{Bellemare}, M.~G. and {Naddaf}, Y. and {Veness}, J. and {Bowling}, M.},
	title = {The Arcade Learning Environment: An Evaluation Platform for General Agents},
	journal = {Journal of Artificial Intelligence Research},
	year = 2013,
	month = 06,
	volume = 47,
	pages = {253--279}
}
```

## Installation

On Linux the package automatically downloads and builds version 0.5.1 of the
ArcadeLearningEnvironment by issuing the following commands.

```
Pkg.clone("https://github.com/nowozin/ArcadeLearningEnvironment.jl.git")
Pkg.build("ArcadeLearningEnvironment")
```

On other systems (which I have not tried) you can build the `libale_c.so` or
`libale_c.dll` file manually and set the `LIBALE_HOME` environment variable to
the directory containing this file.  Then, the above two commands should work
as well.  Note that this is untested and any correction or feedback is
welcome.


## Example

```julia
using ArcadeLearningEnvironment

# For this example you need to obtain the Seaquest ROM file from
# https://atariage.com/system_items.html?SystemID=2600&ItemTypeID=ROM

episodes = 50

ale = ALE_new()
loadROM(ale, "SEAQUEST.BIN")

S = Array(Int, episodes)
TR = Array(Float64, episodes)
for ei = 1:episodes
    ctr = 0.0

    fc = 0
    while game_over(ale) == false
        actions = getLegalActionSet(ale)
        ctr += act(ale, actions[rand(1:length(actions))])
        fc += 1
    end
    reset_game(ale)
    println("Game $ei ended after $fc frames with total reward $(ctr).")

    S[ei] = fc
    TR[ei] = ctr
end
ALE_del(ale)
```


