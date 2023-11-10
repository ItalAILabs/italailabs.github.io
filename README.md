# ItalAILAbs

See it live in action at <https://italailabs.github.io/>

## To use the Creative Theme template in your project

- Start by adding your info in `_config.yml`
- In `_layouts/front.html` reorder or remove section as you prefer.

## Run locally (macOS only)

Github guide [here](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll).

1. Create a `Gemfile` in the root directory:
```sh
source 'https://rubygems.org'
gem 'github-pages', group: :jekyll_plugins
```

2. Install all of the required gems:
```sh
bundle install
```

3. Run your Jekyll site locally:
```sh
bundle exec jekyll serve
```