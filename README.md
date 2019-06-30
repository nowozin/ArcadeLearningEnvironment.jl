[![Build Status](https://travis-ci.com/JuliaReinforcementLearning/ArcadeLearningEnvironment.jl.svg?branch=master)](https://travis-ci.com/JuliaReinforcementLearning/ArcadeLearningEnvironment.jl)
[![codecov](https://codecov.io/gh/JuliaReinforcementLearning/ArcadeLearningEnvironment.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaReinforcementLearning/ArcadeLearningEnvironment.jl)

# ArcadeLearningEnvironment.jl

This package is a [Julia](http://julialang.org/) wrapper for the
[ArcadeLearningEnvironment](https://github.com/mgbellemare/Arcade-Learning-Environment) (ALE).

**This is the maintained fork that is in the official Julia registry.**

For a higher level access to ALE see [ReinforcementLearningEnvironments](https://github.com/JuliaReinforcementLearning/ReinforcementLearningEnvironments.jl).

ALE is a modified emulator for the Atari 2600 that can emulate around 50 games
with additional access to game state information and in-game rewards.
This is useful for learning and benchmarking artificial intelligence agents
playing computer games.


## Citation

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

On Mac OS and Linux the package automatically downloads and builds version
0.6.0 of the ArcadeLearningEnvironment by adding it in julia 0.6 with

```julia
Pkg.add("ArcadeLearningEnvironment")
```

or in the package REPL of julia 0.7.0 with
```julia
add ArcadeLearningEnvironment
```

On Windows (which I have not tried yet) you can build the `libale_c.dll` file
manually and set the `LIBALE_HOME` environment variable to the directory
containing this file.  Then, the above two commands should work as well.  Note
that this is untested and any correction or feedback is welcome.


## Example

```julia
using ArcadeLearningEnvironment


episodes = 50

ale = ALE_new()
loadROM(ale, "seaquest")

S = zeros(Int64, episodes)
TR = zeros(episodes)
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


