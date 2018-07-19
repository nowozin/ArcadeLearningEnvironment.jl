using ArcadeLearningEnvironment
using Compat.Test

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
s = zeros(Cuchar, 3*33600)
getScreenRGB(ale, s)
act(ale, Int32(0))
s = zeros(Cuchar, 33600)
getScreenGrayscale(ale, s)
ALE_del(ale)

