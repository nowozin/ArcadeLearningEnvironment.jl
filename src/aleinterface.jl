
if isfile(joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl"))
    include("../deps/deps.jl")
else
    error("libale_c not properly installed. Please run Pkg.build(\"ArcadeLearningEnvironment\")")
end

const ALEInterface = Cvoid
const ALEPtr = Ptr{ALEInterface}
const ALEState = Cvoid
const ALEStatePtr = Ptr{ALEState}

const Logger = Dict(
    :info => 0,
    :warning => 1,
    :error => 2
)

"""
Creates a new ALE instance.
"""
ALE_new() = ccall((:ALE_new, libale_c), ALEPtr, ())

"""
Destroys the passed ALE instance pointer. Acts as a destructor. Use with caution.
"""
ALE_del(ale::ALEPtr) = ccall((:ALE_del, libale_c), Cvoid, (ALEPtr,), ale)

"""
Returns the string value held by the ALE instance's field with the same name as `key`.
"""
function getString(ale::ALEPtr, key::String)
    res = ccall((:getString, libale_c), Ptr{Cchar}, (ALEPtr, Ptr{Cchar}),
        ale, key)
    bytestring(res)
end

"""
Returns the integer value held by the ALE instance's field with the same name as `key`.
"""
getInt(ale::ALEPtr, key::String) = ccall((:getInt, libale_c), Cint,
    (ALEPtr, Ptr{Cchar}), ale, key)

"""
Returns the boolean value held by the ALE instance's field with the same name as `key`.
"""
getBool(ale::ALEPtr, key::String) = ccall((:getBool, libale_c), Cint,
    (ALEPtr, Ptr{Cchar}), ale, key) > 0

"""
Returns the float value held by the ALE field with the same name as `key`.
"""
getFloat(ale::ALEPtr, key::String) = ccall((:getFloat, libale_c), Float32,
    (ALEPtr, Ptr{Cchar}), ale, key)

"""
Modifies the ALE instance field value with the same name as `key` to the passed String value.
"""
setString(ale::ALEPtr, key::String, value::String) =
    ccall((:setString, libale_c), Cvoid, (ALEPtr, Ptr{Cchar}, Ptr{Cchar}),
        ale, key, value)

"""
Modifies the ALE instance field value with the same name as `key` to the passed integer value.
"""
setInt(ale::ALEPtr, key::String, value::Cint) = ccall((:setInt, libale_c),
    Cvoid, (ALEPtr, Ptr{Cchar}, Cint), ale, key, value)

"""
Modifies the ALE instance field value with the same name as `key` to the passed boolean value.
"""
setBool(ale::ALEPtr, key::String, value::Bool) = ccall((:setBool, libale_c),
    Cvoid, (ALEPtr, Ptr{Cchar}, Cint), ale, key, value)

"""
Modifies the ALE instance field with the same name as `key` to the passed floating point value.
"""
setFloat(ale::ALEPtr, key::String, value::Cfloat) =
    ccall((:setFloat, libale_c), Cvoid, (ALEPtr, Ptr{Cchar}, Cfloat),
        ale, key, value)

"""
Loads the game binary whose path has been passed. This is neccessary after changing a setting for a setting to take effect.
"""
loadROM(ale::ALEPtr, rom_file::String) = ccall((:loadROM, libale_c), Cvoid,
    (ALEPtr, Ptr{Cchar}), ale, rom_file)

"""
Applies an action to the game and returns the reward. It is the user's
responsibility to check if the game has ended and reset when neccessary -
this function will keep pushing buttons on the game over screen.
"""
act(ale::ALEPtr, action::Cint) =
    ccall((:act, libale_c), Cint, (ALEPtr, Cint), ale, action)

"""
Returns a boolean value that tells whether the game is over. Any actions performed
from hereon until the next `reset_game()` have no effect.
"""
game_over(ale::ALEPtr) =
    ccall((:game_over, libale_c), Cint, (ALEPtr,), ale) > 0

"""
Resets the game.
"""
reset_game(ale::ALEPtr) = ccall((:reset_game, libale_c), Cvoid, (ALEPtr,), ale)

"""
Returns the vector of the legal set of actions needed the play the game.
"""
function getLegalActionSet(ale::ALEPtr)
    actions = Cint[]
    _getLegalActionSet!(ale, actions)
    actions
end

function _getLegalActionSet!(ale::ALEPtr, actions::Vector{Cint})
    resize!(actions, getLegalActionSize(ale))
    ccall((:getLegalActionSet, libale_c), Cvoid, (ALEPtr, Ptr{Cint}),
        ale, actions)
end

"""
Returns the size of the legal action set. Not to be confused with `getLegalActionSet`
"""
getLegalActionSize(ale::ALEPtr) =
    ccall((:getLegalActionSize, libale_c), Cint, (ALEPtr,), ale)

"""
Returns the set of actions that actually affect the game.
"""
function getMinimalActionSet(ale::ALEPtr)
    actions = Cint[]
    _getMinimalActionSet!(ale, actions)
    actions
end

function _getMinimalActionSet!(ale::ALEPtr, actions::Vector{Cint})
    resize!(actions, getMinimalActionSize(ale))
    ccall((:getMinimalActionSet, libale_c), Cvoid, (ALEPtr, Ptr{Cint}),
        ale, actions)
end

"""
Returns the size of the minimal action set required to play the game.
"""
getMinimalActionSize(ale::ALEPtr) =
    ccall((:getMinimalActionSize, libale_c), Cint, (ALEPtr,), ale)

"""
Returns the frame number since the ALE instance was created.
"""
getFrameNumber(ale::ALEPtr) =
    ccall((:getFrameNumber, libale_c), Cint, (ALEPtr,), ale)
"""
Returns the number of lives remaining, by games that support the concept of lives.
"""
lives(ale::ALEPtr) = ccall((:lives, libale_c), Cint, (ALEPtr,), ale)

"""
Returns the frame number since the last reset.
"""
getEpisodeFrameNumber(ale::ALEPtr) =
    ccall((:getEpisodeFrameNumber, libale_c), Cint, (ALEPtr,), ale)

function getScreen(ale::ALEPtr)
    w = getScreenWidth(ale)
    h = getScreenHeight(ale)
    screen_data = Array{Cuchar}(undef, w*h) # row-major order
    getScreen!(ale, screen_data)
    screen_data
end
getScreen!(ale::ALEPtr, screen_data::Vector{Cuchar}) =
    ccall((:getScreen, libale_c), Cvoid, (ALEPtr, Ptr{Cuchar}), ale, screen_data)

"""
Returns the size of the RAM
"""
getRAMSize(ale::ALEPtr) = ccall((:getRAMSize, libale_c), Cint, (ALEPtr,), ale)
_getRAM(ale::ALEPtr, ram::Vector{Cuchar}) =
    ccall((:getRAM, libale_c), Cvoid, (ALEPtr, Ptr{Cuchar}), ale, ram)

"""
Returns the snapshot of the RAM as a vector.
"""
function getRAM(ale::ALEPtr)
    output = Array{UInt8, 1}(undef, getRAMSize(ale))
    _getRAM(ale, output)
    return output
end

# Screen function utilities
getScreenWidth(ale::ALEPtr) =
    ccall((:getScreenWidth, libale_c), Cint, (ALEPtr,), ale)
getScreenHeight(ale::ALEPtr) =
    ccall((:getScreenHeight, libale_c), Cint, (ALEPtr,), ale)

getScreenRGB(ale::ALEPtr, output_buffer::Vector{Cuchar}) =
    ccall((:getScreenRGB, libale_c), Cvoid, (ALEPtr, Ptr{Cuchar}),
        ale, output_buffer)
getScreenGrayscale(ale::ALEPtr, output_buffer::Vector{Cuchar}) =
    ccall((:getScreenGrayscale, libale_c), Cvoid, (ALEPtr, Ptr{Cuchar}),
        ale, output_buffer)


"""
Saves the state of the game
"""
saveState(ale::ALEPtr) = ccall((:saveState, libale_c), Cvoid, (ALEPtr,), ale)

"""
Loads the state of the game
"""
loadState(ale::ALEPtr) = ccall((:loadState, libale_c), Cvoid, (ALEPtr,), ale)

"""
This makes a copy of the environment state. This copy does *not* include pseudorandomness,
making it suitable for planning purposes. By contrast, see cloneSystemState.
"""
cloneState(ale::ALEPtr) = ccall((:cloneState, libale_c), ALEStatePtr,
    (ALEPtr,), ale)

"""
Reverse operation of cloneState(). This doesn't restore pseudorandomness, so that
repeated calls to restoreState() in the stochastic controls settinig will not lead to the same outcomes.
By contrast, see restoreSystemState.
"""
restoreState(ale::ALEPtr, state::ALEStatePtr) =
    ccall((:restoreState, libale_c), Cvoid, (ALEPtr, ALEStatePtr), ale, state)

"""
This makes a copy of the system & environment state, suitable for serialization. This includes
pseudorandomness and so is *not* suitable for planning purposes.
"""
cloneSystemState(ale::ALEPtr) = ccall((:cloneSystemState, libale_c),
    ALEStatePtr, (ALEPtr,), ale)

"""
Reverse operation of cloneSystemState.
"""
restoreSystemState(ale::ALEPtr, state::ALEStatePtr) =
    ccall((:restoreSystemState, libale_c), Cvoid, (ALEPtr, ALEStatePtr),
        ale, state)
deleteState(state::ALEStatePtr) = ccall((:deleteState, libale_c), Cvoid,
    (ALEStatePtr,), state)

"""
Save the current screen as a png file
"""
saveScreenPNG(ale::ALEPtr, filename::String) = ccall((:saveScreenPNG, libale_c),
    Cvoid, (ALEPtr, Ptr{Cchar}), ale, filename)

function encodeState(state::ALEStatePtr)
    len = encodeStateLen(state)
    buf = Array{Cchar}(len)
    ccall((:encodeState, libale_c), Cvoid, (ALEStatePtr, Ptr{Cchar}, Cint),
        state, buf, len)
    buf
end
encodeStateLen(state::ALEStatePtr) = ccall((:encodeStateLen, libale_c),
    Cint, (ALEStatePtr,), state)
decodeState(buf::Array{Cchar,1}) = ccall((:decodeState, libale_c),
    ALEStatePtr, (Ptr{Cchar}, Cint), buf, length(buf))

"""
Sets the mode for the Logger for the ALE instance. Three modes(::Symbol) are available.
    :info    ==> logs all details and information
    :warning ==> logs warnings and errors
    :error   ==> logs errors only
"""
function setLoggerMode!(mode::Symbol)
    @assert mode ∈ keys(Logger) "$mode is unavailable. Please select one of :info, :warning, :error"
    ccall((:setLoggerMode, libale_c), Cvoid, (Cint,), Logger[mode])
end

export
    # Types
    ALEInterface,
    ALEPtr,
    # Functions
    ALE_new,
    ALE_del,
    getInt,
    getBool,
    getFloat,
    setString,
    setInt,
    setBool,
    setFloat,
    loadROM,
    act,
    game_over,
    reset_game,
    getLegalActionSet,
    getLegalActionSize,
    getMinimalActionSet,
    getMinimalActionSize,
    getFrameNumber,
    lives,
    getEpisodeFrameNumber,
    getScreen,
    getScreen!,
    getRAM,
    getRAMSize,
    getScreenWidth,
    getScreenHeight,
    getScreenRGB,
    getScreenGrayscale,
    saveState,
    loadState,
    cloneState,
    restoreState,
    cloneSystemState,
    restoreSystemState,
    deleteState,
    saveScreenPNG,
    encodeState,
    encodeStateLen,
    decodeState,
    setLoggerMode!
