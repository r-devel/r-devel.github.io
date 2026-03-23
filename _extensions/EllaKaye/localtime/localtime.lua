-- localtime.lua
-- Quarto shortcode extension to display times in the reader's local timezone.
-- Usage: {{< localtime YYYY-MM-DD HH:MM TZ >}}

local counter = 0
local luxon_script_injected = false

-- Timezone abbreviations mapped to either:
--   a string  → IANA timezone name  (browser Intl handles DST automatically)
--   a number  → fixed UTC offset in minutes (positive = east of UTC)
-- Where an abbreviation is ambiguous, the most widely-used interpretation is chosen.
local TZ_ZONES = {
  -- Universal
  UTC = "UTC", GMT = "UTC",

  -- North America (DST-aware → IANA)
  NST = "America/St_Johns",    NDT = "America/St_Johns",
  AST = "America/Halifax",     ADT = "America/Halifax",
  EST = "America/New_York",    EDT = "America/New_York",
  CST = "America/Chicago",     CDT = "America/Chicago",
  MST = "America/Denver",      MDT = "America/Denver",
  PST = "America/Los_Angeles", PDT = "America/Los_Angeles",
  AKST = "America/Anchorage",  AKDT = "America/Anchorage",
  HST = -600,                  HDT = -570,

  -- South America (fixed offsets, minutes)
  VET = -240, BOT = -240, PYT = -240, CLT = -240,
  AMT = -240, GYT = -240,
  COT = -300, PET = -300, ECT = -300,
  BRT = -180, ART = -180, UYT = -180, SRT = -180,
  PYST = -180, CLST = -180,
  BRST = -120,

  -- Europe (DST-aware → IANA)
  WET  = "Europe/Lisbon",   WEST = "Europe/Lisbon",
  BST  = "Europe/London",
  CET  = "Europe/Paris",    CEST = "Europe/Paris",
  EET  = "Europe/Helsinki", EEST = "Europe/Helsinki",
  MSK  = 180,               TRT  = 180,

  -- Africa (fixed offsets)
  WAT = 60, CAT = 120, SAST = 120, EAT = 180,

  -- Middle East
  IDT  = 180,
  IRST = 210, IRDT = 270,

  -- Asia (fixed offsets)
  GST  = 240, AZT  = 240,
  AFT  = 270,
  PKT  = 300, UZT  = 300,
  IST  = 330, SLST = 330,
  NPT  = 345,
  BDT  = 360, BTT  = 360,
  MMT  = 390,
  ICT  = 420, WIB  = 420, HOVT = 420,
  HKT  = 480, SGT  = 480, MYT  = 480,
  PHT  = 480, WITA = 480, AWST = 480,
  JST  = 540, KST  = 540, WIT  = 540, TLT = 540,

  -- Australia & Pacific (DST-aware → IANA, others fixed)
  ACST = "Australia/Adelaide", ACDT = "Australia/Adelaide",
  AEST = "Australia/Sydney",   AEDT = "Australia/Sydney",
  LHST = 630,                  LHDT = 660,
  SBT  = 660, NCT = 660, NFT = 660,
  NZST = "Pacific/Auckland",   NZDT = "Pacific/Auckland",
  FJT  = 720, TOT  = 780, LINT = 840,
  SST  = -660, WST = -660,
  MART = -570, GAMT = -540,
}

