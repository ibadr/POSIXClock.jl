import POSIXClock

function main()
  interval = 100000 # 100us

  t::POSIXClock.timespec = POSIXClock.gettime(POSIXClock.CLOCK_MONOTONIC)

  n = 0
  # Lock future memory allocations
  ccall(:mlockall, Cint, (Cint,), 2) # CAUTION: will crash Julia on future memory allocations

  @time while n <= 50000
    n+=1
    t = POSIXClock.nanosleep(t,interval)
  end # time should be around 5 seconds
end

main()
