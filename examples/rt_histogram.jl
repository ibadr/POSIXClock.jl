import POSIXClock

typeof(Pkg.installed("PlotlyJS"))==Void &&
  error("Please install PlotlyJS package to run this example.")
import PlotlyJS; pl=PlotlyJS

const interval = 100000 # 100us
function run()
  t = POSIXClock.timespec(0,0)
  POSIXClock.gettime!(t,POSIXClock.CLOCK_MONOTONIC)
  nItr = div(60000000000,interval)
  # pre-allocate samples array
  differ = Vector{Int64}(nItr+1)
  # pre-allocate timespec
  start_t = POSIXClock.timespec(0,0)
  stop_t = POSIXClock.timespec(0,0)

  # Lock future memory allocations, disable GC
  ccall(:mlockall, Cint, (Cint,), 2) # CAUTION: will crash Julia on future memory allocations
  gc_enable(false)

  n = 0
  @time while n <= nItr
    n+=1
    POSIXClock.gettime!(start_t,POSIXClock.CLOCK_MONOTONIC)
    POSIXClock.nanosleep!(t,interval)
    POSIXClock.gettime!(stop_t,POSIXClock.CLOCK_MONOTONIC)
    differ[n]=stop_t-start_t
  end

  # Unlock memory allocations, enable GC
  ccall(:munlockall, Cint, ())
  gc_enable(true)

  return differ
end

function getHistogram(differences::Vector{Int64})
  trace1 = pl.histogram(x=(differences-interval)/1000, opacity=0.75)
  layout = pl.Layout(barmode="overlay")
  return ([trace1],layout)
end

const d=run()
(data,layout) = getHistogram(d)
pl.plot(data,layout)