-- Parse a timezone string.
-- Returns a string (IANA name) or number (offset in minutes) for Luxon, or nil if unrecognised.
local function parse_tz(tz_str)
  if not tz_str or tz_str == "" then return "UTC" end

  local upper = tz_str:upper()

  -- Direct abbreviation lookup
  local zone = TZ_ZONES[upper]
  if zone ~= nil then return zone end

  -- Already an IANA name (contains "/")
  if tz_str:find("/", 1, true) then
    return tz_str
  end

  -- Convert h/m strings + sign to total minutes
  local function to_minutes(sign, h, m)
    local mins = tonumber(h) * 60 + (tonumber(m) or 0)
    return sign == "+" and mins or -mins
  end

  -- Handle UTC+X or GMT+X (e.g. UTC+5, UTC+5:30, GMT-8)
  local after_prefix = upper:match("^UTC(.+)$") or upper:match("^GMT(.+)$")
  if after_prefix then
    local sign, h, m = after_prefix:match("^([%+%-])(%d+):?(%d*)$")
    if sign and h then
      return to_minutes(sign, h, m ~= "" and m or "0")
    end
  end

  -- Handle bare ±HH:MM or ±HHMM
  local sign2, h2, m2 = tz_str:match("^([%+%-])(%d%d):?(%d%d)$")
  if sign2 and h2 and m2 then
    return to_minutes(sign2, h2, m2)
  end

  -- Handle bare ±H or ±HH
  local sign3, h3 = tz_str:match("^([%+%-])(%d+)$")
  if sign3 and h3 then
    return to_minutes(sign3, h3, "0")
  end

  return nil
end

