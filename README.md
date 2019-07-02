# CrackPipe

## Introduction

A little over a year ago, I discovered [Trailblazer](http://trailblazer.to) and used its concept of "operations" in a few projects. While I came to enjoy their concept of pipelines and result objects, I felt the entire project was entirely too complex for my use cases. I wanted much simpler pipelines and nesting.

### What's with the name?

Gem names are hard to come by these days. I'd considered something slightly more mature like `half_pipe`, but in the age of appending a codes of conduct to projects, I lean offensive in naming wherever possible. I'm kinda wishing I had named [my factory gem](https://github.com/binarypaladin/toil) `meth_lab` instead.

## Installation

Pretty standard gem stuff.

```
$ gem install crack_pipe
```

If you're using [Bundler](https://bundler.io) (and who isn't?) it's likely you'll add this to your `Gemfile` like so:

```
gem 'crack_pipe'
```

## Usage

One day I'll write some actual documentation. (Yeah, right.) In the meantime, [the action spec](spec/action_spec.rb) has a pretty good example of steps, always passing, fail tracks, short circuiting, and nesting actions.

## Contributing

### Issue Guidelines

GitHub issues are for bugs, not support. As of right now, there is no official support for this gem. You can try reaching out to the author, [Joshua Hansen](mailto:joshua@epicbanality.com?subject=CrackPipe+sucks) if you're really stuck, but there's a pretty high chance that won't go anywhere at the moment or you'll get a response like this:

> Hi. I'm super busy. It's nothing personal. Check the README first if you haven't already. If you don't find your answer there, it's time to start reading the source. Have fun! Let me know if I screwed something up.

### Pull Request Guidelines

* Include tests with your PRs.

### Code of Conduct

Don't smoke crack.

## License

See [`LICENSE.txt`](LICENSE.txt).

## What if I stop maintaining this?

The codebase is pretty small. That was one of the main design goals. If you can figure out how to use it, I'm sure you can maintain it.
