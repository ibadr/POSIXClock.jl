typealias clockid_t Int32
@enum(CLOCK_ID,
  CLOCK_REALTIME = 0,
  CLOCK_MONOTONIC = 1
)

@enum(TIMER_FLAG,
  TIMER_RELTIME = 0,
  TIMER_ABSTIME = 1
)

const BILLION = 1000000000

if Base.Sys.ARCH==:x86 || Base.Sys.ARCH==:arm
  typealias time_t Clong
elseif Base.Sys.ARCH==:x86_64
  typealias time_t Clonglong
else # TODO support more architectures
  error("Unsupported architecture")
end

type timespec
  sec::time_t
  nsec::Clong
end

function gettime!(result::timespec,clockid::CLOCK_ID)
  s = ccall((:clock_gettime,librt),Int32,(clockid_t,Ref{timespec}),
    clockid,Ref(result))
  s!=0 && error("Error in gettime()")
  return result
end

function nanosleep(clockid::CLOCK_ID, t::timespec, flag::TIMER_FLAG = TIMER_ABSTIME)
  flag==TIMER_RELTIME && error("Relative time nanosleep not supported yet!")
  rem = timespec(0,0)
  s = ccall((:clock_nanosleep,librt),Int32,(clockid_t,Int32,Ref{timespec},Ref{timespec}),
    clockid,flag,Ref(t),Ref(rem))
  s!=0 && error("Error in nanosleep()")
  return nothing
end

function nanosleep!(t::timespec,nanosec::Clong)
  t.nsec+=nanosec
  while t.nsec >= BILLION
    t.nsec -= BILLION
    t.sec += 1
  end
  nanosleep(CLOCK_MONOTONIC,t,TIMER_ABSTIME)
end
