import POSIXClock

typeof(Pkg.installed("Gadfly"))==Void &&
  error("Please install Gadfly package to run this example.")
import Gadfly; pl=Gadfly

const interval = 200000 # 200us
function run()
  nItr = div(60000000000,interval)
  # pre-allocate samples array
  differ = Vector{Int64}(nItr+1)
  # pre-allocate timespec
  t = POSIXClock.timespec(0,0)
  actual_t = POSIXClock.timespec(0,0)

  # Lock future memory allocations, disable GC
  ccall(:mlockall, Cint, (Cint,), 2) # CAUTION: will crash Julia on future memory allocations
  gc_enable(false)

  n = 0
  POSIXClock.gettime!(t,POSIXClock.CLOCK_MONOTONIC)
  @time while n <= nItr
    POSIXClock.nanosleep!(t,interval)
    POSIXClock.gettime!(actual_t,POSIXClock.CLOCK_MONOTONIC)
    n+=1
    differ[n]=actual_t-t
  end

  # Unlock memory allocations, enable GC
  ccall(:munlockall, Cint, ())
  gc_enable(true)

  return differ
end

const d=run()
histplot=pl.plot(
  x=d/1000, pl.Geom.histogram(),
  pl.Guide.xlabel("Latency (us)"),
  pl.Guide.ylabel("Histogram counts"))
