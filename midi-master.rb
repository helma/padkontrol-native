require_relative "pk.rb"

=begin
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
=end
p AlsaRawMIDI::Device.all.select{|i| i.subname=="padKONTROL MIDI 2"}
AlsaRawMIDI::Device.all.select{|i| i.subname=="padKONTROL MIDI 2"}.first.open do |input|
#PK_IN.open do |input|
  loop do
    pk = input.gets#.first
    p pk
    pk = pk.first
    p pk[:data]
    if pk[:data][5] == 72 and pk[:data][7] == 127 # BUTTON on
      p "BUTTON"
      #LXR_MUTE_BUTTONS[pk[:data][6]].toggle
    elsif pk[:data][5] == 69 # PAD on
      p "PAD"
    elsif pk[:data][5] == 67 # ENCODER
      p "ENC"
    elsif pk[:data][5] == 73 # KNOB
      p "KNOB"
      # TODO X,Y 
      #LXR_PATTERN_BUTTONS.each{|b| b.deselect if b and b.on}
      #LXR_PATTERN_BUTTONS[pk[:data][6]].select
    end
  end
end
