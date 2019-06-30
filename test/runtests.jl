using ArcadeLearningEnvironment
using Test

setLoggerMode!(:error)

@testset "alien" begin
    ale = ALE_new()
    loadROM(ale, "alien")
    actionset = getLegalActionSet(ale)
    minactionset = getMinimalActionSet(ale)
    @test actionset == minactionset
    @test length(actionset) == 18
    for a in actionset
        act(ale, a)
    end
    @test false == game_over(ale)
    @test 3 == lives(ale)
    @test 18 == getFrameNumber(ale)
    @test 18 == getEpisodeFrameNumber(ale)
    @test length(getScreen(ale)) == 33600 == getScreenWidth(ale) * getScreenHeight(ale)
    getScreen(ale)
    s = getScreenRGB(ale)
    act(ale, Int32(0))
    s = getScreenGrayscale(ale)
    ALE_del(ale)
end

@testset "all roms" begin
    roms = readdir(joinpath(dirname(pathof(ArcadeLearningEnvironment)), "..", "deps", "roms"))
    for rom in roms
        if rom == "defender.bin"
            @warn("defender.bin not tested")
            continue
        end
        ale = ALE_new()
        setBool(ale, "color_averaging", true)
        setInt(ale, "frame_skip", Int32(4))
        setFloat(ale, "repeat_action_probability",
                 Float32(0.))
        loadROM(ale, string(split(rom, ".")[1]))
        actionset = getLegalActionSet(ale)
        reset_game(ale)

        for i in 1:1000
            act(ale, rand(actionset))
            game_over(ale) && reset_game(ale)
        end

        width = getScreenWidth(ale)
        height = getScreenHeight(ale)
        getScreenGrayscale(ale)
        getScreenRGB(ale)
        getScreen(ale)

        @test true

        state_ref = cloneState(ale)
        pre_restore_state = encodeState(state_ref)
        deleteState(state_ref)
        state_ref = decodeState(pre_restore_state)
        restoreState(ale, state_ref)
        post_restore_state = ale |> cloneState |> encodeState
        @test pre_restore_state == post_restore_state
        deleteState(state_ref)

        state_ref = cloneSystemState(ale)
        pre_restore_state = encodeState(state_ref)
        state_ref = decodeState(pre_restore_state)
        restoreSystemState(ale, state_ref)
        post_restore_state = ale |> cloneSystemState |> encodeState
        @test post_restore_state == pre_restore_state
        deleteState(state_ref)

        ALE_del(ale)
    end
end
