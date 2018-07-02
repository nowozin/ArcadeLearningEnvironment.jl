
libale_detected = false
if haskey(ENV, "LIBALE_HOME")
    info("LIBALE_HOME environment detected: $(ENV["LIBALE_HOME"])")
    info("Trying to load existing libale_c...")
    lib = Libdl.find_library(["libale_c.so","libale_c.dll"],
        [joinpath(ENV["LIBALE_HOME"], "ale_python_interface")])
    if isempty(lib) == false
        info("Existing libalec detected at $lib, skip building...")
        libale_detected = true
    else
        info("Failed to load existing libalec, trying to build from source...")
    end
end

using BinDeps
@BinDeps.setup
if libale_detected == false
    if is_windows()
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
                `rm -rf Arcade-Learning-Environment-0.6.0`
                `rm -rf v0.6.0.zip`
                `wget
                https://github.com/mgbellemare/Arcade-Learning-Environment/archive/v0.6.0.zip`
                `unzip v0.6.0.zip`
                FileRule(joinpath(_libdir, "libale_c.so"),
                    @build_steps begin
                        ChangeDirectory("$_aledir")
                        `cmake .`
                        `make`
                        `cp ale_python_interface/libale_c.so $_libdir`
                    end)
            end
        end), libale_c)
    @BinDeps.install Dict(:libale_c => :libale_c)
end

