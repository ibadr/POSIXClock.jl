import POSIXClock

function main()
  interval = 100000 # 100us

  t::POSIXClock.timespec = POSIXClock.gettime(POSIXClock.CLOCK_MONOTONIC)

  n = 0
  # Lock future memory allocations, disable GC
  ccall(:mlockall, Cint, (Cint,), 2) # CAUTION: will crash Julia on future memory allocations
  gc_enable(false)

  @time while n <= div(5000000000,interval)
    n+=1
    t = POSIXClock.nanosleep(t,interval)
  end # time should be around 5 seconds

  # Unlock memory allocations, enable GC
  ccall(:munlockall, Cint, ())
  gc_enable(true)

  return nothing
end

main()