return {
  ["localtime"] = function(args, kwargs, meta, raw_args)
    -- Collect positional args as strings
    local parts = {}
    for _, arg in ipairs(args) do
      table.insert(parts, pandoc.utils.stringify(arg))
    end

    if #parts < 2 then
      io.stderr:write("[localtime] Error: expected at least date and time arguments\n")
      return pandoc.RawInline("html", "<span class='localtime-error'>[localtime: invalid args]</span>")
    end

    local date_str = parts[1]  -- e.g. "2026-01-30"
    local time_str = parts[2]  -- e.g. "13:00" or "1:00"
    local tz_str
    local next_idx = 3

    -- Handle space-separated AM/PM: "1:00 PM EST" → parts = ["1:00", "PM", "EST"]
    if parts[3] and (parts[3]:upper() == "AM" or parts[3]:upper() == "PM") then
      time_str = parts[2] .. " " .. parts[3]
      next_idx = 4
    end
    tz_str = parts[next_idx]

    -- Parse date
    local year, month, day = date_str:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if not year then
      io.stderr:write("[localtime] Error: invalid date format '" .. date_str .. "' (expected YYYY-MM-DD)\n")
      return pandoc.RawInline("html", "<span class='localtime-error'>[localtime: bad date]</span>")
    end
    year, month, day = tonumber(year), tonumber(month), tonumber(day)

    -- Parse time (12-hour or 24-hour)
    local time_str_lower = time_str:lower()
    local hour, minute, ampm = time_str_lower:match("^(%d%d?):(%d%d)%s*([ap]m)$")
    if hour then
      hour, minute = tonumber(hour), tonumber(minute)
      if hour < 1 or hour > 12 then
        io.stderr:write("[localtime] Error: 12-hour clock hour " .. hour .. " is out of range (1-12)\n")
        return pandoc.RawInline("html", "<span class='localtime-error'>[localtime: bad time]</span>")
      end
      if ampm == "am" then
        if hour == 12 then hour = 0 end
      else
        if hour ~= 12 then hour = hour + 12 end
      end
    else
      local h24, m24 = time_str:match("^(%d%d?):(%d%d)$")
      if not h24 then
        io.stderr:write("[localtime] Error: invalid time format '" .. time_str .. "' (expected HH:MM or H:MMam/pm)\n")
        return pandoc.RawInline("html", "<span class='localtime-error'>[localtime: bad time]</span>")
      end
      hour, minute = tonumber(h24), tonumber(m24)
    end

    -- Validate ranges
    if month < 1 or month > 12 then
      io.stderr:write("[localtime] Warning: month " .. month .. " is out of range (1-12)\n")
    end
    if day < 1 or day > 31 then
      io.stderr:write("[localtime] Warning: day " .. day .. " is out of range (1-31)\n")
    end
    if hour < 0 or hour > 23 then
      io.stderr:write("[localtime] Warning: hour " .. hour .. " is out of range (0-23)\n")
    end
    if minute < 0 or minute > 59 then
      io.stderr:write("[localtime] Warning: minute " .. minute .. " is out of range (0-59)\n")
    end

    -- Parse timezone
    local zone = parse_tz(tz_str or "UTC")
    if zone == nil then
      io.stderr:write("[localtime] Warning: unrecognised timezone '" .. (tz_str or "") .. "', assuming UTC\n")
      zone = "UTC"
      tz_str = "UTC"
    end

    -- zone is either a string (IANA name) or a number (offset in minutes).
    -- JS detects which via isNaN(Number(tz)).
    local zone_attr = type(zone) == "number" and tostring(zone) or zone

    -- ISO datetime string without timezone (Luxon applies zone separately)
    local datetime_iso = string.format("%04d-%02d-%02dT%02d:%02d", year, month, day, hour, minute)

    -- Fallback text (shown when JS is disabled)
    local fallback = string.format("%s %s %s", date_str, time_str, tz_str or "UTC")

    -- Optional format kwarg (empty → JS uses its default)
    local fmt_attr = ""
    if kwargs["format"] then
      fmt_attr = pandoc.utils.stringify(kwargs["format"])
    end

    -- Unique element ID
    counter = counter + 1
    local id = "localtime-" .. counter

    -- Inject Luxon CDN script once, before the first localtime element
    local luxon_tag = ""
    if not luxon_script_injected then
      luxon_tag = '<script src="https://cdn.jsdelivr.net/npm/luxon@3/build/global/luxon.min.js"></script>'
      luxon_script_injected = true
    end

    -- Inline JS: reads data attributes, converts timezone, formats with Luxon.
    -- Zone attribute is either an IANA name (string) or offset in minutes (number).
    -- Format string uses strftime-style tokens (%Y, %m, %H, %-H, etc.) substituted
    -- directly — avoiding Luxon's toFormat() for the full string, which would
    -- misinterpret literal text containing Luxon token letters (e.g. "at" → a=AM/PM, t=time).
    local js = [[(function(){var el=document.getElementById(']] .. id .. [[');
if(typeof luxon==='undefined'){return;}
var tz=el.getAttribute('data-tz');
var zone=isNaN(Number(tz))?tz:Number(tz);
var dt=luxon.DateTime.fromISO(el.getAttribute('data-datetime'),{zone:zone}).toLocal();
if(!dt.isValid){return;}
var fmt=el.getAttribute('data-format')||'%Y-%m-%d %H:%M';
var P={datetime:'%Y-%m-%d %H:%M',date:'%Y-%m-%d',time:'%H:%M',time12:'%-I:%M%P',datetime12:'%Y-%m-%d %-I:%M%P',full:'%A, %-d %B %Y at %H:%M %Z',full12:'%A, %-d %B %Y at %-I:%M%P %Z'};
if(P[fmt])fmt=P[fmt];
var pad=function(n){return String(n).padStart(2,'0');};
var h=dt.hour,mi=dt.minute;
el.textContent=fmt
  .replace(/%Y/g,String(dt.year))
  .replace(/%-m/g,String(dt.month)).replace(/%m/g,pad(dt.month))
  .replace(/%-d/g,String(dt.day)).replace(/%d/g,pad(dt.day))
  .replace(/%-H/g,String(h)).replace(/%H/g,pad(h))
  .replace(/%-I/g,String(h%12||12)).replace(/%I/g,pad(h%12||12))
  .replace(/%-M/g,String(mi)).replace(/%M/g,pad(mi))
  .replace(/%P/g,h<12?'am':'pm').replace(/%p/g,h<12?'AM':'PM')
  .replace(/%A/g,dt.toFormat('EEEE')).replace(/%a/g,dt.toFormat('EEE'))
  .replace(/%B/g,dt.toFormat('MMMM')).replace(/%b/g,dt.toFormat('MMM'))
  .replace(/%Z/g,(Intl.DateTimeFormat(undefined,{timeZoneName:'short'}).formatToParts(dt.toJSDate()).find(function(p){return p.type==='timeZoneName';})||{value:''}).value);})();]]

    local html = luxon_tag ..
      '<span id="' .. id .. '" class="localtime"' ..
      ' data-datetime="' .. datetime_iso .. '"' ..
      ' data-tz="' .. zone_attr .. '"' ..
      ' data-format="' .. fmt_attr .. '">' ..
      fallback .. '</span>' ..
      '<script>' .. js .. '</script>'

    return pandoc.RawInline("html", html)
  end
}
