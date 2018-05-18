//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 05  Brian Frank  Creation
//

**
** Duration represents a relative duration of time with nanosecond precision.
**
** Also see [docLang]`docLang::DateTime`.
**
@Serializable { simple = true }
const struct class Duration
{
  ** nano second
  private const Int ticks

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the current value of the system timer.  This method returns
  ** a relative time unrelated to system or wall-clock time.  Typically
  ** it is the number of nanosecond ticks which have elapsed since system
  ** startup.
  **
  native static Duration now()

  **
  ** Convenience for 'now.ticks'.
  **
  private static Int nowTicks() { now.ticks }

  **
  ** Create a Duration which represents the specified number of nanosecond ticks.
  **
  private new make(Int ticks) {
    this.ticks = ticks
  }

  new fromDateTime(Int t) { ticks = t }

  new fromNanaos(Int nanao) { ticks = nanao }

  new fromMicros(Int s) { ticks = s * 1000 }

  new fromMillis(Int s) { ticks = s * 1000_000 }

  new fromSec(Int s) { ticks = s * nsPerSec }

  new fromDay(Int s) { ticks = s * nsPerDay }

  new fromMin(Int s) { ticks = s * nsPerMin }

  new fromHour(Int s) { ticks = s * nsPerHr }

  **
  ** Parse a Str into a Duration according to the Fantom
  ** [literal format]`docLang::Literals#duration`.
  ** If invalid format and checked is false return null,
  ** otherwise throw ParseErr.  The following suffixes
  ** are supported:
  **   ns:   nanoseconds  (x 1)
  **   ms:   milliseconds (x 1,000,000)
  **   sec:  seconds      (x 1,000,000,000)
  **   min:  minutes      (x 60,000,000,000)
  **   hr:   hours        (x 3,600,000,000,000)
  **   day:  days         (x 86,400,000,000,000)
  **
  ** Examples:
  **   Duration.fromStr("4ns")
  **   Duration.fromStr("100ms")
  **   Duration.fromStr("-0.5hr")
  **
  static new fromStr(Str s, Bool checked := true) {
    try
    {
      len := s.size
      x1 := s.get(len-1)
      x2 := s.get(len-2)
      x3 := s.get(len-3)
      dot := s.index(".") > 0

      mult := -1
      suffixLen  := -1
      switch (x1)
      {
        case 's':
          if (x2 == 'n') { mult=1; suffixLen=2; } // ns
          if (x2 == 'm') { mult=1000000; suffixLen=2; } // ms
          //break;
        case 'c':
          if (x2 == 'e' && x3 == 's') { mult=1000000000; suffixLen=3; } // sec
          //break;
        case 'n':
          if (x2 == 'i' && x3 == 'm') { mult=60000000000; suffixLen=3; } // min
          //break;
        case 'r':
          if (x2 == 'h') { mult=3600000000000; suffixLen=2; } // hr
          //break;
        case 'y':
          if (x2 == 'a' && x3 == 'd') { mult=86400000000000; suffixLen=3; } // day
          //break;
      }

      if (mult < 0) throw Err()

      s = s[0..<len-suffixLen]
      if (dot)
        return make(((s.toFloat)*mult).toInt)
      else
        return make(s.toInt*mult)
    }
    catch (Err e)
    {
      if (!checked) return null
      throw ParseErr.make("Duration:$s")
    }
  }

  **
  ** Get the system timer at boot time of the Fantom VM.
  **
  native static Duration boot()

  **
  ** Get the duration which has elapsed since the
  ** Fantom VM was booted which is 'now - boot'.
  **
  static Duration uptime() { now - boot }

  **
  ** Default value is 0ns.
  **
  static const Duration defVal := zero

  **
  ** Min value is equivalent to 'make(Int.minVal)'.
  **
  static const Duration minVal := make(Int.minVal)

  **
  ** Max value is equivalent to 'make(Int.maxVal)'.
  **
  static const Duration maxVal := make(Int.maxVal)

  private static const Duration zero := make(0)

  static const Int nsPerDay   := 86400000000000
  static const Int nsPerHr    := 3600000000000
  static const Int nsPerMin   := 60000000000
  static const Int nsPerSec   := 1000000000
  static const Int nsPerMilli := 1000000
  static const Int micrsPerDay   := 86400000000
  static const Int micrsPerHr    := 3600000000
  static const Int micrsPerMin   := 60000000
  static const Int micrsPerSec   := 1000000
  static const Int micrsPerMilli := 1000
  static const Int secPerDay  := 86400
  static const Int secPerHr   := 3600
  static const Int secPerMin  := 60

//////////////////////////////////////////////////////////////////////////
// Obj Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if same number nanosecond ticks.
  **
  override Bool equals(Obj? obj) {
    if (obj is Duration) {
     return ((Duration)obj).ticks == this.ticks
    }
    return false
  }

  **
  ** Compare based on nanosecond ticks.
  **
  override Int compare(Obj obj) {
    this.ticks - ((Duration)obj).ticks
  }

  **
  ** Return ticks().
  **
  override Int hash() { ticks }

  **
  ** Return string representation of the duration which is a valid
  ** duration literal format suitable for decoding via `fromStr`.
  **
  override Str toStr() {
    if (ticks == 0) return "0ns"
    // if clean millisecond boundary
    ns := toNanos
    if (ns % nsPerMilli == 0)
    {
      if (ns % nsPerDay == 0) return "${ns/nsPerDay}day"
      if (ns % nsPerHr  == 0) return "${ns/nsPerHr}hr"
      if (ns % nsPerMin == 0) return "${ns/nsPerMin}min"
      if (ns % nsPerSec == 0) return "${ns/nsPerSec}sec"
      return "${ns/nsPerMilli}ms"
    }
    // return in nanoseconds
    return "${ns}ns"
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Return number of nanosecond ticks.
  **
  //Int ticks

  **
  ** Negative of this.  Shortcut is -a.
  **
  @Operator Duration negate() { make(-ticks) }

  **
  ** Multiply this with b.  Shortcut is a*b.
  **
  @Operator Duration mult(Int b) { make(ticks * b) }

  **
  ** Multiply this with b.  Shortcut is a*b.
  **
  @Operator Duration multFloat(Float b) { make((ticks * b).toInt) }

  **
  ** Divide this by b.  Shortcut is a/b.
  **
  @Operator Duration div(Int b) { make(ticks / b) }

  **
  ** Divide this by b.  Shortcut is a/b.
  **
  @Operator Duration divFloat(Float b) { make((ticks / b).toInt) }

  **
  ** Add this with b.  Shortcut is a+b.
  **
  @Operator Duration plus(Duration b){ make(ticks + b.ticks) }

  **
  ** Subtract b from this.  Shortcut is a-b.
  **
  @Operator Duration minus(Duration b){ make(ticks - b.ticks) }

  **
  ** Absolute value - if this is a negative duration,
  ** then return its positive value.
  **
  Duration abs() { ticks > 0 ? this : make(-ticks) }

  **
  ** Return the minimum duration between this and that.
  **
  Duration min(Duration that) { ticks < that.ticks ? this : that }

  **
  ** Return the maximum duration between this and that.
  **
  Duration max(Duration that) { ticks > that.ticks ? that : this }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a new Duration with this duration's nanosecond
  ** ticks truncated according to the specified accuracy.
  ** For example 'floor(1min)' will truncate this duration
  ** such that its seconds are 0.0.
  **
  Duration floor(Duration accuracy) { make(ticks - (ticks % accuracy.ticks)) }

  **
  ** Return number of nanosecond ticks.
  **
  Int toNanos() { ticks }

  **
  ** Return number of microsecond ticks.
  **
  Int toMicros() { ticks / 1000 }

  **
  ** Get this duration in milliseconds.  Any fractional
  ** milliseconds are truncated with a loss of precision.
  **
  Int toMillis() { ticks / 1000_1000 }

  **
  ** Get this duration in seconds.  Any fractional
  ** seconds are truncated with a loss of precision.
  **
  Int toSec() { ticks / 1000_000_000  }

  **
  ** Get this duration in minutes.  Any fractional
  ** minutes are truncated with a loss of precision.
  Int toMin() { ticks / nsPerMin }

  **
  ** Get this duration in hours.  Any fractional
  ** hours are truncated with a loss of precision.
  **
  Int toHour() { ticks / nsPerHr }

  **
  ** Get this duration in 24 hour days.  Any fractional
  ** days are truncated with a loss of precision.
  **
  Int toDay() { ticks / nsPerDay }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  **
  ** Return human friendly string representation.
  ** TODO: enhance this for pattern
  **
  Str toLocale() { toStr }

//////////////////////////////////////////////////////////////////////////
// Conversions
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this Duration as a Fantom code literal.
  **
  Str toCode() { toStr }

  **
  ** Format this duration according to ISO 8601.  Also see `fromIso`.
  **
  ** Examples:
  **   8ns.toIso             =>  PT0.000000008S
  **   100ms.toIso           =>  PT0.1S
  **   (-20sec).toIso        =>  -PT20S
  **   3.5min.toIso          =>  PT3M30S
  **   1day.toIso            =>  PT24H
  **   (1day+2hr+3min).toIso =>  P1DT2H3M
  **
  Str toIso() { throw UnsupportedErr("TODO") }

  **
  ** Parse a duration according to ISO 8601.  If invalid format
  ** and checked is false return null, otherwise throw ParseErr.
  ** The following restrictions are enforced:
  **   - Cannot specify a 'Y' year or 'M' month component
  **     since it is ambiguous
  **   - Only the 'S' seconds component may include a fraction
  **   - Only nanosecond resolution is supported
  ** See `toIso` for example formats.
  **
  static Duration fromIso(Str s, Bool checked := true) { throw UnsupportedErr("TODO") }

}