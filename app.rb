require "js"

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
end

class BrickType
  attr_reader :image, :points

  def initialize(image, points)
    @image = image
    @points = points
  end
end


class Brick
  attr_reader :x, :y
  def initialize(btype, x, y)
    @btype = btype
    @x = x
    @y = y
  end

  def draw(ctx)
    ctx.drawImage(@btype.image, x, y)
  end

  def height
    BRICK_HEIGHT
  end

  def width
    BRICK_WIDTH
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

  def move_left!(dt)
    rect.x -= PADDLE_SPEED * dt
    rect.x = [0, [GAME_WIDTH-PADDLE_WIDTH, rect.x].min].max
  end

  def move_right!(dt)
    rect.x += PADDLE_SPEED * dt
    rect.x = [0, [GAME_WIDTH-PADDLE_WIDTH, rect.x].min].max
  end
end

class Ball
  attr_accessor :velocity, :rect

  def initialize(image, rect)
    @velocity = [1.0, 3.0]
    @image = image
    @rect = rect
    @velocity = velocity
  end

  def draw(ctx)
    ctx.drawImage(@image, rect.x, rect.y, rect.width, rect.height)
  end
end


class Level
  attr_reader :bricks

  def initialize(layout)
    puts "Initializing layout"
    @bricks = initialize_bricks(layout)
    puts "Initialized a level with #{@bricks.size} bricks"
  end

  private

  def initialize_bricks(layout)
    rows = layout.size
    cols = layout[0].size
    offset_x = (GAME_WIDTH - (BRICK_WIDTH * cols)) / 2
    offset_y = 48

    bricks = []

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

  def initialize(canvas)
    @canvas = canvas
    @canvas[:width] = GAME_WIDTH
    @canvas[:height] = GAME_WIDTH
    @ctx = @canvas.getContext("2d")

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
    request_animaation_frame!
  end

  private

  def key_pressed?(key)
    @keys_down[0] == key
  end

  def update
    # Move the ball
    @ball.rect.x = @ball.rect.x + @ball.velocity[0]
    @ball.rect.y = @ball.rect.y + @ball.velocity[1]

    # Move the paddle
    if key_pressed?(:ArrowLeft)
      @paddle.move_left!(@dt)
    elsif key_pressed?(:ArrowRight)
      @paddle.move_right!(@dt)
    end
  end

  def draw
    # Draw background
    ctx[:fillStyle] = "#140c1c"
    ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT)

    # Draw bricks
    @level.bricks.each do |brick|
      brick.draw(ctx)
    end

    @ball.draw(ctx)
    @paddle.draw(ctx)
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
