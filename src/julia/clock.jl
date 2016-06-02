typealias clockid_t Int32
@enum(CLOCK_ID,
  CLOCK_REALTIME = 0,
  CLOCK_MONOTONIC = 1
)

const BILLION = 1000000000

if Base.Sys.WORD_SIZE==32
  typealias time_t Clong
elseif Base.Sys.WORD_SIZE==64
  typealias time_t Clonglong
else
  error("Unsupported architecture")
end

immutable timespec
  sec::time_t
  nsec::Clong
end

type __timespec
  sec::time_t
  nsec::Clong
end

module TIMER_FLAG
  const RELTIME = Val{0}
  const ABSTIME = Val{1}
end

function gettime(clockid::CLOCK_ID)
  result = __timespec(0,0)
  s = ccall((:clock_gettime,librt),Int32,(clockid_t,Ref{__timespec}),
    clockid,Ref(result))
  s!=0 && error("Error in gettime()")
  return timespec(result.sec,result.nsec)
end

const tx = __timespec(0,0) # hack, to avoid unnecessary memory allocation
function nanosleep(clockid::CLOCK_ID, t::timespec, ::Type{TIMER_FLAG.ABSTIME})
  tx.sec=t.sec;tx.nsec=t.nsec
  f = pointer_from_objref(tx) # hack, to avoid unnecessary memory allocation
  s = ccall((:clock_nanosleep,librt),Int32,(clockid_t,Int32,Ptr{__timespec},Ptr{__timespec}),
    clockid,1,f,f)
  s!=0 && error("Error in nanosleep()")
  return nothing
end
nanosleep(clockid::CLOCK_ID, t::timespec) = nanosleep(clockid, t, TIMER_FLAG.ABSTIME)

function nanosleep(clockid::CLOCK_ID, t::timespec, ::Type{TIMER_FLAG.RELTIME})
  error("Relative time nanosleep not supported yet!")
  return nothing
end

function nanosleep(t::timespec,nanosec::Clong)
  nsec=t.nsec; sec=t.sec
  nsec+=nanosec
  while nsec >= BILLION
    nsec -= BILLION
    sec += 1
  end
  tm = timespec(sec,nsec)
  nanosleep(CLOCK_MONOTONIC,tm)
  return tm
end
