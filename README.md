# Ruby Game Template

This project is a quick way to get started building games in Ruby that run in the browser!

---

*First, a bit of editorialization*: I am a big fan of Scheme and I've been following the development
of [Guile Hoot](https://spritely.institute/hoot/) for a while now. I'm excited to run Scheme in the
browser. Also, I write a lot of Ruby code and am equally as excited to run [Ruby in the browser with
WebAssembly](https://github.com/ruby/ruby.wasm). This project is a re-implementation of the
https://gitlab.com/spritely/guile-hoot-game-jam-template written by [David
Thompson](https://dthompson.us). All credit for the game goes to him!

---

The project includes:

* A simple Breakout clone to use as a starting point.

* `index.html` boilerplate to start the game.

* Examples of DOM bindings for events, images, and sounds.

* Example animation loop drawing on an HTML Canvas

* A `Rakefile` to run a server locally

## Tutorial

This repo is a "template", so the first thing you want to do is to generate your own Github repo. To
do this, click the "User this template" drop down in the top right and select "Create a new
Repository". Then, clone the repository to your local machine.

Ensure that you have Ruby installed on your machine and then you can run a local develpment
server. First make sure you have dependencies installed with Bundler:

```
bundle install
```

Then, run the rake task to start the server:

```
rake server
```

Open http://localhost:8000 and start editing game.rb!

The template uses the pre-compiled WASM binary from the Ruby project available
https://cdn.jsdelivr.net. So there's no need to wait for anything to compile. Make sure that you
have caching disabled in your web browser and simply refresh to see the latest and greatest version
of your game.

## Deployment

Push the latest to your main branch and turn on Github pages. The game will be deployed for you!

Check out the default example running here https://gregbell.github.io/ruby-game-template/.

## Getting help

If you have questions or need some help, visit the
https://github.com/gregbell/ruby-game-template/discussions.
