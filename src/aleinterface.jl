
if isfile(joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl"))
    include("../deps/deps.jl")
else
    error("libale_c not properly installed. Please run Pkg.build(\"ArcadeLearningEnvironment\")")
end

const ALEInterface = Cvoid  # Using Cvoid inplace of Nothing because it is better suited to the context
const ALEPtr = Ptr{ALEInterface}
const ALEState = Cvoid
const ALEStatePtr = Ptr{ALEState}

const Logger = Dict(
    :info => 0,
    :warning => 1,
    :error => 2
)

"""
    ALE_new()

Creates a new ALE instance.
"""
ALE_new() = ccall((:ALE_new, libale_c), ALEPtr, ())

"""
    ALE_del(ale_instance::ALEPtr)

Destroys the passed ALE instance pointer. Acts as a destructor. Use with caution.
"""
ALE_del(ale::ALEPtr) = ccall((:ALE_del, libale_c), Cvoid, (ALEPtr,), ale)

"""
    getString(ale_instance::ALEPtr, key::String)

Returns the string value held by the ALE instance's field with the same name as `key`.
"""
function getString(ale::ALEPtr, key::String)
    res = ccall((:getString, libale_c), Ptr{Cchar}, (ALEPtr, Ptr{Cchar}),
        ale, key)
    bytestring(res)
end

"""
    getInt(ale_instance::ALEPtr, key::String)

Returns the integer value held by the ALE instance's field with the same name as `key`.
"""
getInt(ale::ALEPtr, key::String) = ccall((:getInt, libale_c), Cint,
    (ALEPtr, Ptr{Cchar}), ale, key)

"""
    getBool(ale_instance::ALEPtr, key::String)

Returns the boolean value held by the ALE instance's field with the same name as `key`.
"""
getBool(ale::ALEPtr, key::String) = ccall((:getBool, libale_c), Cint,
    (ALEPtr, Ptr{Cchar}), ale, key) > 0

"""
    getFloat(ale_instance::ALEPtr, key::String)

Returns the float value held by the ALE field with the same name as `key`.
"""
getFloat(ale::ALEPtr, key::String) = ccall((:getFloat, libale_c), Float32,
    (ALEPtr, Ptr{Cchar}), ale, key)

"""
    setString(ale_interface::ALEPtr, key::String, value::String)

Modifies the ALE instance field value with the same name as `key` to the passed String value.
"""
setString(ale::ALEPtr, key::String, value::String) =
    ccall((:setString, libale_c), Cvoid, (ALEPtr, Ptr{Cchar}, Ptr{Cchar}),
        ale, key, value)

"""
    setInt(ale_instance::ALEPtr, key::String, value::Int32)

Modifies the ALE instance field value with the same name as `key` to the passed integer value.
"""
setInt(ale::ALEPtr, key::String, value::Integer) = ccall((:setInt, libale_c),
    Cvoid, (ALEPtr, Ptr{Cchar}, Cint), ale, key, Cint(value))

"""
    setBool(ale_instance::ALEPtr, key::String, value::Bool)

Modifies the ALE instance field value with the same name as `key` to the passed boolean value.
"""
setBool(ale::ALEPtr, key::String, value::Bool) = ccall((:setBool, libale_c),
    Cvoid, (ALEPtr, Ptr{Cchar}, Cint), ale, key, value)

"""
    setFloat(ale_instance::ALEPtr, key::String, value::)

Modifies the ALE instance field with the same name as `key` to the passed floating point value.
"""
setFloat(ale::ALEPtr, key::String, value::Real) =
    ccall((:setFloat, libale_c), Cvoid, (ALEPtr, Ptr{Cchar}, Cfloat),
        ale, key, Cfloat(value))

"""
    loadROM(ale_instance::ALEPtr, rom_file::String)

Loads the binary of passed. `rom_file` can either be the absolute path to the binary,
or the name of the ROM that is present in the "deps/roms" directory. Access this list using
`getROMList()`.

# Examples
```julia-repl
julia> loadROM(ale, "pong")
Game console created:
  ROM file:  /Users/juliauser/.julia/dev/ArcadeLearningEnvironment/src/../deps/roms/pong.bin
  Cart Name: Video Olympics (1978) (Atari)
  Cart MD5:  60e0ea3cbe0913d39803477945e9e5ec
  Display Format:  AUTO-DETECT ==> NTSC
  ROM Size:        2048
  Bankswitch Type: AUTO-DETECT ==> 2K


WARNING: Possibly unsupported ROM: mismatched MD5.
Cartridge_MD5: 60e0ea3cbe0913d39803477945e9e5ec
Cartridge_name: Video Olympics (1978) (Atari)

Running ROM file...
Random seed is 0

julia> loadROM(ale, "/Users/juilauser/Desktop/pewpew/roms/ms_pacman.bin")
Game console created:
  ROM file:  /Users/juilauser/Desktop/pewpew/roms/ms_pacman.bin
  Cart Name: Ms. Pac-Man (1982) (CCE)
  Cart MD5:  9469d18238345d87768e8965f9f4a6b2
  Display Format:  AUTO-DETECT ==> NTSC
  ROM Size:        8192
  Bankswitch Type: AUTO-DETECT ==> F8


WARNING: Possibly unsupported ROM: mismatched MD5.
Cartridge_MD5: 9469d18238345d87768e8965f9f4a6b2
Cartridge_name: Ms. Pac-Man (1982) (CCE)

Running ROM file...
Random seed is 0
```
"""
function loadROM(ale::ALEPtr, rom_file::String)
    if isfile(rom_file)
        ccall((:loadROM, libale_c), Nothing, (ALEPtr, Ptr{Cchar}), ale, rom_file)
    elseif isfile(joinpath(@__DIR__, "..", "deps", "roms", rom_file * ".bin"))
        loadROM(ale, joinpath(@__DIR__, "..", "deps", "roms", rom_file * ".bin"))
    else
        @error("ROM file $rom_file not found.")
    end
end

"""
    getROMList()

Returns an array of names of ROMs available. These ROMS can be loaded by simply passing
their name to the [`loadROM`](@ref) function, as opposed to passing their full path.

# Example
```julia-repl
julia> getROMList()
63-element Array{String,1}:
 "adventure"
 "air_raid"
 "alien"
 "amidar"
 "assault"
 "asterix"
 ⋮
 "venture"
 "video_pinball"
 "wizard_of_wor"
 "yars_revenge"
 "zaxxon"
```
"""
function getROMList()
    (_, _, files), _ = iterate(walkdir(eval(@__DIR__) * "/../deps/roms"))
    files = files[endswith.(files, ".bin")]
    file_names = [file_name[1:end-4] for file_name in files]
    file_names
end

"""
    act(ale_instance::ALEPtr, action::Integer)

Applies an action to the game and returns the reward. It is the user's
responsibility to check if the game has ended and reset when neccessary -
this function will keep pushing buttons on the game over screen.
"""
act(ale::ALEPtr, action::Integer)::Int =
    ccall((:act, libale_c), Cint, (ALEPtr, Cint), ale, Cint(action))

"""
    game_over(ale_instance::ALEPtr)

Returns a boolean value that tells whether the game is over. Any actions performed
from hereon until the next `reset_game()` have no effect.
"""
game_over(ale::ALEPtr) =
    ccall((:game_over, libale_c), Cint, (ALEPtr,), ale) > 0

"""
    reset_game(ale_instance::ALEPtr)

Resets the game and the reward counter.
"""
reset_game(ale::ALEPtr) = ccall((:reset_game, libale_c), Cvoid, (ALEPtr,), ale)

"""
    getLegalActionSet(ale_instance::ALEPtr)

Returns the vector of the legal set of actions needed the play the game. Not to be confused with `getMinimalActionSet`.

See also: [`getMinimalActionSet`](@ref)
"""
function getLegalActionSet(ale::ALEPtr)
    actions = Cint[]
    _getLegalActionSet!(ale, actions)
    Int.(actions)
end

function _getLegalActionSet!(ale::ALEPtr, actions::Vector{Cint})
    resize!(actions, getLegalActionSize(ale))
    ccall((:getLegalActionSet, libale_c), Cvoid, (ALEPtr, Ptr{Cint}),
        ale, actions)
end

"""
    getLegalActionSize(ale_instance::ALEPtr)

Returns the size of the legal action set. Not to be confused with `getMinimalActionSet`.

See also: [`getLegalActionSize`](@ref)
"""
getLegalActionSize(ale::ALEPtr)::Int =
    ccall((:getLegalActionSize, libale_c), Cint, (ALEPtr,), ale)

"""
    getMinimalActionSet(ale_instance::ALEPtr)

Returns the set of actions that actually affect the game. Not to be confused with `getLegalActionSet`.

See also: [`getLegalActionSet`](@ref)
"""
function getMinimalActionSet(ale::ALEPtr)
    actions = Cint[]
    _getMinimalActionSet!(ale, actions)
    Int.(actions)
end

function _getMinimalActionSet!(ale::ALEPtr, actions::Vector{Cint})
    resize!(actions, getMinimalActionSize(ale))
    ccall((:getMinimalActionSet, libale_c), Cvoid, (ALEPtr, Ptr{Cint}),
        ale, actions)
end

"""
    getMinimalActionSize(ale_instance::ALEPtr)

Returns the size of the minimal action set required to play the game. Not to be confused with `getLegalActionSize`.

See also: [`getLegalActionSize`](@ref)
"""
getMinimalActionSize(ale::ALEPtr)::Int =
    ccall((:getMinimalActionSize, libale_c), Cint, (ALEPtr,), ale)

"""
    getFrameNumber(ale_instance::ALEPtr)

Returns the frame number since the ALE instance was created.
"""
getFrameNumber(ale::ALEPtr) =
    ccall((:getFrameNumber, libale_c), Cint, (ALEPtr,), ale)

"""
    lives(ale_instance::ALEPtr)

Returns the number of lives remaining, by games that support the concept of lives.
"""
lives(ale::ALEPtr) = ccall((:lives, libale_c), Cint, (ALEPtr,), ale)

"""
    getEpisodeFrameNumber(ale_instance::ALEPtr)

Returns the frame number since the last reset.
"""
getEpisodeFrameNumber(ale::ALEPtr) =
    ccall((:getEpisodeFrameNumber, libale_c), Cint, (ALEPtr,), ale)


"""
    getRAMSize(ale_instance::ALEPtr)

Returns the size of the RAM.
"""
getRAMSize(ale::ALEPtr) = ccall((:getRAMSize, libale_c), Cint, (ALEPtr,), ale)
_getRAM(ale::ALEPtr, ram::Vector{Cuchar}) =
    ccall((:getRAM, libale_c), Cvoid, (ALEPtr, Ptr{Cuchar}), ale, ram)

"""
    getRAM(ale_instance::ALEPtr)

Returns the snapshot of the RAM as a vector.
"""
function getRAM(ale::ALEPtr)
    output = Array{UInt8, 1}(undef, getRAMSize(ale))
    _getRAM(ale, output)
    return output
end

# Screen function utilities
getScreenWidth(ale::ALEPtr)::Int =
    ccall((:getScreenWidth, libale_c), Cint, (ALEPtr,), ale)
getScreenHeight(ale::ALEPtr)::Int =
    ccall((:getScreenHeight, libale_c), Cint, (ALEPtr,), ale)
getScreen!(ale::ALEPtr, screen_data::Vector{Cuchar}) =
    ccall((:getScreen, libale_c), Cvoid, (ALEPtr, Ptr{Cuchar}), ale, screen_data)
getScreenRGB!(ale::ALEPtr, output_buffer::Vector{Cuchar}) =
    ccall((:getScreenRGB, libale_c), Cvoid, (ALEPtr, Ptr{Cuchar}),
        ale, output_buffer)
getScreenGrayscale!(ale::ALEPtr, output_buffer::Vector{Cuchar}) =
    ccall((:getScreenGrayscale, libale_c), Cvoid, (ALEPtr, Ptr{Cuchar}),
        ale, output_buffer)

"""
    getScreen(ale_instance::ALEPtr)

Returns the current game screen.
"""
function getScreen(ale::ALEPtr)
    w = getScreenWidth(ale)
    h = getScreenHeight(ale)
    screen_data = Array{Cuchar}(undef, w*h) # row-major order
    getScreen!(ale, screen_data)
    screen_data
end

"""
    getScreenRGB(ale_instance::ALEPtr)

Returns the RGB representation of the game screen as a (width * heigth * 3)-element Array{UInt, 1}.
"""
function getScreenRGB(ale::ALEPtr)
    w = getScreenWidth(ale)
    h = getScreenHeight(ale)
    screen_data = Array{Cuchar}(undef, w*h*3)
    getScreenRGB!(ale, screen_data)
    return screen_data
end

"""
    getScreenGrayscale(ale_instance::ALEPtr)

Returns the grayscale representation of the screen.
"""
function getScreenGrayscale(ale::ALEPtr)
    w = getScreenWidth(ale)
    h = getScreenHeight(ale)
    screen_data = Array{Cuchar}(undef, w*h)
    getScreenGrayscale!(ale, screen_data)
    return screen_data
end

"""
    saveState(ale_instance::ALEPtr)

Saves the state of the game
"""
saveState(ale::ALEPtr) = ccall((:saveState, libale_c), ALEState, (ALEPtr,), ale)

"""
    loadState(ale_instance::ALEPtr)

Loads the state of the game
"""
loadState(ale::ALEPtr) = ccall((:loadState, libale_c), ALEState, (ALEPtr,), ale)

"""
    cloneState(ale_instance::ALEPtr)

This makes a copy of the environment state. This copy does *not* include pseudorandomness,
making it suitable for planning purposes.

See also: [`cloneSystemState`](@ref)
"""
cloneState(ale::ALEPtr) = ccall((:cloneState, libale_c), ALEStatePtr,
    (ALEPtr,), ale)

"""
    restoreState(ale_instance::ALEPtr, state::ALEStatePtr)

Reverse operation of cloneState(). This doesn't restore pseudorandomness, so that
repeated calls to restoreState() in the stochastic controls settinig will not lead to the same outcomes.

See also: [`restoreSystemState`](@ref)
"""
restoreState(ale::ALEPtr, state_ref::ALEStatePtr) =
    ccall((:restoreState, libale_c), Cvoid, (ALEPtr, ALEStatePtr), ale, state_ref)

"""
    cloneSystemState(ale_instance::ALEPtr)

This makes a copy of the system & environment state, suitable for serialization. This includes
pseudorandomness and so is *not* suitable for planning purposes.
"""
cloneSystemState(ale::ALEPtr) = ccall((:cloneSystemState, libale_c),
    ALEStatePtr, (ALEPtr,), ale)

"""
    restoreSystemState(ale_instance::ALEPtr, state::ALEStatePtr)

Reverse operation of [`cloneSystemState`](@ref).
"""
restoreSystemState(ale::ALEPtr, state_ref::ALEStatePtr) =
    ccall((:restoreSystemState, libale_c), Cvoid, (ALEPtr, ALEStatePtr),
        ale, state_ref)
deleteState(state::ALEStatePtr) = ccall((:deleteState, libale_c), Cvoid,
    (ALEStatePtr,), state)

"""
    saveScreenPNG(ale_instance::ALEPtr, filename::String)

Save the current screen as a png file.

# Example
```julia-repl
julia> saveScreenPNG(ale, "pongscreenshot.png")
```
"""
saveScreenPNG(ale::ALEPtr, filename::String) = ccall((:saveScreenPNG, libale_c),
    Cvoid, (ALEPtr, Ptr{Cchar}), ale, filename)

function encodeState(state::ALEStatePtr)
    len = encodeStateLen(state)
    buf = Array{Cchar}(undef, len)
    encodeState!(state, buf)
end

function encodeState!(state::ALEStatePtr, buf::Array{Cchar})
    ccall((:encodeState, libale_c), Cvoid, (ALEStatePtr, Ptr{Cchar}, Cint),
        state, buf, length(buf))
    buf
end

encodeStateLen(state::ALEStatePtr) = ccall((:encodeStateLen, libale_c),
    Cint, (ALEStatePtr,), state)

decodeState(buf::Array{Cchar,1}) = ccall((:decodeState, libale_c),
    ALEStatePtr, (Ptr{Cchar}, Cint), buf, length(buf))

"""
    setLoggerMode!(mode::Symbol)

Sets the mode for the Logger for the ALE instance. Three modes(::Symbol) are available.
    :info    ==> logs all details and information
    :warning ==> logs warnings and errors
    :error   ==> logs errors only

# Example
```julia-repl
julia> setLoggerMode!(:info)
```
"""
function setLoggerMode!(mode::Symbol)
    @assert mode ∈ keys(Logger) "$mode is unavailable. Please select one of :info, :warning, :error"
    ccall((:setLoggerMode, libale_c), Cvoid, (Cint,), Logger[mode])
end
