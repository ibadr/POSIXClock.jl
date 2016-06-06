import POSIXClock

typeof(Pkg.installed("PlotlyJS"))==Void &&
  error("Please install PlotlyJS package to run this example.")
import PlotlyJS; pl=PlotlyJS

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

function getHistogram(differences::Vector{Int64})
  trace1 = pl.histogram(x=(differences)/1000, opacity=0.75)
  layout = pl.Layout(barmode="overlay")
  return ([trace1],layout)
end

const d=run()
(data,layout) = getHistogram(d)
pl.plot(data,layout)
