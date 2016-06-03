import POSIXClock

typeof(Pkg.installed("PlotlyJS"))==Void &&
  error("Please install PlotlyJS package to run this example.")
import PlotlyJS; pl=PlotlyJS

const interval = 100000 # 100us
function run()
  t::POSIXClock.timespec = POSIXClock.gettime(POSIXClock.CLOCK_MONOTONIC)
  nItr = div(60000000000,interval)
  # pre-allocate samples array
  differ = Vector{Int64}(nItr+1)

  # Lock future memory allocations, disable GC
  ccall(:mlockall, Cint, (Cint,), 2) # CAUTION: will crash Julia on future memory allocations
  gc_enable(false)

  n = 0
  @time while n <= nItr
    n+=1
    start = POSIXClock.gettime(POSIXClock.CLOCK_MONOTONIC)
    t = POSIXClock.nanosleep(t,interval)
    stop = POSIXClock.gettime(POSIXClock.CLOCK_MONOTONIC)
    differ[n]=stop-start
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
