require "js"
require "forwardable"

puts RUBY_VERSION # (Printed to the Web browser console)

puts "Starting app.rb"

GAME_WIDTH = 640
GAME_HEIGHT = 480
BRICK_WIDTH = 64
BRICK_HEIGHT = 32
PADDLE_WIDTH = 104
PADDLE_HEIGHT = 24
PADDLE_SPEED = 0.35
BALL_WIDTH = 22
BALL_HEIGHT = 22

class Rect
  attr_accessor :x, :y, :width, :height

  def initialize(x, y, width, height)
    @x = x
    @y = y
    @width = width
    @height = height
  end

  def intersects?(other)
    @x < other.x + other.width &&
    @x + @width > other.x &&
    @y < other.y + other.height &&
    @y + @height > other.y
  end

  def clip(other)
    x = [@x, other.x].max
    y = [@y, other.y].max

    end_x = [@x + @width, other.x + other.width].min
    end_y = [@y + @height, other.y + other.height].min

    if x > end_x || y > end_y
      return nil
    end

    Rect.new(x, y, end_x - x, end_y - y)
  end
end

class BrickType
  attr_reader :image, :points

  def initialize(image, points)
    @image = image
    @points = points
  end
end

class Brick
  extend Forwardable

  attr_reader :rect

  def initialize(btype, x, y)
    @btype = btype
    @rect = Rect.new(x, y, BRICK_WIDTH, BRICK_HEIGHT)
    @broken = false
  end

  def_delegators :rect, :x, :y, :width, :height

  def draw(ctx)
    ctx.drawImage(@btype.image, x, y)
  end

  def points
    @btype.points
  end

  def break!
    @broken = true
  end

  def broken?
    @broken
  end
end


class Paddle
  attr_reader :rect

  def initialize(image, rect)
    @image = image
    @rect = rect
  end

  def draw(ctx)
    ctx.drawImage(@image, rect.x, rect.y, rect.width, rect.height)
  end

  def move_left(dt)
    rect.x -= PADDLE_SPEED * dt
    rect.x = [0, [GAME_WIDTH-PADDLE_WIDTH, rect.x].min].max
  end

  def move_right(dt)
    rect.x += PADDLE_SPEED * dt
    rect.x = [0, [GAME_WIDTH-PADDLE_WIDTH, rect.x].min].max
  end
end

class Ball
  attr_accessor :velocity, :rect

  def initialize(image, rect)
    @velocity = [2.0, 6.0]
    @image = image
    @rect = rect
    @velocity = velocity
  end

  def draw(ctx)
    ctx.drawImage(@image, rect.x, rect.y, rect.width, rect.height)
  end

  def reflect(x, y)
    velocity[0] = -1 * velocity[0] if x
    velocity[1] = -1 * velocity[1] if y
  end

  def collide!(other)
    overlap = rect.clip(other)
    if overlap.width < overlap.height
      reflect(true, false)
      if rect.x == overlap.x
        rect.x = rect.x + overlap.width
      else
        rect.x = rect.x - overlap.width
      end
    else
      reflect(false, true)
      if rect.y == overlap.y
        rect.y = rect.y + overlap.height
      else
        rect.y = rect.y - overlap.height
      end
    end
  end
end


class Level
  attr_reader :bricks

  def initialize(layout)
    puts "Initializing layout"
    @bricks = initialize_bricks(layout)
    puts "Initialized a level with #{@bricks.size} bricks"
  end

  def clear?
    @bricks.all? &:broken?
  end

  private

  def initialize_bricks(layout)
    rows = layout.size
    cols = layout[0].size
    offset_x = (GAME_WIDTH - (BRICK_WIDTH * cols)) / 2
    offset_y = 48

    bricks = Array.new(rows * cols)

    layout.each_with_index do |row, y|
      row.each_with_index do |btype, x|
        flat_index = (y * cols) + x
        bricks[flat_index] = Brick.new(btype,
                                           (x * BRICK_WIDTH) + offset_x,
                                           (y * BRICK_HEIGHT) + offset_y)
      end
    end

    bricks
  end
end


