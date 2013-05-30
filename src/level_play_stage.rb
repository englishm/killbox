define_stage :level_play do
  render_with :multi_viewport_renderer
  requires :score_keeper, :sound_manager,
    :bomb_coordinator, :bullet_coordinator, :sword_coordinator

  curtain_down do |*args|
    sound_manager.stop_music :smb11
    director.unsubscribe_all self
    input_manager.clear_hooks
  end

  curtain_up do |*args|
    opts = args.first || {}
    input_manager.reg :down, KbEscape do
      fire :change_stage, :map_select
    end

    director.update_slots = [:first, :before, :update, :last]

    @console = create_actor(:console, visible: false)
    setup_level backstage[:level_name]
    setup_players backstage[:player_count]

    sound_manager.play_music :smb11, repeat: true

    director.when :update do |time|
      unless @restarting
        alive_players = @players.select{|player| player.alive?}
        if @players.size > 1 && alive_players.size < 2
          last_man_standing = alive_players.first

          (@players - alive_players).each do |player_that_died| 
            score_keeper.player_score(player_that_died, -1)
          end
          round_over 
        end
        @computer_players.each do |npc|
          npc.take_turn time
        end
      end
    end

    # F1 console watch values
    player = @players[1]
    if player
      @console.react_to :watch, :p2rotvel do player.rotation_vel end
    end
    @console.react_to :watch, :fps do Gosu.fps end
  end

  helpers do
    attr_accessor :players, :viewports

    def levels 
      {
      :trippy => 4,
      :section_a => 4,
      :basic_jump => 1,
      # :advanced_jump => 2,
      # :cave => 4,
      # :hot_pocket => 2,
      }
    end

    def setup_level(name)
      @level = LevelLoader.load self, name
    end

    def setup_players(player_count=1)
      @computer_players = []
      @players = []
      starting_positions = @level.zones.select{ |zone| zone.type=="start_location" }.sample(player_count)
      starting_positions.each.with_index do |start_zone, i|
        number = i + 1
        name = "player#{number}".to_sym

        zone_properties = start_zone.properties
        rotation = (zone_properties['rotation'] || 0).to_i

        zone_rect = Rect.new start_zone.x, start_zone.y, start_zone.width, start_zone.height
        x = zone_rect.centerx
        y = zone_rect.centery

        player = create_actor :foxy,
          map: @level.map,
          x: x,
          y: y,
          rotation: 0,
          number: number,
          vel: player_velocity(rotation)

        player.rotation = rotation # needed to trigger behaviors
        player.animation_file = "trippers/#{player_color(i)}_tripper.png"
        player.input.map_input(controls[name])

        @players << player
      end
      renderer.viewports = PlayerViewport.create_n @players, config_manager[:screen_resolution]
    end

    def player_color(index)
      %w(red green purple blue)[index]
    end

    def player_velocity(rotation)
      {
        0 => vec2(0,3),
        180 => vec2(0,-3),
        90 => vec2(-3,0),
        270 => vec2(3,0)
      }[rotation]
    end

    def controls
      they = { player1: {
          '+b' => :shoot,
          '+n' => :charging_jump,
          '+m' => :charging_bomb,
          '+v' => :shields_up,
          '+w' => :look_up,
          '+a' => [:look_left, :walk_left],
          '+d' => [:look_right, :walk_right],
          '+s' => :look_down,
        },
        player2: {
          '+i' => :shoot,
          '+o' => :charging_jump,
          '+p' => :charging_bomb, 
          '+u' => :shields_up, 
          '+t' => :look_up,
          '+f' => [:look_left, :walk_left],
          '+h' => [:look_right, :walk_right],
          '+g' => :look_down,

          '+gp0_button_0' => :shoot,
          '+gp0_button_1' => :charging_jump,
          '+gp0_button_2' => :charging_bomb,
          '+gp0_button_3' => :shields_up,
          '+gp0_up' => :look_up,
          '+gp0_left' => [:look_left, :walk_left],
          '+gp0_right' => [:look_right, :walk_right],
          '+gp0_down' => :look_down,
        },
        player3: {
          '+gp1_button_0' => :shoot,
          '+gp1_button_1' => :charging_jump,
          '+gp1_button_2' => :charging_bomb,
          '+gp1_button_3' => :shields_up,
          '+gp1_up' => :look_up,
          '+gp1_left' => [:look_left, :walk_left],
          '+gp1_right' => [:look_right, :walk_right],
          '+gp1_down' => :look_down,
        },
        player4: {
          '+gp2_button_0' => :shoot,
          '+gp2_button_1' => :charging_jump,
          '+gp2_button_2' => :charging_bomb,
          '+gp2_button_3' => :shields_up,
          '+gp2_up' => :look_up,
          '+gp2_left' => [:look_left, :walk_left],
          '+gp2_right' => [:look_right, :walk_right],
          '+gp2_down' => :look_down,
        }
      }

      # they[:player3] = they[:player1]
      # they[:player4] = they[:player1]
      they

    end

    def round_over
      @restarting = true
      timer_manager.add_timer 'restart', 2000 do
        timer_manager.remove_timer 'restart'
        fire :change_stage, :score, {}
      end
    end

  end
end

