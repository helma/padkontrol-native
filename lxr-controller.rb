#!/usr/bin/env ruby
require 'unimidi'
require 'topaz'

# pads
PADS = (0..15).to_a
# button constants
SCENE = 0x10
MESSAGE = 0x11
SETTING = 0x12
NOTE_CC = 0x13
MIDI_CH = 0x14
SW_TYPE = 0x15
REL_VAL = 0x16
VELOCITY = 0x17
PORT = 0x18
FIXED_VELOCITY = 0x19
PROG_CHANGE = 0x1A
X = 0x1B
Y = 0x1C
KNOB_1_ASSIGN = 0x1D
KNOB_2_ASSIGN = 0x1E
PEDAL = 0x1F
ROLL = 0x20
FLAM = 0x21
HOLD = 0x22
PAD = 0X30

# light state constants
LIGHT_OFF = 0x00
LIGHT_ON = 0x20
LIGHT_BLINK = 0x63

# LED state constants
LED_ON = 0x00
LED_BLINK = 0x01

SYSEX_COMMON = [0xF0, 0x42, 0x40, 0x6E, 0x08]
SYSEX_NATIVE_MODE_ON = SYSEX_COMMON + [0x00, 0x00, 0x01, 0xF7]
SYSEX_NATIVE_MODE_ENABLE_OUTPUT = SYSEX_COMMON + [0x3F, 0x2A, 0x00, 0x00,
    0x05, 0x05, 0x05, 0x7F, 0x7E, 0x7F, 0x7F, 0x03, 0x0A, 0x0A, 0x0A, 0x0A,
    0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A,
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C,
    0x0d, 0x0E, 0x0F, 0x10, 0xF7]
SYSEX_NATIVE_MODE_INIT = SYSEX_COMMON + [0xF0, 0x42, 0x40, 0x6E, 0x08, 0x3F,
    0x0A, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x29, 0x29, 0x29, 0xF7]
# displays YES on LED if native mode is enabled properly
SYSEX_NATIVE_MODE_TEST = SYSEX_COMMON + [0x22, 0x04, 0x00, 0x59, 0x45, 0x53, 0xF7]
SYSEX_NATIVE_MODE_OFF = SYSEX_COMMON + [0x00, 0x00, 0x00, 0xF7]

class Button
  attr_reader :on
  def initialize button, channel
    @on = false
    @button = button
    @channel = channel
  end
  def toggle
    @on = !@on
    update
  end
  def update
    update_pk
    update_lxr
  end
  def update_pk
    @on ? state = LIGHT_ON : state = LIGHT_OFF
    PK_OUT.puts SYSEX_COMMON + [0x01, @button, state, 0xF7]
  end
end

class LxrMuteButton < Button
  def initialize button, channel
    super button,channel
    @controller = 120
    update
  end
  def update_lxr
    @on? val = 0 : val = 127
    LXR_OUT.puts(0xB0+@channel,@controller,val) 
  end
end

class LxrPatternButton < Button
  def initialize button, program
    super button,15
    @program = program
    update
  end
  def select
    @on = true
    update
  end
  def deselect
    @on = false
    update
  end
  def update_lxr
    LXR_OUT.puts(0xC0+@channel,@program)
  end
end

pk_in = UniMIDI::Input.find_by_name("padKONTROL").id+1
PK_IN = UniMIDI::Input.all.select{|i| i.id == pk_in}.first.open
pk_out = UniMIDI::Output.find_by_name("padKONTROL").id+1
PK_OUT = UniMIDI::Output.all.select{|i| i.id == pk_out}.first.open

# enable padKontrol native mode
PK_OUT.puts(SYSEX_NATIVE_MODE_ON)
PK_OUT.puts(SYSEX_NATIVE_MODE_ENABLE_OUTPUT)
PK_OUT.puts(SYSEX_NATIVE_MODE_INIT) # must be sent after SYSEX_NATIVE_MODE_ON

#LXR_OUT = UniMIDI::Output.find_by_name("Sonic Potions USB MIDI").open
LXR_OUT = UniMIDI::Output.find_by_name("Virtual Raw MIDI").open

LXR_MUTE_BUTTONS = []
[
  [SCENE, 9],
  [MESSAGE, 10],
  [FIXED_VELOCITY, 11],
  [PROG_CHANGE, 12],
  [HOLD, 13],
  [FLAM, 14],
  [ROLL, 15],
].each { |mb| LXR_MUTE_BUTTONS[mb.first-0x10] = LxrMuteButton.new mb.first, mb.last-1 }

LXR_PATTERN_BUTTONS = []
[13, 14, 15, 16, 9, 10, 11, 12].each_with_index {|n,i| LXR_PATTERN_BUTTONS[63+n] = LxrPatternButton.new PADS[n-1], i}

LXR_PATTERN_BUTTONS[63+13].select

loop do
  pk = PK_IN.gets.first
  if pk[:data][5] == 72 and pk[:data][7] == 127 # BUTTON on
    LXR_MUTE_BUTTONS[pk[:data][6]].toggle
  elsif pk[:data][5] == 69 and pk[:data][6] > 71 # PAD on
    LXR_PATTERN_BUTTONS.each{|b| b.deselect if b and b.on}
    LXR_PATTERN_BUTTONS[pk[:data][6]].select
  end
end