class Game
  attr_reader :canvas, :ctx

  STATE_PLAY = :play
  STATE_LOSE = :lose
  STATE_WIN = :win

  def initialize(canvas)
    @canvas = canvas
    @canvas[:width] = GAME_WIDTH
    @canvas[:height] = GAME_WIDTH
    @ctx = @canvas.getContext("2d")

    @state = nil
    @score = 0

    @last_ts = 0
    @dt = 0

    # Handle Key Presses
    @keys_down = []
    JS.global[:document].addEventListener "keydown" do |event|
      key_code = js_event_to_key_code(event)
      @keys_down.unshift(key_code) unless @keys_down.include?(key_code)
      nil
    end
    JS.global[:document].addEventListener "keyup" do |event|
      key_code = js_event_to_key_code(event)
      @keys_down.delete_if{|key| key == key_code }
      nil
    end

    brick_types = {
      red: BrickType.new(image("assets/images/brick-red.png"), 10),
      green: BrickType.new(image("assets/images/brick-green.png"), 20),
      blue: BrickType.new(image("assets/images/brick-blue.png"), 30)
    }

    # Level 1
    @level = Level.new(
      [
        [:red, :green, :blue, :red, :green, :blue, :red, :green],
        [:green, :blue, :red, :green, :blue, :red, :green, :blue],
        [:blue, :red, :green, :blue, :red, :green, :blue, :red],
        [:red, :green, :blue, :red, :green, :blue, :red, :green],
        [:green, :blue, :red, :green, :blue, :red, :green, :blue],
        [:blue, :red, :green, :blue, :red, :green, :blue, :red]
      ].map{|row| row.map{|color| brick_types[color] }}
    )

    @paddle = Paddle.new(
      image("assets/images/paddle.png"),
      Rect.new(
        (GAME_WIDTH/2) - (PADDLE_WIDTH/2),
        GAME_HEIGHT - PADDLE_HEIGHT - 8,
        PADDLE_WIDTH,
        PADDLE_HEIGHT
      )
    )

    @ball = Ball.new(
      image("assets/images/ball.png"),
      Rect.new(
        GAME_WIDTH / 2,
        GAME_HEIGHT / 2,
        BALL_WIDTH,
        BALL_HEIGHT
      )
    )
  end

  def start!
    puts "Running Game#start!"
    @score = 0
    @state = STATE_PLAY
    request_animaation_frame!
  end

  private

  def key_pressed?(key)
    @keys_down[0] == key
  end

  def update
    if @state == STATE_PLAY
      # Move the paddle
      if key_pressed?(:ArrowLeft)
        @paddle.move_left(@dt)
      elsif key_pressed?(:ArrowRight)
        @paddle.move_right(@dt)
      end

      # Move the ball
      @ball.rect.x = @ball.rect.x + @ball.velocity[0]
      @ball.rect.y = @ball.rect.y + @ball.velocity[1]

      # Wall collisions
      if @ball.rect.x < 0 # left wall
        @ball.rect.x = 0
        @ball.reflect(true, false)

      elsif (@ball.rect.x+@ball.rect.width) > GAME_WIDTH # right wall
        @ball.rect.x = GAME_WIDTH - @ball.rect.width
        @ball.reflect(true, false)

      elsif (@ball.rect.y+@ball.rect.height) > GAME_HEIGHT # bottom wall
        @ball.rect.y = GAME_HEIGHT - @ball.rect.height
        @ball.reflect(false, true)
        @state = STATE_LOSE

      elsif @ball.rect.y < 0 # top wall
        @ball.rect.y = 0
        @ball.reflect(false, true)

      elsif @ball.rect.intersects?(@paddle.rect)
        @ball.collide! @paddle.rect
      else
        @level.bricks.each do |brick|
          if !brick.broken? && @ball.rect.intersects?(brick.rect)
            @ball.collide! brick.rect
            @score += brick.points
            brick.break!
            @state = STATE_WIN if @level.clear?
          end
        end
      end
    end
  end

  def draw
    # Draw background
    ctx[:fillStyle] = "#140c1c"
    ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT)

    # Draw bricks
    @level.bricks.each do |brick|
      brick.draw(ctx) if !brick.broken?
    end

    @ball.draw(ctx)
    @paddle.draw(ctx)

    ctx[:fillStyle] = "#ffffff"
    ctx[:font] = "bold 24px monospace"
    ctx[:textAlign] = "left"
    ctx.fillText("SCORE:", 16, 36)
    ctx.fillText(@score, 108, 36)

    if @state == STATE_WIN
      ctx[:font] = "bold 36px monospace"
      ctx[:textAlign] = "center"
      ctx.fillText("YAY, YOU DID IT!!!", GAME_WIDTH / 2, GAME_HEIGHT / 2)
    elsif @state == STATE_LOSE
      ctx[:font] = "bold 36px monospace"
      ctx[:textAlign] = "center"
      ctx.fillText("OH NO, GAME OVER :(", GAME_WIDTH / 2, GAME_HEIGHT / 2)
    end
  end

  def animate(ts)
    fts = ts.to_f # Make sure its a Ruby float
    @dt = fts - @last_ts
    @last_ts = fts

    update
    draw

    request_animaation_frame!
  end

  def image(src)
    img = JS.global[:Image].new
    img[:src] = src
    img
  end

  def request_animaation_frame!
    JS.global.requestAnimationFrame{|ts| animate(ts) }
  end

  # Returns either a symbol or nil for the key in the event
  def js_event_to_key_code(event)
    return unless event && event[:key]

    event[:key].to_s.to_sym
  end
end

puts "Initializing game"

Game.new(JS.global[:document].getElementById("canvas")).start!

"Starting up"
