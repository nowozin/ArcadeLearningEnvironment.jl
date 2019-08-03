import Compat: @info, @error, Sys.iswindows, mv, GC
using Compat.Libdl
libale_detected = false
if haskey(ENV, "LIBALE_HOME")
    @info("LIBALE_HOME environment detected: $(ENV["LIBALE_HOME"])")
    @info("Trying to load existing libale_c...")
    lib = Libdl.find_library(["libale_c.so","libale_c.dll"],
        [joinpath(ENV["LIBALE_HOME"], "ale_python_interface")])
    if isempty(lib) == false
        @info("Existing libalec detected at $lib, skip building...")
        libale_detected = true
    else
        @info("Failed to load existing libalec, trying to build from source...")
    end
end

import Compat.LibGit2: clone, checkout!, GitRepo
function getroms(romdir)
    @info("Downloading roms to $romdir")
    tmpdir = mktempdir()
    clone("https://github.com/openai/atari-py", tmpdir)
    repo = GitRepo(tmpdir)
    checkout!(repo, "03676470b32711dfa77186712ff9f74f3afdc512")
    GC.gc()
    mv(joinpath(tmpdir, "atari_py", "atari_roms"), romdir, force = true)
    rm(tmpdir, recursive = true, force = true)
end

using BinDeps
@BinDeps.setup
if libale_detected == false
    if Sys.iswindows()
	info("This package currently does not support Windows.")
        info("You may want to try using the prebuilt libale_c.dll file from")
        info("https://github.com/pkulchenko/alecwrap and setting the")
        info("LIBALE_HOME environment variable to the directory containing")
        info("the file, then issuing Pkg.build(\"ArcadeLearningEnvironment\")")
        error("Automatic building of libale_c.dll on Windows is currently not supported yet.")
    end

    libale_c = library_dependency("libale_c",
        aliases=["libale_c.so", "libale_c.dll"])

    _prefix = joinpath(BinDeps.depsdir(libale_c), "usr")
    _srcdir = joinpath(BinDeps.depsdir(libale_c), "src")
    _aledir = joinpath(_srcdir, "Arcade-Learning-Environment-0.6.0")
    _cmakedir = joinpath(_aledir, "build")
    _libdir = joinpath(_prefix, "lib")
    provides(BuildProcess,
        (@build_steps begin
            CreateDirectory(_srcdir)
            CreateDirectory(_libdir)
            @build_steps begin
                ChangeDirectory(_srcdir)
                `rm -rf Arcade-Learning-Environment-0.5.2`
                `rm -rf v0.5.2.zip`
				`rm -rf Arcade-Learning-Environment-0.6.0`
                `rm -rf v0.6.0.zip`
                `curl -LO https://github.com/mgbellemare/Arcade-Learning-Environment/archive/v0.6.0.zip`
                `unzip v0.6.0.zip`
                FileRule(joinpath(_libdir, "libale_c.so"),
                    @build_steps begin
                        ChangeDirectory("$_aledir")
                        `cmake -DUSE_SDL=OFF -DBUILD_EXAMPLES=OFF -DBUILD_CPP_LIB=OFF -DBUILD_CLI=OFF .`
                        `make -j 4`
                        `cp ale_python_interface/libale_c.so $_libdir`
                    end)
            end
        end), libale_c)
    @BinDeps.install Dict(:libale_c => :libale_c)
    getroms(joinpath(@__DIR__, "roms"))
end
