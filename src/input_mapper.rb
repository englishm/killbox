class Actor
  attr_accessor :input_mapper
  def input
    @input_mapper ||= this_object_context[:input_mapper]
  end
end

class InputMapper
  extend Publisher
  can_fire_anything

  construct_with :input_manager
  def initialize
    @action_ids = {}
  end

  # map_input is to be setup outside of an actor and passed in at construction
  # time ie:
  #
  # mapper.map_input {
  #  '+a' => :jump,   # emit jump when 'a' is _pressed_
  #  '-b' => :duck,   # emit duck when 'b' is _released_
  #  'c'  => :block   # emit block when 'c' is _pressed_ AND _released_
  # }
  #
  # all keys will have a <key_name>? defined for checking state at anytime
  # create_actor :fighter, input: mapper
  # 
  # all of the actor's behaviors can / should use the input mapper instead of raw key bindings
  def map_input(input_hash)
    input_hash.each do |input, actions|
      if input.start_with? '-'
        register_key_released(input[1..-1], actions)
      elsif input.start_with? '+'
        register_key_pressed(input[1..-1], actions)
      else
        register_key_released(input, actions)
        register_key_pressed(input, actions)
      end
    end
  end

  # unsubscribes for all input
  def clear
    input_manager.unsubscribe_all
  end

  def method_missing(name, *args)
    if name.to_s.end_with? '?'
      button_syms = @action_ids[name[0..-2].to_sym]
      if button_syms
        return button_syms.any? do |button_sym| 
          input_manager.down_ids.include? BUTTON_SYM_TO_ID[button_sym]
        end
      end
    end

    false
  end

  private
  def register_key_pressed(key, actions)
    input_manager.reg :down, BUTTON_SYM_TO_ID[key.to_sym] do |*args|
      Array.wrap(actions).each do |action|
        fire action, *args
      end
    end
    def_state_probe_method(key, actions)
  end

  def register_key_released(key, actions)
    input_manager.reg :up, BUTTON_SYM_TO_ID[key.to_sym] do |*args|
      Array.wrap(actions).each do |action|
        fire action, *args
      end
    end

    def_state_probe_method(key, actions)
  end

  def def_state_probe_method(key, actions)
    Array.wrap(actions).each do |action|
      @action_ids[action] ||= []
      @action_ids[action] << key.to_sym
    end
  end
end

class Array
  def self.wrap(thing)
    if thing.is_a? Array
      thing
    else
      [thing]
    end
  end
end
