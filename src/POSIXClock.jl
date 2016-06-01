module POSIXClock

const librt = Libdl.find_library(["librt.so"])
const juliasrc = "julia"
include(joinpath(juliasrc,"clock.jl"))

end
