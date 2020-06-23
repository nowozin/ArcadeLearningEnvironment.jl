using MD5
using LibArchive_jll
using Pkg.Artifacts

function import_roms(dir)
    md5_target = Dict{String, String}()
    for line in readlines(joinpath(dir, "md5.txt"))[3:end] # remove 2 header lines
        md5, name = split(line, " ")
        md5_target[md5] = name
    end
    md5_target
    md5_source = Dict{String, String}()
    for filename in readdir(joinpath(dir, "ROMS"))
        key = bytes2hex(open(md5, joinpath(dir, "ROMS", filename)))
        if haskey(md5_source, key)
            rm(joinpath(dir, "ROMS", filename)) # duplicate
        else
            md5_source[key] = filename
        end
    end
    for (md5, filename) in md5_source
        if haskey(md5_target, md5)
            if filename != md5_target[md5]
                mv(joinpath(dir, "ROMS", filename),
                   joinpath(dir, "ROMS", md5_target[md5]), force = true)
            end
        else
            rm(joinpath(dir, "ROMS", filename)) # not supported
        end
    end
end

artifact_toml = joinpath(@__DIR__, "..", "Artifacts.toml")
rom_hash = artifact_hash("atari_roms", artifact_toml)
if rom_hash == nothing || !artifact_exists(rom_hash)
    rom_hash = create_artifact() do artifact_dir
        download("https://raw.githubusercontent.com/mgbellemare/Arcade-Learning-Environment/v0.6.1/md5.txt", joinpath(artifact_dir, "md5.txt"))
        download("http://www.atarimania.com/roms/Roms.rar", joinpath(artifact_dir, "Roms.rar"))
        cd(artifact_dir)
        bsdtar() do exe
            run(`$exe -xf $(joinpath(artifact_dir, "Roms.rar"))`)
            run(`$exe -xf $(joinpath(artifact_dir, "ROMS.zip"))`)
        end
        rm(joinpath(artifact_dir, "Roms.rar"))
        rm(joinpath(artifact_dir, "ROMS.zip"))
        rm(joinpath(artifact_dir, "HC ROMS.zip"))
        import_roms(artifact_dir)
    end
    bind_artifact!(artifact_toml, "atari_roms", rom_hash)
end
